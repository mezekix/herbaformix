# HERBAFORMIX — Proje İlerleme Takibi (Progress)

> **Son Güncelleme:** 2026-06-13
> **Mevcut Sürüm:** v1.0.0-beta+1
> **Genel İlerleme:** ~%78 (Beta aşaması)
> **Bir sonraki kilometre taşı:** v1.0 Production (Faz 11–14)

---

## 🎯 Proje Vizyonu

Danışanların kişisel sağlık hedeflerine ulaşırken eğlenceli ve oyunlaştırılmış bir arayüzle rutinlerini takip edebildiği; yaşam koçlarının ise tüm müşteri portföyünü tek bir CRM panelinden yönetebildiği **hepsi bir arada** platform.

---

## 🗺️ SÜRÜM YOL HARİTASI (MILESTONE)

| Sürüm | Tema | İçerdiği Fazlar | Durum |
|---|---|---|---|
| **v1.0** | Production Hazırlık | 11 (perf) · 12 (a11y) · 13 (test) · 14 (FCM) · 15 (release engineering) · 16 (KVKK) | 🔄 Aktif odak |
| **v1.1** | Beslenme Derinleşmesi | 17 (kalori detay) · 18 (AI yemek tanıma) · 19 (aktivite/hareket) · 20 (uyku) | 📋 Planlandı |
| **v1.2** | Sosyal & İletişim | 21 (sohbet) · 22 (meydan okuma) · 23 (bildirim merkezi) · 24 (analiz paneli) · 25 (kariyer) | 📋 Planlandı |
| **v2.0** | AI Premium | 26 (AI vücut dönüşümü) · 27 (AI koç sohbet) · 28 (fotoğraf bulut yedek) | 📋 Vizyon |
| **Deneysel** | Belirsiz öncelik | 29 (takvim) · 30 (çoklu dil/tema) · 31 (ana ekran widget) · 32 (QR davet) | 🤔 Karar bekliyor |

> Her fazın başında **Hedef Sürüm**, **Bağımlılıklar** ve (uygulanabilirse) **Açık Sorular** bloğu vardır.

---

## ✅ TAMAMLANAN BÜYÜK ÇALIŞMA SERİLERİ

Faz takibi dışında, kod kalitesi için yürütülen seriler:

| Seri | Commit | Açıklama |
|---|---|---|
| **P0 — Güvenlik** | `ba75891` | Firestore kuralları sıkılaştırma, API anahtarları `.env`'e taşıma |
| **P1.6–P1.9 — Model temizliği** | `c0e00af`, `2a601c7`, `1f8db5c`, `74efc76`, `5876948` | `UserProfileModel` immutable + `copyWith`, deprecated alan kaldırma, snake_case → camelCase normalize, `Daily_Routines` → `dailyRoutines` |
| **P2.10 — Repository pattern** | `062bd2b` | `firestore_service.dart` (~37 KB) **9 repository'ye bölündü** (facade pattern): `user_profile`, `product`, `customer`, `order`, `progress`, `water`, `invite_code`, `motivation` + `customer_insights_service` |
| **P2.13 — Provider sadeleştirme** | `bf863c8` | `ProgressProvider` 14 getter → 2 parametrik metod |

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

### 5.3 — Günlük Egzersiz Takibi ⚠️ (Kısmi)
- [x] `/users/{userId}/daily_exercise/{exerciseId}` koleksiyon güvenlik kuralı (`firestore.rules:142`)
- [ ] Egzersiz girişi UI ekranı
- [ ] Egzersiz türü kataloğu (yürüyüş, koşu, ağırlık vb.)
- [ ] Egzersiz geçmişi ve istatistik görünümü

> Tam aktivite/hareket takibi (adım sayar, HealthKit/Google Fit) **Faz 19** altında.

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

> `firebase_storage: ^13.4.2` paketi pubspec'te zaten var; bulut yedekleme planı **Faz 28** altında.

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
- [ ] Confetti animasyonu rozet kazanıldığında (`confetti` paketi pubspec'te hazır)

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
- [ ] Zamanlanmış takip hatırlatma bildirimleri (Faz 14 FCM ile birlikte)

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

## FAZ 9 — ÜRÜN KATALOĞU, SİPARİŞ VE TARİFLER 🔄 (Kısmen Tamamlandı)

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

### 9.4 — Tarifler (Recipes) Modülü 🔄
- [x] `RecipeModel` — tarif veri modeli (malzemeler, besin değerleri)
- [x] `RecipeIngredient` ve `RecipeNutrition` alt modelleri
- [x] `RecipeProvider` — JSON tabanlı (`assets/recipes.json`) tarif yükleme
- [x] `RecipesListScreen` — tarif listesi
- [x] `RecipeCard` ve `RecipeDetailSheet` widget'ları
- [x] Ürün detayında ilgili tariflerin listelenmesi
- [ ] Tariflerin Firestore'a taşınması (distribütör özel tarif ekleyebilsin)
- [ ] `productId` bazlı gerçek eşleştirme (şu an tümü `formul1_id` ile mock)
- [ ] Tarif arama ve filtreleme
- [ ] Tarif favorileme (müşteri tarafı)

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
- [ ] `scheduled_follow_ups` ve `careerRoadmap` kurallarının audit'i (zayıf olabilir)
- [ ] Kuralların test edilmesi (Firebase Emulator + `@firebase/rules-unit-testing`)

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
- [ ] Lazy loading ve sayfalama (büyük listeler için: müşteri listesi, ölçüm geçmişi)
- [ ] Soğuk başlatma süresi ölçümü ve hedefe çekme (< 2 sn)

---

## FAZ 12 — ERİŞİLEBİLİRLİK (a11y) 🔄 (Devam Ediyor)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** —
> **İlerleme:** %65

- [x] **Tüm `IconButton`'lara `tooltip` eklendi** — 22 farklı IconButton'a tooltip eklendi; projedeki 64 IconButton'un tamamı artık ekran okuyucu için anlamlı bir etiket sunuyor. Tooltip Flutter'da hem üzerinde uzun basıldığında popup gösterir hem de TalkBack/VoiceOver tarafından okunur (Semantics label görevi görür).
- [x] **Grafik barları için erişilebilir açıklamalar eklendi** — `WeightChartWidget` ve `CalorieHistoryScreen` bar chart'ı `Semantics` ile sarıldı; özet metin (ölçüm sayısı, ilk/son değer, toplam değişim, hedef / ortalama kalori, hedef üstü gün sayısı) ekran okuyucu için üretiliyor. WeightChart'taki 1H/1A/3A zaman aralığı tab'leri `Semantics(button: true, selected: ...)` ile bildiriliyor.
- [x] **Onboarding form alanları Semantics ile etiketlendi** — Onboarding'in `_buildTextField` helper'ı ve kilo/boy/hedef özel sayı girişi `Semantics(label: ..., textField: true)` ile sarıldı. Diğer ekranlarda zaten `InputDecoration.labelText/hintText` mevcut (25 dosyada 77 alan, 96 etiket; sadece onboarding'de boşluk vardı).
- [x] **Mango sarısı (#EFAC29) ve düşük kontrast noktaları düzeltildi** — `AppColors.mangoDeep` (#8A5A00, ~5.9:1 AA) eklendi ve metin/ikon kullanımlarına uygulandı; mango'nun arka plan olarak kullanıldığı yerlerde (FAB tema, cart Badge'i) ön plan beyazdan `nightSky`'a çevrildi; aqua zemin + beyaz su damlası ikonu da koyu renge (`bay`) çevrildi. **7 noktada WCAG AA uyumu sağlandı.**
- [ ] Kontrast oranı doğrulaması (WCAG AA — 4.5:1) — kalan ekranlar için sistematik tarama
- [ ] Büyük yazı tipi desteği — `MediaQuery.textScaler` test edilmedi, taşma noktaları taranmalı
- [ ] Ekran okuyucu ile uçtan uca test (TalkBack/VoiceOver)

---

## FAZ 13 — TEST ALTYAPISI ❌ (Başlanmadı)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** Repository refactor (✅ tamamlandı) — artık mock'lanabilir
> **İlerleme:** %0

- [ ] Test stratejisi belirleme (Glados zaten dev_dependency'de)
- [ ] **Firestore Emulator + `firebase_rules_test`** ile güvenlik kuralı testleri
- [ ] Model testleri
  - [ ] `UserProfileModel`, `ProgressEntryModel`, `InviteCodeModel`, `ProgramModel`, `OrderModel`, `RecipeModel`
- [ ] Provider testleri (repository mock'larıyla)
  - [ ] `AuthProvider`, `WaterProvider`, `ProgressProvider`, `ProgramProvider`, `CustomerProvider`
- [ ] Repository testleri (fake Firestore ile)
  - [ ] `UserProfileRepository`, `WaterRepository`, `ProgressRepository`, `MotivationRepository`
- [ ] Servis testleri
  - [ ] `WaterCalculationEngine` (saf fonksiyon — kolay), `CustomerInsightsService`, `NotificationService`
- [ ] Widget testleri
  - [ ] `WeightChartWidget`, `AddMeasurementSheet`, `DailySuccessRing`
- [ ] Integration testleri
  - [ ] Onboarding akışı, Program oluşturma, Su ekleme, Ölçüm girişi
- [ ] CI pipeline (GitHub Actions ile otomatik test koşturma)

---

## FAZ 14 — PUSH BİLDİRİMLERİ (FCM) ❌ (Başlanmadı)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** —
> **İlerleme:** %0

- [ ] FCM paketi ekleme ve yapılandırma (`firebase_messaging`)
- [ ] FCM token alma ve `UserProfileModel.fcmToken`'a kaydetme
- [ ] Token yenileme mekanizması
- [ ] Distribütör → Danışan push bildirimi:
  - [ ] Yeni program hazırlandığında
  - [ ] Takip hatırlatması oluşturulduğunda
  - [ ] Motivasyon mesajı gönderildiğinde
- [ ] Cloud Functions veya backend altyapısı (bildirim gönderimi için)
- [ ] Bildirim tercihleri (`notificationSettings` alanı modelde hazır)
- [ ] Foreground / background bildirim handler'ları
- [ ] Bildirime tıklayınca deep-link ile ilgili ekrana yönlendirme

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

## FAZ 16 — KVKK / GDPR UYUMLULUĞU ❌ (Başlanmadı)

> **Hedef Sürüm:** v1.0
> **Bağımlılıklar:** —
> **İlerleme:** %0

- [ ] Gizlilik politikası metni hazırlama
- [ ] Kullanım şartları metni
- [ ] Onboarding'de açık rıza ekranı (kişisel veri işleme onayı)
- [ ] **Veri dışa aktarma** — kullanıcı kendi verisini JSON olarak indirebilir
- [ ] **Hesap silme akışı** — KVKK zorunluluğu (Apple App Review da artık zorunlu kılıyor)
- [ ] Veri saklama süresi politikası (örn. silinen hesap → 30 gün sonra hard delete)
- [ ] **Audit log** — distribütör müşteri profilinde ne değiştirdi? (B2B güvenilirlik)
- [ ] Çocuk kullanıcı koruma (18 yaş altı için yaş kapısı)
- [ ] Çerez / SDK izinleri (Web tarafı için)

---

# 🥗 v1.1 — BESLENME DERİNLEŞMESİ

---

## FAZ 17 — GELİŞMİŞ KALORİ & BESLENME TAKİBİ 📋

> **Hedef Sürüm:** v1.1
> **Bağımlılıklar:** Faz 5.2 (mevcut kalori UI)
> **Açık Sorular:** Besin DB için FatSecret API (ücretli) mi, OpenFoodFacts (ücretsiz Türkçe kalitesi sınırlı) mı?

### 17.1 — Kalori Firestore Entegrasyonu
- [ ] `CalorieProvider` Firestore senkronizasyonu
- [ ] `/users/{userId}/calorieLogs/{YYYY-MM-DD}` koleksiyonu (camelCase konvansiyonu)
- [ ] Kalori geçmişi kalıcı saklama (cihaz bağımsız)
- [ ] Günlük / haftalık / aylık kalori grafikleri (`fl_chart`)

### 17.2 — Makro Besin Takibi
- [ ] Protein / Karbonhidrat / Yağ ayrı ayrı takip
- [ ] Makro dağılım pasta grafiği (günlük / haftalık)
- [ ] Hedef makro oranları belirleme (distribütör veya kullanıcı tarafından)
- [ ] Makro bazlı renk uyarıları (eksik protein, fazla karbonhidrat vb.)

### 17.3 — Besin Veritabanı Entegrasyonu
- [ ] Türkçe besin veritabanı (FatSecret API veya özel Firestore koleksiyonu)
- [ ] Besin arama ve otomatik kalori/makro doldurma
- [ ] Sık tüketilen yiyecekler listesi (favoriler)
- [ ] Son eklenen besinler (hızlı tekrar)
- [ ] Porsiyon boyutu seçimi (küçük / orta / büyük / gram)

### 17.4 — Öğün Bazlı Kayıt Sistemi
- [ ] Kahvaltı / Öğle / Akşam / Ara Öğün kategorileri
- [ ] Her öğün için ayrı kalori ve makro özeti
- [ ] Öğün bazlı zamanlama (programdaki öğün saatleriyle entegre)
- [ ] "Boş öğün" uyarısı — kaçırılan öğünlerde hatırlatma

### 17.5 — Barkod Okuyucu ile Besin Ekleme
- [ ] `mobile_scanner` paketi entegrasyonu
- [ ] Paketli ürünlerin barkodunu tarayarak kalori/makro otomatik çekme
- [ ] OpenFoodFacts API entegrasyonu (açık kaynak besin veritabanı)
- [ ] Taranan ürünleri favorilere ekleme

---

## FAZ 18 — AI YEMEK FOTOĞRAFI TANIMA 📋

> **Hedef Sürüm:** v1.1
> **Bağımlılıklar:** Faz 17 (besin DB)
> **Açık Sorular:** Gemini Vision maliyeti per-image? Türk mutfağı tanıma kalitesi?

- [ ] Kamera ile yemek fotoğrafı çekme
- [ ] Gemini Vision API ile yemek tanıma
- [ ] Otomatik kalori ve makro tahmini
- [ ] Tanınan yemeğin onay/düzeltme ekranı
- [ ] Porsiyon büyüklüğü tahmini (görsel analiz)
- [ ] Birden fazla yemek içeren tabakta ayrı ayrı tanıma
- [ ] Tanıma geçmişi ve doğruluk istatistikleri
- [ ] Türk mutfağı için prompt engineering

---

## FAZ 19 — AKTİVİTE VE HAREKET TAKİBİ 📋

> **Hedef Sürüm:** v1.1
> **Bağımlılıklar:** Faz 5.3 (günlük egzersiz altyapısı)

### 19.1 — Adım Sayacı
- [ ] Telefon sensörleri ile adım sayma (`pedometer` paketi)
- [ ] Günlük adım hedefi belirleme
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

> Egzersiz seviyesi `WaterCalculationEngine`'i besler — entegrasyon noktası mevcut.

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

> Distribütör → müşteri **motivasyon mesajı** (günlük, asenkron) için Faz 8.4'e bakın — sohbet farklı bir kanaldır.

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

## FAZ 23 — BİLDİRİM MERKEZİ & UYGULAMA İÇİ BİLDİRİMLER 📋

> **Hedef Sürüm:** v1.2
> **Bağımlılıklar:** Faz 14 (FCM)

- [ ] Bildirim merkezi ekranı (tüm bildirimlerin listesi)
- [ ] Bildirim türleri: Program, Su, Ölçüm, Rozet, Takip, Sipariş, Mesaj, Meydan Okuma, Motivasyon
- [ ] Okundu/okunmadı durumu
- [ ] Bildirim filtreleme (türe göre)
- [ ] Bildirim tercihleri yönetimi (hangi bildirimler açık/kapalı)
- [ ] AppBar'da bildirim sayacı (badge)

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
> **Not:** `careerRoadmap` koleksiyonu Firestore'da zaten mevcut.

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
> **Not:** `firebase_storage: ^13.4.2` pubspec'te zaten var; integrasyon kalmış.

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

> Bu fazlar uzun vadeli vizyon — bir milestone'a bağlanmadan önce karar bekliyor.

## FAZ 29 — TAKVIM GÖRÜNÜMÜ 🤔

- [ ] Aylık takvim widget'ı (grid görünümü)
- [ ] Her gün için aktivite özet ikonu (yeşil tik / kırmızı çarpı / gri boş)
- [ ] Günlük detay: su, kalori, rutin, ölçüm, fotoğraf bilgisi
- [ ] Seri günleri vurgulama (arka plan rengi ile)
- [ ] Haftalık/aylık özet kartı
- [ ] Distribütör: danışan takvimi görüntüleme

## FAZ 30 — ÇOKLU DİL & TEMA DESTEĞİ 🤔

### 30.1 — Çoklu Dil (i18n)
- [ ] Flutter intl/arb dosyaları ile lokalizasyon altyapısı
- [ ] Türkçe (varsayılan) tam destek
- [ ] İngilizce çeviri
- [ ] Almanca çeviri (yurtdışı distribütörler)
- [ ] Dil seçimi ayar ekranında
- [ ] Tarih/sayı formatı dile göre otomatik ayarlama

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
| 05 | Günlük Takip Modülleri | — | ✅ | %90 |
| 06 | Gelişim Takibi | — | ⚠️ | %85 |
| 07 | Rozet ve Oyunlaştırma | — | ✅ | %90 |
| 08 | CRM ve Müşteri Yönetimi | — | ⚠️ | %88 |
| 09 | Ürün, Sipariş ve Tarifler | — | ⚠️ | %85 |
| 10 | Güvenlik Kuralları | — | ✅ | %90 |
| **11** | **Performans Optimizasyonu** | **v1.0** | 🔄 | %35 |
| **12** | **Erişilebilirlik** | **v1.0** | 🔄 | %65 |
| **13** | **Test Altyapısı** | **v1.0** | ❌ | %0 |
| **14** | **Push Bildirimleri (FCM)** | **v1.0** | ❌ | %0 |
| **15** | **Üretim Çıkış Hazırlığı** | **v1.0** | ❌ | %0 |
| **16** | **KVKK Uyumluluğu** | **v1.0** | ❌ | %0 |
| 17 | Gelişmiş Kalori & Beslenme | v1.1 | 📋 | %0 |
| 18 | AI Yemek Fotoğrafı Tanıma | v1.1 | 📋 | %0 |
| 19 | Aktivite ve Hareket Takibi | v1.1 | 📋 | %0 |
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
| 30 | Çoklu Dil & Tema | Deneysel | 🤔 | %0 |
| 31 | Ana Ekran Widget'ları | Deneysel | 🤔 | %0 |
| 32 | QR Kod & Gelişmiş Davet | Deneysel | 🤔 | %0 |

---

## 🐛 BİLİNEN HATALAR VE TEKNİK BORÇLAR

| # | Öncelik | Açıklama | Dosya/Konum |
|---|---|---|---|
| 1 | 🟡 Orta | Fotoğraflar yalnızca yerel — cihaz değişince kaybolur | `progress_photos_screen.dart` |
| 2 | 🟡 Orta | `scheduled_follow_ups` ve `careerRoadmap` güvenlik kuralları audit edilmedi | `firestore.rules:157-174` |
| 3 | 🟡 Orta | **iOS Google Sign-In yapılandırması eksik** — `GoogleService-Info.plist` yok, `Info.plist`'te `CFBundleURLSchemes` (REVERSED_CLIENT_ID) tanımlı değil. iOS'ta Firebase de Google Sign-In de çalışmaz. | `ios/Runner/` |
| 4 | 🟡 Orta | **Login Screen — Apple ve Face/Biometric sosyal butonları işlevsiz** — `onTap` parametresi geçilmemiş, tıklanınca hiçbir şey olmuyor; kullanıcıyı yanıltıyor. Ya implemente edilmeli ya gizlenmeli. | `login_screen.dart:407-421` |
| ~~5~~ | ✅ Kapandı | ~~Mango sarısı üzerinde beyaz yazı kontrast sorunu~~ → `AppColors.mangoDeep` eklendi + 7 noktada düzeltildi | `app_colors.dart` |
| 6 | 🟢 Düşük | Test dosyaları eksik (unit/widget/integration) | `test/` dizini |
| 7 | 🟢 Düşük | Recipes — tüm tarifler `formul1_id` ile mock; gerçek `productId` eşleştirmesi yok | `recipe_provider.dart:38` |
| 8 | 🟢 Düşük | Confetti animasyonu rozet kazanılırken devreye girmiyor (paket hazır) | `progress_provider.dart` |
| 9 | 🟢 Düşük | Android SHA-1 hash'inin Firebase Console'a kayıtlı olduğu manuel doğrulanmalı (Google Sign-In Android için kritik) | Firebase Console |

> **Kapanan eski bug'lar:** ~~products koleksiyonu açık~~ (P0 ile düzeltildi), ~~firestore_service.dart 37 KB~~ (P2.10 ile 9 repository'ye bölündü), ~~Google Sign-In uçtan uca test edilmedi~~ (Faz 2.1 ile kapatıldı), ~~CalorieProvider Firestore kaydı yok~~ (Faz 5.2 ile kapatıldı — `/users/{uid}/calorieLogs/` koleksiyonu + auth-aware ProxyProvider), ~~Mango üzeri beyaz yazı kontrast sorunu~~ (Faz 12 ile `mangoDeep` eklenerek kapatıldı).

---

## 🎯 AÇIK STRATEJİK SORULAR

> Yol haritası kararlarını etkileyecek, henüz cevaplanmamış sorular:

1. **Monetizasyon modeli:** Distribütöre satılan B2B SaaS aboneliği mi (aylık/yıllık), müşteri tarafında freemium mu, yoksa hibrit mi?
2. **AI maliyet eşiği:** Gemini API'nin kullanıcı başına aylık maliyeti ne kadar olursa premium feature gerekli hale gelir?
3. **Web tarafının önemi:** Distribütör CRM için PWA / desktop optimize UI ne kadar öncelikli? (şu an mobile-first)
4. **Yurt dışı genişleme:** Çoklu dil (Faz 30) ne zaman gerek olur? Hangi pazar (DE öncelikli mi)?
5. **Tarif kaynağı:** Tarifleri kim üretir — distribütör mü, merkezi içerik ekibi mi, kullanıcı katkısı mı?
6. **Beta tester profili:** v1.0 öncesi kaç distribütör + kaç müşteri ile test edilecek?

---

## 💡 FİKİR KUTUSU

> Henüz faz olmaya aday olmayan fikirler. Faz tablosunda zaten bulunan maddeler buradan çıkarıldı.

### 🤖 Yapay Zeka & Akıllı Özellikler
- [ ] Doğal dil ile besin ekleme ("2 yumurta ve 1 dilim ekmek yedim")
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

### 🌍 Diğer
- [ ] Distribütör arası müşteri transferi (koç değişikliği akışı)
- [ ] Uygulama içi güncelleme kontrolü (in-app update)
- [ ] A/B testing altyapısı (Firebase Remote Config)
- [ ] Referans program (mevcut kullanıcıların yeni kullanıcı getirmesi)
- [ ] Bayram/özel gün teması (Ramazan, yılbaşı — özel UI dekorasyonları)
