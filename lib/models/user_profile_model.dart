// Bu dosya, kullanıcı profili verilerini temsil eden model sınıfını içerir.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Kullanıcı profili — **immutable**.
///
/// State güncellemeleri için `copyWith` kullanın. Doğrudan alan ataması yapmayın
/// (Dart compile-time'da engelleyecektir; tüm alanlar `final`).
///
/// ```dart
/// final updated = oldProfile.copyWith(name: 'Yeni Ad', isOnboarded: true);
/// ```
class UserProfileModel {
  final String id; // Firebase Auth UID ile aynı
  final String email;
  final UserRole role;
  final String? name;
  final String? distributorLevel; // Örn: Supervisor, President's Team
  final int? monthlyVPTarget; // Aylık Kişisel Hacim Puanı Hedefi

  // Onboarding alanları
  final bool isOnboarded;
  final int? age;
  final String? phoneNumber;
  final double? weight;
  final double? height;
  final double? targetWeight; // Hedef kilo (kg) — sayısal alan
  final DateTime? programStartDate;

  // Yeni eklenen alanlar (Distribütör Takip Aracı)
  final String?
  userGoal; // String: weight_loss, healthy_living, weight_gain, skin_care
  final String? wakeTime; // Örn: "07:30"
  final String? lunchTime; // Örn: "13:00"
  final String? sleepTime; // Örn: "23:00"

  // Müşteri Profil Ayarları
  final DateTime? birthDate;
  final String? gender; // "Kadın" | "Erkek"
  final String? healthNotes; // max 1000 karakter
  final String? allergies; // max 1000 karakter
  final String? medications; // max 1000 karakter
  final String? assignedDistributorId;
  final String? profilePhotoUrl;
  final DateTime? profilePhotoUpdatedAt;
  final List<String> earnedBadges; // Kazanılan rozet ID'leri
  final int? waterDailyGoal; // Günlük su hedefi (ml)
  final int? waterMinLimit; // Distribütörün koyduğu min limit (ml)
  final int? waterMaxLimit; // Distribütörün koyduğu max limit (ml)
  final String? distributorRequestStatus; // null / 'pending' / 'approved'

  // Push bildirimleri (Faz 14)
  final String? fcmToken; // Cihazın güncel FCM token'ı
  final DateTime? fcmTokenUpdatedAt; // Son token güncelleme zamanı
  final Map<String, bool>
  notificationSettings; // Faz 23 bildirim türü tercihleri

  const UserProfileModel({
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
    this.targetWeight,
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
    this.waterMinLimit,
    this.waterMaxLimit,
    this.distributorRequestStatus,
    this.fcmToken,
    this.fcmTokenUpdatedAt,
    this.notificationSettings = const {
      'newProgram': true,
      'water': true,
      'measurement': true,
      'badge': true,
      'dailyMessages': true,
      'followUps': true,
      'order': true,
      'challenge': true,
    },
  });

  // ── Sentinel ────────────────────────────────────────────────────────────────
  // copyWith içinde "alanı null yap" ile "alanı değiştirme" senaryolarını
  // ayırt edebilmek için sentinel kullanılır.
  static const Object _unset = Object();

  /// İmmutable profili istenen alanlar değişmiş yeni bir kopyayla döndürür.
  ///
  /// Alanı **null** yapmak için `null` geçin (sentinel sayesinde ayırt edilir):
  /// ```dart
  /// profile.copyWith(profilePhotoUrl: null) // → fotoğraf URL'i silinir
  /// profile.copyWith() // → hiçbir alan değişmez
  /// ```
  UserProfileModel copyWith({
    String? id,
    String? email,
    UserRole? role,
    Object? name = _unset,
    Object? distributorLevel = _unset,
    Object? monthlyVPTarget = _unset,
    bool? isOnboarded,
    Object? age = _unset,
    Object? phoneNumber = _unset,
    Object? weight = _unset,
    Object? height = _unset,
    Object? targetWeight = _unset,
    Object? programStartDate = _unset,
    Object? userGoal = _unset,
    Object? wakeTime = _unset,
    Object? lunchTime = _unset,
    Object? sleepTime = _unset,
    Object? birthDate = _unset,
    Object? gender = _unset,
    Object? healthNotes = _unset,
    Object? allergies = _unset,
    Object? medications = _unset,
    Object? assignedDistributorId = _unset,
    Object? profilePhotoUrl = _unset,
    Object? profilePhotoUpdatedAt = _unset,
    List<String>? earnedBadges,
    Object? waterDailyGoal = _unset,
    Object? waterMinLimit = _unset,
    Object? waterMaxLimit = _unset,
    Object? distributorRequestStatus = _unset,
    Object? fcmToken = _unset,
    Object? fcmTokenUpdatedAt = _unset,
    Map<String, bool>? notificationSettings,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: identical(name, _unset) ? this.name : name as String?,
      distributorLevel: identical(distributorLevel, _unset)
          ? this.distributorLevel
          : distributorLevel as String?,
      monthlyVPTarget: identical(monthlyVPTarget, _unset)
          ? this.monthlyVPTarget
          : monthlyVPTarget as int?,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      age: identical(age, _unset) ? this.age : age as int?,
      phoneNumber: identical(phoneNumber, _unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      weight: identical(weight, _unset) ? this.weight : weight as double?,
      height: identical(height, _unset) ? this.height : height as double?,
      targetWeight: identical(targetWeight, _unset)
          ? this.targetWeight
          : targetWeight as double?,
      programStartDate: identical(programStartDate, _unset)
          ? this.programStartDate
          : programStartDate as DateTime?,
      userGoal: identical(userGoal, _unset)
          ? this.userGoal
          : userGoal as String?,
      wakeTime: identical(wakeTime, _unset)
          ? this.wakeTime
          : wakeTime as String?,
      lunchTime: identical(lunchTime, _unset)
          ? this.lunchTime
          : lunchTime as String?,
      sleepTime: identical(sleepTime, _unset)
          ? this.sleepTime
          : sleepTime as String?,
      birthDate: identical(birthDate, _unset)
          ? this.birthDate
          : birthDate as DateTime?,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      healthNotes: identical(healthNotes, _unset)
          ? this.healthNotes
          : healthNotes as String?,
      allergies: identical(allergies, _unset)
          ? this.allergies
          : allergies as String?,
      medications: identical(medications, _unset)
          ? this.medications
          : medications as String?,
      assignedDistributorId: identical(assignedDistributorId, _unset)
          ? this.assignedDistributorId
          : assignedDistributorId as String?,
      profilePhotoUrl: identical(profilePhotoUrl, _unset)
          ? this.profilePhotoUrl
          : profilePhotoUrl as String?,
      profilePhotoUpdatedAt: identical(profilePhotoUpdatedAt, _unset)
          ? this.profilePhotoUpdatedAt
          : profilePhotoUpdatedAt as DateTime?,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      waterDailyGoal: identical(waterDailyGoal, _unset)
          ? this.waterDailyGoal
          : waterDailyGoal as int?,
      waterMinLimit: identical(waterMinLimit, _unset)
          ? this.waterMinLimit
          : waterMinLimit as int?,
      waterMaxLimit: identical(waterMaxLimit, _unset)
          ? this.waterMaxLimit
          : waterMaxLimit as int?,
      distributorRequestStatus: identical(distributorRequestStatus, _unset)
          ? this.distributorRequestStatus
          : distributorRequestStatus as String?,
      fcmToken: identical(fcmToken, _unset)
          ? this.fcmToken
          : fcmToken as String?,
      fcmTokenUpdatedAt: identical(fcmTokenUpdatedAt, _unset)
          ? this.fcmTokenUpdatedAt
          : fcmTokenUpdatedAt as DateTime?,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  // Firestore'dan veri okurken Map'i UserProfileModel'e dönüştürmek için factory
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
      monthlyVPTarget: (map['monthlyVPTarget'] as num?)?.toInt(),
      isOnboarded: map['isOnboarded'] ?? false,
      age: (map['age'] as num?)?.toInt(),
      phoneNumber: map['phoneNumber'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      programStartDate: _parseDate(map['programStartDate']),
      userGoal: map['userGoal'] as String?,
      wakeTime: map['wakeTime'] as String?,
      lunchTime: map['lunchTime'] as String?,
      sleepTime: map['sleepTime'] as String?,
      birthDate: _parseDate(map['birthDate']),
      gender: map['gender'] as String?,
      healthNotes: map['healthNotes'] as String?,
      allergies: map['allergies'] as String?,
      medications: map['medications'] as String?,
      assignedDistributorId: map['assignedDistributorId'] as String?,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      profilePhotoUpdatedAt: _parseDate(map['profilePhotoUpdatedAt']),
      earnedBadges:
          (map['earnedBadges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      waterDailyGoal: (map['waterDailyGoal'] as num?)?.toInt(),
      waterMinLimit: (map['waterMinLimit'] as num?)?.toInt(),
      waterMaxLimit: (map['waterMaxLimit'] as num?)?.toInt(),
      distributorRequestStatus: map['distributorRequestStatus'] as String?,
      fcmToken: map['fcmToken'] as String?,
      fcmTokenUpdatedAt: _parseDate(map['fcmTokenUpdatedAt']),
      notificationSettings: map['notificationSettings'] != null
          ? Map<String, bool>.from(map['notificationSettings'] as Map)
          : const {
              'newProgram': true,
              'water': true,
              'measurement': true,
              'badge': true,
              'dailyMessages': true,
              'followUps': true,
              'order': true,
              'challenge': true,
            },
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Timestamp) return value.toDate();
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return (value as dynamic).toDate() as DateTime?;
      } catch (_) {}
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return null;
  }

  // UserProfileModel'i Firestore'a yazmak için Map'e dönüştürür
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
    if (targetWeight != null) map['targetWeight'] = targetWeight;
    if (programStartDate != null) {
      map['programStartDate'] = programStartDate!.millisecondsSinceEpoch;
    }
    // Standart yazım: camelCase.
    if (userGoal != null) map['userGoal'] = userGoal;
    if (wakeTime != null) map['wakeTime'] = wakeTime;
    if (lunchTime != null) map['lunchTime'] = lunchTime;
    if (sleepTime != null) map['sleepTime'] = sleepTime;
    if (birthDate != null) {
      map['birthDate'] = birthDate!.millisecondsSinceEpoch;
    }
    if (gender != null) map['gender'] = gender;
    if (healthNotes != null) map['healthNotes'] = healthNotes;
    if (allergies != null) map['allergies'] = allergies;
    if (medications != null) map['medications'] = medications;
    if (assignedDistributorId != null) {
      map['assignedDistributorId'] = assignedDistributorId;
    }
    if (profilePhotoUrl != null) map['profilePhotoUrl'] = profilePhotoUrl;
    if (profilePhotoUpdatedAt != null) {
      map['profilePhotoUpdatedAt'] =
          profilePhotoUpdatedAt!.millisecondsSinceEpoch;
    }
    if (earnedBadges.isNotEmpty) map['earnedBadges'] = earnedBadges;
    if (waterDailyGoal != null) map['waterDailyGoal'] = waterDailyGoal;
    if (waterMinLimit != null) map['waterMinLimit'] = waterMinLimit;
    if (waterMaxLimit != null) map['waterMaxLimit'] = waterMaxLimit;
    if (distributorRequestStatus != null) {
      map['distributorRequestStatus'] = distributorRequestStatus;
    }
    if (fcmToken != null) map['fcmToken'] = fcmToken;
    if (fcmTokenUpdatedAt != null) {
      map['fcmTokenUpdatedAt'] = fcmTokenUpdatedAt!.millisecondsSinceEpoch;
    }
    map['notificationSettings'] = notificationSettings;

    return map;
  }
}
