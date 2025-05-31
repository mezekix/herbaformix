// Bu dosya, kullanıcı profili verilerini temsil eden model sınıfını içerir.

class UserProfileModel {
  final String id; // Firebase Auth UID ile aynı olacak
  final String email;
  String? name;
  String? distributorLevel; // Örn: Supervisor, President's Team
  int? monthlyVPTarget; // Aylık Kişisel Hacim Puanı Hedefi

  UserProfileModel({
    required this.id,
    required this.email,
    this.name,
    this.distributorLevel,
    this.monthlyVPTarget,
  });

  // Firestore'dan veri okurken Map'i UserProfileModel'e dönüştürmek için factory constructor
  factory UserProfileModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfileModel(
      id: documentId,
      email: map['email'] ?? '',
      name: map['name'] as String?,
      distributorLevel: map['distributorLevel'] as String?,
      monthlyVPTarget: map['monthlyVPTarget'] as int?,
    );
  }

  // UserProfileModel'i Firestore'a yazmak için Map'e dönüştürmek için metot
  Map<String, dynamic> toMap() {
    return {
      'email': email, // ID zaten doküman ID'si olduğu için map'e eklemiyoruz.
      'name': name,
      'distributorLevel': distributorLevel,
      'monthlyVPTarget': monthlyVPTarget,
    };
  }
}