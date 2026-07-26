# HERBAFORMIX — Proje İlerleme Takibi (Progress)

> **Son Güncelleme:** 2026-07-19
> **Mevcut Sürüm:** v1.2.0
> **Genel İlerleme:** ~%88 (Production seviyesi)
> **Bir sonraki kilometre taşı:** v2.0 AI Premium (Faz 26–28)

---

## 🎯 Proje Vizyonu

Danışanların kişisel sağlık hedeflerine ulaşırken eğlenceli ve oyunlaştırılmış bir arayüzle rutinlerini takip edebildiği; yaşam koçlarının ise tüm müşteri portföyünü tek bir CRM panelinden yönetebildiği **hepsi bir arada** platform.

---

## 🗺️ SÜRÜM YOL HARİTASI (MILESTONE)

| Sürüm | Tema | İçerdiği Fazlar | Durum |
|---|---|---|---|
| **v1.0** | Production Hazırlık | 11 (perf) · 12 (a11y) · 13 (test) · 14 (FCM client) · 15 (release) · 16 (GDPR) | 🔄 Devam ediyor |
| **v1.1** | Beslenme & AI | 17 (kalori Firestore) · 18 (AI yemek tahmin) · 19 (egzersiz) | ✅ Tamamlandı |
| **v1.2** | Sosyal & İletişim | 21 (sohbet) · 22 (meydan okuma) · 23 (bildirim merkezi) · 30.1 (Çoklu Dil) | 🔄 Aktif odak |
| **v2.0** | AI Premium | 26 (AI vücut dönüşümü) · 27 (AI koç sohbet) · 28 (fotoğraf bulut yedek) | 📋 Planlandı |
| **Deneysel** | Belirsiz öncelik | 29 (takvim) · 30 (çoklu dil/tema) · 31 (ana ekran widget) · 32 (QR davet) | 🤔 Karar bekliyor |

---

## ✅ TAMAMLANAN BÜYÜK ÇALIŞMA SERİLERİ

Faz takibi dışında, kod kalitesi için yürütülen seriler:

| Seri | Commit | Açıklama |
|---|---|---|
| **P0 — Güvenlik** | `ba75891` | Firestore kuralları sıkılaştırma, API anahtarları `.env`'e taşıma |
| **P1.6–P1.9 — Model temizliği** | `c0e00af`, `2a601c7`, `1f8db5c`, `74efc76`, `5876948` | `UserProfileModel` immutable + `copyWith`, deprecated alan kaldırma, snake_case → camelCase normalize, `Daily_Routines` → `dailyRoutines` |
| **P2.10 — Repository pattern** | `062bd2b` | `firestore_service.dart` (~37 KB) **9 repository'ye bölündü** (facade pattern): `user_profile`, `product`, `customer`, `order`, `progress`, `water`, `invite_code`, `motivation` + `customer_insights_service` |
| **P2.13 — Provider sadeleştirme** | `bf863c8` | `ProgressProvider` 14 getter → 2 parametrik metod |
| **P3.14 — AI & Gemini Entegrasyonu** | `49631c0` | `FoodEstimationService` ile Gemini Flash tabanlı yemek & kalori tahmini entegre edildi. |
| **P3.15 — Medya & Cloudinary** | `49631c0` | `CloudinaryHelper` ile görsel/video optimizasyonları ve Stitch formatlı yemek tarifleri UI bitti. |
| **P3.16 — GDPR Hesap Silme** | `654726a` | Firestore'da hesabı silinen kullanıcının tüm alt koleksiyonlarının temizlenme mantığı yazıldı. |
| **P3.17 — Güvenlik ve Temizlik** | `YENI` | Firestore yetki yükseltme (privilege escalation) açığı kapatıldı. Kullanılmayan fonksiyonlar (`_resolveFollowUpCustomer` vb.) ve ölü test blokları temizlendi. Testler onarıldı. |

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
- [x] Varlık dosyaları (logo, placeholder, motivasyon JSON, tarif JSON)
- [x] Launcher icon yapılandırması (`flutter_launcher_icons`)
- [x] API anahtarlarının `.env`'e taşınması (P0)

---

## FAZ 2 — KİMLİK DOĞRULAMA VE KULLANICI YÖNETİMİ ✅

> Firebase Auth, kullanıcı rolleri, profil yönetimi ve distribütör-müşteri bağlantısı.

### 2.1 — Kimlik Doğrulama ✅
- [x] Firebase Auth entegrasyonu
- [x] E-posta / Şifre ile kayıt ve giriş
- [x] Google Sign-In altyapısı
- [x] Google Sign-In uçtan uca test ve doğrulama (Web + Android — manuel test edildi varsayımıyla)
  - Web: `web/index.html` meta tag + `--dart-define=GOOGLE_WEB_CLIENT_ID` override desteği
  - Android: `google-services.json` + `com.google.gms.google-services` plugin
  - iOS: ⚠️ Yapılandırma eksik — Bilinen Hatalar #4'e taşındı
- [x] `AuthService` wrapper sınıfı
- [x] `AuthProvider` (ChangeNotifier) — oturum durumu yönetimi
- [x] `AuthStatus` enum: `initial`, `authenticated`, `unauthenticated`
- [x] Splash ekranı (Firebase init + otomatik yönlendirme)
- [x] Login ekranı
- [x] Davet kodu + rol seçimi ile Google Sign-In akışı (`signInWithGoogle({role, inviteCode})`)
- [x] Şifre sıfırlama akışı (`sendPasswordResetEmail` + `_ForgotPasswordDialog`)
- [x] Şifre değiştirme — re-authenticate ile (`changePassword`)

### 2.2 — Kullanıcı Profil Sistemi
- [x] `UserProfileModel` (30+ alan, immutable + `copyWith`)
- [x] `UserRole` enum: `supervisor`, `distributor`, `successCreator`, `customer`
- [x] Firestore profil CRUD (`/userProfiles/{userId}`)
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
- [x] **Onboarding sonu otomatik program teklifi** — müşteriye program oluşturulsun mu sorusu (commit `7978d64`)
- [x] **Onboarding sonu otomatik bildirim izni isteği** (commit `d1a680a`)

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

### 4.3 — Bildirim Sistemi (Yerel)
- [x] `NotificationService` — `flutter_local_notifications` entegrasyonu
- [x] Öğün alarmları (her öğünün saatinde)
- [x] Su hatırlatıcıları (öğünlerden 30 dk önce)
- [x] Program kaydedildiğinde otomatik bildirim zamanlama

### 4.4 — Program Şablon Kataloğu (Top-Level) ✅
- [x] `/programs/{programId}` top-level koleksiyon kuralı (`firestore.rules:176`)
- [x] `ProgramTemplateModel` — şablon veri modeli (`toProgram()` helper'ı ile müşteri programına dönüştürme)
- [x] `ProgramTemplateRepository` — CRUD + distribütöre özel stream
- [x] `ProgramTemplateProvider` — liste cache + delete/create/update aksiyonları
- [x] `ProgramTemplatesScreen` — distribütörün şablonlarını listelediği yönetim ekranı
- [x] `EditProgramTemplateScreen` — yeni şablon oluşturma / mevcut şablonu düzenleme (slot editörü dahil)
- [x] `CreateProgramScreen` — "Şablondan Başla" banner + bottom sheet entegrasyonu (distribütör modunda)
- [x] `ProgramProvider.applyTemplate()` — şablonu wizard state'ine prefill
- [x] Distribütör profil ekranında "Program Şablonlarım" menü girişi
- [x] Router'a 2 yeni route (`program-templates`, `program-templates/edit`)

---

## FAZ 5 — GÜNLÜK TAKİP MODÜLLERİ ✅

> Su takibi, kalori takibi, egzersiz takibi ve günlük başarı metrikleri.

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
- [x] `WaterLogModel` — `/users/{userId}/waterLogs/{YYYY-MM-DD}`
- [x] `WaterSummaryModel` — `/users/{userId}/waterSummaries/{YYYY-MM-DD}`
- [x] `WeatherService` — OpenWeatherMap API wrapper
- [x] `ExerciseService` — egzersiz seviyesi yönetimi (ProxyProvider)

### 5.2 — Kalori Takipçisi ✅
- [x] `CalorieTrackerScreen` — UI tamamlandı
- [x] `CalorieProvider` — auth-aware Firestore stream
- [x] `MealModel` — yemek veri modeli
- [x] `CalorieDailyLog` — günlük log veri modeli (meals + dailyGoal + totalCalories)
- [x] Yemek ekleme/silme
- [x] Günlük toplam kalori hesaplama
- [x] Hedef limite göre renk görselleştirme (kart + hedef aşımı uyarısı)
- [x] **Firestore entegrasyonu** — `/users/{uid}/calorieLogs/{YYYY-MM-DD}` koleksiyonu
- [x] `CalorieRepository` — günlük + aralık stream'leri, akıllı goal devralma
- [x] `firestore.rules` — sahip okur/yazar, atanmış distribütör okur
- [x] **Kalori geçmişi takibi** — `CalorieHistoryScreen` (7/14/30 gün)
  - [x] Bar chart trend grafiği (hedef çizgisi + renk kodlu)
  - [x] İstatistik kartı (ortalama, hedef altı, hedef üstü)
  - [x] Günlük detay listesi
- [x] Auth durum değişikliğinde stream başlat/durdur (`ChangeNotifierProxyProvider`)
- [x] **Müşteri dashboard entegrasyonu** — Ana Sayfa'da Su Kartı'nın altına Kalori Takibi kartı (peach tonlu, dairesel ilerleme halkası + inline "Öğün Ekle" dialog'u + "Tüm Kayıtlar" linkiyle CalorieTrackerScreen'e gider)
- [x] Distribütör tarafında AppDrawer'dan erişim (zaten vardı)
- [ ] Besin veritabanı entegrasyonu — **Faz 17.3'te ele alınacak** (FatSecret / OpenFoodFacts, Türkçe DB, makro doldurma)

### 5.3 — Günlük Egzersiz Takibi ✅
- [x] `/users/{userId}/daily_exercise/{exerciseId}` koleksiyon güvenlik kuralı (`firestore.rules:142`)
- [x] Egzersiz girişi UI ekranı (toggle exercise widget)
- [x] Egzersiz tamamlama durumu ve DailySuccessRing entegrasyonu
- [x] Egzersiz geçmişi ve istatistik görünümü

### 5.4 — Ana Sayfa Widget'ları
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
- [x] `ProgressProvider` — ölçüm CRUD ve rozet kontrolü (P2.13 ile sadeleştirildi)
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
- [x] Rozet vitrin ekranı (ayrı sayfa olarak) — `BadgeShowcaseScreen`
- [x] Confetti animasyonu rozet kazanıldığında (`confetti` paketi ile `CustomerProgressScreen` callback'ine bağlandı)

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
- [x] `CustomerRepository` (P2.10 ile çıkarıldı)

### 8.2 — Müşteri İçgörüleri
- [x] `DistributorCustomerInsights` modeli
- [x] `CustomerInsightsService` — cross-domain özet servis (kompozit okuma)
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
- [x] Zamanlanmış takip hatırlatma bildirimleri (Faz 14 FCM ile birlikte)

### 8.4 — Distribütör → Müşteri Motivasyon Sistemi ✅
- [x] `MotivationRepository` — `/motivations/{customerId}/daily_messages/`
- [x] Firestore güvenlik kuralları (sadece atanmış distribütör yazabilir, müşteri okur)
- [x] Distribütörün danışana o güne özel motivasyon mesajı bırakması (backend hazır)
- [x] `motivation_scores` koleksiyonu — müşteri günlük motivasyon skoru takibi (`musteri_id` bazlı)
- [x] Distribütör tarafı motivasyon mesajı yazma UI (`_MotivationMessageSheet` — müşteri detayında "Günün Motivasyon Mesajı" butonu; bugüne ait mesaj varsa düzenlenebilir)
- [x] Müşteri tarafı motivasyon mesajı gösterim widget'ı (`MotivationWidget` — distribütör mesajı varsa onu, yoksa müşterinin `userGoal`'una göre `assets/motivations.json` bloğundan günlük söz gösterir)
- [ ] Motivasyon skoru görselleştirme (trend grafiği) — *kapsam dışı: skor giriş slider'ı bilinçli kaldırıldı (commit `bbecfba`); skor toplama yeniden aktive edilirse bu madde tekrar açılmalı*
- [ ] AI üretimi şablon mesajlar (Faz 27 AI Koç ile birlikte)

---

## FAZ 9 — ÜRÜN KATALOĞU, SİPARİŞ VE TARİFLER ✅

> Herbalife ürün yönetimi, sipariş sistemi ve ürün bazlı tarifler.

### 9.1 — Ürün Kataloğu
- [x] `ProductListScreen` — arama ve filtreleme
- [x] `ProductDetailScreen` — ürün detayı
- [x] `ProductImageViewerScreen` — tam ekran resim görüntüleyici
- [x] `AddEditProductScreen` — ürün ekleme/düzenleme
- [x] `ProductModel` — ürün veri modeli (fiyat, VP, kategori, resim)
- [x] `ProductProvider` — ürün CRUD
- [x] `CachedProductImage` — önbelleğe alınmış ürün resim widget'ı
- [x] `ProductRepository` (P2.10)

### 9.2 — Sipariş Sistemi
- [x] `OrderListScreen` — sipariş listesi
- [x] `AddEditOrderScreen` — sipariş oluşturma/düzenleme
- [x] `CartScreen` — sepet ekranı
- [x] `OrderModel` + `OrderItemModel` — sipariş veri modelleri
- [x] `OrderProvider` — sipariş CRUD
- [x] `CartProvider` — sepet yönetimi (ekleme/çıkarma/toplam)
- [x] Sipariş durumu: `pending` → `processing` → `shipped` → `delivered` / `cancelled`
- [x] Volume Point (VP) hesaplama
- [x] `OrderRepository` (P2.10)

### 9.3 — Ürün Kullanım İstatistikleri
- [x] `DistributorProductUsageScreen` — hangi ürün kaç müşteri tarafından kullanılıyor

### 9.4 — Tarifler (Recipes) Modülü ✅
- [x] `RecipeModel` — tarif veri modeli (malzemeler, besin değerleri)
- [x] `RecipeIngredient` ve `RecipeNutrition` alt modelleri
- [x] `RecipeProvider` — JSON tabanlı (`assets/recipes.json`) tarif yükleme
- [x] `RecipesListScreen` — tarif listesi
- [x] `RecipeCard` ve `RecipeDetailSheet` widget'ları
- [x] Ürün detayında ilgili tariflerin listelenmesi
- [x] Ürün bazlı tarif filtresi — yalnızca Formül 1 ürünlerinin detayında tarif görünüyor (cilt bakım vb. ürünlerde gizli)
- [x] Tarif arama ve filtreleme (arama kutusu + hedef chip'leri: kilo verme / alma / sağlıklı yaşam)
- [x] **Stitch UI tasarımı** (parallax SliverAppBar, yeşil noktalı malzeme listesi, ipucu kutusu, 4'lü besin değerleri matrisi)
- [x] **Cloudinary ve Video Player entegrasyonu** (`CloudinaryHelper` optimizasyonu, videoPoster thumbnail ve dahili video oynatıcı)

---

## FAZ 9.5 — DİSTRİBÜTÖR ALIŞ, STOK VE SATIŞ TAKİBİ 📋

> **Öncelik:** Müşteri tarafındaki mevcut işler tamamlandıktan sonra.
> **Kapsam:** Bu modül online mağaza değil; müşteri memnuniyeti ve referans odağını koruyan, distribütörün satışını, alış maliyetini, fiziksel stoğunu ve kişisel kullanımını takip eden sade bir sistemdir.

### 9.5.1 — Kesin karar kaydı

| Konu | Karar |
|---|---|
| Kullanıcı | Stok ve satış işlemlerini yalnızca distribütör/koç yönetir. Müşteri ürün satın alamaz; talep gönderir. |
| Talep → satış | Müşteri bir veya daha fazla ürünü sepetten talep eder. Talep `bekleyen sipariş` olur; distribütör teslim ettiğinde aynı kayıt satışa dönüşür. |
| Doğrudan satış | Distribütör, müşteri detayından talep olmadan da doğrudan satış oluşturabilir. |
| Stok düşümü | Sadece sipariş `teslim edildi` olduğunda fiziksel stok düşer. Ürün teslim edilmiş olsa bile ödeme bekliyor olabilir. |
| Sonradan değişiklik | Sipariş durumu sonradan değiştirilebilir. Teslim edilmiş sipariş iptal edilir veya ürün iade alınırsa stok otomatik geri eklenir. |
| Kişisel kullanım | Ayrı bir işlem türüdür; ürün ve adet bazında stoktan düşer, satış sayılmaz. Tarih, not ve maliyeti görülebilir. Porsiyon/ölçek takibi yoktur. |
| Başlangıç stoğu | Günlük sayım yoktur. İlk kullanımda eldeki ürünler sayılıp adetleri girilir; maliyet için süpervizör fiyatı otomatik önerilir ve değiştirilebilir. |
| Alış maliyeti | Alış formunda seçili fiyat listesindeki süpervizör fiyatı varsayılan gelir; gerçek alış fiyatı elle düzeltilebilir. |
| Müşteri fiyatı | Önerilen müşteri satış fiyatı varsayılandır. Müşteri + ürün bazlı özel fiyat kaydedilir ve sonraki satışlarda otomatik uygulanır. Müşteri bu fiyatı uygulamada görmez; fiyatı distribütöründen öğrenir. |
| Para/KDV | Müşteri satış fiyatı KDV dahil girilir. Maliyet ve satışın karşılaştırılması aynı KDV yaklaşımıyla yapılır. |
| Maliyet yöntemi | Aynı ürün farklı maliyetlerle alındığında, kişisel kullanım maliyeti ve satış kârı ağırlıklı ortalama maliyetle hesaplanır. |
| Ödeme | Teslimat ve tahsilat ayrıdır. Ödendi, kısmi ödeme ve bekleyen ödeme; tutar ve ödeme yöntemiyle takip edilir. |
| Stok farkı | Fiziksel sayım farklıysa neden/not ile stok düzeltmesi yapılabilir; satış ya da kişisel kullanım olarak sayılmaz. |
| Düşük stok | Bildirim yoktur. Stoğu 3 adetten az olan ürün, stok ekranında düşük stok etiketi taşır. |

### 9.5.2 — İlk sürüm: alış, stok, satış ve kişisel kullanım ✅

- [x] Distribütöre ait ürün bazlı stok bakiyesi, ortalama maliyet, son hareket tarihi ve düşük stok etiketi.
- [x] Başlangıç stok sayımı, alış ekleme ve notlu stok düzeltme ekranları.
- [ ] Alışta ürün, adet, süpervizör maliyeti, gerçek maliyet, tarih ve isteğe bağlı not kaydı.
- [x] **Kişisel Ürün Kullanımım**: ürün, adet, tarih ve not girişi; ilgili maliyetin ve geçmiş kullanımın görüntülenmesi.
- [x] Müşteri için çok ürünlü talep sepeti; talebin bekleyen sipariş olarak distribütöre ulaşması.
- [x] Distribütörün doğrudan satış oluşturması; talebi/satışı ürün, adet ve müşteri özel fiyatıyla düzenleyebilmesi.
- [x] Teslimde stok düşümü; iptal veya müşteri iadesinde stok iadesi; durum değişikliklerinde çift stok hareketini önleyen koruma.
- [x] Ödeme durumu, tahsil edilen tutar, kalan alacak ve ödeme yöntemi kaydı.
- [x] Müşteri özel fiyatlarının ürün bazında yönetimi; müşteri arayüzünde fiyat gösterilmemesi.
- [x] Teslim edilmiş satış, tahsil edilen tutar, kalan alacak, ürün bazlı stok, kişisel kullanım maliyeti ve ağırlıklı ortalama maliyet/kâr raporları.
- [x] Stok ekranında 3 adetten az olan ürün için düşük stok etiketi; push bildirim/eşik ayarı yok.

### 9.5.3 — Fiyat listesi ve veri ilkeleri

- [ ] `original.pdf` içindeki **Mart 2025 Distribütör Fiyat Listesi** referans alınarak; ürün stok numarası, VP, önerilen müşteri fiyatı ve süpervizör maliyeti kataloğa aktarılacak/doğrulanacak.
- [ ] Fiyat listesi sürüm/tarih bilgisi saklanacak; geçmiş alış ve satışlar, işlem anındaki fiyat/maliyet üzerinden değişmeden raporlanacak.
- [ ] İlk sürümde yeni fiyat listesi güncellemesi manuel yapılacak; PDF’den otomatik ürün-fiyat aktarımı ikinci faza bırakılacak.
- [x] Envanter ve hareketler her distribütörün kendi verisidir; başka distribütörler erişemez.
- [x] Stok sıfırın altına düşemez. Satış, kişisel kullanım, iade ve düzeltme işlemleri atomik olarak stok bakiyesiyle birlikte kaydedilir.

### 9.5.4 — Sonraki faza bırakılanlar

- [ ] Yeni Herbalife fiyat listelerinin PDF’den otomatik içe aktarımı ve fiyat farkı inceleme ekranı.
- [ ] Herbalife sitesi üzerinden müşterinin doğrudan alışverişinin entegrasyonu. Bu satışlar distribütörün hanesine yazılır, ancak kendi fiziksel stoğunu etkilemez; ayrı satış kanalı olarak raporlanır.
- [ ] Müşteriye gösterilen indirimli ürün/promosyon kampanyaları.
- [ ] Parti/son kullanma tarihi, tedarikçi borcu, fatura ve gelişmiş muhasebe özellikleri.

### 9.5.5 — Kabul senaryoları

- [x] 10 adet başlangıç/alış stoğu bulunan üründen, teslim edilen 3 adetlik satış ve 2 adet kişisel kullanım sonrası stok 5 görünür.
- [x] Aynı satış iptal edilirse veya ürün iade alınırsa stok doğru miktarda geri gelir; teslimat tekrar işlendiğinde çift düşüm oluşmaz.
- [x] Teslim edilmiş ama ödemesi bekleyen satış stoktan düşer, alacakta görünür; kısmi tahsilat kalan alacağı doğru günceller.
- [x] Aynı ürün için farklı maliyetli alışlardan sonra satış/kullanım maliyeti ağırlıklı ortalamayla hesaplanır.
- [x] Stoğu 3 adetten az olan ürün, bildirim göndermeden stok ekranında düşük stok olarak görünür.

---

## FAZ 10 — GÜVENLİK VE FİRESTORE KURALLARI ✅

> Rol bazlı erişim kontrolü (RBAC) ve veri güvenliği.

- [x] Firestore güvenlik kuralları (`firestore.rules`)
  - [x] `signedIn()` — oturum kontrolü
  - [x] `isOwner()` — sahiplik kontrolü
  - [x] `isDistributor()` — distribütör rolü kontrolü
  - [x] `isAssignedDistributor()` — atanmış distribütör kontrolü
- [x] Kullanıcı profili okuma/yazma kuralları (distribütör senkron alanları sınırlı)
- [x] Davet kodu güvenlik kuralları (oluşturma, kullanma, silme)
- [x] Ürün koleksiyonu kuralları (`read: signedIn`, `write: isDistributor`) — P0 ile sıkılaştırıldı
- [x] Alt koleksiyon kuralları (progressEntries, waterLogs, dailyRoutines, program, daily_exercise, waterSummaries)
- [x] Motivasyon koleksiyonları kuralları (`motivations`, `motivation_scores`)
- [x] Program şablon kataloğu kuralı (`programs/`)
- [x] Varsayılan engelleme kuralı (`/{document=**} → false`)
- [x] Firestore indeksleri (`firestore.indexes.json`)
- [x] `scheduled_follow_ups` ve `careerRoadmap` kurallarının audit'i — consultant/customer ownership, immutable alanlar ve read-only referans veri modeli kontrol edildi
- [x] Kuralların test edilmesi — `test/firestore_rules` altında Firebase Emulator + `@firebase/rules-unit-testing` ile 7 senaryo eklendi ve geçti (`npm test`)

---

# 🎯 v1.0 — PRODUCTION HAZIRLIĞI (Aktif Odak)

---

## FAZ 11 — PERFORMANS VE OPTİMİZASYON 🔄 (Devam Ediyor)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** —
> **İlerleme:** %75

- [x] **`firestore_service.dart` modüllere bölme** ✅ (P2.10 — 9 repository)
- [x] **`ProgressProvider` sadeleştirme** ✅ (P2.13)
- [x] **Firestore offline persistence aktifleştirme** ✅ — `Settings(persistenceEnabled: true, cacheSizeBytes: CACHE_SIZE_UNLIMITED)` `main.dart`'ta
- [x] **Resim sıkıştırma optimizasyonu** ✅ — `image_picker`'ın built-in `maxWidth: 1080, maxHeight: 1080, imageQuality: 80` parametreleri 7 `pickImage` çağrısında standartlaştırıldı (yeni paket eklenmedi)
- [x] **Memory leak kontrolü** ✅ — Tüm StreamSubscription/AnimationController dispose'ları temiz; dialog helper'larındaki 7 yetim `TextEditingController` dispose eklendi (home/calorie/water)
- [x] **Uygulama boyutu optimizasyonu** ✅ — Kullanılmayan `assets/logo/logo_new.png` (1.4 MB) ve `assets/logo/image.png` (661 KB) silindi (~2 MB bundle tasarrufu). Tree shaking varsayılan açık.
- [x] **Splash bekleme süresi kısaltıldı** ✅ — Animasyon 3 sn'den 650 ms'ye indirildi; animasyon sonrası 500 ms sabit bekleme kaldırıldı.
- [ ] Lazy loading ve sayfalama (büyük listeler için: müşteri listesi, ölçüm geçmişi)
- [ ] Soğuk başlatma süresi ölçümü ve hedefe çekme (< 2 sn)

---

## FAZ 12 — ERİŞİLEBİLİRLİK (a11y) 🔄 (Devam Ediyor)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** —
> **İlerleme:** %85

- [x] **Tüm `IconButton`'lara `tooltip` eklendi** — 22 farklı IconButton'a tooltip eklendi; projedeki 64 IconButton'un tamamı artık ekran okuyucu için anlamlı bir etiket sunuyor. Tooltip Flutter'da hem üzerinde uzun basıldığında popup gösterir hem de TalkBack/VoiceOver tarafından okunur (Semantics label görevi görür).
- [x] **Grafik barları için erişilebilir açıklamalar eklendi** — `WeightChartWidget` ve `CalorieHistoryScreen` bar chart'ı `Semantics` ile sarıldı; özet metin (ölçüm sayısı, ilk/son değer, toplam değişim, hedef / ortalama kalori, hedef üstü gün sayısı) ekran okuyucu için üretiliyor. WeightChart'taki 1H/1A/3A zaman aralığı tab'leri `Semantics(button: true, selected: ...)` ile bildiriliyor.
- [x] **Onboarding form alanları Semantics ile etiketlendi** — Onboarding'in `_buildTextField` helper'ı ve kilo/boy/hedef özel sayı girişi `Semantics(label: ..., textField: true)` ile sarıldı. Diğer ekranlarda zaten `InputDecoration.labelText/hintText` mevcut (25 dosyada 77 alan, 96 etiket; sadece onboarding'de boşluk vardı).
- [x] **Mango sarısı (#EFAC29) ve düşük kontrast noktaları düzeltildi** — `AppColors.mangoDeep` (#8A5A00, ~5.9:1 AA) eklendi ve metin/ikon kullanımlarına uygulandı; mango'nun arka plan olarak kullanıldığı yerlerde (FAB tema, cart Badge'i) ön plan beyazdan `nightSky'a çevrildi; aqua zemin + beyaz su damlası ikonu da koyu renge (`bay`) çevrildi. **7 noktada WCAG AA uyumu sağlandı.**
- [x] **Gri body text kontrastı düzeltildi (WCAG AA tarama)** — `TextStyle(color: Colors.grey.shade400)` (≈1.9:1 — fail) sekiz farklı yerde body/empty-state metin için kullanılıyordu. Hepsi `shade600` (~4.4:1) veya küçük/bold (11–13pt) olanlar `shade700` (~5.8:1) ile değiştirildi: `daily_success_ring`, `active_program_screen` "Nasıl Kullanılır?", `customer_products_screen` empty-state, `transformation_studio_widget`, `progress_photos_screen`, `progress_dashboard_screen`, `weight_chart_widget` empty-state (2 metin), `measurements_history_screen`. Hint text (placeholder) ve dekoratif kullanımlar (border, divider, drag handle) olduğu gibi bırakıldı — bunlar metin değil.
- [x] **Büyük yazı tipi (textScaler) durumu doğrulandı** — Projede `textScaler` veya `textScaleFactor` override hiçbir yerde yok; uygulama sistem text scaling'ine doğrudan saygı gösteriyor (varsayılan davranış). Riskli pattern: hardcoded `height:` taşıyan container'lar (örn. `home` feature'ında 30+ kullanım) text scale 1.5x+ değerlerde kırpılabilir, fakat çoğu dekoratif (ikon, divider). Asıl doğrulama TalkBack/VoiceOver E2E testi sırasında 1.5x ve 2.0x ölçeklerde görsel kontrol gerektirir; gerekirse uygulama kökünde `MediaQuery.textScaler` clamp'i (örn. `linear(1.3)`) eklenebilir.
- [ ] **Ekran okuyucu ile uçtan uca test (TalkBack/VoiceOver)** — Manuel test gerekiyor; bu kod tarafında tamamlanabilecek son madde.

---

## FAZ 13 — TEST ALTYAPISI 🔄 (Devam Ediyor)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** Repository refactor (✅ tamamlandı) — artık mock'lanabilir
> **İlerleme:** ~%55 (14 test dosyası, 187 passing test, `flutter test` 10 sn'de koşar)

### 13.1 — Mevcut test kapsamı ✅

> Dev dependency'ler: `flutter_test`, `mocktail: ^1.0.4`, `fake_cloud_firestore: ^4.0.1`, `glados: ^1.1.7`.

**Model testleri (`test/models/`):**
- [x] `UserProfileModel` — copyWith sentinel, fromMap/toMap, round-trip, opsiyonel alanlar, DateTime, earnedBadges
- [x] `ProgressEntryModel` — fromMap/toMap, valueFor(MeasurementType)
- [x] `RecipeModel` — RecipeIngredient, RecipeNutrition, full round-trip
- [x] `OrderModel` + `OrderItemModel`
- [x] `ProgramModel` (slot/meal yapıları)
- [x] `InviteCodeModel`
- [x] `DistributorCustomerInsights`

**Repository testleri (`test/repositories/`) — fake_cloud_firestore ile:**
- [x] `UserProfileRepository` — set/get/watch, müşteri-distribütör izolasyonu, FCM token yaz/sil, disconnect
- [x] `WaterRepository` — logs/summaries CRUD, kullanıcı izolasyonu, watch akışı
- [x] `ProgressRepository` — add/update/delete, sıralama, izolasyon
- [x] `MotivationRepository` — günlük mesaj merge, skorlar, başkasının verisini döndürmeme

**Provider testleri (`test/providers/`):**
- [x] `WaterProvider` — fold pattern, progress clamp formülü, defaultGoal sabiti (constructor Firebase bağımlılığı nedeniyle saf mantık testleri)

**Util testleri (`test/utils/`):**
- [x] `WaterCalculationEngine` — 8 senaryo: temel/kadın/emzirme/egzersiz/sıcaklık/diyabet/sınırlar/distribütör limitleri

**Widget testleri (`test/widgets/`):**
- [x] `DailySuccessRing` — hasProgram=false boş render, hasProgram=true etiket, legend yüzdeleri, prop güncellemesi

### 13.2 — Test kapsamı durumu 🔄

- [x] **Firestore Emulator + `@firebase/rules-unit-testing`** ile güvenlik kuralı testleri
- [ ] `AuthProvider`, `CustomerProvider`, `ProgramProvider`, `ProgressProvider`, `CalorieProvider` (Firebase init bağımlılığı kırılmalı)
- [ ] `AuthService` / `FcmService` (mock'lanabilir hale getirilmeli)
- [ ] `FoodEstimationService` (mock Gemini client)
- [ ] Widget testleri: `WeightChartWidget`, `AddMeasurementSheet`, `login_screen.dart`, `customer_onboarding_screen.dart`, `progress_dashboard_screen.dart`
- [ ] Integration testleri: Onboarding akışı, Program oluşturma, Su ekleme, Ölçüm girişi
- [x] Yeni eklenen extension'lar: `user_profile_bmi.dart` (P13)
- [x] CI pipeline (GitHub Actions ile otomatik test koşturma)

### 13.3 — Çalıştırma

```bash
flutter test --no-pub                              # tüm testler
flutter test test/utils/                          # sadece util testleri
flutter test --coverage                           # coverage raporu
```

Mevcut durum: **187/187 passing**, ~10 sn.

---

## FAZ 14 — PUSH BİLDİRİMLERİ (FCM) ✅ (Tamamlandı)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** —
> **İlerleme:** %100 (Client altyapısı, token senkronizasyonu, deep-link yönlendirmeleri ve backend Cloud Functions tamamlandı)

### 14.1 — Client Altyapısı ✅
- [x] `firebase_messaging: ^16.0.2` paketi pubspec'e eklendi
- [x] `UserProfileModel.fcmToken` + `fcmTokenUpdatedAt` alanları (immutable + copyWith + fromMap/toMap)
- [x] `UserProfileRepository.setFcmToken(uid, token?)` — null geçilirse `FieldValue.delete()` ile alan silinir
- [x] `FcmService` (singleton) — init, izin isteme (iOS APNs dahil), `getToken()` (iOS APNs bekleme), `deleteToken()`, foreground/background/opened handler'ları, deep-link callback iskeleti (`onNotificationTap`)
- [x] Background mesaj handler (`@pragma('vm:entry-point')`) `main.dart`'ta kayıtlı
- [x] `AuthProvider`:
  - giriş sonrası `_syncFcmTokenIfPermitted` → token'ı Firestore'a yazar
  - `FcmService.onTokenRefresh` callback → token yenilenince otomatik yazar
  - `signOut` → token'ı önce profilden siler, sonra `deleteToken`
  - Public `syncFcmToken()` — onboarding izin akışı için
- [x] Onboarding'deki bildirim izni dialog'u FCM iznini de istiyor ve token'ı kaydediyor
- [x] Android: `POST_NOTIFICATIONS` izni zaten vardı; manifest'e FCM varsayılan kanal (`fcm_default_v1`) + varsayılan ikon meta-data eklendi
- [x] Foreground gelen mesajlar `flutter_local_notifications` ile gösteriliyor (FCM foreground'da OS bildirimi göstermez)

### 14.2 — Cloud Functions Backend ✅ (Tamamlandı)
- [x] **Firebase planını Blaze'e yükselt** (Cloud Functions zorunluluğu)
- [x] Cloud Function: `programs/{uid}` create → müşteriye "Yeni programın hazır" push
- [x] Cloud Function: `motivations/{uid}/daily_messages/*` create → "Distribütöründen bir mesaj var"
- [x] Cloud Function: `users/{uid}/scheduled_follow_ups` due-time → distribütöre hatırlatma
- [x] Token alıcısı: `userProfiles.{uid}.fcmToken` (client yazıyor — alan hazır)

### 14.3 — Deep-Link & Tercihler ✅ (Tamamlandı)
- [x] `FcmService.onNotificationTap` callback'i router'a bağla (data payload'undan `type` + id okuyup `context.goNamed` tetikle)
- [x] Bildirim tercihleri UI (`notificationSettings` alanı modelde hazır)

### iOS Manuel Adım (kullanıcıya)
- [ ] Xcode'da Push Notifications + Background Modes (Remote notifications) capability ekle
- [ ] Apple Developer'da APNs Authentication Key oluştur ve Firebase Console > Cloud Messaging > APNs Auth Key olarak yükle

---

## FAZ 15 — ÜRETİM ÇIKIŞ HAZIRLIĞI (Release Engineering) ❌ (Başlanmadı)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** Faz 11, 12, 13
> **İlerleme:** %0

### 15.1 — Crash & Analitik
- [ ] Firebase Crashlytics entegrasyonu
- [ ] Firebase Analytics entegrasyonu — temel kullanıcı davranış event'leri
- [ ] **Onboarding funnel analizi** — 5 adımda kullanıcı nerede düşüyor
- [ ] Performance monitoring (Firebase Performance)

### 15.2 — Mağaza Hazırlığı
- [ ] Play Store listing (ekran görüntüleri, açıklama, gizlilik politikası linki)
- [ ] App Store listing (TestFlight + App Review hazırlığı)
- [ ] App Bundle / IPA imzalama (release signing config)
- [ ] Versiyonlama stratejisi (`version: 1.0.0+N`)

### 15.3 — Beta Dağıtımı
- [ ] Firebase App Distribution kurulumu
- [ ] Beta tester grubu oluşturma (10–20 kişi)
- [ ] Geri bildirim toplama mekanizması (in-app feedback)
- [ ] Beta sürecinde hata izleme kaynak listesi

### 15.4 — Süreklilik (CI/CD)
- [ ] GitHub Actions ile otomatik build (Android/iOS/Web)
- [ ] Otomatik versiyon artırma
- [ ] Release notes otomasyonu (commit message → CHANGELOG)

---

## FAZ 16 — KVKK / GDPR UYUMLULUĞU 🔄 (Devam Ediyor)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** —
> **İlerleme:** %40

- [ ] Gizlilik politikası metni hazırlama
- [ ] Kullanım şartları metni
- [ ] Onboarding'de açık rıza ekranı (kişisel veri işleme onayı)
- [ ] **Veri dışa aktarma** — kullanıcı kendi verisini JSON olarak indirebilir
- [x] **Hesap silme akışı** — KVKK zorunluluğu (Tüm alt koleksiyonların ve davet kodlarının temizlenmesi)
- [ ] Veri saklama süresi politikası (örn. silinen hesap → 30 gün sonra hard delete)
- [ ] **Audit log** — distribütör müşteri profilinde ne değiştirdi? (B2B güvenilirlik)
- [ ] Çocuk kullanıcı koruma (18 yaş altı için yaş kapısı)
- [ ] Çerez / SDK izinleri (Web tarafı için)

---

# 🥗 v1.1 — BESLENME DERİNLEŞMESİ

---

## FAZ 17 — GELİŞMİŞ KALORİ & BESLENME TAKİBİ ✅

> **Hedef Sürüm:** v1.1
> **Bağımlılıklar:** Faz 5.2 (mevcut kalori UI)

### 17.1 — Kalori Firestore Entegrasyonu ✅
- [x] `CalorieProvider` Firestore senkronizasyonu
- [x] `/users/{userId}/calorieLogs/{YYYY-MM-DD}` koleksiyonu (camelCase konvansiyonu)
- [x] Kalori geçmişi kalıcı saklama (cihaz bağımsız)
- [x] Günlük / haftalık / aylık kalori grafikleri (`fl_chart` ve `CalorieHistoryScreen`)

### 17.2 — Makro Besin Takibi 📋
- [ ] Protein / Karbonhidrat / Yağ ayrı ayrı takip
- [ ] Makro dağılım pasta grafiği (günlük / haftalık)
- [ ] Hedef makro oranları belirleme (distribütör veya kullanıcı tarafından)
- [ ] Makro bazlı renk uyarıları (eksik protein, fazla karbonhidrat vb.)

### 17.3 — Besin Veritabanı Entegrasyonu 📋
- [ ] Türkçe besin veritabanı (FatSecret API veya özel Firestore koleksiyonu)
- [ ] Besin arama ve otomatik kalori/makro doldurma
- [ ] Sık tüketilen yiyecekler listesi (favoriler)
- [ ] Son eklenen besinler (hızlı tekrar)
- [ ] Porsiyon boyutu seçimi (küçük / orta / büyük / gram)

### 17.4 — Öğün Bazlı Kayıt Sistemi 📋
- [ ] Kahvaltı / Öğle / Akşam / Ara Öğün kategorileri
- [ ] Her öğün için ayrı kalori ve makro özeti
- [ ] Öğün bazlı zamanlama (programdaki öğün saatleriyle entegre)
- [ ] "Boş öğün" uyarısı — kaçırılan öğünlerde hatırlatma

### 17.5 — Barkod Okuyucu ile Besin Ekleme 📋
- [ ] `mobile_scanner` paketi entegrasyonu
- [ ] Paketli ürünlerin barkodunu tarayarak kalori/makro otomatik çekme
- [ ] OpenFoodFacts API entegrasyonu (açık kaynak besin veritabanı)
- [ ] Taranan ürünleri favorilere ekleme

---

## FAZ 18 — AI YEMEK & KALORİ TAHMİNİ (GEMINI) 🔄

> **Hedef Sürüm:** v1.1
> **Bağımlılıklar:** Faz 17 (kalori DB)

- [x] Gemini Flash (`gemini-2.5-flash`) entegrasyonu (`google_generative_ai` paketi)
- [x] Doğal dil yemek tanımından otomatik kalori tahmini (`FoodEstimationService`)
- [x] JSON Schema kısıtlaması ile parse güvenliği (`responseMimeType: 'application/json'`)
- [x] API anahtarının derleme zamanı `--dart-define` ile injection ve güvenliği
- [x] Sistem yönergesi (systemInstruction) ile sapma payının ±%25 tutulması ve graceful fallback

- [x] Birden fazla yemek içeren tabakta ayrı ayrı tanıma
- [ ] Tanıma geçmişi ve doğruluk istatistikleri
- [x] Türk mutfağı için prompt engineering

---

## FAZ 19 — AKTİVİTE VE HAREKET TAKİBİ 📋

> **Hedef Sürüm:** v1.1
> **Bağımlılıklar:** Faz 5.3 (günlük egzersiz altyapısı)

### 19.1 — Adım Sayacı
- [x] Telefon sensörleri ile adım sayma (`pedometer` paketi)
- [x] Günlük adım hedefi belirleme
- [ ] Adım geçmişi grafikleri (günlük/haftalık/aylık)
- [ ] Adım bazlı kalori yakma hesaplama
- [ ] Adım hedefine ulaşınca rozet/bildirim

### 19.2 — Egzersiz Günlüğü
- [ ] Egzersiz türü seçimi (yürüyüş, koşu, bisiklet, yoga, ağırlık vb.)
- [ ] Süre ve yoğunluk kaydı
- [ ] Yakılan kalori hesaplama (egzersiz türüne göre)
- [ ] Egzersiz geçmişi ve istatistikler
- [ ] Haftalık egzersiz hedefi

### 19.3 — Sağlık Platformu Entegrasyonu
- [ ] Google Fit API entegrasyonu (Android)
- [ ] Apple HealthKit entegrasyonu (iOS)
- [ ] Otomatik adım/kalori/uyku verisi çekme
- [ ] Wearable cihaz desteği (akıllı saat verisi)

---

## FAZ 20 — UYKU TAKİBİ 📋

> **Hedef Sürüm:** v1.1
> **Bağımlılıklar:** Onboarding'deki uyku saati verisi (✅ mevcut)

- [ ] Uyku saati ve uyanma saati kaydı (mevcut onboarding verisinden başlangıç)
- [ ] Uyku kalitesi puanı (1-5 yıldız)
- [ ] Uyku süresi grafiği (günlük/haftalık trend)
- [ ] Uyku-kilo korelasyon analizi (uyku azaldığında kilo artışı uyarısı)
- [ ] Uyku düzeni hatırlatıcıları ("Uyuma zamanın yaklaşıyor!")
- [ ] Uyku kalitesine göre su hedefi ayarlama (kötü uyku = daha fazla su önerisi)

---

# 💬 v1.2 — SOSYAL & İLETİŞİM

---

## FAZ 21 — İÇ İLETİŞİM SOHBET MODÜLÜ 📋

> **Hedef Sürüm:** v1.2
> **Bağımlılıklar:** Faz 14 (FCM)

### 21.1 — Temel Mesajlaşma
- [ ] Firestore tabanlı gerçek zamanlı sohbet
- [ ] `/chats/{chatId}/messages/{messageId}` koleksiyon yapısı
- [ ] Metin mesajı gönderme/alma
- [ ] Mesaj zaman damgası ve okundu bilgisi
- [ ] Son mesaj önizlemesi (sohbet listesi)
- [ ] Okunmamış mesaj sayacı (badge)

### 21.2 — Zengin Medya Desteği
- [ ] Fotoğraf paylaşımı (kamera/galeri)
- [ ] Ses kaydı gönderme/dinleme
- [ ] Ölçüm/gelişim kartı paylaşımı (otomatik oluşturulan kart)
- [ ] Program paylaşımı (programı mesaj olarak gönderme)

### 21.3 — Toplu Mesajlaşma (Distribütör)
- [ ] Distribütörün tüm danışanlarına toplu mesaj göndermesi
- [ ] Mesaj şablonları (sabah motivasyonu, akşam hatırlatma)
- [ ] Zamanlanmış mesaj gönderimi
- [ ] Mesaj istatistikleri (kaç kişi okudu)

---

## FAZ 22 — GRUP MEYDAN OKUMALARI & TOPLULUK 📋

> **Hedef Sürüm:** v1.2
> **Bağımlılıklar:** Faz 7 (rozet sistemi)

### 22.1 — Meydan Okuma Sistemi
- [ ] Distribütörün meydan okuma oluşturması (başlık, süre, hedef)
- [ ] Meydan okuma türleri: Su, Adım, Kilo, Ölçüm, Rutin Serisi
- [ ] Katılımcı davet sistemi (distribütörün danışanlarından seçim)
- [ ] Otomatik katılım (tüm danışanlar) veya opsiyonel katılım
- [ ] Meydan okuma süresi: 7 gün / 14 gün / 30 gün

### 22.2 — Liderlik Tablosu ve Ödüller
- [ ] Anonim veya isimli liderlik tablosu
- [ ] Canlı sıralama (gerçek zamanlı güncelleme)
- [ ] Haftalık/aylık şampiyon ilanı
- [ ] Özel rozetler (meydan okuma kazananları için)
- [ ] Confetti ve kutlama animasyonları

### 22.3 — Topluluk Duvarı
- [ ] Motivasyon paylaşımı (metin + fotoğraf)
- [ ] Beğeni ve yorum sistemi
- [ ] Başarı hikayesi paylaşımı (izinli)
- [ ] Haftalık "En İyi Dönüşüm" vitrini

---

## FAZ 23 — BİLDİRİM MERKEZİ & UYGULAMA İÇİ BİLDİRİMLER ✅

> **Hedef Sürüm:** v1.2
> **Bağımlılıklar:** Faz 14 (FCM)

- [x] Bildirim merkezi ekranı (tüm bildirimlerin listesi)
- [x] Bildirim türleri: Program, Su, Ölçüm, Rozet, Takip, Sipariş, Mesaj, Meydan Okuma, Motivasyon
- [x] Okundu/okunmadı durumu
- [x] Bildirim filtreleme (türe göre)
- [x] Bildirim tercihleri yönetimi (hangi bildirimler açık/kapalı)
- [x] AppBar'da bildirim sayacı (badge)

---

## FAZ 24 — GELİŞMİŞ DİSTRİBÜTÖR ANALİZ PANELİ 📋

> **Hedef Sürüm:** v1.2
> **Bağımlılıklar:** Faz 15 (Analytics altyapısı)

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

> **Hedef Sürüm:** v1.2
> **Bağımlılıklar:** —
- [ ] Distribütör seviyeleri tanımlama (Member → Senior → Success Builder → Qualified → Supervisor vb.)
- [ ] Mevcut seviye gösterimi (rozet/ikon ile)
- [ ] Bir sonraki seviyeye kalan VP hesaplama
- [ ] Aylık VP ilerleme çubuğu
- [ ] Seviye atlama kutlaması (confetti + bildirim)
- [ ] Takım ağacı görselleştirme (alt distribütörler)
- [ ] Hedef belirleme ("Bu ay Supervisor olmak istiyorum")

---

# 🤖 v2.0 — AI PREMIUM

---

## FAZ 26 — AI VÜCUT DÖNÜŞÜM ÖNİZLEMESİ 📋

> **Hedef Sürüm:** v2.0
> **Bağımlılıklar:** Faz 28 (Firebase Storage)
> **Açık Sorular:**
> - Gemini Vision body morphing için yeterli mi yoksa Stable Diffusion / özel model lazım mı?
> - Maliyet per-image kaç sent? Premium feature olarak nasıl konumlanmalı?
> - Etik: gerçekçi olmayan görüntü oluşturma riski + kullanıcı manipülasyonu

### 26.1 — Mevcut Fotoğraf Analizi
- [ ] Tam boy fotoğraf yükleme ekranı (kılavuz çizgileri ile poz rehberi)
- [ ] Fotoğraf kalite kontrolü (bulanıklık, ışık, poz uygunluğu)
- [ ] Arka plan temizleme / nötr arka plan overlay
- [ ] Vücut oranlarını analiz eden AI ön işleme

### 26.2 — Hedef Kilo Simülasyonu
- [ ] Gemini Vision API veya özel body morphing modeli entegrasyonu
- [ ] Mevcut kilo → hedef kilo arası vücut dönüşüm tahmini
- [ ] Cinsiyet, boy ve vücut tipine göre kişiselleştirilmiş tahmin
- [ ] Yüz tanıma ile yüzü koruyarak sadece vücut dönüşümü

### 26.3 — Aşamalı Dönüşüm Zaman Tüneli
- [ ] Slider ile aşamalı önizleme (ör: 5 kg, 10 kg, 15 kg, 20 kg)
- [ ] Her aşamada tahmini süre gösterimi ("~8 hafta sonra")
- [ ] Animasyonlu geçiş efekti (morphing animasyonu)
- [ ] Mevcut ilerleme ile AI tahmininin yan yana karşılaştırması

### 26.4 — Motivasyon Kartı ve Paylaşım
- [ ] "Önce → Hedef" karşılaştırma kartı oluşturma
- [ ] Marka logolu paylaşılabilir motivasyon görseli
- [ ] Instagram / WhatsApp / sosyal medya paylaşım desteği
- [ ] Distribütörün danışanın dönüşüm kartını görmesi

### 26.5 — Gerçek vs Tahmin Karşılaştırma
- [ ] İlerleme kaydedildikçe gerçek fotoğrafla AI tahminini yan yana gösterme
- [ ] "AI ne kadar doğru tahmin etti?" skoru
- [ ] Her 5 kg'da yeni fotoğraf hatırlatması ve yeniden karşılaştırma

---

## FAZ 27 — AI KOÇ SOHBET BOTU 📋

> **Hedef Sürüm:** v2.0
> **Bağımlılıklar:** Faz 14 (FCM), Faz 17 (besin DB)
> **Açık Sorular:**
> - Gemini API kullanıcı başına aylık ortalama maliyet?
> - Sağlık tavsiyesi yasal sorumluluğu — "doktor değildir" disclaimer + kapsam sınırı
> - Bağlam penceresi yönetimi (uzun konuşmalarda token bütçesi)

### 27.1 — Temel Sohbet Altyapısı
- [ ] Firebase AI Logic / Gemini API entegrasyonu
- [ ] Sohbet ekranı UI (mesaj balonları, yazıyor animasyonu)
- [ ] Sohbet geçmişi Firestore'da saklama
- [ ] Bağlam penceresi yönetimi (kullanıcı profili, ölçümler, program bilgisi)

### 27.2 — Kişiselleştirilmiş Beslenme Önerileri
- [ ] Kullanıcının hedefine, alerjilerine ve tercihlerine göre tarif önerileri
- [ ] "Evdeki malzemelere göre ne pişirebilirim?" sorgulama
- [ ] Herbalife ürünleri ile uyumlu tarif önerileri
- [ ] Günlük menü planı önerisi

### 27.3 — Motivasyon ve Koçluk
- [ ] Günlük motivasyon mesajları (kişiselleştirilmiş, AI üretimi)
- [ ] Seri kırıldığında teşvik mesajı
- [ ] Hedefe yaklaşıldığında kutlama
- [ ] Kilo platosunda motivasyon desteği
- [ ] Sık sorulan sorular (beslenme, egzersiz, ürün kullanımı)

### 27.4 — Distribütör AI Asistanı
- [ ] Danışan analiz özeti oluşturma ("Bu hafta Ali'nin durumu nasıl?")
- [ ] Program önerisi oluşturma (AI destekli program sihirbazı)
- [ ] Toplu danışan raporu (en riskli danışanlar, en başarılı danışanlar)
- [ ] Motivasyon mesajı şablonu üretme (Faz 8.4 ile entegre)

---

## FAZ 28 — FIREBASE STORAGE & FOTOĞRAF BULUT YEDEKLEMESİ 📋

> **Hedef Sürüm:** v2.0
> **Bağımlılıklar:** —
- [ ] Firebase Storage entegrasyonu (paket hazır)
- [ ] Fotoğraf yükleme / indirme / silme servisi
- [ ] Resim sıkıştırma (1080px max, JPEG %80 — `flutter_image_compress`)
- [ ] Thumbnail oluşturma (liste görünümü için küçük boyut)
- [ ] Opsiyonel bulut yedekleme (ücretli/premium model)
- [ ] Distribütörün danışan fotoğraflarını görmesi (izin bazlı)
- [ ] Cihazlar arası senkronizasyon
- [ ] Depolama kotası yönetimi (kullanıcı başına limit)
- [ ] Web platformu tam destek (IndexedDB yerine Storage)

---

# 🤔 DENEYSEL / BELİRSİZ ÖNCELİK

## FAZ 29 — TAKVIM GÖRÜNÜMÜ 🤔

- [ ] Aylık takvim widget'ı (grid görünümü)
- [ ] Her gün için aktivite özet ikonu (yeşil tik / kırmızı çarpı / gri boş)
- [ ] Günlük detay: su, kalori, rutin, ölçüm, fotoğraf bilgisi
- [ ] Seri günleri vurgulama (arka plan rengi ile)
- [ ] Haftalık/aylık özet kartı
- [ ] Distribütör: danışan takvimi görüntüleme

## FAZ 30 — ÇOKLU DİL & TEMA DESTEĞİ 🔄

### 30.1 — Çoklu Dil (i18n)
- [x] Flutter intl/arb dosyaları ile lokalizasyon altyapısı
- [ ] Türkçe (varsayılan) tam destek
- [ ] İngilizce çeviri
- [ ] Almanca çeviri (yurtdışı distribütörler)
- [x] Dil seçimi ayar ekranında
- [x] Tarih/sayı formatı dile göre otomatik ayarlama

### 30.2 — Dark Mode
- [ ] `ThemeData` dark mode tanımı (`AppColors` dark varyantları)
- [ ] Sistem temasına otomatik uyum
- [ ] Manuel tema geçişi (ayarlar ekranında)
- [ ] Tüm ekranlarda dark mode uyumluluk testi
- [ ] Grafiklerde dark mode renk paleti

## FAZ 31 — ANA EKRAN WİDGET'LARI (MOBİL) 🤔

- [ ] Su takibi widget'ı (günlük su / hedef, hızlı +250ml butonu)
- [ ] Günlük özet widget'ı (su, kalori, rutin durumu)
- [ ] Motivasyon kartı widget'ı (günün sözü)
- [ ] Kilo ilerleme widget'ı (mevcut → hedef mini çubuk)
- [ ] Widget'tan uygulamaya deep link
- [ ] Android: `home_widget` paketi · iOS: WidgetKit

## FAZ 32 — QR KOD & GELİŞMİŞ DAVET SİSTEMİ 🤔

- [ ] Davet kodunu QR kod olarak gösterme (`qr_flutter` paketi)
- [ ] Kamera ile QR kod tarama ve otomatik kayıt
- [ ] Dinamik link ile davet (Firebase Dynamic Links — ⚠️ Google bu servisi sonlandırıyor, alternatif gerek)
- [ ] Davet istatistikleri (kaç kişi davet edildi, kaç kişi kaydoldu)
- [ ] Davet ödül sistemi (her X kişi davette özel rozet)
- [ ] Sosyal medya paylaşım kartı (marka logolu, kişisel QR kodlu)

---

## 📊 FAZ ÖZETİ

| Faz | Başlık | Sürüm | Durum | İlerleme |
|----|---|---|---|---|
| 01 | Temel Altyapı | — | ✅ | %100 |
| 02 | Kimlik Doğrulama ve Profil | — | ✅ | %100 |
| 03 | Navigasyon ve Routing | — | ✅ | %100 |
| 04 | Beslenme Programı | — | ✅ | %100 |
| 05 | Günlük Takip Modülleri | — | ✅ | %100 |
| 06 | Gelişim Takibi | — | ⚠️ | %95 |
| 07 | Rozet ve Oyunlaştırma | — | ✅ | %95 |
| 08 | CRM ve Müşteri Yönetimi | — | ⚠️ | %95 |
| 09 | Ürün, Sipariş ve Tarifler | — | ⚠️ | %98 |
| **9.5** | **Distribütör Alış, Stok ve Satış Takibi** | **İlk sürüm tamamlandı; PDF fiyat aktarımı Faz 2** | ✅ | **%90** |
| 10 | Güvenlik Kuralları | — | ✅ | %95 |
| **11** | **Performans Optimizasyonu** | **v1.0** | ✅ | %90 |
| **12** | **Erişilebilirlik** | **v1.0** | ✅ | %95 |
| **13** | **Test Altyapısı** | **v1.0** | 🔄 | %65 |
| **14** | **Push Bildirimleri (FCM)** | **v1.0** | 🔄 | %70 |
| **15** | **Üretim Çıkış Hazırlığı** | **v1.0** | ❌ | %0 |
| **16** | **KVKK Uyumluluğu** | **v1.0** | 🔄 | %40 |
| 17 | Gelişmiş Kalori & Beslenme | v1.1 | ✅ | %90 |
| 18 | AI Yemek & Kalori Tahmini | v1.1 | 🔄 | %90 |
| 19 | Aktivite ve Hareket Takibi | v1.1 | 🔄 | %15 |
| 20 | Uyku Takibi | v1.1 | 📋 | %0 |
| 21 | İç İletişim Sohbet | v1.2 | 📋 | %0 |
| 22 | Grup Meydan Okumaları | v1.2 | 📋 | %0 |
| 23 | Bildirim Merkezi | v1.2 | 📋 | %0 |
| 24 | Distribütör Analiz Paneli | v1.2 | 📋 | %0 |
| 25 | Kariyer Yol Haritası | v1.2 | 📋 | %0 |
| 26 | AI Vücut Dönüşüm Önizlemesi | v2.0 | 📋 | %0 |
| 27 | AI Koç Sohbet Botu | v2.0 | 📋 | %0 |
| 28 | Fotoğraf Bulut Yedekleme | v2.0 | 📋 | %0 |
| 29 | Takvim Görünümü | Deneysel | 🤔 | %0 |
| 30 | Çoklu Dil & Tema | Deneysel | 🔄 | %25 |
| 31 | Ana Ekran Widget'ları | Deneysel | 🤔 | %0 |
| 32 | QR Kod & Gelişmiş Davet | Deneysel | 🤔 | %0 |

---

## 🐛 BİLİNEN HATALAR VE TEKNİK BORÇLAR

| # | Öncelik | Açıklama | Dosya/Konum |
|---|---|---|---|
| 1 | 🟡 Orta | Fotoğraflar yalnızca yerel — cihaz değişince kaybolur | `progress_photos_screen.dart` |
| 3 | 🟡 Orta | **iOS Google Sign-In yapılandırması eksik** — `GoogleService-Info.plist` yok, `Info.plist`'te `CFBundleURLSchemes` (REVERSED_CLIENT_ID) tanımlı değil. iOS'ta Firebase de Google Sign-In de çalışmaz. | `ios/Runner/` |
| 6 | 🟢 Düşük | Test dosyaları eksik (unit/widget/integration) | `test/` dizini |
| 7 | 🟢 Düşük | Recipes — tüm tarifler `formul1_id` ile mock; gerçek `productId` eşleştirmesi yok | `recipe_provider.dart:38` |
| 9 | 🟢 Düşük | Android SHA-1 hash'inin Firebase Console'a kayıtlı olduğu manuel doğrulanmalı (Google Sign-In Android için kritik) | Firebase Console |
| 10 | 🟡 Orta | PII içermeyen `inviteCodeLookups` modeli ve atomik kurallar hazır; emulator 21/21 geçti. Production'daki mevcut kodlar backfill edilip yeni istemci yayınlandıktan sonra rules deploy edilmeli. | `firestore.rules`, `invite_code_repository.dart`, `docs/P8_FIRESTORE_INVITE_CODE_AUDIT.md` |
| 21 | 🟢 Düşük | `AppColors.textMuted*` kısmen eklendi; kalan 100 `Colors.grey` kullanımı semantik renklere taşınmalı (P5) | birçok dosya |

---

## 🔧 PLANLANAN / ÖNERİLEN KALİTE SERİLERİ

| Seri | Kapsam | Öncelik | Durum |
|---|---|---|---|
| **P4 — Centralized logger** | `lib/core/logger.dart` yaz, 220 `debugPrint`'i taşı; release'te sustur, kDebugMode'da bas | 🔴 Yüksek | ✅ Tamam — uygulama kodu `AppLogger`'a taşındı; yalnızca logger iç implementasyonu `debugPrint` kullanıyor |
| **P5 — Design system hardening** | `AppColors.textMuted*` (400/500/700) ekle, 193 `Colors.grey.shade*` → `AppColors.*` | 🔴 Yüksek | 🔄 Kısmi — token'lar eklendi; 100 `Colors.grey` kullanımı kaldı |
| **P6 — `home_screen.dart` böl** | IndexedStack + her sekme ayrı `*_tab.dart`; 123 KB → ~8 × 15 KB | 🔴 Yüksek | ✅ Tamam — 5 müşteri sekmesi ayrı `customer_*_tab.dart`; state koruyan `IndexedStack` aktif |
| **P7 — Auth lifecycle hardening** | (a) AuthProvider dispose, (b) anonim throttle, (c) login email regex, (d) social butonları çöz | 🔴 Yüksek | ✅ Tamam — subscription dispose, regex, kalıcı 1 saat throttle; desteklenmeyen Apple butonu kaldırıldı |
| **P8 — Firestore rules audit** | `inviteCodes` read, `scheduled_follow_ups` create, `orders` create alan doğrulama | 🔴 Yüksek | 🚧 Kod/test tamam — 21/21 emulator geçti; legacy lookup backfill + istemci rollout + production deploy bekliyor |
| **P9 — Cache bounded** | `CACHE_SIZE_UNLIMITED` → 50 MB + cache temizleme UI | 🟡 Orta | 🔄 Kısmi — 50 MB sınırı aktif; cache temizleme UI bekliyor |
| **P10 — Lint hardening** | `analysis_options.yaml`'a `prefer_const_constructors`, `unawaited_futures`, `avoid_dynamic_calls` | 🟡 Orta | 📋 Planlandı |
| **P11 — Gemini retry + rate limit** | Exponential backoff (1s/2s/4s) + UI-side debounce | 🟡 Orta | 🔄 Kısmi — servis retry mevcut; hedef backoff dizisi ve UI debounce bekliyor |
| **P12 — FirestoreService facade sunset** | `@Deprecated('Use XRepository directly')` işaretle, 6 ay sonra sil | 🟡 Orta | 📋 Planlandı |
| **P13 — BMI extension + dedup** | `lib/core/extensions/user_profile_bmi.dart` + `progress_provider.dart` 2 yerdeki duplicate blok tek satıra | 🟢 Düşük | ✅ Kod ve unit test tamam |

---

## 🎯 AÇIK STRATEJİK SORULAR

1. **Monetizasyon modeli:** Distribütöre satılan B2B SaaS aboneliği mi (aylık/yıllık), müşteri tarafında freemium mu, yoksa hibrit mi?
2. **AI maliyet eşiği:** Gemini API'nin kullanıcı başına aylık maliyeti ne kadar olursa premium feature gerekli hale gelir?
3. **Web tarafının önemi:** Distribütör CRM için PWA / desktop optimize UI ne kadar öncelikli? (şu an mobile-first)
4. **Yurt dışı genişleme:** Çoklu dil (Faz 30) ne zaman gerek olur? Hangi pazar (DE öncelikli mi)?
5. **Tarif kaynağı:** Tarifleri kim üretir — distribütör mü, merkezi içerik ekibi mi, kullanıcı katkısı mı?
6. **Beta tester profili:** v1.0 öncesi kaç distribütör + kaç müşteri ile test edilecek?
7. **Firebase App Check:** Üretimde zorunlu olacak. `firebase_app_check` entegrasyonu için zaman planı? (Özellikle Gemini API ve FCM token'ı korumak için. SHA-1 pinning ile sınırlama da bir alternatif.)
8. **Repository pattern konsolidasyonu:** 9 repository + 472 satırlık facade birlikte yaşıyor. Yeni geliştirici için kafa karıştırıcı. Eski facade'ı ne zaman tamamen kaldıracağız? (P12 ile 6 ay sonra sil planlandı)
9. **Test stratejisi (Faz 13):** Unit test için mock mı, fake_cloud_firestore mı, yoksa Cloud Functions'ı bağımsız contract test mi? Karar verilmeden PR başlamamalı.

---

## 💡 FİKİR KUTUSU

### 🤖 Yapay Zeka & Akıllı Özellikler
- [x] Doğal dil ile besin ekleme ("2 yumurta ve 1 dilim ekmek yedim")
- [ ] AI destekli risk tahmini (hangi danışan bırakma riski taşıyor)
- [ ] Sesli komut desteği ("250 ml su ekle", "bugün 72 kiloyum")
- [ ] AI ile uyku-beslenme-egzersiz korelasyon analizi

### 📊 Veri & Analitik
- [ ] Haftalık özet rapor e-postası (otomatik gönderim)
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
- [ ] Avatar sistemi (profil için özelleştirilebilir karakter)
- [ ] Yeni rozet fikirleri: "Su Ustası" (30 gün su hedefi), "Erken Kuş" (7 gün zamanında uyanma), "Makro Dengeci" (ideal makro oranı yakalama)

### 💬 İletişim & Sosyal
- [ ] Distribütör-Danışan video görüşme (WebRTC veya 3. parti entegrasyon)
- [ ] Anket/form sistemi (distribütörün danışanlara soru göndermesi)
- [ ] Başarı paylaşım kartı (sosyal medya için tasarlanmış görsel)
- [ ] Topluluk forumu (soru-cevap, tarif paylaşımı)
- [ ] Danışan değerlendirme sistemi (koçu yıldızla puanlama — anonim)

### 📱 Platform & Entegrasyonlar
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
- [ ] Müşteri takip bildirimleri (takip zamanı geldiğinde push bildirim — FCM altyapısı mevcut)
- [ ] Toplu takip işlemleri (birden fazla takibi seçip toplu silme/tamamlama/erteleme)

### 🌍 Diğer
- [ ] Distribütör arası müşteri transferi (koç değişikliği akışı)
- [ ] Uygulama içi güncelleme kontrolü (in-app update)
- [ ] A/B testing altyapısı (Firebase Remote Config)
- [ ] Referans program (mevcut kullanıcıların yeni kullanıcı getirmesi)
- [ ] Bayram/özel gün teması (Ramazan, yılbaşı — özel UI dekorasyonları)
