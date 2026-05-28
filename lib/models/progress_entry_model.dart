import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının bir günde girdiği kilo + vücut ölçümü kaydı.
/// Firestore yolu: users/{userId}/progressEntries/{entryId}
class ProgressEntryModel {
  final String id;
  final DateTime date;
  final double weight; // kg
  final double? bmi; // Vücut Kitle İndeksi
  final double? waist; // bel cm
  final double? hip; // kalça cm
  final double? chest; // göğüs cm
  final double? bodyFat; // yağ oranı %
  final double? muscleMass; // kas kütlesi kg
  final double? arm; // kol cm
  final double? thigh; // bacak cm

  const ProgressEntryModel({
    required this.id,
    required this.date,
    required this.weight,
    this.bmi,
    this.waist,
    this.hip,
    this.chest,
    this.bodyFat,
    this.muscleMass,
    this.arm,
    this.thigh,
  });

  factory ProgressEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return ProgressEntryModel(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      weight: (map['weight'] as num).toDouble(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      chest: (map['chest'] as num?)?.toDouble(),
      bodyFat: (map['bodyFat'] as num?)?.toDouble(),
      muscleMass: (map['muscleMass'] as num?)?.toDouble(),
      arm: (map['arm'] as num?)?.toDouble(),
      thigh: (map['thigh'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      if (bmi != null) 'bmi': bmi,
      if (waist != null) 'waist': waist,
      if (hip != null) 'hip': hip,
      if (chest != null) 'chest': chest,
      if (bodyFat != null) 'bodyFat': bodyFat,
      if (muscleMass != null) 'muscleMass': muscleMass,
      if (arm != null) 'arm': arm,
      if (thigh != null) 'thigh': thigh,
    };
  }

  ProgressEntryModel copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bmi,
    double? waist,
    double? hip,
    double? chest,
    double? bodyFat,
    double? muscleMass,
    double? arm,
    double? thigh,
  }) {
    return ProgressEntryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      chest: chest ?? this.chest,
      bodyFat: bodyFat ?? this.bodyFat,
      muscleMass: muscleMass ?? this.muscleMass,
      arm: arm ?? this.arm,
      thigh: thigh ?? this.thigh,
    );
  }
}
