import 'package:cloud_firestore/cloud_firestore.dart';

/// Günlük su hedefini ve dinamik hesaplama parametrelerini temsil eden model.
/// Firestore Yolu: users/{userId}/waterSummaries/{dateStr} (Örn: waterSummaries/2026-05-20)
class WaterSummaryModel {
  final String id; // Tarih string'i (YYYY-MM-DD)
  final int targetMl;
  final String exerciseLevel;
  final double? weatherTemp;
  final double? weatherHumidity;
  final String? weatherStatus;
  final bool isWeatherFetched;
  final DateTime updatedAt;

  const WaterSummaryModel({
    required this.id,
    required this.targetMl,
    required this.exerciseLevel,
    this.weatherTemp,
    this.weatherHumidity,
    this.weatherStatus,
    this.isWeatherFetched = false,
    required this.updatedAt,
  });

  factory WaterSummaryModel.fromMap(Map<String, dynamic> map, String id) {
    return WaterSummaryModel(
      id: id,
      targetMl: (map['targetMl'] as num).toInt(),
      exerciseLevel: map['exerciseLevel'] as String? ?? 'sedentary',
      weatherTemp: (map['weatherTemp'] as num?)?.toDouble(),
      weatherHumidity: (map['weatherHumidity'] as num?)?.toDouble(),
      weatherStatus: map['weatherStatus'] as String?,
      isWeatherFetched: map['isWeatherFetched'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetMl': targetMl,
      'exerciseLevel': exerciseLevel,
      'weatherTemp': weatherTemp,
      'weatherHumidity': weatherHumidity,
      'weatherStatus': weatherStatus,
      'isWeatherFetched': isWeatherFetched,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WaterSummaryModel copyWith({
    String? id,
    int? targetMl,
    String? exerciseLevel,
    double? weatherTemp,
    double? weatherHumidity,
    String? weatherStatus,
    bool? isWeatherFetched,
    DateTime? updatedAt,
  }) {
    return WaterSummaryModel(
      id: id ?? this.id,
      targetMl: targetMl ?? this.targetMl,
      exerciseLevel: exerciseLevel ?? this.exerciseLevel,
      weatherTemp: weatherTemp ?? this.weatherTemp,
      weatherHumidity: weatherHumidity ?? this.weatherHumidity,
      weatherStatus: weatherStatus ?? this.weatherStatus,
      isWeatherFetched: isWeatherFetched ?? this.isWeatherFetched,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
