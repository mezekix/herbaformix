import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id; // Firestore doküman ID'si
  final String userId; // Bu müşterinin hangi distribütöre ait olduğu (Auth User ID)
  String name;
  String? phone;
  String? email;
  String? address;
  String? notes; // Müşteri hakkında özel notlar
  Timestamp? createdAt; // Müşterinin ne zaman eklendiği
  Timestamp? lastContactedAt; // Son iletişim tarihi (Opsiyonel)

  CustomerModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.createdAt,
    this.lastContactedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomerModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'İsim Yok',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
      lastContactedAt: map['lastContactedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Eğer null ise sunucu zamanını kullan
      'lastContactedAt': lastContactedAt,
    };
  }
}