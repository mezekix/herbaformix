// ProgressRepository — fake_cloud_firestore ile ölçüm CRUD testleri
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/progress_entry_model.dart';
import 'package:herbaformix/services/repositories/progress_repository.dart';

void main() {
  group('ProgressRepository', () {
    late FakeFirebaseFirestore fake;
    late ProgressRepository repo;
    const userId = 'user_1';

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = ProgressRepository(firestore: fake);
    });

    ProgressEntryModel entry({
      String id = '',
      required DateTime date,
      double weight = 80.0,
      double? waist,
    }) {
      return ProgressEntryModel(
        id: id,
        date: date,
        weight: weight,
        waist: waist,
      );
    }

    test('addProgressEntry yeni ölçüm yazar', () async {
      await repo.addProgressEntry(
        userId,
        entry(date: DateTime(2026, 1, 1), weight: 85.0),
      );

      final snap = await repo.ref(userId).get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data().weight, 85.0);
    });

    test('getProgressEntries kayıtları tarih sırasında akıtır', () async {
      await repo.addProgressEntry(
          userId, entry(date: DateTime(2026, 3, 1), weight: 80));
      await repo.addProgressEntry(
          userId, entry(date: DateTime(2026, 1, 1), weight: 85));
      await repo.addProgressEntry(
          userId, entry(date: DateTime(2026, 2, 1), weight: 82));

      final list = await repo.getProgressEntries(userId, limitDays: 365).first;
      expect(list.length, 3);
      // Tarih artan sırada (en eski → en yeni)
      expect(list[0].weight, 85);
      expect(list[1].weight, 82);
      expect(list[2].weight, 80);
    });

    test('getProgressEntries kullanıcı izolasyonu', () async {
      await repo.addProgressEntry(
          'user_A', entry(date: DateTime(2026, 6, 1), weight: 80));
      await repo.addProgressEntry(
          'user_B', entry(date: DateTime(2026, 6, 1), weight: 60));

      final aEntries =
          await repo.getProgressEntries('user_A', limitDays: 365).first;
      expect(aEntries.length, 1);
      expect(aEntries.first.weight, 80);
    });

    test('updateProgressEntry mevcut belgeyi günceller', () async {
      final doc = await repo.addProgressEntry(
        userId,
        entry(date: DateTime(2026, 1, 1), weight: 80.0),
      );

      final updated = ProgressEntryModel(
        id: doc.id,
        date: DateTime(2026, 1, 1),
        weight: 75.0,
        waist: 90.0,
      );
      await repo.updateProgressEntry(userId, updated);

      final read = await repo.ref(userId).doc(doc.id).get();
      expect(read.data()?.weight, 75.0);
      expect(read.data()?.waist, 90.0);
    });

    test('deleteProgressEntry belgeyi siler', () async {
      final doc = await repo.addProgressEntry(
        userId,
        entry(date: DateTime(2026, 1, 1)),
      );

      await repo.deleteProgressEntry(userId, doc.id);

      final read = await repo.ref(userId).doc(doc.id).get();
      expect(read.exists, false);
    });

    test('round-trip: addProgressEntry → getProgressEntries → aynı alanlar',
        () async {
      final original = entry(
        date: DateTime(2026, 5, 1),
        weight: 78.5,
        waist: 88.0,
      );
      await repo.addProgressEntry(userId, original);

      final list = await repo.getProgressEntries(userId, limitDays: 365).first;
      expect(list.length, 1);
      expect(list.first.weight, 78.5);
      expect(list.first.waist, 88.0);
      expect(list.first.date, DateTime(2026, 5, 1));
    });
  });
}
