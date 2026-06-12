import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_model.dart';

/// Bir günün kalori kaydı.
///
/// Firestore: `/users/{uid}/calorieLogs/{YYYY-MM-DD}`
///
/// `totalCalories` denormalize edilmiştir — distribütörün müşteri özet
/// kartlarında hızlı erişim için. `meals` listesi yazıldıktan sonra
/// repository tarafında otomatik hesaplanıp birlikte yazılır.
class CalorieDailyLog {
  /// 'YYYY-MM-DD' — aynı zamanda doküman ID'si.
  final String date;
  final List<Meal> meals;
  final int dailyGoal;
  final int totalCalories;
  final DateTime updatedAt;

  /// `true` ise [dailyGoal], profil (cinsiyet/kilo/boy/yaş/hedef) ve günün
  /// aktivite seviyesinden otomatik hesaplanır — provider, profil veya
  /// aktivite değişirse hedefi tazeler.
  ///
  /// `false` ise kullanıcı manuel girdiği değeri korur, otomatik recompute
  /// ezmeyi denemez.
  ///
  /// Eski (alanı olmayan) kayıtlar `true` sayılır — uygulamanın varsayılan
  /// davranışı otomatik, kullanıcı bilinçli olarak manuel seçmedikçe otomatik
  /// kalır.
  final bool isAutoGoal;

  const CalorieDailyLog({
    required this.date,
    required this.meals,
    required this.dailyGoal,
    required this.totalCalories,
    required this.updatedAt,
    this.isAutoGoal = false,
  });

  /// Tarihten 'YYYY-MM-DD' string üretir.
  static String dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Boş log (yeni gün başlarken). Yeni günler varsayılan olarak otomatik
  /// modda açılır — provider profil bilgileri tamamsa gerçek hedefi hemen
  /// hesaplayıp üzerine yazar.
  factory CalorieDailyLog.empty({
    required DateTime date,
    int dailyGoal = 2000,
    bool isAutoGoal = true,
  }) {
    return CalorieDailyLog(
      date: dateKey(date),
      meals: const [],
      dailyGoal: dailyGoal,
      totalCalories: 0,
      updatedAt: date,
      isAutoGoal: isAutoGoal,
    );
  }

  factory CalorieDailyLog.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final rawMeals = (map['meals'] as List<dynamic>?) ?? const [];
    final meals = rawMeals
        .map((e) => Meal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return CalorieDailyLog(
      date: documentId,
      meals: meals,
      dailyGoal: map['dailyGoal'] as int? ?? 2000,
      totalCalories: map['totalCalories'] as int? ??
          meals.fold<int>(0, (acc, m) => acc + m.calories),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAutoGoal: map['isAutoGoal'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'meals': meals.map((m) => m.toJson()).toList(),
        'dailyGoal': dailyGoal,
        'totalCalories': totalCalories,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isAutoGoal': isAutoGoal,
      };

  CalorieDailyLog copyWith({
    String? date,
    List<Meal>? meals,
    int? dailyGoal,
    int? totalCalories,
    DateTime? updatedAt,
    bool? isAutoGoal,
  }) {
    final newMeals = meals ?? this.meals;
    return CalorieDailyLog(
      date: date ?? this.date,
      meals: newMeals,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      totalCalories:
          totalCalories ?? newMeals.fold<int>(0, (acc, m) => acc + m.calories),
      updatedAt: updatedAt ?? DateTime.now(),
      isAutoGoal: isAutoGoal ?? this.isAutoGoal,
    );
  }

  /// Hedef tutturma oranı (0..1+); hedef 0 ise 0 döner.
  double get progress => dailyGoal > 0 ? totalCalories / dailyGoal : 0.0;
}
