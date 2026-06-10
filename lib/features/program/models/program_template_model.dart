import 'package:cloud_firestore/cloud_firestore.dart';

import 'program_model.dart';

/// Distribütörün hazırladığı, müşteriye uygulanmadan önce kullanılabilen
/// program şablonu.
///
/// Firestore: `/programs/{programId}` (top-level)
/// `ProgramModel`'den farkı: `startDate`, `currentWeight`, `targetWeight`,
/// `isActive` gibi müşteri/zaman bağlamı yok. Şablonlar `name` ve
/// `description` ile katalogda saklanır.
class ProgramTemplateModel {
  final String id;
  final String name;
  final String? description;
  final String userGoal; // 'weight_loss' | 'healthy_living' | 'weight_gain'
  final List<MealSlot> slots;
  final int defaultDurationMonths;
  final String createdBy; // distribütör uid
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProgramTemplateModel({
    required this.id,
    required this.name,
    this.description,
    required this.userGoal,
    required this.slots,
    this.defaultDurationMonths = 1,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgramTemplateModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final rawSlots = (map['slots'] as List<dynamic>?) ?? const [];
    return ProgramTemplateModel(
      id: documentId,
      name: map['name'] as String? ?? 'Adsız Şablon',
      description: map['description'] as String?,
      userGoal: map['userGoal'] as String? ?? 'healthy_living',
      slots: rawSlots
          .map((e) => MealSlot.fromMap(e as Map<String, dynamic>))
          .toList(),
      defaultDurationMonths: map['defaultDurationMonths'] as int? ?? 1,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'userGoal': userGoal,
        'slots': slots.map((s) => s.toMap()).toList(),
        'defaultDurationMonths': defaultDurationMonths,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ProgramTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? userGoal,
    List<MealSlot>? slots,
    int? defaultDurationMonths,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgramTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userGoal: userGoal ?? this.userGoal,
      slots: slots ?? this.slots,
      defaultDurationMonths:
          defaultDurationMonths ?? this.defaultDurationMonths,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Şablondan müşteri programı türetir.
  ///
  /// Slot'lar olduğu gibi kopyalanır; başlangıç tarihi şu an, süre şablonun
  /// `defaultDurationMonths` değeri. `currentWeight`/`targetWeight` gibi
  /// müşteri-spesifik alanlar dışarıdan verilir.
  ProgramModel toProgram({
    required DateTime startDate,
    double? currentWeight,
    double? targetWeight,
    int? overrideDurationMonths,
  }) {
    return ProgramModel(
      id: 'active',
      userGoal: userGoal,
      startDate: startDate,
      durationMonths: overrideDurationMonths ?? defaultDurationMonths,
      slots: slots,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      createdAt: startDate,
      isActive: true,
    );
  }
}
