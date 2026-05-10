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

  DailyRoutineModel({
    required this.id,
    required this.productId,
    required this.scheduledTime,
    this.isCompleted = false,
    this.stepType = RoutineStepType.product,
    this.amountMl,
  });

  factory DailyRoutineModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    // Geriye dönük uyumluluk: 'step_type' alanı yoksa 'product' kabul et
    final stepTypeStr = map['step_type'] as String? ?? 'product';
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
      productId: map['product_id'] as String? ?? '',
      scheduledTime: map['scheduled_time'] != null
          ? (map['scheduled_time'] as Timestamp).toDate()
          : DateTime.now(),
      isCompleted: map['is_completed'] as bool? ?? false,
      stepType: stepType,
      amountMl: map['amount_ml'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'scheduled_time': Timestamp.fromDate(scheduledTime),
      'is_completed': isCompleted,
      'step_type': stepType.name,
      if (amountMl != null) 'amount_ml': amountMl,
    };
  }

  DailyRoutineModel copyWith({
    String? id,
    String? productId,
    DateTime? scheduledTime,
    bool? isCompleted,
    RoutineStepType? stepType,
    int? amountMl,
  }) {
    return DailyRoutineModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      stepType: stepType ?? this.stepType,
      amountMl: amountMl ?? this.amountMl,
    );
  }

  bool get isWaterStep => stepType == RoutineStepType.water;
  bool get isProductStep => stepType == RoutineStepType.product;
  bool get isNormalMealStep => stepType == RoutineStepType.normalMeal;
}
