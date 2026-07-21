import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

class AppNotificationRepository {
  AppNotificationRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _ref(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _ref(userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> markAsRead(String userId, String notificationId) {
    return _ref(userId).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final unread = await _ref(
      userId,
    ).where('isRead', isEqualTo: false).limit(100).get();
    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final document in unread.docs) {
      batch.update(document.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
