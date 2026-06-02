# HERBAFORMIX — Proje İlerleme Takibi (Progress)

> **Son Güncelleme:** 2026-05-30
> **Mevcut Sürüm:** v1.0.0-beta+1
> **Genel İlerleme:** ~%75 (Beta aşaması)

---

## 🎯 Proje Vizyonu

Danışanların kişisel sağlık hedeflerine ulaşırken eğlenceli ve oyunlaştırılmış bir arayüzle rutinlerini takip edebildiği; yaşam koçlarının ise tüm müşteri portföyünü tek bir CRM panelinden yönetebildiği **hepsi bir arada** platform.

---

## FAZ 1 — TEMEL ALTYAPI VE İSKELET ✅

> Tüm temel altyapı, proje iskeleti ve Firebase entegrasyonu.

- [x] Flutter proje oluşturma (Android, iOS, Web, Windows)
- [x] Firebase projesi kurulumu (`herbaformix`)
- [x] `firebase_options.dart` oluşturma (FlutterFire CLI)
- [x] Proje klasör yapısı: Feature-First mimari
- [x] `pubspec.yaml` bağımlılık yönetimi
- [x] `analysis_options.yaml` lint yapılandırması (`flutter_lints`)
- [x] Renk paleti ve tasarım sistemi (`AppColors` sınıfı)
- [x] `ThemeData` yapılandırması (`app.dart` — renk, buton, input, typography)
- [x] Varlık dosyaları (logo, placeholder, motivasyon JSON)
- [x] Launcher icon yapılandırması (`flutter_launcher_icons`)

---

## FAZ 2 — KİMLİK DOĞRULAMA VE KULLANICI YÖNETİMİ ✅

> Firebase Auth, kullanıcı rolleri, profil yönetimi ve distribütör-müşteri bağlantısı.

### 2.1 — Kimlik Doğrulama
- [x] Firebase Auth entegrasyonu
- [x] E-posta / Şifre ile kayıt ve giriş
- [x] Google Sign-In altyapısı
- [ ] Google Sign-In uçtan uca test ve doğrulama
- [x] `AuthService` wrapper sınıfı
- [x] `AuthProvider` (ChangeNotifier) — oturum durumu yönetimi
- [x] `AuthStatus` enum: `initial`, `authenticated`, `unauthenticated`
- [x] Splash ekranı (Firebase init + otomatik yönlendirme)
- [x] Login ekranı

### 2.2 — Kullanıcı Profil Sistemi
- [x] `UserProfileModel` (30+ alan — kapsamlı profil)
- [x] `UserRole` enum: `supervisor`, `distributor`, `successCreator`, `customer`
- [x] Firestore profil CRUD (`/users/{userId}`)
- [x] Profil ekranı (rol bazlı görünüm)
- [x] Kişisel bilgiler ekranı (`PersonalInfoScreen`)
- [x] Sağlık hedefleri ekranı (`HealthGoalsScreen`)
- [x] Uygulama ayarları ekranı (`AppSettingsScreen`)
- [x] Destek ekranı (`SupportScreen`)
- [x] Profil fotoğrafı yükleme (`ProfilePhotoWidget`)
- [x] Şifre değiştirme diyalogu (`ChangePasswordDialog`)
- [x] Distribütör profil görünümü (`DistributorProfileView`)
- [x] Müşteri profil görünümü (`CustomerProfileView`)
- [x] Profil doğrulama yardımcıları (`ProfileValidators`)

### 2.3 — Distribütör-Müşteri Bağlantısı (Davet Sistemi)
- [x] `InviteCodeModel` — 8 haneli alfanümerik benzersiz kod
- [x] `InviteStatus` enum: `pending`, `used`, `expired`
- [x] Davet kodu oluşturma (distribütör tarafı)
- [x] Davet kodu ile kayıt (müşteri tarafı — `assignedDistributorId` otomatik atama)
- [x] 7 gün geçerlilik süresi
- [x] Davet kodu bölümü (`InviteCodeSection` widget)
- [x] WhatsApp üzerinden davet paylaşımı (`WhatsappHelper`)

### 2.4 — Müşteri Oryantasyonu (Onboarding)
- [x] 5 adımlı zorunlu sihirbaz (`CustomerOnboardingScreen`)
  - [x] Adım 1: Hoş geldin + ilerleme göstergesi
  - [x] Adım 2: Kişisel bilgiler (isim, yaş, telefon)
  - [x] Adım 3: Sağlık hedefi seçimi (kilo verme / sağlıklı yaşam / kilo alma)
  - [x] Adım 4: Mevcut durum (kilo, boy, hedef kilo)
  - [x] Adım 5: Günlük yaşam (uyanma, öğle, uyku saatleri)
- [x] Onboarding tamamlanmadan ana sayfaya geçiş engeli (GoRouter redirect)
- [x] `isOnboarded` flag kontrolü

---

## FAZ 3 — NAVİGASYON VE ROUTING ✅

> GoRouter ile declarative routing, rol bazlı yönlendirme.

- [x] `GoRouter` yapılandırması (`lib/core/router.dart`)
- [x] `_GoRouterRefreshNotifier` — Auth değişikliklerinde güvenli yenileme
- [x] 24+ route tanımı (nested routing)
- [x] Redirect mantığı:
  - [x] Giriş yapılmamış → `/login`
  - [x] Giriş yapılmış + Login'de → `/home`
  - [x] Müşteri + onboarding eksik → `/home/onboarding`
  - [x] Müşteri + onboarding tamam + onboarding'e erişim → `/home`
- [x] `state.extra` ile parametre geçişi
- [x] Müşteri Bottom Navigation (4 sekme: Ana Sayfa, Programım, Gelişim, Profil)
- [x] Distribütör Bottom Navigation (4 sekme: Ana Sayfa, Müşteriler, Siparişler, Profil)
- [x] `AppDrawer` yan menü widget'ı

---

## FAZ 4 — BESLENME PROGRAMI SİSTEMİ ✅

> Distribütörlerin müşterilerine özel program hazırlaması ve müşterilerin programı takip etmesi.

### 4.1 — Program Sihirbazı (Distribütör Tarafı)
- [x] 4 adımlı sihirbaz (`CreateProgramScreen`)
  - [x] Adım 1: Hedef belirleme (`GoalSelectionStep`)
  - [x] Adım 2: Kilo parametreleri (`WeightInputStep`) — otomatik süre hesaplama
  - [x] Adım 3: Öğün ve ürün planlama (`MealPlanStep`)
  - [x] Adım 4: Özet ve kaydetme (`ProgramSummaryStep`)
- [x] `ProgramModel` ve `MealSlot` / `MealProduct` veri yapıları
- [x] `ProgramProvider` — program CRUD işlemleri
- [x] `ProgramService` — iş mantığı katmanı
- [x] `ProgramEditorArgs` — düzenleme parametreleri
- [x] Ürün kataloğundan öğüne ürün ekleme
- [x] Ara öğün ekleme/silme
- [x] Su adımlarının otomatik eklenmesi (her öğünden 30 dk önce)
- [x] `WaterStepTile` widget'ı

### 4.2 — Aktif Program (Müşteri Tarafı)
- [x] `ActiveProgramScreen` — saat bazlı program görüntüleme
- [x] Adım tamamlama işaretleme (checkbox)
- [x] `DailyRoutineModel` — günlük rutin takibi
- [x] `RoutineService` — rutin CRUD

### 4.3 — Bildirim Sistemi
- [x] `NotificationService` — `flutter_local_notifications` entegrasyonu
- [x] Öğün alarmları (her öğünün saatinde)
- [x] Su hatırlatıcıları (öğünlerden 30 dk önce)
- [x] Program kaydedildiğinde otomatik bildirim zamanlama
- [ ] Firebase Cloud Messaging (FCM) push bildirimleri
- [ ] FCM token senkronizasyonu (`fcmToken` alanı modelde hazır)

---

## FAZ 5 — GÜNLÜK TAKİP MODÜLLERİ ✅

> Su takibi, kalori takibi ve günlük başarı metrikleri.

### 5.1 — Su Takipçisi ✅
- [x] `WaterTrackerScreen` — gerçek zamanlı Firestore senkronizasyonu
- [x] `WaterProvider` — `ChangeNotifierProxyProvider` ile auth-bağımlı
- [x] `WaterCalculationEngine` — dinamik su hedefi hesaplama
  - [x] Vücut ağırlığına göre baz hesaplama
  - [x] Egzersiz seviyesi etkisi (sedentary, light, moderate, intense)
  - [x] Hava durumu etkisi (sıcaklık, nem — OpenWeatherMap API)
- [x] `WaterCalculationConstants` — hesaplama sabitleri
- [x] Hızlı ekleme butonları (+250ml, +500ml, özel miktar)
- [x] Graceful degradation (API fallback: 22°C / %50 nem)
- [x] `WaterLogModel` — `/users/{userId}/water_logs/{YYYY-MM-DD}`
- [x] `WaterSummaryModel` — `/users/{userId}/waterSummaries/{YYYY-MM-DD}`
- [x] `WeatherService` — OpenWeatherMap API wrapper
- [x] `ExerciseService` — egzersiz seviyesi yönetimi (ProxyProvider)

### 5.2 — Kalori Takipçisi ⚠️ (Kısmi)
- [x] `CalorieTrackerScreen` — UI tamamlandı
- [x] `CalorieProvider` — yerel state yönetimi
- [x] `MealModel` — yemek veri modeli
- [x] Yemek ekleme/silme
- [x] Günlük toplam kalori hesaplama
- [x] Hedef limite göre renk görselleştirme
- [ ] ⚠️ **Firestore entegrasyonu yok** — sayfa yenilenince veriler sıfırlanır
- [ ] Kalori geçmişi takibi
- [ ] Besin veritabanı entegrasyonu

### 5.3 — Ana Sayfa Widget'ları
- [x] `HomeScreen` — rol bazlı içerik (müşteri vs distribütör)
- [x] `HomeProvider` — ana sayfa veri yönetimi
- [x] `DailySuccessRing` — günlük başarı halkası widget'ı
- [x] `MotivationWidget` — motivasyon mesajları (JSON veri kaynağı)

---

## FAZ 6 — GELİŞİM TAKİBİ VE ÖLÇÜM SİSTEMİ ✅

> Ölçüm girişi, grafikler, hedef ilerleme, fotoğraf günlüğü ve istatistikler.

### 6.1 — Ölçüm Girişi ve Geçmişi
- [x] `AddMeasurementSheet` — ölçüm giriş bottom sheet
  - [x] Kilo (zorunlu) + 8 opsiyonel ölçüm (bel, kalça, göğüs, kol, bacak, yağ oranı, kas kütlesi, BMI)
  - [x] Virgül ve nokta girişi desteği
  - [x] Geçmiş tarihli giriş (DatePicker)
  - [x] Aynı gün tekrar uyarı dialogu
- [x] `ProgressEntryModel` — ölçüm veri modeli (9 alan)
- [x] `ProgressProvider` — ölçüm CRUD ve rozet kontrolü
- [x] `MeasurementsHistoryScreen` — tablo görünümünde geçmiş
  - [x] Düzenleme desteği
  - [x] Silme desteği

### 6.2 — Gelişim Grafikleri
- [x] `WeightChartWidget` — genelleştirilmiş grafik widget'ı (`fl_chart`)
  - [x] `MeasurementType` enum ile 8 ölçüm türü desteği
  - [x] Zaman aralığı filtreleri: 1 Hafta, 1 Ay, 3 Ay
  - [x] Hedef kilo çizgisi (turuncu kesikli yatay çizgi + "Hedef XX.X" etiketi)
  - [x] Hedef bazlı renk mantığı:
    - `weight_loss` → azalış yeşil / artış kırmızı
    - `weight_gain` → artış yeşil / azalış kırmızı

### 6.3 — Hedef İlerleme ve İstatistikler
- [x] `ProgressDashboardScreen` — ana gelişim paneli
  - [x] Dairesel ilerleme çubuğu (mevcut → hedef kilo oranı)
  - [x] Başlangıç / Mevcut / Hedef / Kalan bilgileri
  - [x] %100 ulaşıldığında "Ulaşıldı!" etiketi
  - [x] Haftalık ortalama değişim (kg/hafta)
  - [x] Toplam kayıt sayısı
  - [x] En iyi hafta ve miktarı
  - [x] Dijital mezura (bel, kalça, göğüs son ölçümler + değişim)
  - [x] Gizlilik modu (BMI gösterimi, kilo maskeleme `***`)
  - [x] CSV dışa aktarma (`share_plus`)
  - [x] RefreshIndicator (pull-to-refresh)

### 6.4 — Gelişim Fotoğrafları ⚠️ (Kısmi)
- [x] `ProgressPhotosScreen` — fotoğraf yönetimi
  - [x] "Önce" (gri tonlamalı) ve "Sonra" (renkli) fotoğraf yükleme
  - [x] Kamera ve galeri desteği (`image_picker`)
  - [x] Carousel (PageView) + dot indicator
  - [x] Tam ekran görüntüleyici (InteractiveViewer — zoom/pan)
- [x] `TransformationStudioWidget` — önce/sonra karşılaştırma
  - [x] Slider ile sürükle-bırak yan yana karşılaştırma
  - [x] Gri tonlamalı "önce" + renkli "sonra" üst üste bindirme
  - [x] Dikey çizgi + tutamak ile bölge ayarlama
  - [x] Birden fazla "sonra" fotoğrafı arasından seçim
- [ ] ⚠️ **Firebase Storage entegrasyonu yok** — fotoğraflar yalnızca yerel
- [ ] Cihaz değiştiğinde fotoğraf kaybı riski uyarı metni
- [ ] Web platformu kısıtlama bildirimi
- [ ] Resim sıkıştırma optimizasyonu (`flutter_image_compress`)

---

## FAZ 7 — ROZET VE OYUNLAŞTIRMA SİSTEMİ ✅

> Motivasyon ve bağlılık artırıcı oyunlaştırma mekanizmaları.

- [x] `BadgeDefinition` modeli — 8 rozet tanımı (statik liste)
- [x] Rozet kontrol mekanizması (`ProgressProvider._checkAndAwardBadges`)
- [x] Firestore'a kazanılan rozet kaydetme (`earnedBadges` listesi)
- [x] Anlık snackbar bildirimi (`onBadgeEarned` callback)
- [x] Rozet listesi:

| Rozet | Kazanma Koşulu | Durum |
|---|---|---|
| `first_entry` — İlk Adım | İlk ölçüm kaydı | ✅ |
| `streak_7` — 7 Gün Seri | 7 gün üst üste aktivite | ✅ |
| `streak_30` — 30 Gün Seri | 30 gün üst üste aktivite | ✅ |
| `lost_1kg` — 1 KG Kayıp | Toplam 1+ kg kayıp | ✅ |
| `lost_5kg` — 5 KG Kayıp | Toplam 5+ kg kayıp | ✅ |
| `goal_reached` — Hedefe Ulaştı | Hedef kiloya ulaşım | ✅ |
| `measurement_added` — Ölçüm Ustası | Vücut ölçümü girişi | ✅ |
| `photo_added` — Dönüşüm Fotoğrafı | Fotoğraf yükleme | ✅ |

- [x] Hedef bazlı rozet mantığı (`weight_loss` / `weight_gain`)
- [x] Genişletilmiş seri hesabı (su dolumu + routine tamamlama dahil)
- [ ] Rozet vitrin ekranı (ayrı sayfa olarak)
- [ ] Confetti animasyonu rozet kazanıldığında (`confetti` paketi hazır)

---

## FAZ 8 — CRM VE MÜŞTERİ YÖNETİMİ (DİSTRİBÜTÖR) ✅

> Distribütörlerin müşteri portföyünü yönetmesi.

### 8.1 — Müşteri Listesi ve Detay
- [x] `CustomerListScreen` — arama ve filtreleme destekli liste
- [x] `CustomerDetailScreen` — müşteri detay ekranı
  - [x] Kilo değişim grafiği (`WeightChartWidget`)
  - [x] Bel, kalça, göğüs değişim chip'leri
  - [x] Son 5 ölçüm kaydı listesi
  - [x] Su / kalori takip durumu
  - [x] Risk analizi (3+ gün inaktif veya tamamlama <%50)
- [x] `AddEditCustomerScreen` — müşteri ekleme/düzenleme
- [x] `CustomerModel` — CRM veri modeli
- [x] `CustomerProvider` — müşteri CRUD

### 8.2 — Müşteri İçgörüleri
- [x] `DistributorCustomerInsights` modeli
  - [x] Son ölçüm, son 90 gün kayıtları
  - [x] Bugünkü su tüketimi / hedefi
  - [x] Son 7 gün rutin tamamlama oranı
  - [x] Son aktivite tarihi
  - [x] Risk durumu (`isAtRisk`)
  - [x] Toplam kilo değişimi

### 8.3 — Müşteri Takip Sistemi (Follow-Up)
- [x] `FollowUpModel` — takip kaydı modeli
- [x] `FollowUpProvider` — takip CRUD
- [x] Takip tipleri: Telefon, WhatsApp, E-posta, Yüz Yüze
- [x] Takip durumları: Tamamlandı, Eylem Gerekiyor
- [x] `ScheduledFollowUpModel` — zamanlanmış takipler
- [ ] Zamanlanmış takip hatırlatma bildirimleri

---

## FAZ 9 — ÜRÜN KATALOĞU VE SİPARİŞ YÖNETİMİ ✅

> Herbalife ürün yönetimi ve sipariş sistemi.

### 9.1 — Ürün Kataloğu
- [x] `ProductListScreen` — arama ve filtreleme
- [x] `ProductDetailScreen` — ürün detayı
- [x] `ProductImageViewerScreen` — tam ekran resim görüntüleyici
- [x] `AddEditProductScreen` — ürün ekleme/düzenleme
- [x] `ProductModel` — ürün veri modeli (fiyat, VP, kategori, resim)
- [x] `ProductProvider` — ürün CRUD
- [x] `CachedProductImage` — önbelleğe alınmış ürün resim widget'ı

### 9.2 — Sipariş Sistemi
- [x] `OrderListScreen` — sipariş listesi
- [x] `AddEditOrderScreen` — sipariş oluşturma/düzenleme
- [x] `CartScreen` — sepet ekranı
- [x] `OrderModel` + `OrderItemModel` — sipariş veri modelleri
- [x] `OrderProvider` — sipariş CRUD
- [x] `CartProvider` — sepet yönetimi (ekleme/çıkarma/toplam)
- [x] Sipariş durumu: `pending` → `processing` → `shipped` → `delivered` / `cancelled`
- [x] Volume Point (VP) hesaplama

### 9.3 — Ürün Kullanım İstatistikleri
- [x] `DistributorProductUsageScreen` — hangi ürün kaç müşteri tarafından kullanılıyor

---

## FAZ 10 — GÜVENLİK VE FİRESTORE KURALLARI ✅

> Rol bazlı erişim kontrolü (RBAC) ve veri güvenliği.

- [x] Firestore güvenlik kuralları (`firestore.rules`)
  - [x] `signedIn()` — oturum kontrolü
  - [x] `isOwner()` — sahiplik kontrolü
  - [x] `isDistributor()` — distribütör rolü kontrolü
  - [x] `isAssignedDistributor()` — atanmış distribütör kontrolü
- [x] Kullanıcı profili okuma/yazma kuralları
- [x] Davet kodu güvenlik kuralları (oluşturma, kullanma, silme)
- [x] Alt koleksiyon kuralları (progressEntries, waterLogs, Daily_Routines, program)
- [x] Varsayılan engelleme kuralı (`/{document=**} → false`)
- [x] Firestore indeksleri (`firestore.indexes.json`)
- [ ] Güvenlik kuralları kapsamlı audit (⚠️ `products` koleksiyonu tamamen açık)
- [ ] `scheduled_follow_ups` ve `careerRoadmap` koleksiyonları yalnızca `signedIn()` ile korunuyor

---

## FAZ 11 — PERFORMANS VE OPTİMİZASYON 🔄 (Devam Ediyor)

> Uygulama performansı, çevrimdışı destek ve optimizasyon.

- [ ] Firestore offline persistence aktifleştirme
- [ ] Resim sıkıştırma optimizasyonu (1080px max, JPEG %80)
- [ ] `firestore_service.dart` refactoring (~37 KB — çok büyük, modüllere bölünmeli)
- [ ] Lazy loading ve sayfalama (büyük listeler için)
- [ ] Memory leak kontrolü (stream subscription'lar)
- [ ] Uygulama boyutu optimizasyonu (tree shaking, asset optimizasyonu)

---

## FAZ 12 — ERİŞİLEBİLİRLİK (a11y) 🔄 (Devam Ediyor)

> WCAG AA uyumluluğu, ekran okuyucu desteği.

- [ ] Tüm butonlara `Semantics` label ekleme
- [ ] Grafik barları için erişilebilir açıklamalar
- [ ] Form alanları için anlamlı etiketler
- [ ] Kontrast oranı doğrulaması (WCAG AA — 4.5:1)
- [ ] Mango sarısı (#EFAC29) üzerinde beyaz yazı sorunu düzeltme
- [ ] Büyük yazı tipi desteği
- [ ] Ekran okuyucu ile uçtan uca test

---

## FAZ 13 — TEST ALTYAPISI ❌ (Başlanmadı)

> Unit, widget ve integration test katmanları.

- [ ] Test stratejisi belirleme
- [ ] Model testleri (serialization / deserialization)
  - [ ] `UserProfileModel` testleri
  - [ ] `ProgressEntryModel` testleri
  - [ ] `InviteCodeModel` testleri
  - [ ] `ProgramModel` testleri
  - [ ] `OrderModel` testleri
- [ ] Provider testleri
  - [ ] `AuthProvider` testleri
  - [ ] `WaterProvider` testleri
  - [ ] `ProgressProvider` testleri
  - [ ] `ProgramProvider` testleri
  - [ ] `CustomerProvider` testleri
- [ ] Servis testleri
  - [ ] `FirestoreService` testleri
  - [ ] `WaterCalculationEngine` testleri
  - [ ] `NotificationService` testleri
- [ ] Widget testleri
  - [ ] `WeightChartWidget` testleri
  - [ ] `AddMeasurementSheet` testleri
  - [ ] `DailySuccessRing` testleri
- [ ] Integration testleri
  - [ ] Onboarding akışı
  - [ ] Program oluşturma akışı
  - [ ] Su ekleme akışı
  - [ ] Ölçüm girişi akışı

---

## FAZ 14 — PUSH BİLDİRİMLERİ (FCM) ❌ (Başlanmadı)

> Firebase Cloud Messaging ile uzak bildirimler.

- [ ] FCM paketi ekleme ve yapılandırma
- [ ] FCM token alma ve `UserProfileModel.fcmToken`'a kaydetme
- [ ] Token yenileme mekanizması
- [ ] Distribütör → Danışan push bildirimi:
  - [ ] Yeni program hazırlandığında
  - [ ] Takip hatırlatması oluşturulduğunda
  - [ ] Motivasyon mesajı gönderildiğinde
- [ ] Cloud Functions veya backend altyapısı (bildirim gönderimi için)
- [ ] Bildirim tercihleri (`notificationSettings` alanı modelde hazır)

---

## FAZ 15 — GELİŞMİŞ KALORİ & BESLENME TAKİBİ 📋

> Mevcut kalori takibinin tam kapsamlı bir beslenme izleme modülüne dönüştürülmesi.

### 15.1 — Kalori Firestore Entegrasyonu
- [ ] `CalorieProvider` Firestore senkronizasyonu
- [ ] `/users/{userId}/calorie_logs/{YYYY-MM-DD}` koleksiyonu
- [ ] Kalori geçmişi kalıcı saklama (cihaz bağımsız)
- [ ] Günlük / haftalık / aylık kalori grafikleri (`fl_chart`)

### 15.2 — Makro Besin Takibi
- [ ] Protein / Karbonhidrat / Yağ ayrı ayrı takip
- [ ] Makro dağılım pasta grafiği (günlük / haftalık)
- [ ] Hedef makro oranları belirleme (distribütör veya kullanıcı tarafından)
- [ ] Makro bazlı renk uyarıları (eksik protein, fazla karbonhidrat vb.)

### 15.3 — Besin Veritabanı Entegrasyonu
- [ ] Türkçe besin veritabanı (FatSecret API veya özel Firestore koleksiyonu)
- [ ] Besin arama ve otomatik kalori/makro doldurma
- [ ] Sık tüketilen yiyecekler listesi (favoriler)
- [ ] Son eklenen besinler (hızlı tekrar)
- [ ] Porsiyon boyutu seçimi (küçük / orta / büyük / gram)

### 15.4 — Öğün Bazlı Kayıt Sistemi
- [ ] Kahvaltı / Öğle / Akşam / Ara Öğün kategorileri
- [ ] Her öğün için ayrı kalori ve makro özeti
- [ ] Öğün bazlı zamanlama (programdaki öğün saatleriyle entegre)
- [ ] "Boş öğün" uyarısı — kaçırılan öğünlerde hatırlatma

### 15.5 — Barkod Okuyucu ile Besin Ekleme
- [ ] `mobile_scanner` veya `barcode_scan` paketi entegrasyonu
- [ ] Paketli ürünlerin barkodunu tarayarak kalori/makro otomatik çekme
- [ ] OpenFoodFacts API entegrasyonu (açık kaynak besin veritabanı)
- [ ] Taranan ürünleri favorilere ekleme

---

## FAZ 16 — AI VÜCUT DÖNÜŞÜM ÖNİZLEMESİ 📋

> Kullanıcının hedef kilodaki görünümünü AI ile tahmin etme — motivasyon artırıcı killer feature.

### 16.1 — Mevcut Fotoğraf Analizi
- [ ] Tam boy fotoğraf yükleme ekranı (kılavuz çizgileri ile poz rehberi)
- [ ] Fotoğraf kalite kontrolü (bulanıklık, ışık, poz uygunluğu)
- [ ] Arka plan temizleme / nötr arka plan overlay
- [ ] Vücut oranlarını analiz eden AI ön işleme

### 16.2 — Hedef Kilo Simülasyonu
- [ ] Gemini Vision API veya özel body morphing modeli entegrasyonu
- [ ] Mevcut kilo → hedef kilo arası vücut dönüşüm tahmini
- [ ] Cinsiyet, boy ve vücut tipine göre kişiselleştirilmiş tahmin
- [ ] Yüz tanıma ile yüzü koruyarak sadece vücut dönüşümü

### 16.3 — Aşamalı Dönüşüm Zaman Tüneli
- [ ] Slider ile aşamalı önizleme (ör: 5 kg, 10 kg, 15 kg, 20 kg)
- [ ] Her aşamada tahmini süre gösterimi ("~8 hafta sonra")
- [ ] Animasyonlu geçiş efekti (morphing animasyonu)
- [ ] Mevcut ilerleme ile AI tahmininin yan yana karşılaştırması

### 16.4 — Motivasyon Kartı ve Paylaşım
- [ ] "Önce → Hedef" karşılaştırma kartı oluşturma
- [ ] Marka logolu paylaşılabilir motivasyon görseli
- [ ] Instagram / WhatsApp / sosyal medya paylaşım desteği
- [ ] Distribütörün danışanın dönüşüm kartını görmesi

### 16.5 — Gerçek vs Tahmin Karşılaştırma
- [ ] İlerleme kaydedildikçe gerçek fotoğrafla AI tahminini yan yana gösterme
- [ ] "AI ne kadar doğru tahmin etti?" skoru
- [ ] Her 5 kg'da yeni fotoğraf hatırlatması ve yeniden karşılaştırma

---

## FAZ 17 — AI YEMEK FOTOĞRAFI TANIMA 📋

> Fotoğrafla otomatik kalori ve besin tahmini.

- [ ] Kamera ile yemek fotoğrafı çekme
- [ ] Gemini Vision API ile yemek tanıma
- [ ] Otomatik kalori ve makro tahmini
- [ ] Tanınan yemeğin onay/düzeltme ekranı
- [ ] Porsiyon büyüklüğü tahmini (görsel analiz)
- [ ] Birden fazla yemek içeren tabakta ayrı ayrı tanıma
- [ ] Tanıma geçmişi ve doğruluk istatistikleri
- [ ] Türk mutfağı için özel eğitilmiş model / prompt engineering

---

## FAZ 18 — AI KOÇ SOHBET BOTU 📋

> Gemini tabanlı kişiselleştirilmiş sağlık ve beslenme asistanı.

### 18.1 — Temel Sohbet Altyapısı
- [ ] Firebase AI Logic / Gemini API entegrasyonu
- [ ] Sohbet ekranı UI (mesaj balonları, yazıyor animasyonu)
- [ ] Sohbet geçmişi Firestore'da saklama
- [ ] Bağlam penceresi yönetimi (kullanıcı profili, ölçümler, program bilgisi)

### 18.2 — Kişiselleştirilmiş Beslenme Önerileri
- [ ] Kullanıcının hedefine, alerjilerine ve tercihlerine göre tarif önerileri
- [ ] "Evdeki malzemelere göre ne pişirebilirim?" sorgulama
- [ ] Herbalife ürünleri ile uyumlu tarif önerileri
- [ ] Günlük menü planı önerisi

### 18.3 — Motivasyon ve Koçluk
- [ ] Günlük motivasyon mesajları (kişiselleştirilmiş, AI üretimi)
- [ ] Seri kırıldığında teşvik mesajı
- [ ] Hedefe yaklaşıldığında kutlama
- [ ] Kilo platosunda motivasyon desteği
- [ ] Sık sorulan sorular (beslenme, egzersiz, ürün kullanımı)

### 18.4 — Distribütör AI Asistanı
- [ ] Danışan analiz özeti oluşturma ("Bu hafta Ali'nin durumu nasıl?")
- [ ] Program önerisi oluşturma (AI destekli program sihirbazı)
- [ ] Toplu danışan raporu (en riskli danışanlar, en başarılı danışanlar)
- [ ] Motivasyon mesajı şablonu üretme

---

## FAZ 19 — FIREBASE STORAGE & FOTOĞRAF BULUT YEDEKLEMESİ 📋

> Gelişim fotoğraflarının bulutta güvenli saklanması.

- [ ] Firebase Storage entegrasyonu
- [ ] Fotoğraf yükleme / indirme / silme servisi
- [ ] Resim sıkıştırma (1080px max, JPEG %80 — `flutter_image_compress`)
- [ ] Thumbnail oluşturma (liste görünümü için küçük boyut)
- [ ] Opsiyonel bulut yedekleme (ücretli/premium model)
- [ ] Distribütörün danışan fotoğraflarını görmesi (izin bazlı)
- [ ] Cihazlar arası senkronizasyon
- [ ] Depolama kotası yönetimi (kullanıcı başına limit)
- [ ] Web platformu tam destek (IndexedDB yerine Storage)

---

## FAZ 20 — İÇ İLETİŞİM SOHBET MODÜLÜ 📋

> Distribütör ve danışan arasında uygulama içi mesajlaşma.

### 20.1 — Temel Mesajlaşma
- [ ] Firestore tabanlı gerçek zamanlı sohbet
- [ ] `/chats/{chatId}/messages/{messageId}` koleksiyon yapısı
- [ ] Metin mesajı gönderme/alma
- [ ] Mesaj zaman damgası ve okundu bilgisi
- [ ] Son mesaj önizlemesi (sohbet listesi)
- [ ] Okunmamış mesaj sayacı (badge)

### 20.2 — Zengin Medya Desteği
- [ ] Fotoğraf paylaşımı (kamera/galeri)
- [ ] Ses kaydı gönderme/dinleme
- [ ] Ölçüm/gelişim kartı paylaşımı (otomatik oluşturulan kart)
- [ ] Program paylaşımı (programı mesaj olarak gönderme)

### 20.3 — Toplu Mesajlaşma (Distribütör)
- [ ] Distribütörün tüm danışanlarına toplu mesaj göndermesi
- [ ] Mesaj şablonları (sabah motivasyonu, akşam hatırlatma)
- [ ] Zamanlanmış mesaj gönderimi
- [ ] Mesaj istatistikleri (kaç kişi okudu)

---

## FAZ 21 — GRUP MEYDAN OKUMALARI & TOPLULUK 📋

> Sosyal etkileşim ve yarışma ile motivasyon artırma.

### 21.1 — Meydan Okuma Sistemi
- [ ] Distribütörün meydan okuma oluşturması (başlık, süre, hedef)
- [ ] Meydan okuma türleri: Su, Adım, Kilo, Ölçüm, Rutin Serisi
- [ ] Katılımcı davet sistemi (distribütörün danışanlarından seçim)
- [ ] Otomatik katılım (tüm danışanlar) veya opsiyonel katılım
- [ ] Meydan okuma süresi: 7 gün / 14 gün / 30 gün

### 21.2 — Liderlik Tablosu ve Ödüller
- [ ] Anonim veya isimli liderlik tablosu
- [ ] Canlı sıralama (gerçek zamanlı güncelleme)
- [ ] Haftalık/aylık şampiyon ilanı
- [ ] Özel rozetler (meydan okuma kazananları için)
- [ ] Confetti ve kutlama animasyonları

### 21.3 — Topluluk Duvarı
- [ ] Motivasyon paylaşımı (metin + fotoğraf)
- [ ] Beğeni ve yorum sistemi
- [ ] Başarı hikayesi paylaşımı (izinli)
- [ ] Haftalık "En İyi Dönüşüm" vitrini

---

## FAZ 22 — AKTİVİTE VE HAREKET TAKİBİ 📋

> Adım sayacı, egzersiz takibi ve sağlık entegrasyonları.

### 22.1 — Adım Sayacı
- [ ] Telefon sensörleri ile adım sayma (`pedometer` paketi)
- [ ] Günlük adım hedefi belirleme
- [ ] Adım geçmişi grafikleri (günlük/haftalık/aylık)
- [ ] Adım bazlı kalori yakma hesaplama
- [ ] Adım hedefine ulaşınca rozet/bildirim

### 22.2 — Egzersiz Günlüğü
- [ ] Egzersiz türü seçimi (yürüyüş, koşu, bisiklet, yoga, ağırlık vb.)
- [ ] Süre ve yoğunluk kaydı
- [ ] Yakılan kalori hesaplama (egzersiz türüne göre)
- [ ] Egzersiz geçmişi ve istatistikler
- [ ] Haftalık egzersiz hedefi

### 22.3 — Sağlık Platformu Entegrasyonu
- [ ] Google Fit API entegrasyonu (Android)
- [ ] Apple HealthKit entegrasyonu (iOS)
- [ ] Otomatik adım/kalori/uyku verisi çekme
- [ ] Wearable cihaz desteği (akıllı saat verisi)

---

## FAZ 23 — UYKU TAKİBİ 📋

> Uyku kalitesi izleme ve uyku-kilo ilişkisi analizi.

- [ ] Uyku saati ve uyanma saati kaydı (mevcut onboarding verisinden başlangıç)
- [ ] Uyku kalitesi puanı (1-5 yıldız)
- [ ] Uyku süresi grafiği (günlük/haftalık trend)
- [ ] Uyku-kilo korelasyon analizi (uyku azaldığında kilo artışı uyarısı)
- [ ] Uyku düzeni hatırlatıcıları ("Uyuma zamanın yaklaşıyor!")
- [ ] Uyku kalitesine göre su hedefi ayarlama (kötü uyku = daha fazla su önerisi)

---

## FAZ 24 — GELİŞMİŞ DİSTRİBÜTÖR ANALİZ PANELİ 📋

> Distribütörler için kapsamlı iş zekası (BI) ve raporlama.

### 24.1 — Performans Dashboard'u
- [ ] Aylık VP gelişim grafiği (hedef vs gerçek)
- [ ] En çok sipariş edilen ürünler (Top 10 listesi)
- [ ] Toplam müşteri sayısı / aktif müşteri oranı
- [ ] Yeni müşteri kazanım trendi (aylık)
- [ ] Müşteri kaybı oranı (churn rate)

### 24.2 — Danışan Başarı Analizi
- [ ] Danışan başarı oranları (hedefe ulaşan / devam eden / bırakan)
- [ ] Ortalama kilo kayıp hızı (tüm danışanlar)
- [ ] En başarılı danışanlar listesi (motivasyon)
- [ ] Risk altındaki danışanlar listesi (3+ gün inaktif)
- [ ] Danışan memnuniyet skoru

### 24.3 — Gelir ve Sipariş Analizi
- [ ] Aylık gelir grafiği
- [ ] Sipariş tamamlanma oranı
- [ ] Tekrar sipariş oranı (müşteri sadakati)
- [ ] Ürün bazlı gelir dağılımı
- [ ] Sezonsal trend analizi

### 24.4 — PDF/Excel Rapor Dışa Aktarma
- [ ] Aylık performans raporu PDF oluşturma
- [ ] Danışan gelişim raporu PDF (tek danışan)
- [ ] Toplu müşteri listesi Excel export
- [ ] Sipariş geçmişi Excel export
- [ ] Özelleştirilebilir rapor şablonları

---

## FAZ 25 — KARİYER YOL HARİTASI (DİSTRİBÜTÖR) 📋

> Herbalife distribütör kariyer seviye sistemi ve VP hedefi takibi.

- [ ] `careerRoadmap` koleksiyonu kullanımı (Firestore'da zaten mevcut)
- [ ] Distribütör seviyeleri tanımlama (Member → Senior → Success Builder → Qualified → Supervisor vb.)
- [ ] Mevcut seviye gösterimi (rozet/ikon ile)
- [ ] Bir sonraki seviyeye kalan VP hesaplama
- [ ] Aylık VP ilerleme çubuğu
- [ ] Seviye atlama kutlaması (confetti + bildirim)
- [ ] Takım ağacı görselleştirme (alt distribütörler)
- [ ] Hedef belirleme ("Bu ay Supervisor olmak istiyorum")

---

## FAZ 26 — TAKVIM GÖRÜNÜMÜ 📋

> Aylık takvimde tüm aktivite özetleri.

- [ ] Aylık takvim widget'ı (grid görünümü)
- [ ] Her gün için aktivite özet ikonu (yeşil tik / kırmızı çarpı / gri boş)
- [ ] Günlük detay: su, kalori, rutin, ölçüm, fotoğraf bilgisi
- [ ] Seri günleri vurgulama (arka plan rengi ile)
- [ ] Haftalık/aylık özet kartı (kaç gün aktif, ortalama su, ortalama kalori)
- [ ] Distribütör: danışan takvimi görüntüleme

---

## FAZ 27 — BİLDİRİM MERKEZİ & UYGULAMA İÇİ BİLDİRİMLER 📋

> Merkezi bildirim sistemi ve uygulama içi bildirim akışı.

- [ ] Bildirim merkezi ekranı (tüm bildirimlerin listesi)
- [ ] Bildirim türleri: Program, Su, Ölçüm, Rozet, Takip, Sipariş, Mesaj, Meydan Okuma
- [ ] Okundu/okunmadı durumu
- [ ] Bildirim filtreleme (türe göre)
- [ ] Bildirim tercihleri yönetimi (hangi bildirimler açık/kapalı)
- [ ] AppBar'da bildirim sayacı (badge)
- [ ] FCM push bildirim entegrasyonu (Faz 14 ile birlikte)

---

## FAZ 28 — ÇOKLU DİL & TEMA DESTEĞİ 📋

> Uluslararası kullanıcılar ve görsel tercihler.

### 28.1 — Çoklu Dil (i18n)
- [ ] Flutter intl/arb dosyaları ile lokalizasyon altyapısı
- [ ] Türkçe (varsayılan) tam destek
- [ ] İngilizce çeviri
- [ ] Almanca çeviri (yurtdışı distribütörler)
- [ ] Dil seçimi ayar ekranında
- [ ] Tarih/sayı formatı dile göre otomatik ayarlama

### 28.2 — Dark Mode
- [ ] `ThemeData` dark mode tanımı (`AppColors` dark varyantları)
- [ ] Sistem temasına otomatik uyum
- [ ] Manuel tema geçişi (ayarlar ekranında)
- [ ] Tüm ekranlarda dark mode uyumluluk testi
- [ ] Grafiklerde dark mode renk paleti

---

## FAZ 29 — ANA EKRAN WİDGET'LARI (MOBİL) 📋

> Android/iOS ana ekran widget'ları ile hızlı erişim.

- [ ] Su takibi widget'ı (günlük su / hedef, hızlı +250ml butonu)
- [ ] Günlük özet widget'ı (su, kalori, rutin durumu)
- [ ] Motivasyon kartı widget'ı (günün sözü)
- [ ] Kilo ilerleme widget'ı (mevcut → hedef mini çubuk)
- [ ] Widget'tan uygulamaya deep link
- [ ] Android: `home_widget` paketi
- [ ] iOS: WidgetKit entegrasyonu

---

## FAZ 30 — QR KOD & GELİŞMİŞ DAVET SİSTEMİ 📋

> Davet sürecini kolaylaştıran ve takip eden gelişmiş sistem.

- [ ] Davet kodunu QR kod olarak gösterme (`qr_flutter` paketi)
- [ ] Kamera ile QR kod tarama ve otomatik kayıt
- [ ] Dinamik link ile davet (Firebase Dynamic Links)
- [ ] Davet istatistikleri (kaç kişi davet edildi, kaç kişi kaydoldu)
- [ ] Davet ödül sistemi (her X kişi davette özel rozet)
- [ ] Sosyal medya paylaşım kartı (marka logolu, kişisel QR kodlu)

---

## 📊 FAZ ÖZETİ

| Faz | Başlık | Durum | İlerleme |
|----|---|---|---|
| 01 | Temel Altyapı | ✅ Tamamlandı | %100 |
| 02 | Kimlik Doğrulama ve Profil | ✅ Tamamlandı | %95 |
| 03 | Navigasyon ve Routing | ✅ Tamamlandı | %100 |
| 04 | Beslenme Programı | ✅ Tamamlandı | %90 |
| 05 | Günlük Takip Modülleri | ⚠️ Kısmi | %80 |
| 06 | Gelişim Takibi | ⚠️ Kısmi | %85 |
| 07 | Rozet ve Oyunlaştırma | ✅ Tamamlandı | %90 |
| 08 | CRM ve Müşteri Yönetimi | ✅ Tamamlandı | %95 |
| 09 | Ürün ve Sipariş | ✅ Tamamlandı | %100 |
| 10 | Güvenlik Kuralları | ⚠️ Kısmi | %80 |
| 11 | Performans Optimizasyonu | 🔄 Devam Ediyor | %20 |
| 12 | Erişilebilirlik | 🔄 Devam Ediyor | %10 |
| 13 | Test Altyapısı | ❌ Başlanmadı | %0 |
| 14 | Push Bildirimleri (FCM) | ❌ Başlanmadı | %0 |
| 15 | Gelişmiş Kalori & Beslenme | 📋 Planlandı | %0 |
| 16 | AI Vücut Dönüşüm Önizlemesi | 📋 Planlandı | %0 |
| 17 | AI Yemek Fotoğrafı Tanıma | 📋 Planlandı | %0 |
| 18 | AI Koç Sohbet Botu | 📋 Planlandı | %0 |
| 19 | Fotoğraf Bulut Yedekleme | 📋 Planlandı | %0 |
| 20 | İç İletişim Sohbet | 📋 Planlandı | %0 |
| 21 | Grup Meydan Okumaları | 📋 Planlandı | %0 |
| 22 | Aktivite ve Hareket Takibi | 📋 Planlandı | %0 |
| 23 | Uyku Takibi | 📋 Planlandı | %0 |
| 24 | Distribütör Analiz Paneli | 📋 Planlandı | %0 |
| 25 | Kariyer Yol Haritası | 📋 Planlandı | %0 |
| 26 | Takvim Görünümü | 📋 Planlandı | %0 |
| 27 | Bildirim Merkezi | 📋 Planlandı | %0 |
| 28 | Çoklu Dil & Tema | 📋 Planlandı | %0 |
| 29 | Ana Ekran Widget'ları | 📋 Planlandı | %0 |
| 30 | QR Kod & Gelişmiş Davet | 📋 Planlandı | %0 |

---

## 🐛 BİLİNEN HATALAR VE TEKNİK BORÇLAR

| # | Öncelik | Açıklama | Dosya/Konum |
|---|---|---|---|
| 1 | 🔴 Yüksek | `products` koleksiyonu tamamen açık (`allow read, write: if true`) | `firestore.rules:28` |
| 2 | 🔴 Yüksek | `CalorieProvider` Firestore kaydı yok — veri kaybı riski | `calorie_provider.dart` |
| 3 | 🟡 Orta | `firestore_service.dart` ~37 KB — monolitik, bölünmeli | `services/firestore_service.dart` |
| 4 | 🟡 Orta | Fotoğraflar yalnızca yerel — cihaz değişince kaybolur | `progress_photos_screen.dart` |
| 5 | 🟡 Orta | `scheduled_follow_ups` ve `careerRoadmap` güvenlik kuralları zayıf | `firestore.rules:119-128` |
| 6 | 🟢 Düşük | Google Sign-In uçtan uca test edilmedi | `auth_service.dart` |
| 7 | 🟢 Düşük | Mango sarısı üzerinde beyaz yazı kontrast sorunu | `app_colors.dart` |
| 8 | 🟢 Düşük | Test dosyaları eksik (unit/widget/integration) | `test/` dizini |

---

## 💡 FİKİR KUTUSU

> Gelecekte değerlendirilecek yeni fikirler buraya eklenebilir. Kategorize edilmiştir.

### 🤖 Yapay Zeka & Akıllı Özellikler
- [ ] AI ile akıllı program önerisi (danışanın geçmiş verilerine göre otomatik program oluşturma)
- [ ] Doğal dil ile besin ekleme ("2 yumurta ve 1 dilim ekmek yedim")
- [ ] AI destekli risk tahmini (hangi danışan bırakma riski taşıyor)
- [ ] Kişiselleştirilmiş motivasyon mesajları (AI üretimi, danışanın durumuna göre)
- [ ] Sesli komut desteği ("250 ml su ekle", "bugün 72 kiloyum")
- [ ] Yemek fotoğrafından porsiyon tahmini ve diyet uygunluk analizi
- [ ] AI ile uyku-beslenme-egzersiz korelasyon analizi

### 📊 Veri & Analitik
- [ ] Haftalık özet rapor e-postası (otomatik gönderim)
- [ ] PDF rapor dışa aktarma (gelişim raporu — profesyonel şablon)
- [ ] Karşılaştırmalı dönem analizi ("Bu ay vs geçen ay")
- [ ] Hedef bazlı tahmin motoru ("Hedefe tahmini X hafta kaldı")
- [ ] Vücut kitle indeksi (BMI) trend grafiği ve sağlık aralığı gösterimi
- [ ] Besin eksikliği uyarısı (yetersiz protein alımı vb.)
- [ ] Su-kilo korelasyon analizi grafiği

### 🎮 Oyunlaştırma & Motivasyon
- [ ] Seviye sistemi (Çaylak → Disiplinli → Kahraman → Efsane)
- [ ] Deneyim puanı (XP) kazanma (her aktivite için puan)
- [ ] Günlük görevler (3 görev tamamla → bonus XP)
- [ ] Haftalık mini hedefler (distribütör tarafından atanabilir)
- [ ] Başarı hikayesi vitrini (diğer danışanların başarıları — izinli)
- [ ] Confetti ve kutlama animasyonları (rozet, seviye atlama)
- [ ] Avatar sistemi (profil için özelleştirilebilir karakter)
- [ ] Yeni rozetler: "Su Ustası" (30 gün su hedefi), "Erken Kuş" (7 gün zamanında uyanma), "Makro Dengeci" (ideal makro oranı yakalama)

### 💬 İletişim & Sosyal
- [ ] Distribütör-Danışan video görüşme (WebRTC veya 3. parti entegrasyon)
- [ ] Anket/form sistemi (distribütörün danışanlara soru göndermesi)
- [ ] Başarı paylaşım kartı (sosyal medya için tasarlanmış görsel)
- [ ] Topluluk forumu (soru-cevap, tarif paylaşımı)
- [ ] Danışan değerlendirme sistemi (koçu yıldızla puanlama — anonim)

### 📱 Platform & Entegrasyonlar
- [ ] Ana ekran widget'ları (su takibi, günlük özet)
- [ ] Wearable entegrasyonu (Apple Watch, WearOS, Fitbit, Xiaomi Mi Band)
- [ ] Apple Shortcuts / Android Quick Settings entegrasyonu
- [ ] Siri / Google Assistant sesli komut desteği
- [ ] iPad / Tablet optimize edilmiş UI (distribütör paneli için)
- [ ] Desktop uygulaması optimize UI (Windows/macOS — distribütör CRM)
- [ ] PWA (Progressive Web App) desteği geliştirme

### 🛒 Ürün & Sipariş Geliştirmeleri
- [ ] Ürün karşılaştırma özelliği (yan yana karşılaştırma tablosu)
- [ ] Ürün yorum ve puanlama sistemi
- [ ] Otomatik yeniden sipariş hatırlatması (ürün bitme tahmini)
- [ ] Ürün paketleri / set tanımlama (distribütör tarafından)
- [ ] Sipariş takip bildirimleri (kargo durumu)
- [ ] Ödeme entegrasyonu (iyzico, Stripe veya banka transferi kaydı)
- [ ] Fatura / fiş oluşturma (PDF)

### 🔒 Güvenlik & Gizlilik
- [ ] İki faktörlü kimlik doğrulama (2FA)
- [ ] Biyometrik giriş (parmak izi / yüz tanıma)
- [ ] Veri dışa aktarma (KVKK uyumu — tüm kişisel verileri indirme)
- [ ] Hesap silme akışı (KVKK zorunluluğu)
- [ ] Gizlilik modu geliştirme (uygulama kilidi, PIN)
- [ ] Uçtan uca şifreleme (sohbet modülü için)

### 🎨 UI/UX İyileştirmeler
- [ ] Onboarding animasyonları (Lottie)
- [ ] Skeleton loading (içerik yüklenirken iskelet ekranlar)
- [ ] Pull-to-refresh animasyonu (özelleştirilmiş)
- [ ] Splash ekranı animasyonu geliştirme (logo morph efekti)
- [ ] Mikro-etkileşimler (su ekleme dalgası, tik atma animasyonu)
- [ ] Haptic feedback (titreşim geri bildirimi — su ekleme, rozet kazanma)
- [ ] Renk teması özelleştirme (kullanıcının kendi renk paleti seçmesi)
- [ ] Font boyutu ayarlama (erişilebilirlik)
- [ ] Sağ-sol kaydırma gestleri (navigasyon)

### 🗓️ Planlama & Hatırlatıcılar
- [ ] Takvim entegrasyonu (Google Calendar'a öğün/su hatırlatıcıları ekleme)
- [ ] Hedefe özel geri sayım sayacı ("Hedef kiloya X gün kaldı")
- [ ] Periyodik ölçüm hatırlatması ("Son ölçümünüzün üzerinden 7 gün geçti")
- [ ] Distribütör randevu sistemi (danışan ile görüşme planla)
- [ ] Akıllı hatırlatıcı optimizasyonu (kullanıcının aktif olduğu saatlere göre)

### 🌍 Diğer
- [ ] Distribütör arası müşteri transferi (koç değişikliği akışı)
- [ ] Çevrimdışı mod geliştirme (Firestore offline persistence + offline indicator)
- [ ] Uygulama içi güncelleme kontrolü (in-app update)
- [ ] Crash reporting (Firebase Crashlytics entegrasyonu)
- [ ] Analytics (Firebase Analytics ile kullanıcı davranış takibi)
- [ ] A/B testing altyapısı (Firebase Remote Config)
- [ ] Referans program (mevcut kullanıcıların yeni kullanıcı getirmesi)
- [ ] Bayram/özel gün teması (Ramazan, yılbaşı — özel UI dekorasyonları)
