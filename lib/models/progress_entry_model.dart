import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının bir günde girdiği kilo + vücut ölçümü kaydı.
/// Firestore yolu: users/{userId}/progressEntries/{entryId}
class ProgressEntryModel {
  final String id;
  final DateTime date;
  final double weight; // kg
  final double? waist; // bel cm
  final double? hip; // kalça cm
  final double? chest; // göğüs cm

  const ProgressEntryModel({
    required this.id,
    required this.date,
    required this.weight,
    this.waist,
    this.hip,
    this.chest,
  });

  factory ProgressEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return ProgressEntryModel(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      weight: (map['weight'] as num).toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      chest: (map['chest'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      if (waist != null) 'waist': waist,
      if (hip != null) 'hip': hip,
      if (chest != null) 'chest': chest,
    };
  }

  ProgressEntryModel copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? waist,
    double? hip,
    double? chest,
  }) {
    return ProgressEntryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      chest: chest ?? this.chest,
    );
  }
}
