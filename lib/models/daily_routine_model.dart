import 'package:cloud_firestore/cloud_firestore.dart';

/// Rutin adımının tipi: ürün kullanımı, su içme veya normal yemek
enum RoutineStepType { product, water, normalMeal }

class DailyRoutineModel {
  final String id;
  final String productId; // Su adımları için 'water_step' kullanılır
  final DateTime scheduledTime;
  final bool isCompleted;
  // Yeni alanlar — geriye dönük uyumlu (mevcut dokümanlar 'product' olarak yorumlanır)
  final RoutineStepType stepType;
  final int? amountMl; // Yalnızca stepType == water için (250 ml)
  final String? slotId; // Hangi kalıcı slot'tan üretildiğini takip etmek için

  DailyRoutineModel({
    required this.id,
    required this.productId,
    required this.scheduledTime,
    this.isCompleted = false,
    this.stepType = RoutineStepType.product,
    this.amountMl,
    this.slotId,
  });

  factory DailyRoutineModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final stepTypeStr = map['stepType'] as String? ?? 'product';
    RoutineStepType stepType;
    if (stepTypeStr == 'water') {
      stepType = RoutineStepType.water;
    } else if (stepTypeStr == 'normalMeal') {
      stepType = RoutineStepType.normalMeal;
    } else {
      stepType = RoutineStepType.product;
    }

    return DailyRoutineModel(
      id: documentId,
      productId: map['productId'] as String? ?? '',
      scheduledTime: map['scheduledTime'] != null
          ? (map['scheduledTime'] as Timestamp).toDate()
          : DateTime.now(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      stepType: stepType,
      amountMl: map['amountMl'] as int?,
      slotId: map['slotId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'isCompleted': isCompleted,
      'stepType': stepType.name,
      if (amountMl != null) 'amountMl': amountMl,
      if (slotId != null) 'slotId': slotId,
    };
  }

  DailyRoutineModel copyWith({
    String? id,
    String? productId,
    DateTime? scheduledTime,
    bool? isCompleted,
    RoutineStepType? stepType,
    int? amountMl,
    String? slotId,
  }) {
    return DailyRoutineModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      stepType: stepType ?? this.stepType,
      amountMl: amountMl ?? this.amountMl,
      slotId: slotId ?? this.slotId,
    );
  }

  bool get isWaterStep => stepType == RoutineStepType.water;
  bool get isProductStep => stepType == RoutineStepType.product;
  bool get isNormalMealStep => stepType == RoutineStepType.normalMeal;
}
