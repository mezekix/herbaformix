# Uygulama Planı: Müşteri Program Oluşturma

## Genel Bakış

Bu plan, `customer-program-creation` özelliğini katmanlı ve bağımsız adımlarla hayata geçirir. Her görev bir öncekinin üzerine inşa edilir; hiçbir kod parçası entegre edilmeden bırakılmaz. Uygulama dili **Dart / Flutter**'dır.

---

## Görevler

- [x] 1. Veri Modellerini Oluştur
  - [x] 1.1 `ProgramModel` ve `MealSlot` sınıflarını yaz
    - `lib/features/program/models/program_model.dart` dosyasını oluştur
    - `ProgramModel` alanları: `id`, `userGoal`, `startDate`, `durationMonths`, `mealPlan`, `currentWeight`, `targetWeight`, `createdAt`, `isActive`
    - `MealSlot` alanları: `type` (`product` | `normal_meal`), `productId`, `productName`, `scheduledTime` ("HH:mm")
    - `toMap()` / `fromMap()` metotlarını yaz; `weight_loss` dışındaki hedeflerde `currentWeight` ve `targetWeight` alanları `null` olmalı
    - `_Requirements: 5.2_`

  - [ ]* 1.2 `ProgramModel` serileştirme property testi yaz
    - **Özellik 7: ProgramModel Serileştirme Bütünlüğü**
    - `test/features/program/models/program_model_test.dart` dosyasını oluştur
    - `fast_check` ile rastgele `ProgramModel` üret; `toMap()` çıktısının zorunlu alanları içerdiğini ve `fromMap(toMap(x)) == x` olduğunu doğrula
    - `weight_loss` hedefi için `current_weight` ve `target_weight` alanlarının varlığını kontrol et
    - **Doğrular: Gereksinim 5.2**

  - [x] 1.3 `DailyRoutineModel`'i `stepType` ve `amountMl` alanlarıyla genişlet
    - `lib/models/daily_routine_model.dart` dosyasını güncelle
    - `stepType` alanı ekle: `'product'` | `'water'` (varsayılan: `'product'`)
    - `amountMl` alanı ekle: `int?` (su adımları için 250)
    - `toMap()` ve `fromMap()` metotlarını güncelle; mevcut testler bozulmamalı
    - `_Requirements: 4.1, 4.3_`

  - [x] 1.4 Süre ve saat hesaplama fonksiyonlarını yaz
    - `lib/features/program/models/program_model.dart` içine `calculateMinDuration()`, `calculateEveningMealTime()`, `calculateWaterStepTime()` fonksiyonlarını ekle
    - `calculateMinDuration`: diff ≤ 0 → `ArgumentError`; 1–5 → 1; 6–10 → 2; 11–20 → 3; >20 → 4
    - `calculateEveningMealTime`: `sleepTime - 3 saat`
    - `calculateWaterStepTime`: `mealTime - 30 dakika`
    - `_Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_`

  - [ ]* 1.5 Geçersiz kilo girişi property testi yaz
    - **Özellik 1: Geçersiz Kilo Girişi Reddi**
    - `fast_check` ile `diff <= 0` olan değerler üret; `calculateMinDuration` her durumda `ArgumentError` fırlatmalı
    - **Doğrular: Gereksinim 2.6**

  - [ ]* 1.6 Süre hesaplama doğruluğu property testi yaz
    - **Özellik 2: Süre Hesaplama Doğruluğu**
    - `fast_check` ile pozitif `diff` değerleri üret; dönen sürenin aralık kurallarına uyduğunu doğrula
    - **Doğrular: Gereksinim 2.1, 2.2, 2.3, 2.4, 2.5**

- [x] 2. Servis Katmanını Oluştur
  - [x] 2.1 `ProgramService` sınıfını yaz
    - `lib/features/program/services/program_service.dart` dosyasını oluştur
    - `saveProgram(userId, program)`: `users/{uid}/program` dokümanına yaz; mevcut aktif program varsa önce sil
    - `getActiveProgram(userId)`: `is_active == true` olan dokümanı getir
    - `watchActiveProgram(userId)`: gerçek zamanlı stream döndür
    - `deleteProgram(userId, programId)`: dokümanı sil
    - `hasActiveProgram(userId)`: bool döndür
    - Tüm Firestore işlemleri `try-catch` ile sarılmalı; `FirebaseException` yakalanmalı
    - `_Requirements: 5.1, 5.2, 5.5, 5.6, 5.7_`

  - [x] 2.2 `ProgramService.saveProgram` içinde rutin oluşturma entegrasyonunu yaz
    - Program Firestore'a kaydedildikten sonra `RoutineService.generateDailyRoutine()` çağır
    - `assignedProducts` parametresine yalnızca `type == 'product'` olan öğünlerin ürünlerini geçir
    - Her ürün atanmış öğün için `calculateWaterStepTime()` ile su adımı oluştur ve `Daily_Routines`'e `stepType: 'water'` olarak kaydet
    - `_Requirements: 5.3, 5.4, 4.1_`

  - [ ]* 2.3 `generateDailyRoutine` parametre filtresi property testi yaz
    - **Özellik 11: generateDailyRoutine Parametre Filtresi**
    - `fast_check` ile rastgele `MealSlot` haritası üret; `saveProgram` çağrısında `assignedProducts`'ın yalnızca `type == 'product'` öğünleri içerdiğini doğrula
    - **Doğrular: Gereksinim 5.4**

  - [ ]* 2.4 Su adımı sayısı ve zamanlaması property testi yaz
    - **Özellik 5: Su Adımı Sayısı ve Zamanlaması**
    - `fast_check` ile rastgele öğün planı üret; oluşturulan su adımı sayısının ürün atanmış öğün sayısına eşit olduğunu ve her su adımının öğün saatinden tam 30 dk önce olduğunu doğrula
    - **Doğrular: Gereksinim 4.1**

  - [ ]* 2.5 Rutin listesinde su adımı sıralaması property testi yaz
    - **Özellik 6: Rutin Listesinde Su Adımı Sıralaması**
    - `fast_check` ile rastgele rutin listesi üret; her `stepType == 'water'` adımının ilgili `stepType == 'product'` adımından önce geldiğini doğrula
    - **Doğrular: Gereksinim 4.3, 8.2**

  - [x] 2.6 `NotificationService` sınıfını yaz
    - `lib/features/program/services/notification_service.dart` dosyasını oluştur
    - `flutter_local_notifications` paketini kullan
    - `initialize()`: servisi başlat ve izin iste; `bool` döndür
    - `scheduleMealNotification({notificationId, title, body, scheduledTime})`: günlük tekrarlayan bildirim planla
    - `cancelAllProgramNotifications()`: morning (1000), lunch (1001), evening (1002) ID'li bildirimleri iptal et
    - `hasPermission()` ve `requestPermission()` metotlarını yaz
    - Bildirim hataları program akışını engellemez (graceful degradation)
    - `_Requirements: 6.1, 6.2, 6.4, 6.5, 6.6_`

  - [ ]* 2.7 Bildirim sayısı tutarlılığı property testi yaz
    - **Özellik 8: Bildirim Sayısı Tutarlılığı**
    - `fast_check` ile rastgele öğün planı üret; planlanan bildirim sayısının `type == 'product'` öğün sayısına eşit olduğunu ve `normal_meal` öğünler için bildirim planlanmadığını doğrula
    - **Doğrular: Gereksinim 6.1, 3.6**

- [ ] 3. Kontrol Noktası — Tüm testler geçmeli
  - Tüm testlerin geçtiğini doğrula; sorular varsa kullanıcıya sor.

- [x] 4. `ProgramProvider`'ı Oluştur
  - [x] 4.1 `ProgramProvider` sınıfını yaz
    - `lib/features/program/providers/program_provider.dart` dosyasını oluştur
    - Wizard durumu: `currentStep` (0–3), `selectedGoal`, `currentWeight`, `targetWeight`, `durationMonths`, `mealPlan`
    - Aktif program: `activeProgram`, `isLoading`, `errorMessage`
    - `calculateMinDuration()` metodunu `ProgramModel`'deki fonksiyona delege et
    - `nextStep()` / `previousStep()` navigasyon metotlarını yaz
    - `saveProgram(userId)`: `ProgramService.saveProgram()` çağır; ardından `NotificationService.scheduleMealNotification()` çağır
    - `loadActiveProgram(userId)`: `ProgramService.getActiveProgram()` çağır
    - `_Requirements: 1.1, 1.2, 1.3, 1.5, 2.7, 2.8_`

  - [ ]* 4.2 Kalan gün hesaplama property testi yaz
    - **Özellik 10: Kalan Gün Hesaplama Doğruluğu**
    - `fast_check` ile rastgele `(startDate, durationMonths)` çifti üret; kalan gün sayısının hiçbir zaman negatif olmadığını doğrula
    - **Doğrular: Gereksinim 8.5**

- [x] 5. Wizard Ekranını Oluştur (`CreateProgramScreen`)
  - [x] 5.1 Ekran iskeletini ve adım navigasyonunu yaz
    - `lib/features/program/screens/create_program_screen.dart` dosyasını oluştur
    - `static const String routeName = 'create-program'` tanımla
    - `PageView` veya `IndexedStack` ile 4 adım arası geçiş sağla
    - `ProgramProvider.currentStep` değerine göre aktif adımı göster
    - `_Requirements: 7.1_`

  - [x] 5.2 `GoalSelectionStep` widget'ını yaz
    - `lib/features/program/widgets/goal_selection_card.dart` dosyasını oluştur
    - Üç hedef kartı: `weight_loss`, `healthy_living`, `weight_gain`
    - Seçim `ProgramProvider.selectedGoal`'a yazılmalı
    - `_Requirements: 1.1, 1.2_`

  - [x] 5.3 `WeightInputStep` widget'ını yaz
    - Yalnızca `selectedGoal == 'weight_loss'` ise göster; diğer hedeflerde bu adım atlanmalı
    - Mevcut kilo ve hedef kilo alanları; boş bırakılırsa "Lütfen mevcut ve hedef kilonuzu girin." uyarısı
    - Hedef kilo ≥ mevcut kilo ise "Hedef kilo mevcut kilodan küçük olmalıdır." uyarısı
    - Hesaplanan minimum süreyi göster; müşteri artırabilmeli
    - `_Requirements: 1.3, 1.4, 2.6, 2.8_`

  - [x] 5.4 `MealPlanStep` widget'ını yaz
    - `lib/features/program/widgets/meal_plan_tile.dart` dosyasını oluştur
    - Sabah, öğle, akşam öğün dilimleri; `UserProfileModel.wakeTime`, `lunchTime`, `sleepTime` alanlarından saatleri doldur
    - Saat alanı boşsa kullanıcıdan giriş iste
    - `weight_loss` için sabah ve akşam varsayılan Shake; öğle için Shake / Normal_Yemek seçeneği
    - Ürün seçiminde yalnızca `category == 'meal_replacement'` ürünleri listele
    - Seçilen ürünün `instructionsByGoal[userGoal]` talimatını göster
    - `_Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.7, 3.8_`

  - [ ]* 5.5 Meal replacement filtresi property testi yaz
    - **Özellik 3: Meal Replacement Filtresi**
    - `fast_check` ile rastgele ürün listesi üret; `MealPlanStep`'in sunduğu listenin yalnızca `category == 'meal_replacement'` ürünleri içerdiğini doğrula
    - **Doğrular: Gereksinim 3.4**

  - [ ]* 5.6 Öğün talimatı eşleşmesi property testi yaz
    - **Özellik 4: Öğün Talimatı Eşleşmesi**
    - `fast_check` ile rastgele ürün ve `userGoal` kombinasyonu üret; gösterilen talimatın `product.instructionsByGoal[userGoal]` ile tam eşleştiğini doğrula
    - **Doğrular: Gereksinim 3.5**

  - [x] 5.7 `ProgramSummaryStep` widget'ını yaz
    - `lib/features/program/widgets/program_summary_card.dart` dosyasını oluştur
    - Gösterilecek bilgiler: seçilen hedef, program süresi, başlangıç tarihi, her öğün için ürün adı veya "Normal Yemek", öğün saatleri
    - "Programı Başlat" butonu: `ProgramProvider.saveProgram()` çağırır; yükleme sırasında `CircularProgressIndicator` göster ve butonu devre dışı bırak
    - "Geri Dön" butonu: öğün planlama adımına döner
    - Hata mesajı varsa `errorMessage` alanını göster
    - `_Requirements: 7.2, 7.3, 7.4, 7.5_`

  - [ ]* 5.8 Özet ekranı veri bütünlüğü property testi yaz
    - **Özellik 9: Özet Ekranı Veri Bütünlüğü**
    - `fast_check` ile rastgele `ProgramModel` üret; özet widget'ının hedef, süre, başlangıç tarihi, öğün adları ve saatlerini render ettiğini doğrula
    - **Doğrular: Gereksinim 7.2**

- [ ] 6. Kontrol Noktası — Tüm testler geçmeli
  - Tüm testlerin geçtiğini doğrula; sorular varsa kullanıcıya sor.

- [x] 7. Aktif Program Ekranını Entegre Et (`Programım` Sekmesi)
  - [x] 7.1 `ActiveProgramScreen` widget'ını yaz
    - `lib/features/program/screens/active_program_screen.dart` dosyasını oluştur
    - `ProgramProvider.watchActiveProgram()` stream'ini dinle
    - Aktif program yoksa "Program Oluştur" yönlendirme butonu göster
    - Aktif program varsa: hedef, kalan gün sayısı (`startDate + durationMonths - bugün`, min 0), bugünkü öğün planı özeti göster
    - `_Requirements: 8.1, 8.5_`

  - [x] 7.2 Günlük rutin listesini `ActiveProgramScreen`'e ekle
    - `RoutineService.getDailyRoutines()` stream'ini kullan
    - Su adımları (`stepType == 'water'`) ve ürün adımları (`stepType == 'product'`) sıralı listelenmeli; su adımı her zaman ilgili öğün adımından önce
    - `lib/features/program/widgets/water_step_tile.dart` dosyasını oluştur
    - `_Requirements: 8.2, 4.3_`

  - [x] 7.3 Rutin adımı "Yaptım" işaretleme mantığını yaz
    - Ürün adımı işaretlendiğinde `RoutineService.updateRoutineStatus()` çağır
    - Su adımı işaretlendiğinde `RoutineService.updateRoutineStatus()` çağır ve `WaterProvider.addWater(250)` çağır
    - `WaterProvider.addWater()` başarısız olursa "Su kaydı yapılamadı, lütfen tekrar deneyin." snackbar göster
    - `_Requirements: 8.3, 8.4, 4.2, 4.4, 4.5_`

  - [x] 7.4 `HomeScreen`'deki `_buildProgramimTab` metodunu `ActiveProgramScreen` ile değiştir
    - `lib/features/home/screens/home_screen.dart` içindeki `case 1:` bloğunu güncelle
    - `ActiveProgramScreen` widget'ını döndür
    - `_Requirements: 8.1_`

- [x] 8. Router ve `main.dart` Güncellemeleri
  - [x] 8.1 `CreateProgramScreen` rotasını router'a ekle
    - `lib/core/router.dart` dosyasını güncelle
    - `HomeScreen` alt rotalarına `create-program` rotasını ekle
    - `GoRoute(path: CreateProgramScreen.routeName, builder: ...)` tanımla
    - `_Requirements: 7.1_`

  - [x] 8.2 `ProgramProvider`'ı `main.dart`'a ekle
    - `lib/main.dart` dosyasını güncelle
    - `MultiProvider` listesine `ChangeNotifierProvider<ProgramProvider>` ekle
    - `ProgramService` ve `NotificationService` bağımlılıklarını enjekte et
    - `_Requirements: 5.1, 6.1_`

  - [x] 8.3 `NotificationService.initialize()` çağrısını uygulama başlangıcına ekle
    - `lib/main.dart` içinde `Firebase.initializeApp()` sonrasına `NotificationService().initialize()` çağrısını ekle
    - `_Requirements: 6.5_`

- [x] 9. Su Adımı Entegrasyonunu Tamamla
  - [x] 9.1 `WaterStepTile` widget'ını `ActiveProgramScreen`'e bağla
    - `WaterProvider`'ı `context.read<WaterProvider>()` ile eriş
    - Su adımı tamamlandığında `WaterProvider.addWater(250)` çağır
    - Su takip ekranındaki günlük ilerlemenin güncellendiğini doğrula
    - `_Requirements: 4.2, 4.4_`

  - [x] 9.2 `ActiveProgramScreen`'deki "Programı Oluştur" butonunu `CreateProgramScreen`'e yönlendir
    - Mevcut aktif program varsa "Mevcut programınız silinecek. Devam etmek istiyor musunuz?" onay diyaloğu göster
    - Onay verilirse `ProgramService.deleteProgram()` çağır, ardından `CreateProgramScreen`'e yönlendir
    - `_Requirements: 5.6, 5.7_`

- [ ] 10. Bildirim Entegrasyonunu Tamamla
  - [x] 10.1 Program kaydedildiğinde bildirimleri planla
    - `ProgramProvider.saveProgram()` içinde, Firestore kaydı başarılı olduktan sonra `NotificationService.scheduleMealNotification()` çağır
    - Yalnızca `type == 'product'` olan öğünler için bildirim planla; `normal_meal` öğünler için bildirim planlanmamalı
    - Bildirim içeriği: ürün adı + `instructionsByGoal[userGoal]` kısa talimatı
    - `_Requirements: 6.1, 6.2, 3.6_`

  - [x] 10.2 Bildirim aksiyonu ile rutin durumu güncelleme bağlantısını yaz
    - Bildirim "Yaptım" aksiyonu tetiklendiğinde `RoutineService.updateRoutineStatus()` çağır
    - `NotificationService` içinde bildirim aksiyon handler'ını tanımla
    - `_Requirements: 6.3_`

  - [x] 10.3 Program iptal / yenileme sırasında bildirimleri temizle
    - `ProgramService.deleteProgram()` veya `saveProgram()` (yeni program) çağrısı öncesinde `NotificationService.cancelAllProgramNotifications()` çağır
    - `_Requirements: 6.4_`

- [x] 11. Son Kontrol Noktası — Tüm testler geçmeli
  - Tüm birim, property ve widget testlerinin geçtiğini doğrula; sorular varsa kullanıcıya sor.

---

## Notlar

- `*` ile işaretli alt görevler isteğe bağlıdır; MVP için atlanabilir
- Her görev belirli gereksinimlere referans verir (izlenebilirlik için)
- Property testleri `fast_check` paketi ile minimum 100 iterasyon çalıştırılmalıdır
- Kontrol noktaları artımlı doğrulama sağlar
- `DailyRoutineModel` güncellemesi geriye dönük uyumlu olmalı; mevcut `stepType` alanı olmayan dokümanlar `'product'` olarak yorumlanmalı
