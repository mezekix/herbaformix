# Tasarım Belgesi: Müşteri Program Oluşturma

## Genel Bakış

Bu özellik, HerbaForm Flutter uygulamasında müşterilerin kişiselleştirilmiş günlük beslenme programı oluşturmasını sağlar. Müşteri; hedefini seçer, kilo bilgilerini girer (kilo verme hedefi için), öğün planını yapılandırır ve program Firestore'a kaydedilir. Sistem, mevcut `RoutineService` ve `WaterProvider` altyapısıyla entegre çalışır; her öğün için push bildirimi planlanır ve su içme adımları su takibine yansıtılır.

### Temel Akış

```
Hedef Seçimi → (Kilo Girişi) → Öğün Planlama → Özet & Onay → Program Aktif
```

- **Hedef Seçimi**: `weight_loss`, `healthy_living`, `weight_gain`
- **Kilo Girişi**: Yalnızca `weight_loss` için; süre hesaplama burada yapılır
- **Öğün Planlama**: Sabah / Öğle / Akşam öğünlerine ürün veya normal yemek atama
- **Özet & Onay**: Tüm detayların gösterildiği son adım
- **Program Aktif**: Firestore kaydı, rutin oluşturma, bildirim planlama

---

## Mimari

Özellik, mevcut uygulamanın katmanlı mimarisine uygun şekilde tasarlanmıştır:

```
UI Katmanı (Screens / Widgets)
        ↓
Provider Katmanı (ProgramProvider)
        ↓
Servis Katmanı (ProgramService, NotificationService)
        ↓
Veri Katmanı (Firestore, flutter_local_notifications)
```

### Mevcut Altyapıyla Entegrasyon

```
ProgramService
    ├── RoutineService.generateDailyRoutine()   ← mevcut servis
    └── RoutineService.clearAllRoutines()       ← mevcut servis

ProgramProvider
    └── WaterProvider.addWater(250)             ← mevcut provider

NotificationService
    └── RoutineService.updateRoutineStatus()    ← mevcut servis
```

### Klasör Yapısı

```
lib/
  features/
    program/
      models/
        program_model.dart
      providers/
        program_provider.dart
      screens/
        create_program_screen.dart
        active_program_screen.dart
      services/
        program_service.dart
        notification_service.dart
      widgets/
        goal_selection_card.dart
        meal_plan_tile.dart
        program_summary_card.dart
        water_step_tile.dart
```

---

## Bileşenler ve Arayüzler

### ProgramModel

Program verilerini temsil eden veri modeli. Firestore `users/{uid}/program` dokümanına karşılık gelir.

```dart
class ProgramModel {
  final String id;
  final String userGoal;          // 'weight_loss' | 'healthy_living' | 'weight_gain'
  final DateTime startDate;
  final int durationMonths;       // Minimum süre (ay)
  final Map<String, MealSlot> mealPlan; // 'morning' | 'lunch' | 'evening' → MealSlot
  final double? currentWeight;    // Yalnızca weight_loss için
  final double? targetWeight;     // Yalnızca weight_loss için
  final DateTime createdAt;
  final bool isActive;
}

class MealSlot {
  final String type;              // 'product' | 'normal_meal'
  final String? productId;        // type == 'product' ise dolu
  final String? productName;      // Görüntüleme için
  final String scheduledTime;     // "HH:mm" formatı
}
```

### ProgramService

Firestore CRUD işlemlerini yöneten servis katmanı.

```dart
class ProgramService {
  // Program oluştur veya güncelle
  Future<void> saveProgram(String userId, ProgramModel program);

  // Aktif programı getir
  Future<ProgramModel?> getActiveProgram(String userId);

  // Aktif program stream'i (gerçek zamanlı)
  Stream<ProgramModel?> watchActiveProgram(String userId);

  // Programı sil
  Future<void> deleteProgram(String userId, String programId);

  // Program var mı kontrol et
  Future<bool> hasActiveProgram(String userId);
}
```

### NotificationService

`flutter_local_notifications` paketini kullanan bildirim servisi.

```dart
class NotificationService {
  // Servisi başlat ve izin iste
  Future<bool> initialize();

  // Öğün bildirimi planla (günlük tekrarlayan)
  Future<void> scheduleMealNotification({
    required int notificationId,
    required String title,
    required String body,
    required String scheduledTime, // "HH:mm"
  });

  // Tüm program bildirimlerini iptal et
  Future<void> cancelAllProgramNotifications();

  // Bildirim iznini kontrol et
  Future<bool> hasPermission();

  // İzin iste
  Future<bool> requestPermission();
}
```

### ProgramProvider

UI ile servis katmanı arasındaki köprü. Wizard adım durumunu ve program verilerini yönetir.

```dart
class ProgramProvider with ChangeNotifier {
  // Wizard durumu
  int currentStep;                // 0: Hedef, 1: Kilo (opsiyonel), 2: Öğün, 3: Özet
  String? selectedGoal;
  double? currentWeight;
  double? targetWeight;
  int durationMonths;
  Map<String, MealSlot> mealPlan;

  // Aktif program
  ProgramModel? activeProgram;
  bool isLoading;
  String? errorMessage;

  // Süre hesaplama
  int calculateMinDuration(double weightDiff);

  // Adım navigasyonu
  void nextStep();
  void previousStep();

  // Program kaydetme
  Future<void> saveProgram(String userId);

  // Aktif programı yükle
  Future<void> loadActiveProgram(String userId);
}
```

### CreateProgramScreen

Çok adımlı wizard ekranı. `PageView` veya `IndexedStack` ile adımlar arası geçiş sağlar.

```dart
class CreateProgramScreen extends StatelessWidget {
  static const String routeName = 'create-program';

  // Adımlar:
  // Step 0: GoalSelectionStep
  // Step 1: WeightInputStep (yalnızca weight_loss)
  // Step 2: MealPlanStep
  // Step 3: ProgramSummaryStep
}
```

---

## Veri Modelleri

### Firestore Şeması

**`users/{uid}/program`** (tek doküman — aktif program):

```json
{
  "id": "auto-generated",
  "user_goal": "weight_loss",
  "start_date": Timestamp,
  "duration_months": 2,
  "meal_plan": {
    "morning": {
      "type": "product",
      "product_id": "abc123",
      "product_name": "Formül 1 Shake",
      "scheduled_time": "07:30"
    },
    "lunch": {
      "type": "normal_meal",
      "product_id": null,
      "product_name": null,
      "scheduled_time": "13:00"
    },
    "evening": {
      "type": "product",
      "product_id": "abc123",
      "product_name": "Formül 1 Shake",
      "scheduled_time": "20:00"
    }
  },
  "current_weight": 75.0,
  "target_weight": 68.0,
  "created_at": Timestamp,
  "is_active": true
}
```

**`users/{uid}/Daily_Routines`** (mevcut koleksiyon — değişmez):

Su adımları için `productId` alanına özel bir değer kullanılır:

```json
{
  "product_id": "water_step",
  "scheduled_time": Timestamp,
  "is_completed": false,
  "step_type": "water",
  "amount_ml": 250
}
```

> **Not**: `DailyRoutineModel` genişletilecek: `stepType` (`product` | `water`) ve `amountMl` alanları eklenecek.

### Süre Hesaplama Mantığı

```dart
int calculateMinDuration(double currentWeight, double targetWeight) {
  final diff = currentWeight - targetWeight;
  if (diff <= 0) throw ArgumentError('Hedef kilo mevcut kilodan küçük olmalıdır.');
  if (diff <= 5) return 1;
  if (diff <= 10) return 2;
  if (diff <= 20) return 3;
  return 4;
}
```

### Öğün Saati Hesaplama

```dart
// Akşam öğünü: sleepTime - 3 saat
String calculateEveningMealTime(String sleepTime) {
  final parts = sleepTime.split(':');
  final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  final evening = dt.subtract(const Duration(hours: 3));
  return '${evening.hour.toString().padLeft(2, '0')}:${evening.minute.toString().padLeft(2, '0')}';
}

// Su adımı: öğün saati - 30 dakika
String calculateWaterStepTime(String mealTime) {
  final parts = mealTime.split(':');
  final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  final water = dt.subtract(const Duration(minutes: 30));
  return '${water.hour.toString().padLeft(2, '0')}:${water.minute.toString().padLeft(2, '0')}';
}
```

### Bildirim ID Şeması

Her öğün için deterministik bildirim ID'si:

```dart
// morning: 1000, lunch: 1001, evening: 1002
int getNotificationId(String mealKey) {
  const ids = {'morning': 1000, 'lunch': 1001, 'evening': 1002};
  return ids[mealKey] ?? 1000;
}
```

---

## Doğruluk Özellikleri

*Bir özellik (property), bir sistemin tüm geçerli çalışmalarında doğru olması gereken bir karakteristik veya davranıştır — temelde sistemin ne yapması gerektiğine dair biçimsel bir ifadedir. Özellikler, insan tarafından okunabilir spesifikasyonlar ile makine tarafından doğrulanabilir doğruluk garantileri arasındaki köprüyü oluşturur.*

### Özellik 1: Geçersiz Kilo Girişi Reddi

*Herhangi bir* sıfır veya negatif kilo farkı değeri için (`currentWeight - targetWeight <= 0`), `calculateMinDuration` fonksiyonu hata fırlatmalı veya hata mesajı döndürmelidir; hiçbir zaman geçerli bir süre döndürmemelidir.

**Doğrular: Gereksinim 2.6**

---

### Özellik 2: Süre Hesaplama Doğruluğu

*Herhangi bir* pozitif kilo farkı değeri için, `calculateMinDuration` fonksiyonunun döndürdüğü süre şu kurallara uymalıdır:
- `diff ∈ [1, 5]` → süre = 1
- `diff ∈ [6, 10]` → süre = 2
- `diff ∈ [11, 20]` → süre = 3
- `diff > 20` → süre = 4

**Doğrular: Gereksinim 2.1, 2.2, 2.3, 2.4, 2.5**

---

### Özellik 3: Meal Replacement Filtresi

*Herhangi bir* ürün listesi verildiğinde, öğün planlayıcının sunduğu ürün listesi yalnızca `category == 'meal_replacement'` olan ürünleri içermelidir; diğer kategorideki ürünler hiçbir zaman listelenmemelidir.

**Doğrular: Gereksinim 3.4**

---

### Özellik 4: Öğün Talimatı Eşleşmesi

*Herhangi bir* ürün ve hedef (`userGoal`) kombinasyonu için, öğün planlayıcının gösterdiği kullanım talimatı `product.instructionsByGoal[userGoal]` değeriyle tam olarak eşleşmelidir.

**Doğrular: Gereksinim 3.5**

---

### Özellik 5: Su Adımı Sayısı ve Zamanlaması

*Herhangi bir* öğün planı için, oluşturulan su adımlarının sayısı ürün atanmış öğün sayısına eşit olmalı ve her su adımının zamanı ilgili öğün saatinden tam 30 dakika önce olmalıdır.

**Doğrular: Gereksinim 4.1**

---

### Özellik 6: Rutin Listesinde Su Adımı Sıralaması

*Herhangi bir* günlük rutin listesinde, her su adımı (`step_type == 'water'`) ilgili öğün adımından (`step_type == 'product'`) önce gelmelidir; hiçbir öğün adımı kendi su adımından önce sıralanmamalıdır.

**Doğrular: Gereksinim 4.3, 8.2**

---

### Özellik 7: ProgramModel Serileştirme Bütünlüğü

*Herhangi bir* geçerli `ProgramModel` nesnesi için, `toMap()` çıktısı şu alanların tamamını içermelidir: `user_goal`, `start_date`, `duration_months`, `meal_plan`, `created_at`, `is_active`. `weight_loss` hedefi için ek olarak `current_weight` ve `target_weight` alanları da bulunmalıdır.

**Doğrular: Gereksinim 5.2**

---

### Özellik 8: Bildirim Sayısı Tutarlılığı

*Herhangi bir* öğün planı için, planlanan bildirim sayısı ürün atanmış öğün sayısına eşit olmalıdır; `normal_meal` tipi öğünler için bildirim planlanmamalıdır.

**Doğrular: Gereksinim 6.1, 3.6**

---

### Özellik 9: Özet Ekranı Veri Bütünlüğü

*Herhangi bir* `ProgramModel` için, özet ekranının render ettiği içerik şu bilgilerin tamamını içermelidir: seçilen hedef, program süresi, başlangıç tarihi, her öğün için atanan ürün adı veya "Normal Yemek" etiketi, ve öğün saatleri.

**Doğrular: Gereksinim 7.2**

---

### Özellik 10: Kalan Gün Hesaplama Doğruluğu

*Herhangi bir* (`startDate`, `durationMonths`) çifti için, kalan gün sayısı `(startDate + durationMonths ay) - bugün` formülüyle hesaplanmalı ve sonuç hiçbir zaman negatif olmamalıdır (program bitmişse 0 gösterilmelidir).

**Doğrular: Gereksinim 8.5**

---

### Özellik 11: generateDailyRoutine Parametre Filtresi

*Herhangi bir* öğün planı için, `RoutineService.generateDailyRoutine()` çağrısına geçirilen `assignedProducts` listesi yalnızca `type == 'product'` olan öğünlerin ürünlerini içermelidir; `normal_meal` tipi öğünlerin ürünleri bu listeye dahil edilmemelidir.

**Doğrular: Gereksinim 5.4**

---

## Hata Yönetimi

### Validasyon Hataları (UI Katmanı)

| Durum | Hata Mesajı | Davranış |
|---|---|---|
| Kilo alanları boş | "Lütfen mevcut ve hedef kilonuzu girin." | Sonraki adıma geçiş engellenir |
| Hedef kilo ≥ mevcut kilo | "Hedef kilo mevcut kilodan küçük olmalıdır." | Sonraki adıma geçiş engellenir |
| Öğün saati boş | "Lütfen [sabah/öğle/akşam] saatini girin." | Sonraki adıma geçiş engellenir |

### Servis Hataları (Servis Katmanı)

| Durum | Hata Mesajı | Davranış |
|---|---|---|
| Firestore kayıt başarısız | "Program kaydedilemedi. İnternet bağlantınızı kontrol edin." | Kullanıcı özet adımına döner |
| `WaterProvider.addWater()` başarısız | "Su kaydı yapılamadı, lütfen tekrar deneyin." | Snackbar gösterilir |
| Bildirim izni yok | İzin açıklama diyaloğu | Program bildirimsiz devam eder |

### Hata Yönetimi Stratejisi

- Tüm Firestore işlemleri `try-catch` bloğu içinde yapılır
- `ProgramProvider.errorMessage` alanı UI'da gösterilir
- Ağ hataları için `FirebaseException` yakalanır
- Bildirim hataları program akışını engellemez (graceful degradation)

---

## Test Stratejisi

### Birim Testleri

Saf fonksiyonlar ve iş mantığı için örnek tabanlı testler:

- `calculateMinDuration()` — sınır değerleri (1, 5, 6, 10, 11, 20, 21 kg)
- `calculateEveningMealTime()` — gece yarısı geçişi dahil
- `calculateWaterStepTime()` — gece yarısı geçişi dahil
- `ProgramModel.toMap()` / `ProgramModel.fromMap()` — round-trip
- `MealSlot.toMap()` / `MealSlot.fromMap()` — round-trip
- Wizard adım navigasyonu — `nextStep()`, `previousStep()`
- Aktif program onay diyaloğu mantığı

### Property-Based Testler

**Kullanılan kütüphane**: [`fast_check`](https://pub.dev/packages/fast_check) (Dart için property-based testing)

Her property testi minimum **100 iterasyon** çalıştırılmalıdır.

**Özellik 1: Geçersiz Kilo Girişi Reddi**
```
// Feature: customer-program-creation, Property 1: Geçersiz kilo girişi reddi
// Herhangi bir sıfır veya negatif kilo farkı için hata fırlatılmalıdır
```

**Özellik 2: Süre Hesaplama Doğruluğu**
```
// Feature: customer-program-creation, Property 2: Süre hesaplama doğruluğu
// Herhangi bir pozitif kilo farkı için doğru minimum süre döndürülmelidir
```

**Özellik 3: Meal Replacement Filtresi**
```
// Feature: customer-program-creation, Property 3: Meal replacement filtresi
// Herhangi bir ürün listesinde yalnızca meal_replacement kategorisi listelenmeli
```

**Özellik 4: Öğün Talimatı Eşleşmesi**
```
// Feature: customer-program-creation, Property 4: Öğün talimatı eşleşmesi
// Herhangi bir ürün-hedef kombinasyonu için talimat instructionsByGoal ile eşleşmeli
```

**Özellik 5: Su Adımı Sayısı ve Zamanlaması**
```
// Feature: customer-program-creation, Property 5: Su adımı sayısı ve zamanlaması
// Ürün atanmış öğün sayısı kadar su adımı, her biri 30 dk önce
```

**Özellik 6: Rutin Listesinde Su Adımı Sıralaması**
```
// Feature: customer-program-creation, Property 6: Su adımı sıralaması
// Her su adımı ilgili öğün adımından önce gelmelidir
```

**Özellik 7: ProgramModel Serileştirme Bütünlüğü**
```
// Feature: customer-program-creation, Property 7: ProgramModel serileştirme bütünlüğü
// toMap() çıktısı tüm gerekli alanları içermeli; fromMap(toMap(x)) == x
```

**Özellik 8: Bildirim Sayısı Tutarlılığı**
```
// Feature: customer-program-creation, Property 8: Bildirim sayısı tutarlılığı
// Planlanan bildirim sayısı ürün atanmış öğün sayısına eşit olmalı
```

**Özellik 9: Özet Ekranı Veri Bütünlüğü**
```
// Feature: customer-program-creation, Property 9: Özet ekranı veri bütünlüğü
// Herhangi bir ProgramModel için özet tüm gerekli alanları içermeli
```

**Özellik 10: Kalan Gün Hesaplama Doğruluğu**
```
// Feature: customer-program-creation, Property 10: Kalan gün hesaplama doğruluğu
// Herhangi bir (startDate, durationMonths) için kalan gün ≥ 0
```

**Özellik 11: generateDailyRoutine Parametre Filtresi**
```
// Feature: customer-program-creation, Property 11: generateDailyRoutine parametre filtresi
// assignedProducts yalnızca product tipindeki öğünleri içermeli
```

### Entegrasyon Testleri

Mock Firestore ve mock bildirim servisi kullanılarak:

- Program Firestore'a doğru koleksiyona kaydedilir
- Program kaydedildikten sonra `generateDailyRoutine()` çağrılır
- Rutin tamamlandığında `updateRoutineStatus()` doğru parametrelerle çağrılır
- Bildirim aksiyonu tetiklendiğinde `updateRoutineStatus()` çağrılır

### Widget Testleri

- `CreateProgramScreen` wizard adımları arası geçiş
- Hedef seçim kartları render ve seçim
- Özet ekranı tüm alanları gösteriyor
- Yükleme durumunda buton devre dışı ve spinner görünür
- Hata mesajları doğru gösteriliyor
