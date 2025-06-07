import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id; // Firestore doküman ID'si
  String firstName; // Müşteri adı
  String lastName; // Müşteri soyadı
  String phoneNumber; // Telefon numarası
  String? email; // E-posta adresi, opsiyonel
  String? address; // Adres, opsiyonel
  Timestamp firstContactDate; // İlk temas tarihi
  String
  consultantId; // Bu müşteriden sorumlu danışmanın users koleksiyonundaki ID'si
  bool isActive; // Müşteri aktif mi, takibi devam ediyor mu?
  String? notes; // Müşteriyle ilgili genel notlar

  CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.address,
    required this.firstContactDate,
    required this.consultantId,
    this.isActive = true,
    this.notes,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomerModel(
      id: documentId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] as String?,
      address: map['address'] as String?,
      firstContactDate:
          map['firstContactDate'] as Timestamp? ?? Timestamp.now(),
      consultantId: map['consultantId'] ?? '',
      isActive: map['isActive'] ?? true,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'firstContactDate': firstContactDate,
      'consultantId': consultantId,
      'isActive': isActive,
      'notes': notes,
    };
  }
}
