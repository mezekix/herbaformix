import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/user_profile_model.dart';
import 'package:herbaformix/models/user_role.dart';

void main() {
  group('UserProfileModel', () {
    final testDate = DateTime(2026, 1, 15, 10, 30);

    Map<String, dynamic> baseMap() => {
          'email': 'user@example.com',
          'role': 'customer',
          'isOnboarded': true,
          'name': 'Ahmet',
          'age': 30,
          'weight': 80.5,
          'height': 175.0,
          'targetWeight': 75.0,
          'userGoal': 'weight_loss',
          'wakeTime': '07:00',
          'lunchTime': '13:00',
          'sleepTime': '23:00',
          'gender': 'Erkek',
          'healthNotes': 'temiz',
          'earnedBadges': <String>['first_entry', 'streak_7'],
          'waterDailyGoal': 2500,
          'fcmToken': 'tok_abc',
          'fcmTokenUpdatedAt': testDate.millisecondsSinceEpoch,
          'birthDate': testDate.millisecondsSinceEpoch,
          'programStartDate': testDate.millisecondsSinceEpoch,
          'profilePhotoUpdatedAt': testDate.millisecondsSinceEpoch,
        };

    group('fromMap()', () {
      test('tüm alanları doğru dönüştürür', () {
        final m = UserProfileModel.fromMap(baseMap(), 'uid_1');
        expect(m.id, 'uid_1');
        expect(m.email, 'user@example.com');
        expect(m.role, UserRole.customer);
        expect(m.isOnboarded, true);
        expect(m.name, 'Ahmet');
        expect(m.age, 30);
        expect(m.weight, 80.5);
        expect(m.height, 175.0);
        expect(m.targetWeight, 75.0);
        expect(m.userGoal, 'weight_loss');
        expect(m.gender, 'Erkek');
        expect(m.earnedBadges, ['first_entry', 'streak_7']);
        expect(m.fcmToken, 'tok_abc');
        expect(m.fcmTokenUpdatedAt, testDate);
        expect(m.birthDate, testDate);
        expect(m.programStartDate, testDate);
        expect(m.profilePhotoUpdatedAt, testDate);
      });

      test('bilinmeyen role → varsayılan customer', () {
        final map = baseMap()..['role'] = 'foo_role';
        final m = UserProfileModel.fromMap(map, 'uid_x');
        expect(m.role, UserRole.customer);
      });

      test('distributor / successCreator / supervisor role çevrimi', () {
        for (final entry in {
          'distributor': UserRole.distributor,
          'successCreator': UserRole.successCreator,
          'supervisor': UserRole.supervisor,
        }.entries) {
          final m =
              UserProfileModel.fromMap(baseMap()..['role'] = entry.key, 'x');
          expect(m.role, entry.value, reason: entry.key);
        }
      });

      test('weight int olarak geldiğinde double\'a çevrilir', () {
        final m =
            UserProfileModel.fromMap(baseMap()..['weight'] = 80, 'uid_int');
        expect(m.weight, 80.0);
      });

      test('eksik alanlar için varsayılan değerler', () {
        final m = UserProfileModel.fromMap(
            {'email': 'a@b.com', 'role': 'customer'}, 'uid_min');
        expect(m.isOnboarded, false);
        expect(m.name, isNull);
        expect(m.weight, isNull);
        expect(m.earnedBadges, isEmpty);
        expect(m.fcmToken, isNull);
      });

      test('earnedBadges yoksa boş liste döner', () {
        final m = UserProfileModel.fromMap({'email': 'x', 'role': 'customer'},
            'uid_no_badges');
        expect(m.earnedBadges, isEmpty);
      });
    });

    group('toMap()', () {
      test('zorunlu alanlar her zaman map\'te', () {
        final m = UserProfileModel(
          id: 'uid_1',
          email: 'a@b.com',
          role: UserRole.customer,
        );
        final map = m.toMap();
        expect(map['email'], 'a@b.com');
        expect(map['role'], 'customer');
        expect(map['isOnboarded'], false);
      });

      test('null opsiyonel alanlar map\'e dahil edilmez', () {
        final m = UserProfileModel(
          id: 'uid_1',
          email: 'a@b.com',
          role: UserRole.customer,
        );
        final map = m.toMap();
        expect(map.containsKey('name'), false);
        expect(map.containsKey('weight'), false);
        expect(map.containsKey('fcmToken'), false);
        expect(map.containsKey('birthDate'), false);
      });

      test('id alanı map\'e dahil edilmez', () {
        final m = UserProfileModel(
          id: 'uid_1',
          email: 'a@b.com',
          role: UserRole.customer,
        );
        expect(m.toMap().containsKey('id'), false);
      });

      test('DateTime alanlar millisecondsSinceEpoch olarak yazılır', () {
        final m = UserProfileModel(
          id: 'uid_1',
          email: 'a@b.com',
          role: UserRole.customer,
          birthDate: testDate,
          fcmTokenUpdatedAt: testDate,
        );
        final map = m.toMap();
        expect(map['birthDate'], testDate.millisecondsSinceEpoch);
        expect(map['fcmTokenUpdatedAt'], testDate.millisecondsSinceEpoch);
      });

      test('earnedBadges boşsa map\'e yazılmaz', () {
        final m = UserProfileModel(
          id: 'uid_1',
          email: 'a@b.com',
          role: UserRole.customer,
        );
        expect(m.toMap().containsKey('earnedBadges'), false);
      });
    });

    group('round-trip fromMap → toMap → fromMap', () {
      test('zengin profil için alanlar korunur', () {
        final original = UserProfileModel.fromMap(baseMap(), 'uid_rt');
        final round = UserProfileModel.fromMap(original.toMap(), 'uid_rt');
        expect(round.email, original.email);
        expect(round.role, original.role);
        expect(round.isOnboarded, original.isOnboarded);
        expect(round.name, original.name);
        expect(round.weight, original.weight);
        expect(round.userGoal, original.userGoal);
        expect(round.earnedBadges, original.earnedBadges);
        expect(round.fcmToken, original.fcmToken);
        expect(round.fcmTokenUpdatedAt, original.fcmTokenUpdatedAt);
        expect(round.birthDate, original.birthDate);
      });
    });

    group('copyWith()', () {
      test('belirtilen alanlar güncellenir, diğerleri korunur', () {
        final original = UserProfileModel.fromMap(baseMap(), 'uid_1');
        final updated = original.copyWith(
          name: 'Mehmet',
          weight: 70.0,
          isOnboarded: false,
        );
        expect(updated.name, 'Mehmet');
        expect(updated.weight, 70.0);
        expect(updated.isOnboarded, false);
        // Korunması gereken alanlar
        expect(updated.id, original.id);
        expect(updated.email, original.email);
        expect(updated.role, original.role);
        expect(updated.age, original.age);
      });

      test('sentinel: copyWith(field: null) ile alan null yapılabilir', () {
        final original = UserProfileModel.fromMap(baseMap(), 'uid_1');
        expect(original.fcmToken, isNotNull);
        final updated = original.copyWith(fcmToken: null);
        expect(updated.fcmToken, isNull);
      });

      test('sentinel: copyWith() argümansız → tüm alanlar aynı kalır', () {
        final original = UserProfileModel.fromMap(baseMap(), 'uid_1');
        final updated = original.copyWith();
        expect(updated.fcmToken, original.fcmToken);
        expect(updated.name, original.name);
        expect(updated.weight, original.weight);
        expect(updated.birthDate, original.birthDate);
      });

      test('earnedBadges güncellemesi yeni listeyi kullanır', () {
        final original = UserProfileModel.fromMap(baseMap(), 'uid_1');
        final updated = original.copyWith(earnedBadges: ['streak_30']);
        expect(updated.earnedBadges, ['streak_30']);
      });
    });
  });
}
