# HERBAFORMIX — Agent Bağlam Dosyası

> Bu dosya, AI asistanların projeyi hızlıca tanıyabilmesi için hazırlanmıştır.
> Detaylı ürün gereksinimleri için `PRD.md` dosyasına bakınız.

---

## 1. PROJE ÖZETİ

**Herbaformix**, sağlıklı beslenme ve aktif yaşam tarzını benimseyen bireyler (**Danışanlar/Müşteriler**) ile onlara rehberlik eden **Yaşam Koçları (Distribütörler)** için geliştirilmiş mobil öncelikli bir Flutter uygulamasıdır.

| Alan | Değer |
|---|---|
| **Sürüm** | `v1.0.0-beta+1` |
| **Platform** | Flutter (Android, iOS, Web, Windows) |
| **Dart SDK** | `^3.8.0` |
| **Dil** | Türkçe (`tr_TR`) |
| **Firebase Proje ID** | `herbaformix` |

### Temel Özellikler
- **Distribütör (Koç):** Davet kodu üretme, müşteri CRM, beslenme programı sihirbazı, sipariş yönetimi, danışan gelişim takibi
- **Müşteri (Danışan):** Oryantasyon, günlük su/kalori takibi, aktif program görüntüleme, gelişim ölçümleri, fotoğraf günlüğü, rozet/oyunlaştırma sistemi

---

## 2. TEKNOLOJİ YIĞINI

| Katman | Teknoloji |
|---|---|
| **UI Framework** | Flutter |
| **State Management** | `Provider` + `ChangeNotifier` (+ `ChangeNotifierProxyProvider`) |
| **Navigasyon** | `go_router` (declarative routing) |
| **Backend / DB** | Firebase (Auth, Firestore, Cloud Storage, Hosting) |
| **Kimlik Doğrulama** | Firebase Auth (E-posta/Şifre + Google Sign-In) |
| **Grafik** | `fl_chart` |
| **Bildirimler** | `flutter_local_notifications` |
| **Lokalizasyon** | `intl` (`tr_TR`) |

### Önemli Paketler
```yaml
firebase_core, firebase_auth, cloud_firestore, firebase_storage
go_router, provider, fl_chart, flutter_local_notifications
image_picker, shared_preferences, cached_network_image
share_plus, path_provider, url_launcher, google_sign_in
animated_list_plus, confetti, photo_view, uuid, timezone
```

---

## 3. MİMARİ YAPI (Feature-First)

```
lib/
├── main.dart                    # Firebase init + Provider root (MyAppInitializer)
├── app.dart                     # MaterialApp.router + ThemeData + tüm Provider'lar
├── firebase_options.dart        # FlutterFire CLI ile oluşturulan config
│
├── core/
│   ├── app_colors.dart          # ⭐ Renk paleti sabitleri (AppColors sınıfı)
│   ├── avatar_color_helper.dart # Avatar renk yardımcısı
│   ├── router.dart              # ⭐ GoRouter route tanımları + redirect mantığı
│   └── utils/
│       ├── water_calculation_engine.dart  # Dinamik su hedefi hesaplama
│       └── whatsapp_helper.dart           # WhatsApp paylaşım yardımcısı
│
├── features/
│   ├── auth/                    # Kimlik doğrulama
│   │   ├── providers/auth_provider.dart
│   │   └── screens/ (login, splash, customer_onboarding)
│   │
│   ├── calorie_tracker/         # Kalori takibi (⚠️ yerel state, Firestore yok)
│   │   ├── models/meal_model.dart
│   │   ├── providers/calorie_provider.dart
│   │   └── screens/calorie_tracker_screen.dart
│   │
│   ├── customers/               # CRM: Müşteri listesi/detay/ekleme
│   │   ├── providers/ (customer_provider, follow_up_provider)
│   │   └── screens/ (list, detail, add_edit)
│   │
│   ├── home/                    # Ana sayfa (rol bazlı içerik)
│   │   ├── providers/home_provider.dart
│   │   ├── screens/ (home, customer_progress, customer_support, customer_products, distributor_product_usage)
│   │   └── widgets/ (daily_success_ring, motivation_widget)
│   │
│   ├── orders/                  # Sipariş yönetimi
│   │   ├── providers/ (cart_provider, order_provider)
│   │   └── screens/ (order_list, cart, add_edit_order)
│   │
│   ├── products/                # Ürün kataloğu
│   │   ├── providers/product_provider.dart
│   │   └── screens/ (product_list, detail, add_edit, image_viewer)
│   │
│   ├── profile/                 # Profil yönetimi
│   │   ├── screens/ (profile, personal_info, health_goals, app_settings, support)
│   │   ├── utils/profile_validators.dart
│   │   └── widgets/ (customer_profile_view, distributor_profile_view, invite_code_section, change_password_dialog, profile_photo_widget, distributor_info_card, customer_profile_menu)
│   │
│   ├── program/                 # Beslenme programı sihirbazı
│   │   ├── models/ (program_model, program_editor_args)
│   │   ├── providers/program_provider.dart
│   │   ├── screens/ (create_program, active_program)
│   │   ├── services/ (notification_service, program_service)
│   │   └── widgets/ (goal_selection_step, meal_plan_step, weight_input_step, program_summary_step, water_step_tile)
│   │
│   ├── progress/                # Gelişim takibi
│   │   ├── providers/progress_provider.dart
│   │   ├── screens/ (progress_dashboard, progress_photos, measurements_history)
│   │   └── widgets/ (weight_chart_widget, add_measurement_sheet, transformation_studio_widget)
│   │
│   └── water_tracker/           # Su takibi
│       ├── providers/water_provider.dart
│       ├── screens/water_tracker_screen.dart
│       └── utils/water_calculation_constants.dart
│
├── models/                      # ⭐ Paylaşılan veri modelleri (16 dosya)
│   ├── user_profile_model.dart  # Ana kullanıcı profili
│   ├── user_role.dart           # UserRole enum (supervisor, distributor, successCreator, customer)
│   ├── progress_entry_model.dart
│   ├── invite_code_model.dart / invite_status.dart
│   ├── product_model.dart
│   ├── order_model.dart / order_item_model.dart
│   ├── customer_model.dart
│   ├── daily_routine_model.dart
│   ├── follow_up_model.dart / scheduled_follow_up_model.dart
│   ├── badge_model.dart
│   ├── water_log_model.dart / water_summary_model.dart
│   └── distributor_customer_insights.dart
│
├── services/                    # ⭐ Servis katmanı (Firestore erişimi)
│   ├── firestore_service.dart   # Ana Firestore CRUD servisi (~37 KB — büyük dosya)
│   ├── auth_service.dart        # Firebase Auth wrapper
│   ├── exercise_service.dart    # Egzersiz seviyesi yönetimi
│   ├── routine_service.dart     # Günlük rutin servisi
│   └── weather_service.dart     # OpenWeatherMap API (fallback destekli)
│
├── utils/
│   └── image_utils.dart         # Resim yardımcı fonksiyonları
│
└── widgets/                     # Paylaşılan widget'lar
    ├── app_drawer.dart          # Yan menü
    └── cached_product_image.dart # Önbelleğe alınmış ürün resmi
```

---

## 4. STATE MANAGEMENT MİMARİSİ

### Provider Hiyerarşisi

**`main.dart` (root-level):**
- `Provider<AuthService>`
- `Provider<FirestoreService>`
- `Provider<RoutineService>`
- `ChangeNotifierProvider<AuthProvider>`

**`app.dart` (MaterialApp.router builder içinde):**
- `ChangeNotifierProvider<ProductProvider>`
- `ChangeNotifierProvider<CustomerProvider>`
- `ChangeNotifierProvider<OrderProvider>`
- `ChangeNotifierProvider<CartProvider>`
- `ChangeNotifierProvider<HomeProvider>`
- `ChangeNotifierProxyProvider<AuthProvider, WaterProvider>` (auth değişince auto-listen)
- `ChangeNotifierProxyProvider<AuthProvider, ExerciseService>` (auth değişince auto-listen)
- `ChangeNotifierProvider<CalorieProvider>`
- `ChangeNotifierProvider<ProgramProvider>`
- `ChangeNotifierProvider<ProgressProvider>`

### GoRouter Refresh Mekanizması
`_GoRouterRefreshNotifier` sınıfı, `AuthProvider.notifyListeners` bildirimlerini `addPostFrameCallback` ile bir sonraki frame'e erteler. Bu, aynı build frame'inde Provider ve GoRouter çakışmasını önler.

---

## 5. ROUTING (GoRouter)

| Path | Ekran | Erişim |
|---|---|---|
| `/splash` | SplashScreen | Herkes |
| `/login` | LoginScreen | Herkes |
| `/home` | HomeScreen (rol bazlı) | Giriş yapmış |
| `/home/onboarding` | CustomerOnboardingScreen | Yeni müşteri |
| `/home/create-program` | CreateProgramScreen | Distribütör |
| `/home/water-tracker` | WaterTrackerScreen | Müşteri |
| `/home/calorie-tracker` | CalorieTrackerScreen | Müşteri |
| `/home/progress-dashboard` | ProgressDashboardScreen | Müşteri |
| `/home/progress-photos` | ProgressPhotosScreen | Müşteri |
| `/home/measurements-history` | MeasurementsHistoryScreen | Müşteri |
| `/home/profile` | ProfileScreen | Herkes |
| `/home/profile/personal-info` | PersonalInfoScreen | Herkes |
| `/home/profile/health-goals` | HealthGoalsScreen | Herkes |
| `/home/profile/app-settings` | AppSettingsScreen | Herkes |
| `/home/profile/support` | SupportScreen | Herkes |
| `/home/products` | ProductListScreen | Herkes |
| `/home/products/add-product` | AddEditProductScreen | Distribütör |
| `/home/products/product-detail/:productId` | ProductDetailScreen | Herkes |
| `/home/customers` | CustomerListScreen | Distribütör |
| `/home/customers/add-edit-customer` | AddEditCustomerScreen | Distribütör |
| `/home/customers/customer-detail` | CustomerDetailScreen | Distribütör |
| `/home/cart` | CartScreen | Herkes |
| `/home/orders` | OrderListScreen | Distribütör |
| `/home/orders/add-edit-order` | AddEditOrderScreen | Distribütör |

### Redirect Mantığı
1. Splash'te → yönlendirme yok
2. Giriş yapılmış + Login'de → `/home`
3. Giriş yapılmış + Müşteri + onboarding tamamlanmamış → `/home/onboarding`
4. Giriş yapılmamış + Login dışındaki bir sayfada → `/login`

---

## 6. FİRESTORE KOLEKSIYON YAPISI

```
/users/{userId}                      → UserProfileModel (ana profil)
/users/{userId}/progressEntries/     → ProgressEntryModel (ölçümler)
/users/{userId}/water_logs/          → WaterLogModel (YYYY-MM-DD)
/users/{userId}/waterSummaries/      → WaterSummaryModel (YYYY-MM-DD)
/users/{userId}/Daily_Routines/      → DailyRoutineModel
/users/{userId}/program/             → ProgramModel
/users/{userId}/daily_exercise/      → Egzersiz verileri
/users/{userId}/customers/           → CustomerModel (distribütör CRM)
/users/{userId}/customers/{id}/follow_ups/ → FollowUpModel
/users/{userId}/orders/              → OrderModel

/userProfiles/{userId}               → Güvenlik kurallarında referans profil
/inviteCodes/{codeId}                → InviteCodeModel (davet kodları)
/invite_codes/{inviteCodeId}         → (Alternatif koleksiyon adı)
/products/{productId}                → ProductModel
/scheduled_follow_ups/{followUpId}   → ScheduledFollowUpModel
/programs/{programId}                → Ek program koleksiyonu
/careerRoadmap/{levelId}             → Kariyer haritası
/orders/{orderId}                    → Global sipariş koleksiyonu
```

---

## 7. KULLANICI ROLLERİ (RBAC)

```dart
// lib/models/user_role.dart
enum UserRole { supervisor, distributor, successCreator, customer }
```

| Rol | Açıklama |
|---|---|
| `supervisor` | En üst seviye distribütör. Tüm verilere erişim. |
| `distributor` | Yaşam Koçu. Müşteri CRM, program hazırlama, sipariş yönetimi. |
| `successCreator` | Distribütör ile benzer yetkiler, farklı unvan. |
| `customer` | Danışan. Kendi verilerine erişim, takip, rozet kazanma. |

---

## 8. TASARIM SİSTEMİ VE RENK PALETİ

Renk sabitleri `lib/core/app_colors.dart` dosyasındaki `AppColors` sınıfında tanımlıdır:

| Sabit | Hex | Kullanım |
|---|---|---|
| `primary` | `#7AC144` | Ana butonlar, vurgular, AppBar |
| `secondary` / `grass` | `#42A146` | Tamamlayıcı yeşil |
| `accent` / `mango` | `#EFAC29` | Rozetler, FAB, CTA |
| `error` / `papaya` | `#D24A39` | Hatalar, silme |
| `background` | `#F5F5F5` | Scaffold arka planı |
| `surface` | `#FFFFFF` | Kart/form arka planları |
| `textPrimary` / `nightSky` | `#101820` | Ana metinler |
| `textSecondary` | `#575757` | İkincil açıklamalar |
| `garden` | `#266431` | Ana yeşil |
| `rosemary` | `#3A5137` | Koyu yeşil |
| `aqua` | `#78E3D7` | Açık mavi/yeşil |
| `blueberry` | `#4A28A9` | Mor |
| `bay` | `#224945` | Çok koyu yeşil/mavi |
| `rain` | `#DDFCFF` | Çok açık mavi |
| `laguna` | `#3A70C2` | Mavi |
| `sunflower` | `#FFF176` | Açık sarı |
| `lake` | `#3B9187` | Turkuaz yeşil |

### Tema Yapılandırması (`app.dart`)
- `ThemeData` içinde `ColorScheme.fromSeed(seedColor: AppColors.primary)` kullanılır
- AppBar: Yeşil arka plan (`AppColors.primary`), beyaz foreground
- Butonlar: `BorderRadius.circular(10)`, yükseklik 2
- Input alanları: Dolgu arka plan, `BorderRadius.circular(10)`, odaklanınca yeşil kenarlık
- Scaffold: `AppColors.background` (#F5F5F5)

---

## 9. FIREBASE YAPILANDIRMASI

| Dosya | Açıklama |
|---|---|
| `.firebaserc` | Firebase projesi: `herbaformix` |
| `firebase.json` | Hosting (build/web), Firestore kuralları yapılandırması |
| `firestore.rules` | Güvenlik kuralları |
| `firestore.indexes.json` | Firestore indeksleri |
| `lib/firebase_options.dart` | Platform-spesifik Firebase config |

---

## 10. KOD YAZIM STANDARTLARI

### Genel Kurallar
1. **Dil:** Tüm UI metinleri ve yorumlar Türkçe (`tr_TR`)
2. **Magic Number/String Yasağı:** Tüm renkler `AppColors`, sabit değerler enum/const ile tanımlanmalı
3. **Tema Uyumu:** Projede `tema.md` varsa, yeni bileşenler bu dosyadaki stilleri birebir uygulamalı
4. **Lint Kuralları:** `flutter_lints` paketi (`analysis_options.yaml`)
5. **Dosya İsimlendirme:** `snake_case` (Dart/Flutter standardı)
6. **Sınıf İsimlendirme:** `PascalCase`
7. **Değişken İsimlendirme:** `camelCase`
8. **Firestore Alan Adları:** `camelCase` (geriye uyumluluk için bazı eski alanlar farklı olabilir)

### Feature Modülü Yapısı
Yeni bir özellik eklenirken şu klasör yapısı takip edilmelidir:
```
lib/features/<feature_name>/
├── models/          # Özelliğe özel veri modelleri (opsiyonel)
├── providers/       # ChangeNotifier sınıfları
├── screens/         # Ekran widget'ları
├── services/        # Servis sınıfları (opsiyonel)
├── utils/           # Yardımcı fonksiyonlar (opsiyonel)
└── widgets/         # Alt widget'lar (opsiyonel)
```

### Provider Ekleme Kuralları
- Yeni Provider → `app.dart` içindeki `MultiProvider`'a eklenmeli
- Auth'a bağımlı Provider → `ChangeNotifierProxyProvider<AuthProvider, ...>` kullanılmalı
- Servis bağımlılığı → `main.dart` içindeki root `MultiProvider`'a eklenmeli

### Routing Kuralları
- Yeni route → `lib/core/router.dart` içine eklenmeli
- Screen sınıfı içinde `static const String routeName = 'route-name';` tanımlanmalı
- `state.extra` ile parametre geçişi yapılıyor (type casting gerekli)

---

## 11. BİLİNEN KISITLAMALAR VE TEKNİK BORÇLAR

| Kısıtlama | Detay |
|---|---|
| **Kalori Takibi** | `CalorieProvider` yerel state'te çalışır, Firestore entegrasyonu yok |
| **Gelişim Fotoğrafları** | Yerel dosya sisteminde, Firebase Storage entegrasyonu yok. Cihaz değişince kaybolur. |
| **Google Sign-In** | Altyapı hazır, uçtan uca test eksik |
| **Test Altyapısı** | Unit/widget/integration test bulunmuyor |
| **Erişilebilirlik** | Semantic label çalışmaları devam ediyor |
| **firestore_service.dart** | ~37 KB büyük dosya, refactoring ihtiyacı var |

---

## 12. ÖNEMLİ DOSYALAR (HIZLI ERİŞİM)

| Amaç | Dosya Yolu |
|---|---|
| Uygulama giriş noktası | `lib/main.dart` |
| MaterialApp + Tema + Provider'lar | `lib/app.dart` |
| Renk sabitleri | `lib/core/app_colors.dart` |
| Route tanımları | `lib/core/router.dart` |
| Ana veri modeli (kullanıcı) | `lib/models/user_profile_model.dart` |
| Rol enum'ı | `lib/models/user_role.dart` |
| Firestore CRUD servisi | `lib/services/firestore_service.dart` |
| Auth servisi | `lib/services/auth_service.dart` |
| Auth provider | `lib/features/auth/providers/auth_provider.dart` |
| Su hesaplama motoru | `lib/core/utils/water_calculation_engine.dart` |
| Bildirim servisi | `lib/features/program/services/notification_service.dart` |
| Ürün gereksinimleri | `PRD.md` |
| Firestore güvenlik kuralları | `firestore.rules` |
| Firebase yapılandırması | `firebase.json`, `.firebaserc` |
| Proje bağımlılıkları | `pubspec.yaml` |
| Lint yapılandırması | `analysis_options.yaml` |

---

## 13. ÇALIŞTIRMA KOMUTLARI

```bash
# Bağımlılıkları yükle
flutter pub get

# Android'de çalıştır
flutter run

# Web'de çalıştır
flutter run -d chrome

# Web build (Firebase Hosting için)
flutter build web

# Firebase deploy
firebase deploy --only hosting
firebase deploy --only firestore:rules

# Analiz
flutter analyze

# Launcher ikon oluştur
dart run flutter_launcher_icons
```

---

## 14. ASSETS YAPISI

```
assets/
├── logo/
│   └── logo.webp              # Marka logosu (launcher icon dahil)
├── f1.png, f2.png             # Dekoratif görseller
├── ph.webp                    # Placeholder görsel
└── motivations.json           # Motivasyon mesajları verisi
```
