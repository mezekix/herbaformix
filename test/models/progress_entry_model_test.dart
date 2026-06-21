import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/features/progress/models/measurement_type.dart';
import 'package:herbaformix/models/progress_entry_model.dart';

void main() {
  group('ProgressEntryModel', () {
    final testDate = DateTime(2026, 3, 1, 8, 0);

    Map<String, dynamic> baseMap() => {
          'date': Timestamp.fromDate(testDate),
          'weight': 78.5,
          'bmi': 25.6,
          'waist': 88.0,
          'belly': 91.0,
          'hip': 100.0,
          'chest': 95.0,
          'bodyFat': 22.0,
          'muscleMass': 32.5,
          'arm': 33.0,
          'thigh': 58.0,
        };

    group('fromMap()', () {
      test('tüm alanları dönüştürür', () {
        final m = ProgressEntryModel.fromMap(baseMap(), 'entry_1');
        expect(m.id, 'entry_1');
        expect(m.date, testDate);
        expect(m.weight, 78.5);
        expect(m.bmi, 25.6);
        expect(m.waist, 88.0);
        expect(m.belly, 91.0);
        expect(m.hip, 100.0);
        expect(m.chest, 95.0);
        expect(m.bodyFat, 22.0);
        expect(m.muscleMass, 32.5);
        expect(m.arm, 33.0);
        expect(m.thigh, 58.0);
      });

      test('sadece zorunlu alanlar (weight + date) verildiğinde null opsiyonlar',
          () {
        final m = ProgressEntryModel.fromMap({
          'date': Timestamp.fromDate(testDate),
          'weight': 80,
        }, 'entry_min');
        expect(m.weight, 80.0); // int → double
        expect(m.bmi, isNull);
        expect(m.waist, isNull);
        expect(m.belly, isNull);
        expect(m.hip, isNull);
        expect(m.bodyFat, isNull);
      });

      test('int olarak gelen ölçümler double\'a dönüştürülür', () {
        final m = ProgressEntryModel.fromMap({
          'date': Timestamp.fromDate(testDate),
          'weight': 75,
          'waist': 90,
          'belly': 92,
        }, 'entry_int');
        expect(m.weight, 75.0);
        expect(m.waist, 90.0);
        expect(m.belly, 92.0);
      });
    });

    group('toMap()', () {
      test('zorunlu alanlar her zaman yazılır', () {
        final m = ProgressEntryModel(
          id: 'e1',
          date: testDate,
          weight: 80.0,
        );
        final map = m.toMap();
        expect(map['date'], isA<Timestamp>());
        expect((map['date'] as Timestamp).toDate(), testDate);
        expect(map['weight'], 80.0);
      });

      test('null opsiyonel alanlar map\'e dahil edilmez', () {
        final m = ProgressEntryModel(
          id: 'e1',
          date: testDate,
          weight: 80.0,
        );
        final map = m.toMap();
        expect(map.containsKey('bmi'), false);
        expect(map.containsKey('waist'), false);
        expect(map.containsKey('belly'), false);
        expect(map.containsKey('hip'), false);
        expect(map.containsKey('bodyFat'), false);
      });

      test('opsiyonel alanlar dolu ise yazılır', () {
        final m = ProgressEntryModel(
          id: 'e1',
          date: testDate,
          weight: 80.0,
          waist: 90.0,
          belly: 91.5,
          hip: 100.0,
        );
        final map = m.toMap();
        expect(map['waist'], 90.0);
        expect(map['belly'], 91.5);
        expect(map['hip'], 100.0);
      });

      test('id alanı map\'e dahil edilmez', () {
        final m = ProgressEntryModel(
          id: 'e1',
          date: testDate,
          weight: 80.0,
        );
        expect(m.toMap().containsKey('id'), false);
      });
    });

    group('round-trip', () {
      test('zengin kayıt için alanlar korunur', () {
        final original = ProgressEntryModel.fromMap(baseMap(), 'rt');
        final round = ProgressEntryModel.fromMap(original.toMap(), 'rt');
        expect(round.weight, original.weight);
        expect(round.bmi, original.bmi);
        expect(round.waist, original.waist);
        expect(round.belly, original.belly);
        expect(round.hip, original.hip);
        expect(round.bodyFat, original.bodyFat);
        expect(round.muscleMass, original.muscleMass);
        expect(round.arm, original.arm);
        expect(round.thigh, original.thigh);
      });
    });

    group('valueFor()', () {
      late ProgressEntryModel m;
      setUp(() {
        m = ProgressEntryModel.fromMap(baseMap(), 'e1');
      });

      test('MeasurementType.weight → weight değeri', () {
        expect(m.valueFor(MeasurementType.weight), 78.5);
      });
      test('MeasurementType.waist → waist değeri', () {
        expect(m.valueFor(MeasurementType.waist), 88.0);
      });
      test('MeasurementType.belly → belly değeri', () {
        expect(m.valueFor(MeasurementType.belly), 91.0);
      });
      test('MeasurementType.hip → hip değeri', () {
        expect(m.valueFor(MeasurementType.hip), 100.0);
      });
      test('MeasurementType.chest → chest değeri', () {
        expect(m.valueFor(MeasurementType.chest), 95.0);
      });
      test('MeasurementType.arm → arm değeri', () {
        expect(m.valueFor(MeasurementType.arm), 33.0);
      });
      test('MeasurementType.thigh → thigh değeri', () {
        expect(m.valueFor(MeasurementType.thigh), 58.0);
      });

      test('opsiyonel alan boş ise null döner', () {
        final empty = ProgressEntryModel(
          id: 'e2',
          date: testDate,
          weight: 80.0,
        );
        expect(empty.valueFor(MeasurementType.waist), isNull);
        expect(empty.valueFor(MeasurementType.belly), isNull);
      });
    });

    group('copyWith()', () {
      test('belirtilen alanı günceller', () {
        final original = ProgressEntryModel.fromMap(baseMap(), 'e1');
        final updated = original.copyWith(weight: 75.0);
        expect(updated.weight, 75.0);
        expect(updated.id, original.id);
        expect(updated.date, original.date);
        expect(updated.waist, original.waist);
      });
    });
  });
}
