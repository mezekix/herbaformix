import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/services/firestore_service.dart';

void main() {
  group('FirestoreService role change command', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore: firestore);
    });

    test(
      'writes a deterministic, server-timestamped promote command',
      () async {
        await service.requestCustomerRoleChange(
          requestedBy: 'distributor-1',
          customerId: 'customer-1',
          action: 'promote',
        );

        final snapshot = await firestore
            .collection('roleChangeActions')
            .doc('distributor-1_customer-1')
            .get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data(), containsPair('requestedBy', 'distributor-1'));
        expect(snapshot.data(), containsPair('customerId', 'customer-1'));
        expect(snapshot.data(), containsPair('action', 'promote'));
        expect(snapshot.data()?['createdAt'], isA<Timestamp>());
      },
    );

    test('rejects an unsupported action before writing', () async {
      expect(
        () => service.requestCustomerRoleChange(
          requestedBy: 'distributor-1',
          customerId: 'customer-1',
          action: 'supervisor',
        ),
        throwsArgumentError,
      );
    });
  });
}
