// UserProfileRepository — fake_cloud_firestore ile CRUD testleri

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/user_profile_model.dart';
import 'package:herbaformix/models/user_role.dart';
import 'package:herbaformix/services/repositories/user_profile_repository.dart';

void main() {
  group('UserProfileRepository', () {
    late FakeFirebaseFirestore fake;
    late UserProfileRepository repo;

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = UserProfileRepository(firestore: fake);
    });

    UserProfileModel sampleCustomer({
      String id = 'cust_1',
      String email = 'c@b.com',
      String? assignedDistributorId,
    }) {
      return UserProfileModel(
        id: id,
        email: email,
        role: UserRole.customer,
        name: 'Test Müşteri',
        isOnboarded: true,
        weight: 80.0,
        waterDailyGoal: 2500,
        assignedDistributorId: assignedDistributorId,
      );
    }

    test('setUserProfile yeni profili Firestore\'a yazar', () async {
      await repo.setUserProfile(sampleCustomer());

      final doc = await fake.collection('userProfiles').doc('cust_1').get();
      expect(doc.exists, true);
      expect(doc.data()?['email'], 'c@b.com');
      expect(doc.data()?['role'], 'customer');
      expect(doc.data()?['weight'], 80.0);
    });

    test('setUserProfile merge ile mevcut belgeyi günceller', () async {
      await repo.setUserProfile(sampleCustomer());
      // Aynı id ile farklı email kullanıcısı yazılır
      await repo.setUserProfile(sampleCustomer(email: 'yeni@b.com'));

      final doc = await fake.collection('userProfiles').doc('cust_1').get();
      expect(doc.data()?['email'], 'yeni@b.com');
    });

    test('getUserProfile var olan profili döner', () async {
      await repo.setUserProfile(sampleCustomer());

      final p = await repo.getUserProfile('cust_1');
      expect(p, isNotNull);
      expect(p!.id, 'cust_1');
      expect(p.email, 'c@b.com');
      expect(p.role, UserRole.customer);
      expect(p.weight, 80.0);
    });

    test('getUserProfile olmayan id için null döner', () async {
      final p = await repo.getUserProfile('yok');
      expect(p, isNull);
    });

    test('watchUserProfile profil değiştikçe yeni değer akıtır', () async {
      await repo.setUserProfile(sampleCustomer(email: 'baslangic@b.com'));

      final stream = repo.watchUserProfile('cust_1');

      final emissions = <UserProfileModel?>[];
      final sub = stream.listen(emissions.add);

      // İlk emission için bekle
      await Future.delayed(const Duration(milliseconds: 10));

      await repo.setUserProfile(sampleCustomer(email: 'guncel@b.com'));
      await Future.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last?.email, 'guncel@b.com');
    });

    test('getCustomersByDistributorId yalnızca atanmış müşterileri akıtır',
        () async {
      await repo.setUserProfile(
          sampleCustomer(id: 'c1', assignedDistributorId: 'dist_X'));
      await repo.setUserProfile(
          sampleCustomer(id: 'c2', assignedDistributorId: 'dist_X'));
      await repo.setUserProfile(
          sampleCustomer(id: 'c3', assignedDistributorId: 'dist_Y'));
      await repo.setUserProfile(sampleCustomer(id: 'c4')); // atanmamış

      final list = await repo.getCustomersByDistributorId('dist_X').first;
      final ids = list.map((c) => c.id).toSet();
      expect(ids, {'c1', 'c2'});
    });

    test('fetchCustomersByDistributorId tek-shot fetch', () async {
      await repo.setUserProfile(
          sampleCustomer(id: 'a', assignedDistributorId: 'dist_X'));
      await repo.setUserProfile(
          sampleCustomer(id: 'b', assignedDistributorId: 'dist_Y'));

      final result = await repo.fetchCustomersByDistributorId('dist_X');
      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('disconnectDistributor assignedDistributorId alanını siler', () async {
      await repo.setUserProfile(
          sampleCustomer(id: 'c1', assignedDistributorId: 'dist_X'));

      await repo.disconnectDistributor('c1');

      final doc = await fake.collection('userProfiles').doc('c1').get();
      expect(doc.data()?.containsKey('assignedDistributorId'), false);
    });

    test('saveEarnedBadges rozet listesini günceller', () async {
      await repo.setUserProfile(sampleCustomer());
      await repo.saveEarnedBadges('cust_1', ['first_entry', 'streak_7']);

      final p = await repo.getUserProfile('cust_1');
      expect(p!.earnedBadges, ['first_entry', 'streak_7']);
    });

    test('getWaterDailyGoal mevcut değeri okur', () async {
      await repo.setUserProfile(sampleCustomer());
      final goal = await repo.getWaterDailyGoal('cust_1');
      expect(goal, 2500);
    });

    test('getWaterDailyGoal olmayan kullanıcı için null döner', () async {
      final goal = await repo.getWaterDailyGoal('yok');
      expect(goal, isNull);
    });

    test('setWaterDailyGoal hedefi günceller', () async {
      await repo.setUserProfile(sampleCustomer());
      await repo.setWaterDailyGoal('cust_1', 3000);

      final goal = await repo.getWaterDailyGoal('cust_1');
      expect(goal, 3000);
    });

    group('setFcmToken', () {
      test('boş olmayan token alanları yazar', () async {
        await repo.setUserProfile(sampleCustomer());
        await repo.setFcmToken('cust_1', 'token_abc');

        final doc = await fake.collection('userProfiles').doc('cust_1').get();
        expect(doc.data()?['fcmToken'], 'token_abc');
        expect(doc.data()?['fcmTokenUpdatedAt'], isA<Timestamp>());
      });

      test('null geçilirse alanları siler', () async {
        await repo.setUserProfile(sampleCustomer());
        await repo.setFcmToken('cust_1', 'tok');
        await repo.setFcmToken('cust_1', null);

        final doc = await fake.collection('userProfiles').doc('cust_1').get();
        expect(doc.data()?.containsKey('fcmToken'), false);
        expect(doc.data()?.containsKey('fcmTokenUpdatedAt'), false);
      });

      test('boş string geçilirse alanları siler', () async {
        await repo.setUserProfile(sampleCustomer());
        await repo.setFcmToken('cust_1', 'tok');
        await repo.setFcmToken('cust_1', '');

        final doc = await fake.collection('userProfiles').doc('cust_1').get();
        expect(doc.data()?.containsKey('fcmToken'), false);
      });
    });
  });
}
