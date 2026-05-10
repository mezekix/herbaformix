import 'package:cloud_firestore/cloud_firestore.dart';

/// Tek bir su alımını temsil eden model.
/// Firestore yolu: users/{userId}/waterLogs/{logId}
class WaterLogModel {
  final String id;
  final DateTime time;
  final int amount; // ml cinsinden

  const WaterLogModel({
    required this.id,
    required this.time,
    required this.amount,
  });

  factory WaterLogModel.fromMap(Map<String, dynamic> map, String id) {
    return WaterLogModel(
      id: id,
      time: (map['time'] as Timestamp).toDate(),
      amount: (map['amount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': Timestamp.fromDate(time),
      'amount': amount,
    };
  }
}
