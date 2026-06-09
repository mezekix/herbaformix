import 'package:cloud_firestore/cloud_firestore.dart';

/// Öğün tipi
enum MealSlotKind {
  morning, // Sabah ana öğünü
  lunch, // Öğle ana öğünü
  evening, // Akşam ana öğünü
  snack, // Ara öğün (çay, bar vb.)
}

/// Bir öğün içindeki tek bir ürün kalemi
class MealProduct {
  final String productId;
  final String productName;

  const MealProduct({required this.productId, required this.productName});

  factory MealProduct.fromMap(Map<String, dynamic> map) {
    return MealProduct(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
      };
}

/// Tek bir öğün dilimi — birden fazla ürün içerebilir, saati değiştirilebilir
class MealSlot {
  final String id; // Benzersiz slot ID'si (uuid veya timestamp)
  final MealSlotKind kind;
  final String label; // "Sabah Öğünü", "Ara Öğün 1" vb.
  final String scheduledTime; // "HH:mm"
  final bool isNormalMeal; // true ise ürün yok, normal yemek
  final List<MealProduct> products; // Birden fazla ürün

  const MealSlot({
    required this.id,
    required this.kind,
    required this.label,
    required this.scheduledTime,
    this.isNormalMeal = false,
    this.products = const [],
  });

  factory MealSlot.fromMap(Map<String, dynamic> map) {
    final rawProducts = map['products'] as List<dynamic>? ?? [];
    return MealSlot(
      id: map['id'] as String? ?? '',
      kind: _kindFromString(map['kind'] as String? ?? 'morning'),
      label: map['label'] as String? ?? 'Öğün',
      scheduledTime: map['scheduledTime'] as String? ?? '09:00',
      isNormalMeal: map['isNormalMeal'] as bool? ?? false,
      products: rawProducts
          .map((e) => MealProduct.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': _kindToString(kind),
        'label': label,
        'scheduledTime': scheduledTime,
        'isNormalMeal': isNormalMeal,
        'products': products.map((p) => p.toMap()).toList(),
      };

  MealSlot copyWith({
    String? id,
    MealSlotKind? kind,
    String? label,
    String? scheduledTime,
    bool? isNormalMeal,
    List<MealProduct>? products,
  }) {
    return MealSlot(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isNormalMeal: isNormalMeal ?? this.isNormalMeal,
      products: products ?? this.products,
    );
  }

  static MealSlotKind _kindFromString(String s) {
    switch (s) {
      case 'lunch':
        return MealSlotKind.lunch;
      case 'evening':
        return MealSlotKind.evening;
      case 'snack':
        return MealSlotKind.snack;
      default:
        return MealSlotKind.morning;
    }
  }

  static String _kindToString(MealSlotKind k) {
    switch (k) {
      case MealSlotKind.lunch:
        return 'lunch';
      case MealSlotKind.evening:
        return 'evening';
      case MealSlotKind.snack:
        return 'snack';
      default:
        return 'morning';
    }
  }

  /// Ürün var mı?
  bool get hasProducts => !isNormalMeal && products.isNotEmpty;

  /// Görüntüleme için kısa özet
  String get summary {
    if (isNormalMeal) return 'Normal Yemek';
    if (products.isEmpty) return 'Ürün seçilmedi';
    return products.map((p) => p.productName).join(', ');
  }
}

/// Müşterinin aktif beslenme programı
/// Firestore: users/{uid}/program/active
class ProgramModel {
  final String id;
  final String userGoal; // 'weight_loss' | 'healthy_living' | 'weight_gain'
  final DateTime startDate;
  final int durationMonths;
  final List<MealSlot> slots; // Sıralı slot listesi (ana + ara öğünler)
  final double? currentWeight;
  final double? targetWeight;
  final DateTime createdAt;
  final bool isActive;

  const ProgramModel({
    required this.id,
    required this.userGoal,
    required this.startDate,
    required this.durationMonths,
    required this.slots,
    this.currentWeight,
    this.targetWeight,
    required this.createdAt,
    this.isActive = true,
  });

  factory ProgramModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawSlots = (map['slots'] as List<dynamic>?) ?? const [];
    final slots = rawSlots
        .map((e) => MealSlot.fromMap(e as Map<String, dynamic>))
        .toList();

    return ProgramModel(
      id: documentId,
      userGoal: map['userGoal'] as String? ?? 'healthy_living',
      startDate: (map['startDate'] as Timestamp).toDate(),
      durationMonths: map['durationMonths'] as int? ?? 1,
      slots: slots,
      currentWeight: (map['currentWeight'] as num?)?.toDouble(),
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userGoal': userGoal,
      'startDate': Timestamp.fromDate(startDate),
      'durationMonths': durationMonths,
      'slots': slots.map((s) => s.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
    if (userGoal == 'weight_loss') {
      map['currentWeight'] = currentWeight;
      map['targetWeight'] = targetWeight;
    }
    return map;
  }

  ProgramModel copyWith({
    String? id,
    String? userGoal,
    DateTime? startDate,
    int? durationMonths,
    List<MealSlot>? slots,
    double? currentWeight,
    double? targetWeight,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ProgramModel(
      id: id ?? this.id,
      userGoal: userGoal ?? this.userGoal,
      startDate: startDate ?? this.startDate,
      durationMonths: durationMonths ?? this.durationMonths,
      slots: slots ?? this.slots,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  DateTime get endDate => DateTime(
        startDate.year,
        startDate.month + durationMonths,
        startDate.day,
      );

  int get remainingDays {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Sıralı slot listesi (saate göre)
  List<MealSlot> get sortedSlots {
    final sorted = List<MealSlot>.from(slots);
    sorted.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return sorted;
  }
}

// ─── Yardımcı Fonksiyonlar ────────────────────────────────────────────────────

int calculateMinDuration(double currentWeight, double targetWeight) {
  final diff = currentWeight - targetWeight;
  if (diff <= 0) throw ArgumentError('Hedef kilo mevcut kilodan küçük olmalıdır.');
  return (diff / 5).ceil();
}

String calculateWaterStepTime(String mealTime) {
  final parts = mealTime.split(':');
  if (parts.length != 2) return '00:00';
  final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  final water = dt.subtract(const Duration(minutes: 30));
  return '${water.hour.toString().padLeft(2, '0')}:${water.minute.toString().padLeft(2, '0')}';
}

String calculateEveningMealTime(String sleepTime) {
  final parts = sleepTime.split(':');
  if (parts.length != 2) return '19:00';
  final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  final evening = dt.subtract(const Duration(hours: 3));
  return '${evening.hour.toString().padLeft(2, '0')}:${evening.minute.toString().padLeft(2, '0')}';
}

int getMealNotificationId(String slotId) {
  return slotId.hashCode.abs() % 9000 + 1000;
}

/// Onboarding sonrası boş varsayılan slot iskeleti oluşturur.
///
/// **Ürün seçimi distribütöre bırakılır** — müşteri uygulamayı ilk açtığında
/// 3 ana öğün slot'u görür (saatleri uyku/uyanma planına göre hesaplanmış),
/// ama içleri boştur. Distribütör CRM'den müşterinin programını düzenleyerek
/// her slot'a uygun ürünleri ekler.
///
/// Kilo verme hedefinde öğle öğünü "normal yemek" olarak işaretlenir —
/// distribütör isterse bunu değiştirebilir.
///
/// Eski davranış: `firstWhere(p.name.contains('formül 1'))` ile listedeki
/// ilk Formül 1 ürününü otomatik seçiyordu. Bu UTF-8 alfabetik sıralamada
/// "Muz" aromasına denk geliyor ve müşteri için anlamsız bir varsayılan
/// üretiyordu.
List<MealSlot> buildDefaultSlots(
  String userGoal, {
  String? wakeTime,
  String? lunchTime,
  String? sleepTime,
}) {
  String calcMorningTime(String wTime) {
    final parts = wTime.split(':');
    if (parts.length != 2) return '09:00';
    final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    final morning = dt.add(const Duration(hours: 1));
    return '${morning.hour.toString().padLeft(2, '0')}:${morning.minute.toString().padLeft(2, '0')}';
  }

  final mTime = wakeTime != null ? calcMorningTime(wakeTime) : '09:00';
  final lTime = lunchTime ?? '13:00';
  final eTime = sleepTime != null ? calculateEveningMealTime(sleepTime) : '19:00';

  return [
    MealSlot(
      id: 'morning',
      kind: MealSlotKind.morning,
      label: 'Sabah Öğünü',
      scheduledTime: mTime,
      isNormalMeal: false,
      products: const [],
    ),
    MealSlot(
      id: 'lunch',
      kind: MealSlotKind.lunch,
      label: 'Öğle Öğünü',
      scheduledTime: lTime,
      isNormalMeal: userGoal == 'weight_loss', // kilo vermede öğle normal yemek
      products: const [],
    ),
    MealSlot(
      id: 'evening',
      kind: MealSlotKind.evening,
      label: 'Akşam Öğünü',
      scheduledTime: eTime,
      isNormalMeal: false,
      products: const [],
    ),
  ];
}
