# Gereksinimler Belgesi

## Giriş

Bu özellik, HerbaForm Flutter uygulamasında müşterilerin kendi hedeflerine göre kişiselleştirilmiş günlük beslenme programı oluşturmasını sağlar. Müşteri; hedefini (kilo verme, sağlıklı yaşam, kilo alma) seçer, öğün planını yapılandırır, program süresi otomatik hesaplanır ve program Firestore'a kaydedilir. Program, mevcut `RoutineService` ve `WaterProvider` altyapısıyla entegre çalışır; her öğün için push bildirimi gönderilir ve su içme adımları su takibine yansıtılır.

---

## Sözlük

- **Program**: Müşterinin hedefine göre oluşturulan, başlangıç tarihi, süresi, öğün planı ve atanmış ürünleri içeren günlük beslenme planı.
- **Program_Oluşturucu**: Müşterinin program oluşturma adımlarını yöneten uygulama bileşeni.
- **Hedef_Seçici**: Müşterinin kilo verme, sağlıklı yaşam veya kilo alma hedefini seçtiği ekran bileşeni.
- **Öğün_Planlayıcı**: Sabah, öğle ve akşam öğünlerine ürün veya normal yemek atayan bileşen.
- **Süre_Hesaplayıcı**: Hedef kilo farkına göre program süresini hesaplayan bileşen.
- **Program_Servisi**: Programı Firestore'a kaydeden ve yöneten servis katmanı.
- **Bildirim_Servisi**: Öğün saatlerinde push bildirimi gönderen servis.
- **Su_Takip_Entegratörü**: Öğün öncesi su içme adımlarını `WaterProvider`'a kaydeden bileşen.
- **Rutin_Servisi**: Mevcut `RoutineService`; günlük rutinleri `users/{uid}/Daily_Routines` koleksiyonuna yazan servis.
- **Müşteri**: `UserRole.customer` rolüne sahip, uygulamayı kullanan son kullanıcı.
- **Öğün**: Sabah, öğle veya akşam yemek zamanı dilimi.
- **Shake**: Formül 1 gibi ürünlerle hazırlanan protein içeceği.
- **Normal_Yemek**: Ürün içermeyen, müşterinin kendi hazırladığı öğün.
- **Kilo_Farkı**: Müşterinin mevcut kilosu ile hedef kilosu arasındaki fark (kg).
- **userGoal**: `UserProfileModel`'deki hedef alanı; `weight_loss`, `healthy_living`, `weight_gain` değerlerini alır.
- **wakeTime / lunchTime / sleepTime**: `UserProfileModel`'deki "HH:mm" formatındaki zaman alanları.
- **recommendedOffsetMins**: `ProductModel`'deki, ürünün uyanma saatinden kaç dakika sonra kullanılacağını belirten alan.
- **instructionsByGoal**: `ProductModel`'deki, hedefe göre değişen kullanım talimatları haritası.

---

## Gereksinimler

### Gereksinim 1: Hedef Seçimi

**Kullanıcı Hikayesi:** Bir müşteri olarak, programıma başlamadan önce hedefimi seçmek istiyorum; böylece uygulama bana uygun bir plan oluşturabilsin.

#### Kabul Kriterleri

1. THE Program_Oluşturucu SHALL müşteriye üç hedef seçeneği sunmalıdır: `weight_loss` (Kilo Verme), `healthy_living` (Sağlıklı Yaşam), `weight_gain` (Kilo Alma).
2. WHEN müşteri bir hedef seçtiğinde, THE Program_Oluşturucu SHALL seçilen hedefi `UserProfileModel.userGoal` alanına kaydetmelidir.
3. WHEN müşteri `weight_loss` hedefini seçtiğinde, THE Program_Oluşturucu SHALL müşteriden mevcut kilosunu ve hedef kilosunu girmesini istemelidir.
4. IF müşteri kilo alanlarını boş bırakırsa, THEN THE Program_Oluşturucu SHALL "Lütfen mevcut ve hedef kilonuzu girin." uyarısını göstermeli ve bir sonraki adıma geçişi engellemelidir.
5. WHEN müşteri `healthy_living` veya `weight_gain` hedefini seçtiğinde, THE Program_Oluşturucu SHALL kilo giriş adımını atlayarak doğrudan öğün planlama adımına geçmelidir.

---

### Gereksinim 2: Program Süresi Hesaplama

**Kullanıcı Hikayesi:** Bir müşteri olarak, kilo verme hedefim için gerçekçi bir program süresi görmek istiyorum; böylece ne kadar süre devam etmem gerektiğini bilebiliyeyim.

#### Kabul Kriterleri

1. WHEN müşteri `weight_loss` hedefini seçip kilo bilgilerini girdiğinde, THE Süre_Hesaplayıcı SHALL Kilo_Farkı'nı `(mevcutKilo - hedefKilo)` formülüyle hesaplamalıdır.
2. WHEN Kilo_Farkı 1 kg ile 5 kg arasında olduğunda, THE Süre_Hesaplayıcı SHALL program süresini en az 1 ay olarak belirlemelidir.
3. WHEN Kilo_Farkı 6 kg ile 10 kg arasında olduğunda, THE Süre_Hesaplayıcı SHALL program süresini en az 2 ay olarak belirlemelidir.
4. WHEN Kilo_Farkı 11 kg ile 20 kg arasında olduğunda, THE Süre_Hesaplayıcı SHALL program süresini en az 3 ay olarak belirlemelidir.
5. WHEN Kilo_Farkı 20 kg'dan fazla olduğunda, THE Süre_Hesaplayıcı SHALL program süresini en az 4 ay olarak belirlemelidir.
6. IF Kilo_Farkı sıfır veya negatif olursa, THEN THE Süre_Hesaplayıcı SHALL "Hedef kilo mevcut kilodan küçük olmalıdır." hata mesajını göstermelidir.
7. WHEN `healthy_living` veya `weight_gain` hedefi seçildiğinde, THE Süre_Hesaplayıcı SHALL program süresini varsayılan olarak 1 ay olarak belirlemelidir.
8. THE Program_Oluşturucu SHALL hesaplanan minimum süreyi müşteriye göstermeli ve müşterinin bu süreyi artırmasına izin vermelidir.

---

### Gereksinim 3: Öğün Bazlı Program Yapılandırması

**Kullanıcı Hikayesi:** Bir müşteri olarak, sabah, öğle ve akşam öğünlerime ürün veya normal yemek atamak istiyorum; böylece günlük rutinime uygun bir plan oluşturabileyim.

#### Kabul Kriterleri

1. THE Öğün_Planlayıcı SHALL sabah, öğle ve akşam olmak üzere üç öğün dilimi sunmalıdır.
2. WHEN müşteri `weight_loss` hedefini seçtiğinde, THE Öğün_Planlayıcı SHALL sabah ve akşam öğünlerine varsayılan olarak Shake (Formül 1) atamalıdır.
3. WHEN müşteri `weight_loss` hedefini seçtiğinde, THE Öğün_Planlayıcı SHALL öğle öğünü için Shake veya Normal_Yemek seçeneği sunmalıdır.
4. WHEN müşteri bir öğüne ürün atamak istediğinde, THE Öğün_Planlayıcı SHALL yalnızca `category` alanı `meal_replacement` olan ürünleri listelemelidir.
5. THE Öğün_Planlayıcı SHALL her öğün için seçilen ürünün `instructionsByGoal` alanından hedefe uygun kullanım talimatını göstermelidir.
6. WHEN müşteri bir öğüne Normal_Yemek atadığında, THE Öğün_Planlayıcı SHALL o öğün için ürün bildirimi oluşturmamalıdır.
7. THE Öğün_Planlayıcı SHALL öğün saatlerini `UserProfileModel.wakeTime`, `UserProfileModel.lunchTime` ve `UserProfileModel.sleepTime` alanlarından otomatik olarak doldurmalıdır.
8. IF `UserProfileModel.wakeTime`, `lunchTime` veya `sleepTime` alanlarından herhangi biri boşsa, THEN THE Öğün_Planlayıcı SHALL müşteriden ilgili saati girmesini istemelidir.

---

### Gereksinim 4: Su İçme Adımlarının Entegrasyonu

**Kullanıcı Hikayesi:** Bir müşteri olarak, her öğünden önce su içmemi hatırlayan adımlar görmek istiyorum; böylece günlük su hedefime ulaşmak kolaylaşsın.

#### Kabul Kriterleri

1. THE Program_Oluşturucu SHALL ürün atanmış her öğün için, öğün saatinden 30 dakika önce bir su içme adımı oluşturmalıdır.
2. WHEN müşteri bir su içme adımını "Yaptım" olarak işaretlediğinde, THE Su_Takip_Entegratörü SHALL `WaterProvider.addWater()` metodunu 250 ml parametre ile çağırmalıdır.
3. THE Program_Oluşturucu SHALL su içme adımlarını günlük rutin listesinde öğün adımlarından önce göstermelidir.
4. WHEN müşteri su içme adımını tamamladığında, THE Su_Takip_Entegratörü SHALL su takip ekranındaki günlük ilerlemeyi güncellemelidir.
5. IF `WaterProvider.addWater()` çağrısı başarısız olursa, THEN THE Su_Takip_Entegratörü SHALL "Su kaydı yapılamadı, lütfen tekrar deneyin." hata mesajını göstermelidir.

---

### Gereksinim 5: Programın Firestore'a Kaydedilmesi

**Kullanıcı Hikayesi:** Bir müşteri olarak, oluşturduğum programın kaydedilmesini istiyorum; böylece danışmanım programımı takip edebilsin ve uygulama her gün rutinlerimi otomatik oluşturabilsin.

#### Kabul Kriterleri

1. WHEN müşteri programı onayladığında, THE Program_Servisi SHALL program bilgilerini `users/{uid}/program` Firestore dokümanına kaydetmelidir.
2. THE Program_Servisi SHALL program dokümanında şu alanları saklamalıdır: `userGoal`, `startDate`, `durationMonths`, `mealPlan` (öğün-ürün eşleşmeleri), `currentWeight`, `targetWeight` (yalnızca `weight_loss` için), `createdAt`.
3. WHEN program Firestore'a kaydedildikten sonra, THE Program_Servisi SHALL `RoutineService.generateDailyRoutine()` metodunu çağırarak bugünün günlük rutinlerini oluşturmalıdır.
4. THE Program_Servisi SHALL `generateDailyRoutine()` çağrısında `assignedProducts` parametresine yalnızca öğün planında ürün atanmış öğünlerin ürünlerini geçirmelidir.
5. IF Firestore kayıt işlemi başarısız olursa, THEN THE Program_Servisi SHALL "Program kaydedilemedi. İnternet bağlantınızı kontrol edin." hata mesajını göstermeli ve kullanıcıyı onay adımına geri döndürmelidir.
6. WHEN müşterinin mevcut bir aktif programı varsa, THE Program_Servisi SHALL "Mevcut programınız silinecek. Devam etmek istiyor musunuz?" onay diyaloğunu göstermelidir.
7. WHEN müşteri mevcut programı silmeyi onayladığında, THE Program_Servisi SHALL eski program dokümanını silmeli ve yeni programı kaydetmelidir.

---

### Gereksinim 6: Push Bildirimleri

**Kullanıcı Hikayesi:** Bir müşteri olarak, ürün alma saatlerinde bildirim almak istiyorum; böylece programımı unutmadan takip edebileyim.

#### Kabul Kriterleri

1. WHEN program oluşturulduğunda, THE Bildirim_Servisi SHALL öğün planında ürün atanmış her öğün için, öğün saatinde bir günlük tekrarlayan push bildirimi planlamalıdır.
2. THE Bildirim_Servisi SHALL bildirim içeriğinde ürün adını ve `instructionsByGoal`'dan alınan kısa kullanım talimatını göstermelidir.
3. WHEN müşteri bildirime "Yaptım" yanıtını verdiğinde, THE Bildirim_Servisi SHALL ilgili `DailyRoutineModel` kaydının `isCompleted` alanını `true` olarak güncellemek için `RoutineService.updateRoutineStatus()` metodunu çağırmalıdır.
4. WHEN müşteri aktif bir programı iptal ettiğinde veya yeni bir program oluşturduğunda, THE Bildirim_Servisi SHALL önceki programa ait tüm planlanmış bildirimleri iptal etmelidir.
5. IF cihaz bildirim iznine sahip değilse, THEN THE Bildirim_Servisi SHALL müşteriden bildirim iznini etkinleştirmesini isteyen bir açıklama diyaloğu göstermelidir.
6. WHERE müşteri bildirim iznini reddederse, THE Program_Oluşturucu SHALL program oluşturmaya devam etmeli ve bildirimsiz çalışma modunda devam etmelidir.

---

### Gereksinim 7: Program Özeti ve Onay Ekranı

**Kullanıcı Hikayesi:** Bir müşteri olarak, programı kaydetmeden önce tüm detayları görmek istiyorum; böylece hatalı bir program oluşturmaktan kaçınabileyim.

#### Kabul Kriterleri

1. THE Program_Oluşturucu SHALL programı kaydetmeden önce bir özet ekranı göstermelidir.
2. THE Program_Oluşturucu SHALL özet ekranında şu bilgileri göstermelidir: seçilen hedef, program süresi, başlangıç tarihi, her öğün için atanan ürün veya Normal_Yemek etiketi, ve öğün saatleri.
3. WHEN müşteri özet ekranında "Programı Başlat" düğmesine bastığında, THE Program_Oluşturucu SHALL Gereksinim 5'te tanımlanan kayıt işlemini başlatmalıdır.
4. WHEN müşteri özet ekranında "Geri Dön" düğmesine bastığında, THE Program_Oluşturucu SHALL müşteriyi öğün planlama adımına geri götürmelidir.
5. WHILE program kaydedilirken, THE Program_Oluşturucu SHALL bir yükleme göstergesi (CircularProgressIndicator) göstermeli ve "Programı Başlat" düğmesini devre dışı bırakmalıdır.

---

### Gereksinim 8: Mevcut Programın Görüntülenmesi

**Kullanıcı Hikayesi:** Bir müşteri olarak, aktif programımı istediğim zaman görmek istiyorum; böylece günlük planımı takip edebileyim.

#### Kabul Kriterleri

1. WHEN müşterinin aktif bir programı varsa, THE Program_Oluşturucu SHALL ana ekranda programın özet bilgilerini (hedef, kalan gün sayısı, bugünkü öğün planı) göstermelidir.
2. THE Program_Oluşturucu SHALL aktif program ekranında bugünkü su içme adımları dahil tüm rutin adımlarını sıralı olarak listelemelidir.
3. WHEN müşteri bir rutin adımını "Yaptım" olarak işaretlediğinde, THE Program_Oluşturucu SHALL `RoutineService.updateRoutineStatus()` metodunu çağırmalıdır.
4. WHEN müşteri bir su içme adımını "Yaptım" olarak işaretlediğinde, THE Su_Takip_Entegratörü SHALL `WaterProvider.addWater()` metodunu 250 ml parametre ile çağırmalıdır.
5. THE Program_Oluşturucu SHALL program bitiş tarihini `startDate + durationMonths` formülüyle hesaplayarak kalan gün sayısını göstermelidir.
