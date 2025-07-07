import 'package:flutter/foundation.dart';

@immutable
class Meal {
  final String id;
  final String name;
  final int calories;
  final DateTime timestamp;

  const Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.timestamp,
  });

  // Veriyi JSON formatına dönüştürmek için
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // JSON formatından veri okumak için
  factory Meal.fromJson(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Meal copyWith({
    String? id,
    String? name,
    int? calories,
    DateTime? timestamp,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
