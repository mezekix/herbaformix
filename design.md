# HerbaFormix — Tasarım ve Mimari Belgesi

> **Sürüm:** 1.0.0-beta+1  
> **Güncelleme:** Haziran 2026  
> **Platform:** Flutter (Android / iOS)  
> **Backend:** Firebase (Firestore, Auth, FCM, Storage)  
> **SDK:** Dart ^3.8.0

---

## 1. Uygulama Genel Bakış

HerbaFormix, **distribütör** ve **müşteri** olmak üzere iki farklı kullanıcı rolüne sahip, sağlık ve beslenme odaklı bir mobil uygulamadır. Distribütörler müşterilerini takip eder, satışlarını yönetir ve kişisel gelişim programları oluşturur. Müşteriler ise kendi sağlık yolculuklarını takip eder, su ve kalori sayacı kullanır, distribütörleriyle iletişim kurar.

### Kullanıcı Rolleri

| Rol | Enum Değeri | Açıklama |
|---|---|---|
| Distribütör | `UserRole.distributor` | Ürün satışı, müşteri takibi, program oluşturma, VP takibi |
| Müşteri | `UserRole.customer` | Kişisel sağlık takibi, su/kalori, program takibi, distribütörle iletişim |

---

## 2. Renk Sistemi (AppColors)

Uygulama renkleri `lib/core/app_colors.dart` dosyasında merkezi olarak tanımlanmıştır. **Yeni bileşen oluştururken bu renkleri kullanın, hardcoded renk kullanmayın.**

### Temel Palet

| Sabit | Hex | Kullanım |
|---|---|---|
| `primary` | `#7AC144` | Ana eylem rengi — butonlar, AppBar, aktif öğeler |
| `secondary` / `grass` | `#42A146` | İkincil vurgu |
| `accent` / `mango` | `#fe9836` | FAB, rozet arka planı, progress bar |
| `background` | `#F5F5F5` | Scaffold zemin |
| `surface` / `white` | `#FFFFFF` | Kart ve input arka planı |
| `error` / `papaya` | `#D24A39` | Hata durumları |
| `nightSky` | `#101820` | Ana metin rengi (`textPrimary`) |
| `textSecondary` | `#575757` | İkincil metin |
| `textOnPrimary` / `white` | `#FFFFFF` | Primary üzerindeki metin |

### Yardımcı Renkler

| Sabit | Hex | Not |
|---|---|---|
| `garden` | `#266431` | Koyu yeşil vurgu |
| `rosemary` | `#3A5137` | Çok koyu yeşil |
| `aqua` | `#78E3D7` | Açık mavi/yeşil aksan |
| `mangoDeep` | `#8A5A00` | Mango'nun erişilebilir WCAG AA varyantı |
| `blueberry` | `#4A28A9` | Mor vurgu |
| `bay` | `#224945` | Çok koyu yeşil/mavi |
| `laguna` | `#1db8e4` | Mavi |
| `lake` | `#3B9187` | Turkuaz yeşil |
| `sunflower` | `#FFF176` | Açık sarı |
| `rain` | `#DDFFFF` | Çok açık mavi |

### Erişilebilirlik Kuralları
- `mango` (#EFAC29) **yalnızca dolgu/arka plan** olarak kullanılır; üzerinde yazı/ikon gerekiyorsa `nightSky` tercih edilir.
- `mangoDeep` (#8A5A00), açık zemin üzerinde metin/ikon rengi olarak WCAG AA (≥4.5:1) kontrast oranını karşılar.
- FAB'da: `backgroundColor: mango`, `foregroundColor: nightSky` (10.8:1 kontrast).

### Splash Ekranı Renkleri
| Sabit | Hex | Kullanım |
|---|---|---|
| Arka Plan | `#E6FFC5` | Fıstık yeşili gradient |
| Metin/İkon | `#1B4D26` | Koyu yeşil (slogan ve logo fallback) |

---

## 3. Tema Yapısı (ThemeData)

`lib/app.dart` içinde `MaterialApp.router` üzerinde tek bir `ThemeData` tanımlıdır.

### AppBar
- `backgroundColor: AppColors.primary` (#7AC144)
- `foregroundColor: AppColors.textOnPrimary` (beyaz)
- `elevation: 2.0`
- `titleTextStyle: fontSize:20, fontWeight:bold`

### Butonlar
- **ElevatedButton:** primary arka plan, beyaz yazı, 10px radius, 24×14 padding, w600
- **TextButton:** primary yazı rengi, fontSize:15, w600
- **OutlinedButton:** primary kenar (1.5px), 10px radius, 24×14 padding

### Input Alanları (InputDecoration)
- `filled: true`, `fillColor: beyaz`
- Varsayılan kenarlık yok, 10px radius
- `enabledBorder: grey.shade300`
- `focusedBorder: primary, 2px`
- `prefixIconColor: primary (alpha 179)`
- `floatingLabelStyle: primary`

### FAB
- `backgroundColor: AppColors.accent` (mango)
- `foregroundColor: AppColors.nightSky`

### Genel
- `scaffoldBackgroundColor: AppColors.background` (#F5F5F5)
- `visualDensity: VisualDensity.adaptivePlatformDensity`
- `progressIndicatorColor: AppColors.primary`

---

## 4. Mimari Yapı

### 4.1 Klasör Organizasyonu

```
lib/
├── main.dart                    # Giriş noktası — Firebase init + runApp
├── app.dart                     # MaterialApp.router + Provider'lar + ThemeData
├── firebase_options.dart        # Firebase platform konfigürasyonu
│
├── core/
│   ├── app_colors.dart          # Merkezi renk tanımları
│   ├── avatar_color_helper.dart # UID hash → deterministik avatar rengi
│   ├── locale_provider.dart     # Dil yönetimi (TR/EN)
│   ├── router.dart              # GoRouter + redirect mantığı
│   └── utils/                   # whatsapp_helper, calorie_calculation_engine vb.
│
├── features/                    # Özellik bazlı modüller
│   ├── auth/                    # Giriş, Splash, Onboarding
│   │   ├── providers/auth_provider.dart
│   │   └── screens/ (splash, login, customer_onboarding)
│   ├── home/                    # Ana ekran + rol bazlı dashboard
│   │   ├── providers/home_provider.dart
│   │   ├── screens/ (home, customer_progress, customer_products, customer_support, distributor_product_usage)
│   │   └── widgets/ (vp_pulse_card, daily_success_ring, motivation_widget, today_actions_strip, customer_pipeline_bar, recent_activity_feed, critical_actions_states)
│   ├── customers/               # Müşteri CRUD
│   ├── orders/                  # Sipariş + Sepet
│   ├── products/                # Ürün kataloğu + Tarifler
│   ├── program/                 # Sağlık programları + Şablonlar
│   ├── progress/                # Ölçüm + Fotoğraf takibi
│   ├── profile/                 # Profil yönetimi
│   ├── calorie_tracker/         # Kalori sayacı + AI besin tahmini
│   └── water_tracker/           # Su takibi
│
├── models/                      # Immutable veri modelleri (17 dosya)
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper
│   ├── fcm_service.dart         # Push bildirimleri (singleton)
│   ├── firestore_service.dart   # Facade — tüm repo'ları sarmalar
│   ├── routine_service.dart     # Günlük rutin yönetimi
│   ├── exercise_service.dart    # Egzersiz takibi (real-time stream)
│   ├── weather_service.dart     # Hava durumu (motivasyon widget için)
│   ├── ai/food_estimation_service.dart  # Gemini AI besin tahmini
│   └── repositories/           # 12 odaklı repository sınıfı
│
├── widgets/                     # Paylaşılan widget'lar
│   ├── app_drawer.dart          # Rol bazlı yan menü
│   └── cached_product_image.dart
│
├── utils/                       # Genel yardımcılar
└── l10n/                        # Lokalizasyon (TR + EN ARB dosyaları)
```

### 4.2 State Management — Provider

Provider'lar iki katmanda tanımlıdır:

**Katman 1 — `main.dart` / `MyAppInitializer` (global, uygulama ömrü boyunca):**
| Provider | Tip | Açıklama |
|---|---|---|
| `AuthService` | `Provider` | Firebase Auth wrapper |
| `FirestoreService` | `Provider` | Firestore facade |
| `RoutineService` | `Provider` | Günlük rutin |
| `AuthProvider` | `ChangeNotifierProvider` | Auth durumu + profil |
| `LocaleProvider` | `ChangeNotifierProvider` | Dil tercihi |

**Katman 2 — `app.dart` / `MaterialApp.builder` (auth sonrası):**
| Provider | Tip | Auth Bağımlı |
|---|---|---|
| `ProductProvider` | `ChangeNotifierProvider` | Hayır |
| `RecipeProvider` | `ChangeNotifierProvider` | Hayır |
| `CustomerProvider` | `ChangeNotifierProvider` | Hayır (ama AuthProvider kullanır) |
| `OrderProvider` | `ChangeNotifierProvider` | Hayır |
| `CartProvider` | `ChangeNotifierProvider` | Hayır |
| `HomeProvider` | `ChangeNotifierProvider` | Hayır |
| `WaterProvider` | `ChangeNotifierProxyProvider` | ✅ — auth'a bağlı stream |
| `ExerciseService` | `ChangeNotifierProxyProvider` | ✅ — auth'a bağlı stream |
| `CalorieProvider` | `ChangeNotifierProxyProvider` | ✅ — auth'a bağlı stream |
| `ProgramProvider` | `ChangeNotifierProvider` | Hayır |
| `ProgramTemplateProvider` | `ChangeNotifierProvider` | Hayır |
| `ProgressProvider` | `ChangeNotifierProvider` | Hayır |

### 4.3 Routing — GoRouter

`lib/core/router.dart` — Başlangıç: `/splash`

**Temel Rotalar:**
```
/splash                              → SplashScreen
/login                               → LoginScreen
/home                                → HomeScreen
/home/customer-onboarding            → CustomerOnboardingScreen
/home/create-program                 → CreateProgramScreen
/home/program-templates              → ProgramTemplatesScreen
/home/program-templates/edit         → EditProgramTemplateScreen
/home/profile                        → ProfileScreen
/home/profile/personal-info          → PersonalInfoScreen
/home/profile/health-goals           → HealthGoalsScreen
/home/profile/app-settings           → AppSettingsScreen
/home/profile/support                → SupportScreen
/home/water-tracker                  → WaterTrackerScreen
/home/calorie-tracker                → CalorieTrackerScreen
/home/calorie-tracker/history        → CalorieHistoryScreen
/home/progress-dashboard             → ProgressDashboardScreen
/home/progress-photos                → ProgressPhotosScreen
/home/measurements-history           → MeasurementsHistoryScreen
/home/products                       → ProductListScreen
/home/products/add-product           → AddEditProductScreen
/home/products/product-detail/:id    → ProductDetailScreen
/home/customers                      → CustomerListScreen
/home/customers/add-edit-customer    → AddEditCustomerScreen
/home/customers/customer-detail      → CustomerDetailScreen
/home/cart                           → CartScreen
/home/orders                         → OrderListScreen
/home/orders/add-edit-order          → AddEditOrderScreen
```

**Redirect Mantığı:**
1. `/splash` → Splash kendi yönlendirmesini yapar (dokunulmaz)
2. `authenticated` + `/login` → `/home`
3. `authenticated` + müşteri + `isOnboarded == false` → `/home/customer-onboarding`
4. `authenticated` + müşteri + `isOnboarded == true` + onboarding'e gidiyor → `/home`
5. `unauthenticated` + herhangi bir sayfa (splash hariç) → `/login`

---

## 5. Veri Modelleri

Tüm modeller **immutable** (`final` alanlar + `copyWith` metodu). `_unset` sentinel pattern ile "null yap" ve "değiştirme" senaryoları ayırt edilir.

### 5.1 UserProfileModel (Ana Model)

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | `String` | Firebase Auth UID |
| `email` | `String` | E-posta |
| `role` | `UserRole` | `distributor` \| `customer` |
| `name` | `String?` | Ad Soyad |
| `distributorLevel` | `String?` | Supervisor, President's Team vb. |
| `monthlyVPTarget` | `int?` | Aylık VP hedefi |
| `isOnboarded` | `bool` | Onboarding tamamlandı mı (varsayılan: false) |
| `age` | `int?` | Yaş |
| `phoneNumber` | `String?` | Telefon |
| `weight / height / targetWeight` | `double?` | Fiziksel ölçüler (kg/cm) |
| `programStartDate` | `DateTime?` | Program başlangıç tarihi |
| `userGoal` | `String?` | `weight_loss` \| `healthy_living` \| `weight_gain` \| `skin_care` |
| `wakeTime / lunchTime / sleepTime` | `String?` | Günlük rutin saatleri ("07:30" formatı) |
| `birthDate` | `DateTime?` | Doğum tarihi |
| `gender` | `String?` | `Kadın` \| `Erkek` \| `Belirtmek İstemiyorum` |
| `healthNotes / allergies / medications` | `String?` | Sağlık notları (max 1000 karakter) |
| `assignedDistributorId` | `String?` | Bağlı distribütör UID |
| `profilePhotoUrl` | `String?` | Profil fotoğrafı (yerel path) |
| `profilePhotoUpdatedAt` | `DateTime?` | Son fotoğraf güncelleme |
| `earnedBadges` | `List<String>` | Kazanılan rozet ID'leri |
| `waterDailyGoal / waterMinLimit / waterMaxLimit` | `int?` | Su hedefleri (ml) |
| `distributorRequestStatus` | `String?` | `null` \| `pending` \| `approved` |
| `fcmToken` | `String?` | Cihazın FCM token'ı |
| `fcmTokenUpdatedAt` | `DateTime?` | Son token güncelleme |

### 5.2 Diğer Modeller

| Model | Dosya | Açıklama |
|---|---|---|
| `CustomerModel` | `customer_model.dart` | Distribütörün müşteri kartı |
| `OrderModel` | `order_model.dart` | Sipariş kaydı |
| `OrderItemModel` | `order_item_model.dart` | Sipariş kalemi |
| `ProductModel` | `product_model.dart` | Ürün kataloğu |
| `RecipeModel` | `recipe_model.dart` | Shake tarifleri |
| `FollowUpModel` | `follow_up_model.dart` | Müşteri takip notu |
| `ScheduledFollowUpModel` | `scheduled_follow_up_model.dart` | Planlanmış takip görüşmesi |
| `ProgressEntryModel` | `progress_entry_model.dart` | Ölçüm kaydı (kilo, ölçü) |
| `WaterLogModel` | `water_log_model.dart` | Su tüketim günlüğü |
| `WaterSummaryModel` | `water_summary_model.dart` | Günlük su özeti |
| `InviteCodeModel` | `invite_code_model.dart` | Davet kodu |
| `BadgeModel` | `badge_model.dart` | Rozet tanımı |
| `DailyRoutineModel` | `daily_routine_model.dart` | Günlük rutin öğesi |
| `DistributorCustomerInsights` | `distributor_customer_insights.dart` | Distribütör analiz özeti |
| `InviteStatus` | `invite_status.dart` | Davet kodu durumları |

---

## 6. Servis Katmanı

### 6.1 FirestoreService — Facade Pattern

`lib/services/firestore_service.dart` — ~30 çağrı noktası için geriye uyumlu API. Yeni kod doğrudan repository'leri kullanmalıdır.

| Repository | Dosya | Sorumluluk |
|---|---|---|
| `UserProfileRepository` | `user_profile_repository.dart` | Kullanıcı profili CRUD, FCM token, rozetler |
| `ProductRepository` | `product_repository.dart` | Ürün kataloğu |
| `CustomerRepository` | `customer_repository.dart` | Müşteri CRUD + takip notları + planlanmış takipler |
| `OrderRepository` | `order_repository.dart` | Sipariş CRUD |
| `InviteCodeRepository` | `invite_code_repository.dart` | Davet kodu üretimi ve doğrulaması |
| `ProgressRepository` | `progress_repository.dart` | Ölçüm kayıtları |
| `WaterRepository` | `water_repository.dart` | Su günlüğü + günlük özet |
| `CalorieRepository` | `calorie_repository.dart` | Kalori kayıtları |
| `FoodRepository` | `food_repository.dart` | Besin veritabanı |
| `MotivationRepository` | `motivation_repository.dart` | Motivasyon mesajları |
| `ProgramTemplateRepository` | `program_template_repository.dart` | Program şablonları |
| `CustomerInsightsService` | `customer_insights_service.dart` | Cross-domain analiz |

### 6.2 Diğer Servisler

| Servis | Dosya | Pattern | Açıklama |
|---|---|---|---|
| `AuthService` | `auth_service.dart` | Sınıf | Firebase Auth (email/şifre + Google Sign-In) |
| `FcmService` | `fcm_service.dart` | Singleton | Push bildirimler, token yönetimi, foreground/background handler |
| `RoutineService` | `routine_service.dart` | Sınıf | Günlük rutin öğeleri |
| `ExerciseService` | `exercise_service.dart` | ChangeNotifier | Egzersiz takibi, real-time Firestore stream |
| `WeatherService` | `weather_service.dart` | Sınıf | Hava durumu verisi (motivasyon widget) |
| `FoodEstimationService` | `ai/food_estimation_service.dart` | Sınıf | Gemini AI ile besin kalori/makro tahmini |

---

## 7. Ekranlar ve Akışlar

### 7.1 Auth Akışı

#### SplashScreen (`/splash`)
- **Rol:** Herkese açık (geçiş ekranı)
- **Animasyonlar:** 3 saniye — `AnimationController` ile 4 aşamalı:
  1. `0-35%` — f1 arka plan resmi scale-in (üst bölge)
  2. `8-40%` — f2 arka plan resmi scale-in (alt bölge, gecikmeli)
  3. `35-75%` — H logosu fade + scale
  4. `60-100%` — Slogan slide-up + fade
- **Arka Plan:** `#E6FFC5` fıstık yeşili, f1/f2 konumları her açılışta randomize
- **Navigasyon:** Animasyon bittikten 500ms sonra auth kontrol başlar (max 100×100ms = 10 sn timeout)
- **Boyut Sınırları:** Logo 220-360px, arka plan görselleri 80-160px (clamp)

#### LoginScreen (`/login`)
- **Rol:** Herkese açık
- **Özellikler:** E-posta/şifre girişi, Google ile giriş, şifre sıfırlama dialog, rol seçimi (distribütör/müşteri), davet kodu ile müşteri kaydı
- **Validasyon:** Form validasyonu + Firebase hata mesajları Türkçe

#### CustomerOnboardingScreen (`/home/customer-onboarding`)
- **Rol:** Müşteri (ilk giriş, tek seferlik)
- **Yapı:** 5 sayfalı PageView
- **Toplanan Veriler:** Ad, yaş, telefon, kilo, boy, hedef kilo, hedef seçimi (weight_loss/healthy_living/weight_gain/skin_care), cinsiyet, uyanış/öğle/uyku saatleri, selfie fotoğrafı
- **Özellikler:** BMI hesaplama + otomatik hedef ağırlık tavsiyesi, metrik/imperial birim dönüşümü
- **Bildirim İzni:** Rationale dialog → OS izin dialog → `NotificationService + FcmService` requestPermission → syncFcmToken
- **Tamamlanınca:** `isOnboarded: true` Firestore'a yazılır

---

### 7.2 Ana Ekran — HomeScreen (`/home`)

3238+ satır — Kullanıcı rolüne göre **tamamen farklı** UI render eder.

#### Distribütör Dashboard

**Selamlama Bölümü:**
- Akıllı selamlama: doğum günü 🎂, program yıl dönümü, 7+ gün streak, saat bazlı (sabah/öğlen/akşam)
- Ay sonu kaç gün kaldı bilgisi
- Bildirim ikonu + yeni aktivasyon badge'i (SharedPreferences'te son görülme)

**Dashboard Bileşenleri:**

| Widget | Dosya | Açıklama |
|---|---|---|
| `VpPulseCard` | `vp_pulse_card.dart` | Aylık VP gauge — 4 durum rengi (yeşil/amber/kırmızı), günlük gereken VP, kalan gün |
| `DailySuccessRing` | `daily_success_ring.dart` | 3 dilimli halka (ürün🟢/su🔵/egzersiz🟠), ağırlıklı ortalama %, konfeti @100% |
| `MotivationWidget` | `motivation_widget.dart` | Hedef bazlı motivasyon sözü, distribütör mesajı öncelikli, gün bazlı rotasyon |
| `TodayActionsStrip` | `today_actions_strip.dart` | Bugünün kritik aksiyonları |
| `CustomerPipelineBar` | `customer_pipeline_bar.dart` | Müşteri hattı (Aktif/Risk/Kayıp) |
| `RecentActivityFeed` | `recent_activity_feed.dart` | Son aktiviteler akışı |
| `CriticalActionsStates` | `critical_actions_states.dart` | Acil aksiyon gerektiren müşteri kartları |

**Aksiyonlar:** Yeni Müşteri, Yeni Sipariş, Ürün Listesi, Müşteri Listesi, Şablon Programlar

#### Müşteri Ana Ekranı — 5 Sekmeli BottomNavigationBar

| # | Sekme | Ekran/Widget | Açıklama |
|---|---|---|---|
| 0 | Ana Sayfa | HomeScreen (embedded) | Günlük özet, selamlama, rozet, su/kalori ring'ler |
| 1 | İlerlemem | `CustomerProgressScreen` | Ölçümler, kilo grafiği, rozet, dönüşüm stüdyosu, dijital mezura |
| 2 | Ürünlerim | `CustomerProductsScreen` | İç/Dış Beslenme ürünleri, sepet, tarif kitabı |
| 3 | Destek | `CustomerSupportScreen` | Distribütörle iletişim, SSS |
| 4 | Profil | `ProfileScreen` | Kişisel bilgiler, ayarlar |

---

### 7.3 Müşteri Yönetimi (Distribütör)

#### CustomerListScreen (`/home/customers`)
- Müşteri listesi, arama, filtreleme
- Durum rozetleri: Aktif, Risk, Kayıp

#### CustomerDetailScreen (`/home/customers/customer-detail`)
- **3 sekmeli:** Takip | Profil & Sağlık | Geçmiş
- **Durum çubuğu:** Aktif/Pasif + Riskli/Takipte/Aktivasyon Bekleniyor
- **Takip:** Planlanmış işler, hızlı aksiyonlar, son 7 gün özeti, gelişim grafiği
- **Profil & Sağlık:** İletişim, kişisel bilgiler, sağlık notları, davet kodu
- **Geçmiş:** Ölçümler + geçmiş takip görüşmeleri
- WhatsApp hızlı erişim, `WeightChartWidget`, `DistributorCustomerInsights`

#### AddEditCustomerScreen
- Müşteri ekleme/düzenleme formu + su limit ayarları (min/max ml)

---

### 7.4 Ürün ve Tarif Yönetimi

#### ProductListScreen (`/home/products`)
- Kategori filtreleme, arama, liste/grid görünüm toggle
- **Distribütör:** Tüm kategoriler + ürün ekleme/düzenleme
- **Müşteri:** Yalnızca `İç Beslenme` ve `Dış Beslenme` kategorileri

#### ProductDetailScreen — Ürün detayı, görseli (CachedNetworkImage), besin değerleri
#### AddEditProductScreen — Ürün ekleme/düzenleme (yalnızca distribütör)

#### Tarif Sistemi
- `RecipeProvider` → `assets/recipes.json` bazlı tarif veritabanı
- `RecipeCard` widget'ı, `RecipesListScreen`
- Formül 1 Shake tarifleri (meyve, süt, su kombinasyonları)

---

### 7.5 Sipariş Yönetimi

| Ekran | Rota | Açıklama |
|---|---|---|
| `OrderListScreen` | `/home/orders` | Sipariş geçmişi, VP toplamları |
| `AddEditOrderScreen` | `/home/orders/add-edit-order` | Sipariş oluşturma/düzenleme |
| `CartScreen` | `/home/cart` | Sepet görünümü, toplam VP |

---

### 7.6 Program Sistemi

| Ekran | Rota | Açıklama |
|---|---|---|
| `ProgramTemplatesScreen` | `/home/program-templates` | Şablon listesi, arama |
| `EditProgramTemplateScreen` | `/home/program-templates/edit` | Şablon düzenleme |
| `CreateProgramScreen` | `/home/create-program` | Müşteri için program oluşturma |
| `ActiveProgramScreen` | (embedded) | Aktif programın günlük görünümü |

**ActiveProgramScreen Detay:**
- `ProgramProvider.watchActiveProgram()` stream
- Günlük rutin listesi: tamamlanmayanlar önce, animasyonlu liste
- İlerleme çubuğu (tamamlanan/toplam)
- Tamamlama konfeti animasyonu
- `NotificationService` ile günlük hatırlatıcılar
- Tarif entegrasyonu (`RecipeProvider` + `RecipeCard`)
- `WaterStepTile` — su adımları için özel widget

---

### 7.7 Gelişim Takibi

#### ProgressDashboardScreen (`/home/progress-dashboard`)
- Kilo grafiği (fl_chart / `WeightChartWidget`)
- Genel bakış: başlangıç/şu an/hedef kilo, toplam kayıp
- İstatistik: ölçüm sayısı, ortalama haftalık kayıp
- FAB: Yeni ölçüm ekle (`AddMeasurementSheet`)
- Paylaşım (share_plus)

#### CustomerProgressScreen (Müşteri İlerlemem Sekmesi)
- Rozet sistemi: `ProgressProvider.onBadgeEarned` callback → SnackBar
- Hedef ilerleme çubuğu
- Kilo değişimi grafiği (`WeightChartWidget`)
- Dönüşüm stüdyosu (`TransformationStudioWidget`)
- Dijital mezura — vücut ölçüm takibi

#### ProgressPhotosScreen — Before/after fotoğraf takibi, PhotoView tam ekran
#### MeasurementsHistoryScreen — Tüm ölçümler geçmişi

---

### 7.8 Su Takibi (`/home/water-tracker`)

- Animasyonlu dairesel ilerleme göstergesi (180×180)
- Hızlı ekle butonları (150ml, 200ml, 250ml, 300ml, özel)
- Egzersiz seviyesi seçici (su hedefini etkiler)
- Günlük su günlüğü listesi
- Hedef düzenleme dialog'u
- Min/Max limit (distribütör tarafından atanabilir)

---

### 7.9 Kalori Takibi (`/home/calorie-tracker`)

- Günlük kalori hedefi ve gerçekleşen (ilerleme kartı)
- `FoodSearchSheet` — Gemini AI destekli besin arama
- Öğün bazlı kayıt (kahvaltı, öğle, akşam, atıştırmalık)
- Profil eksikliği uyarı banner'ı (`missingProfileFields`)
- `CalorieHistoryScreen` — geçmiş kayıtlar

---

### 7.10 Distribütör Kişisel Kullanım (`distributor-usage`)

- Distribütörün **kendi** ürün kullanım takibi ("Ürünün ürünüdür" felsefesi)
- Program yoksa motivasyonel boş durum: "Kendine Rol Model Ol! 🌟"
- Program varsa: `DailySuccessRing` halkası, günlük kontrol listesi, egzersiz toggle, su takibi, `MotivationWidget`

---

### 7.11 Profil

| Ekran | Rota | Açıklama |
|---|---|---|
| `ProfileScreen` | `/home/profile` | Ana profil menüsü |
| `PersonalInfoScreen` | `/home/profile/personal-info` | Ad, e-posta, telefon, doğum tarihi, cinsiyet, fotoğraf, distribütör bilgi kartı |
| `HealthGoalsScreen` | `/home/profile/health-goals` | Hedef kilo, boy, kullanıcı hedefi |
| `AppSettingsScreen` | `/home/profile/app-settings` | Dil, bildirim, şifre değiştirme, hesap silme |
| `SupportScreen` | `/home/profile/support` | Destek iletişim |

---

## 8. Navigasyon — AppDrawer

`lib/widgets/app_drawer.dart` — Rol bazlı menü, aktif öğe vurgulaması (`_isActive` path segment eşleşmesi)

**Distribütör Menüsü:** Ana Sayfa, Müşteriler, Siparişler, Ürünler, Kalori Sayacı, Su Takibi, Profil, Çıkış

**Müşteri Menüsü:** Ana Sayfa, Kalori Sayacı, Su Takibi, Profil, Çıkış

**Drawer Header:** Kullanıcı adı, e-posta, avatar (UID hash bazlı deterministik renk)

---

## 9. Bildirim Sistemi

### FCM (`lib/services/fcm_service.dart` — Singleton)
- **Foreground:** `flutter_local_notifications` ile Android notification channel (`fcm_default_v1`, yüksek öncelikli)
- **Background:** Top-level `firebaseMessagingBackgroundHandler` — `@pragma('vm:entry-point')`
- **Initial Message:** Uygulama kapalıyken bildirime tıklanma (500ms gecikme ile deep-link)
- **Token:** Giriş/çıkış/yenileme olaylarında Firestore'a yazılır/silinir
- **İzin Akışı:** `requestPermission()` ayrı metod — onboarding ve ayarlardan çağrılır

### NotificationService
- Yerel bildirimler (program hatırlatıcıları, günlük rutin)
- `flutter_local_notifications` paketi

### Android Manifest
- `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` izinleri
- `ScheduledNotificationBootReceiver` — cihaz yeniden başladığında planlanmış bildirimleri yeniden kur

---

## 10. Lokalizasyon

- **Desteklenen Diller:** Türkçe (varsayılan), İngilizce
- **Sistem:** Flutter `generate: true` + ARB dosyaları (`l10n/`)
- **Provider:** `LocaleProvider` — `SharedPreferences`'da saklanır, `supportedLocales` listesi
- **Intl:** `DateFormat`, `NumberFormat` için `Intl.defaultLocale` dinamik güncellenir

---

## 11. AI Entegrasyonu

`lib/services/ai/food_estimation_service.dart`
- **Paket:** `google_generative_ai` (Gemini)
- **Akış:** Kullanıcı besin adı girer → `FoodSearchSheet` → Gemini API → yapılandırılmış JSON yanıt → `CalorieProvider`'a eklenir
- **Kullanım Alanı:** Kalori sayacında besin arama ve otomatik kalori/makro tahmini

---

## 12. Önemli Tasarım Kararları

### 12.1 GoRouter + AuthProvider Entegrasyonu
`_GoRouterRefreshNotifier` sarmalayıcısı — `AuthProvider.notifyListeners` çağrılarını `addPostFrameCallback` ile build fazı sonrasına erteler. Bu, aynı frame'de Provider ve GoRouter rebuild çakışmasından kaynaklanan `_dependents.isEmpty` assertion hatasını önler.

### 12.2 AuthProvider NotifyListeners Debounce
`notifyListeners` override edilerek `addPostFrameCallback` ile ertelenir. `_notifyScheduled` flag ile birden fazla hızlı çağrı tek bildirime birleştirilir.

### 12.3 Firestore Offline Persistence
```dart
persistenceEnabled: true
cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
```

### 12.4 FirestoreService Facade Pattern
~30 çağrı noktası için geriye uyumlu API. Yeni kod doğrudan repository'leri kullanmalı. İleride `@Deprecated` olacak.

### 12.5 Immutable Modeller + Sentinel
Tüm model sınıfları `final` alanlı + `copyWith`. Sentinel (`_unset`) pattern ile "null yap" vs "değiştirme" ayırt edilir.

### 12.6 Avatar Renk Sistemi
`avatar_color_helper.dart` — UID hash'ine göre deterministik arka plan rengi + metin kontrast rengi.

### 12.7 ChangeNotifierProxyProvider Pattern
Auth'a bağımlı provider'lar (`WaterProvider`, `ExerciseService`, `CalorieProvider`) `addPostFrameCallback` içinde `startListening/stopListening` çağrısı yapar — build fazı sırasında state mutasyonu önlenir.

---

## 13. Bağımlılıklar

### Üretim

| Paket | Versiyon | Amaç |
|---|---|---|
| `firebase_core` | ^4.10.0 | Firebase temel |
| `firebase_auth` | ^6.5.2 | Kimlik doğrulama |
| `cloud_firestore` | ^6.5.0 | NoSQL veritabanı |
| `firebase_messaging` | ^16.0.2 | Push bildirimleri |
| `firebase_storage` | ^13.4.2 | Dosya depolama |
| `go_router` | ^17.3.0 | Deklaratif navigasyon |
| `provider` | ^6.1.2 | State management |
| `google_sign_in` | ^6.3.0 | Google OAuth |
| `google_generative_ai` | ^0.4.7 | Gemini AI |
| `fl_chart` | ^1.2.0 | Grafikler |
| `flutter_local_notifications` | ^21.0.0 | Yerel bildirimler |
| `shared_preferences` | ^2.5.3 | Yerel key-value depolama |
| `path_provider` | ^2.1.5 | Dosya yolları |
| `image_picker` | ^1.2.1 | Fotoğraf seçimi |
| `cached_network_image` | ^3.4.1 | Ağ resmi önbelleği |
| `photo_view` | ^0.15.0 | Resim zoom |
| `share_plus` | ^13.1.0 | Paylaşım |
| `url_launcher` | ^6.3.2 | WhatsApp/URL açma |
| `animated_list_plus` | ^0.5.2 | Animasyonlu listeler |
| `confetti` | ^0.8.0 | Konfeti animasyonu |
| `intl` | ^0.20.2 | Tarih/para formatlama |
| `uuid` | ^4.5.1 | Benzersiz ID üretimi |
| `timezone` | ^0.11.0 | Saat dilimi |
| `http` | ^1.2.2 | HTTP istekleri |
| `video_player` | ^2.9.2 | Video oynatma |

### Geliştirme

| Paket | Amaç |
|---|---|
| `flutter_lints` | Lint kuralları |
| `flutter_launcher_icons` | Uygulama ikonu üretimi |
| `glados` | Property-based testing |
| `mocktail` | Mock nesneler |
| `fake_cloud_firestore` | Firestore test mock'u |

---

## 14. Dosya Adlandırma ve Kodlama Kuralları

| Kural | Örnek |
|---|---|
| Dosyalar | `snake_case.dart` |
| Sınıflar | `PascalCase` |
| Sabitler | `camelCase` veya `SCREAMING_SNAKE_CASE` |
| Magic String | Enum veya `static const String` (UserRole, routeName) |
| Yorum Dili | Türkçe |
| Lokalizasyon | Kullanıcıya görünür metin `AppLocalizations` üzerinden |
| Modeller | Immutable (`final` + `copyWith`) |
| Renk | Hardcoded değil, `AppColors` sabitleri |

---

*Bu belge projenin canlı durumunu yansıtmaktadır. Yeni özellik veya mimari değişikliklerde güncellenmelidir.*
