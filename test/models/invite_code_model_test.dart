// InviteCodeModel birim testleri
// Gereksinim 9.2: Davet kodu veri modeli doğruluğu
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/invite_code_model.dart';

void main() {
  group('InviteCodeModel', () {
    final testDate = DateTime(2024, 6, 15, 10, 30);
    final testTimestamp = Timestamp.fromDate(testDate);

    // Temel fromMap verisi
    Map<String, dynamic> baseMap() => {
          'code': 'AB12CD34',
          'distributorId': 'dist_uid_001',
          'createdAt': testTimestamp,
          'isUsed': false,
          'usedByUserId': null,
        };

    group('fromMap()', () {
      test('tüm alanları doğru şekilde dönüştürür', () {
        final model = InviteCodeModel.fromMap(baseMap(), 'doc_id_1');

        expect(model.id, 'doc_id_1');
        expect(model.code, 'AB12CD34');
        expect(model.distributorId, 'dist_uid_001');
        expect(model.createdAt, testDate);
        expect(model.isUsed, false);
        expect(model.usedByUserId, isNull);
      });

      test('Firestore Timestamp → DateTime dönüşümü doğru çalışır', () {
        final model = InviteCodeModel.fromMap(baseMap(), 'doc_id_1');
        expect(model.createdAt, equals(testDate));
      });

      test('createdAt int olarak geldiğinde DateTime\'a dönüştürür', () {
        final map = baseMap()
          ..['createdAt'] = testDate.millisecondsSinceEpoch;
        final model = InviteCodeModel.fromMap(map, 'doc_id_1');
        expect(model.createdAt,
            DateTime.fromMillisecondsSinceEpoch(testDate.millisecondsSinceEpoch));
      });

      test('createdAt null veya beklenmedik tür geldiğinde çökmez', () {
        final map = baseMap()..['createdAt'] = null;
        expect(() => InviteCodeModel.fromMap(map, 'doc_id_1'), returnsNormally);
      });

      test('isUsed true ve usedByUserId dolu olduğunda doğru dönüştürür', () {
        final map = baseMap()
          ..['isUsed'] = true
          ..['usedByUserId'] = 'customer_uid_999';
        final model = InviteCodeModel.fromMap(map, 'doc_id_2');

        expect(model.isUsed, true);
        expect(model.usedByUserId, 'customer_uid_999');
      });

      test('usedByUserId null olduğunda null döner', () {
        final model = InviteCodeModel.fromMap(baseMap(), 'doc_id_1');
        expect(model.usedByUserId, isNull);
      });

      test('eksik alanlar için varsayılan değerler kullanılır', () {
        final model = InviteCodeModel.fromMap({}, 'doc_id_empty');
        expect(model.code, '');
        expect(model.distributorId, '');
        expect(model.isUsed, false);
        expect(model.usedByUserId, isNull);
      });
    });

    group('toMap()', () {
      test('tüm alanları doğru şekilde map\'e dönüştürür', () {
        final model = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: false,
        );

        final map = model.toMap();

        expect(map['code'], 'AB12CD34');
        expect(map['distributorId'], 'dist_uid_001');
        expect(map['createdAt'], isA<Timestamp>());
        expect((map['createdAt'] as Timestamp).toDate(), testDate);
        expect(map['isUsed'], false);
        expect(map.containsKey('usedByUserId'), false);
      });

      test('usedByUserId null ise map\'e dahil edilmez', () {
        final model = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: false,
          usedByUserId: null,
        );

        final map = model.toMap();
        expect(map.containsKey('usedByUserId'), false);
      });

      test('usedByUserId dolu ise map\'e dahil edilir', () {
        final model = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: true,
          usedByUserId: 'customer_uid_999',
        );

        final map = model.toMap();
        expect(map['usedByUserId'], 'customer_uid_999');
      });

      test('id alanı toMap() çıktısına dahil edilmez', () {
        final model = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: false,
        );

        final map = model.toMap();
        expect(map.containsKey('id'), false);
      });
    });

    group('fromMap() → toMap() round-trip', () {
      test('kullanılmamış kod için round-trip eşdeğerliği', () {
        final original = InviteCodeModel.fromMap(baseMap(), 'doc_id_1');
        final roundTripped =
            InviteCodeModel.fromMap(original.toMap(), 'doc_id_1');

        expect(roundTripped.id, original.id);
        expect(roundTripped.code, original.code);
        expect(roundTripped.distributorId, original.distributorId);
        expect(roundTripped.createdAt, original.createdAt);
        expect(roundTripped.isUsed, original.isUsed);
        expect(roundTripped.usedByUserId, original.usedByUserId);
      });

      test('kullanılmış kod için round-trip eşdeğerliği', () {
        final map = baseMap()
          ..['isUsed'] = true
          ..['usedByUserId'] = 'customer_uid_999';
        final original = InviteCodeModel.fromMap(map, 'doc_id_2');
        final roundTripped =
            InviteCodeModel.fromMap(original.toMap(), 'doc_id_2');

        expect(roundTripped.isUsed, true);
        expect(roundTripped.usedByUserId, 'customer_uid_999');
      });
    });

    group('copyWith()', () {
      test('belirtilen alanları günceller, diğerlerini korur', () {
        final original = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: false,
        );

        final updated = original.copyWith(
          isUsed: true,
          usedByUserId: 'customer_uid_999',
        );

        expect(updated.id, original.id);
        expect(updated.code, original.code);
        expect(updated.distributorId, original.distributorId);
        expect(updated.createdAt, original.createdAt);
        expect(updated.isUsed, true);
        expect(updated.usedByUserId, 'customer_uid_999');
      });
    });

    group('equality', () {
      test('aynı alanlarla oluşturulan iki model eşittir', () {
        final a = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: false,
        );
        final b = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: false,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('farklı alanlarla oluşturulan iki model eşit değildir', () {
        final a = InviteCodeModel(
          id: 'doc_id_1',
          code: 'AB12CD34',
          distributorId: 'dist_uid_001',
          createdAt: testDate,
          isUsed: false,
        );
        final b = a.copyWith(isUsed: true);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
