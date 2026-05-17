import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  String firstName;
  String lastName;
  String phoneNumber;
  String? email;
  String? address;
  Timestamp firstContactDate;
  String consultantId;
  bool isActive;
  String? notes;
  String? linkedUserId;
  String? inviteCodeId;
  Timestamp? activatedAt;

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
    this.linkedUserId,
    this.inviteCodeId,
    this.activatedAt,
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
      linkedUserId: map['linkedUserId'] as String?,
      inviteCodeId: map['inviteCodeId'] as String?,
      activatedAt: map['activatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
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
    if (linkedUserId != null) map['linkedUserId'] = linkedUserId;
    if (inviteCodeId != null) map['inviteCodeId'] = inviteCodeId;
    if (activatedAt != null) map['activatedAt'] = activatedAt;
    return map;
  }
}