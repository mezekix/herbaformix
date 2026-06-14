import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_profile_model.dart';

/// `/userProfiles/{uid}` koleksiyonu — kullanıcı profili CRUD'u.
///
/// Distribütör-müşteri bağlantısı ([assignedDistributorId]), rozet kaydı,
/// su hedefi gibi profil üzerindeki yardımcı yazımlar da buradadır.
class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<UserProfileModel> get ref => _db
      .collection('userProfiles')
      .withConverter<UserProfileModel>(
        fromFirestore: (s, _) => UserProfileModel.fromMap(s.data()!, s.id),
        toFirestore: (m, _) => m.toMap(),
      );

  Future<void> setUserProfile(UserProfileModel userProfile) async {
    await ref.doc(userProfile.id).set(userProfile, SetOptions(merge: true));
  }

  Future<UserProfileModel?> getUserProfile(String userId) async {
    final d = await ref.doc(userId).get();
    return d.exists ? d.data() : null;
  }

  Stream<UserProfileModel?> watchUserProfile(String userId) {
    return ref.doc(userId).snapshots().map((doc) =>
        doc.exists ? doc.data() : null);
  }

  Future<UserProfileModel?> getDistributorProfile(String distributorId) async {
    try {
      final doc = await ref.doc(distributorId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('getDistributorProfile hatası: $e');
      return null;
    }
  }

  Stream<List<UserProfileModel>> getCustomersByDistributorId(
    String distributorId,
  ) {
    return ref
        .where('assignedDistributorId', isEqualTo: distributorId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<UserProfileModel>> fetchCustomersByDistributorId(
    String distributorId,
  ) async {
    final s = await ref
        .where('assignedDistributorId', isEqualTo: distributorId)
        .get();
    return s.docs.map((d) => d.data()).toList();
  }

  Future<void> disconnectDistributor(String customerUserId) async {
    try {
      await ref
          .doc(customerUserId)
          .update({'assignedDistributorId': FieldValue.delete()});
    } catch (e) {
      debugPrint('disconnectDistributor hatası: $e');
      throw Exception('Distribütör bağlantısı kesilemedi: $e');
    }
  }

  Future<void> saveEarnedBadges(String userId, List<String> badgeIds) async {
    await ref.doc(userId).update({'earnedBadges': badgeIds});
  }

  Future<int?> getWaterDailyGoal(String userId) async {
    final doc = await ref.doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?.toMap()['waterDailyGoal'] as int?;
  }

  Future<void> setWaterDailyGoal(String userId, int goal) async {
    await ref.doc(userId).update({'waterDailyGoal': goal});
  }

  /// Cihazın güncel FCM token'ını kullanıcı profiline yazar.
  /// Token boş geçilirse alan siler (kullanıcı çıkış yaptığında).
  Future<void> setFcmToken(String userId, String? token) async {
    if (token == null || token.isEmpty) {
      await ref.doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
    } else {
      await ref.doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}
