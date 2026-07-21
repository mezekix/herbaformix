import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/features/notifications/models/app_notification.dart';
import 'package:herbaformix/features/notifications/repositories/app_notification_repository.dart';

void main() {
  late FakeFirebaseFirestore fake;
  late AppNotificationRepository repository;
  const userId = 'user-1';

  setUp(() {
    fake = FakeFirebaseFirestore();
    repository = AppNotificationRepository(firestore: fake);
  });

  test('bildirimleri yeniden eskiye sıralayarak yayınlar', () async {
    final ref = fake.collection('users/$userId/notifications');
    await ref
        .doc('old')
        .set(_notification(type: 'water', createdAt: DateTime(2026, 7, 16)));
    await ref
        .doc('new')
        .set(_notification(type: 'program', createdAt: DateTime(2026, 7, 17)));

    final items = await repository.watchNotifications(userId).first;

    expect(items.map((item) => item.id), ['new', 'old']);
    expect(items.first.type, AppNotificationType.program);
  });

  test('tek bildirimi okundu olarak işaretler', () async {
    final ref = fake.collection('users/$userId/notifications').doc('notice');
    await ref.set(
      _notification(type: 'order', createdAt: DateTime(2026, 7, 17)),
    );

    await repository.markAsRead(userId, 'notice');

    final data = (await ref.get()).data()!;
    expect(data['isRead'], true);
    expect(data['readAt'], isA<Timestamp>());
  });

  test('tüm okunmamış bildirimleri tek batch ile günceller', () async {
    final ref = fake.collection('users/$userId/notifications');
    await ref
        .doc('one')
        .set(_notification(type: 'badge', createdAt: DateTime(2026, 7, 17)));
    await ref
        .doc('two')
        .set(_notification(type: 'message', createdAt: DateTime(2026, 7, 17)));

    await repository.markAllAsRead(userId);

    final snapshot = await ref.get();
    expect(snapshot.docs.every((doc) => doc.data()['isRead'] == true), true);
  });
}

Map<String, dynamic> _notification({
  required String type,
  required DateTime createdAt,
}) {
  return {
    'type': type,
    'title': 'Başlık',
    'body': 'Bildirim gövdesi',
    'createdAt': Timestamp.fromDate(createdAt),
    'isRead': false,
    'readAt': null,
  };
}
