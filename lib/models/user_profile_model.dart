// Bu dosya, kullanıcı profili verilerini temsil eden model sınıfını içerir.
import 'user_role.dart';

class UserProfileModel {
  final String id; // Firebase Auth UID ile aynı olacak
  final String email;
  final UserRole role;
  String? name;
  String? distributorLevel; // Örn: Supervisor, President's Team
  int? monthlyVPTarget; // Aylık Kişisel Hacim Puanı Hedefi
  
  // Onboarding alanları
  bool isOnboarded;
  int? age;
  String? phoneNumber;
  double? weight;
  double? height;
  String? goal;
  DateTime? programStartDate;

  // Yeni eklenen alanlar (Distribütör Takip Aracı)
  String? userGoal; // Enum yerine String: weight_loss, healthy_living, weight_gain (maintain)
  String? wakeTime; // Örn: "07:30"
  String? lunchTime; // Örn: "13:00"
  String? sleepTime; // Örn: "23:00"

  // Müşteri Profil Ayarları alanları
  DateTime? birthDate;
  String? gender; // "Kadın" | "Erkek" | "Belirtmek İstemiyorum"
  String? healthNotes; // max 1000 karakter
  String? allergies; // max 1000 karakter
  String? medications; // max 1000 karakter
  String? assignedDistributorId;
  String? profilePhotoUrl;
  DateTime? profilePhotoUpdatedAt;
  List<String> earnedBadges; // Kazanılan rozet ID'leri
  int? waterDailyGoal; // Günlük su hedefi (ml)

  UserProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.distributorLevel,
    this.monthlyVPTarget,
    this.isOnboarded = false,
    this.age,
    this.phoneNumber,
    this.weight,
    this.height,
    this.goal,
    this.programStartDate,
    this.userGoal,
    this.wakeTime,
    this.lunchTime,
    this.sleepTime,
    this.birthDate,
    this.gender,
    this.healthNotes,
    this.allergies,
    this.medications,
    this.assignedDistributorId,
    this.profilePhotoUrl,
    this.profilePhotoUpdatedAt,
    this.earnedBadges = const [],
    this.waterDailyGoal,
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
      isOnboarded: map['isOnboarded'] ?? false,
      age: map['age'] as int?,
      phoneNumber: map['phoneNumber'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      goal: map['goal'] as String?,
      programStartDate: map['programStartDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['programStartDate'] as int)
          : null,
      userGoal: map['user_goal'] as String?,
      wakeTime: map['wake_time'] as String?,
      lunchTime: map['lunch_time'] as String?,
      sleepTime: map['sleep_time'] as String?,
      birthDate: map['birthDate'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['birthDate'] as int)
          : null,
      gender: map['gender'] as String?,
      healthNotes: map['healthNotes'] as String?,
      allergies: map['allergies'] as String?,
      medications: map['medications'] as String?,
      assignedDistributorId: map['assignedDistributorId'] as String?,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      profilePhotoUpdatedAt: map['profilePhotoUpdatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['profilePhotoUpdatedAt'] as int)
          : null,
      earnedBadges: (map['earnedBadges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      waterDailyGoal: map['waterDailyGoal'] as int?,
    );
  }

  // UserProfileModel'i Firestore'a yazmak için Map'e dönüştürmek için metot
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'email': email,
      'role': role.toString().split('.').last,
      'isOnboarded': isOnboarded,
    };

    if (name != null) map['name'] = name;
    if (distributorLevel != null) map['distributorLevel'] = distributorLevel;
    if (monthlyVPTarget != null) map['monthlyVPTarget'] = monthlyVPTarget;
    if (age != null) map['age'] = age;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (weight != null) map['weight'] = weight;
    if (height != null) map['height'] = height;
    if (goal != null) map['goal'] = goal;
    if (programStartDate != null) map['programStartDate'] = programStartDate!.millisecondsSinceEpoch;
    if (userGoal != null) map['user_goal'] = userGoal;
    if (wakeTime != null) map['wake_time'] = wakeTime;
    if (lunchTime != null) map['lunch_time'] = lunchTime;
    if (sleepTime != null) map['sleep_time'] = sleepTime;
    if (birthDate != null) map['birthDate'] = birthDate!.millisecondsSinceEpoch;
    if (gender != null) map['gender'] = gender;
    if (healthNotes != null) map['healthNotes'] = healthNotes;
    if (allergies != null) map['allergies'] = allergies;
    if (medications != null) map['medications'] = medications;
    if (assignedDistributorId != null) map['assignedDistributorId'] = assignedDistributorId;
    if (profilePhotoUrl != null) map['profilePhotoUrl'] = profilePhotoUrl;
    if (profilePhotoUpdatedAt != null) map['profilePhotoUpdatedAt'] = profilePhotoUpdatedAt!.millisecondsSinceEpoch;
    if (earnedBadges.isNotEmpty) map['earnedBadges'] = earnedBadges;
    if (waterDailyGoal != null) map['waterDailyGoal'] = waterDailyGoal;

    return map;
  }
}
