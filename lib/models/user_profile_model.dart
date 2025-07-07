// Bu dosya, kullanıcı profili verilerini temsil eden model sınıfını içerir.
import 'user_role.dart';

class UserProfileModel {
  final String id; // Firebase Auth UID ile aynı olacak
  final String email;
  final UserRole role;
  String? name;
  String? distributorLevel; // Örn: Supervisor, President's Team
  int? monthlyVPTarget; // Aylık Kişisel Hacim Puanı Hedefi

  UserProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.distributorLevel,
    this.monthlyVPTarget,
  });

  // Firestore'dan veri okurken Map'i UserProfileModel'e dönüştürmek için factory constructor
  factory UserProfileModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return UserProfileModel(
      id: documentId,
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.customer, // Varsayılan rol
      ),
      name: map['name'] as String?,
      distributorLevel: map['distributorLevel'] as String?,
      monthlyVPTarget: map['monthlyVPTarget'] as int?,
    );
  }

  // UserProfileModel'i Firestore'a yazmak için Map'e dönüştürmek için metot
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.toString().split('.').last,
      'name': name,
      'distributorLevel': distributorLevel,
      'monthlyVPTarget': monthlyVPTarget,
    };
  }
}
