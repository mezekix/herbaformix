// WaterRepository — fake_cloud_firestore ile log + summary testleri

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/water_log_model.dart';
import 'package:herbaformix/models/water_summary_model.dart';
import 'package:herbaformix/services/repositories/water_repository.dart';

void main() {
  group('WaterRepository — logs', () {
    late FakeFirebaseFirestore fake;
    late WaterRepository repo;
    const userId = 'user_1';
    final today = DateTime(2026, 6, 14, 12, 0);

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = WaterRepository(firestore: fake);
    });

    test('addWaterLog yeni log yazar', () async {
      await repo.addWaterLog(
        userId,
        WaterLogModel(id: '', time: today, amount: 250),
      );

      final docs = await fake
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .get();
      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['amount'], 250);
    });

    test('getWaterLogs sadece o güne ait logları döner', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.addWaterLog(userId,
          WaterLogModel(id: '', time: today, amount: 250));
      await repo.addWaterLog(userId,
          WaterLogModel(id: '', time: today, amount: 500));
      await repo.addWaterLog(userId,
          WaterLogModel(id: '', time: yesterday, amount: 1000));

      final logs = await repo.getWaterLogs(userId, today).first;
      expect(logs.length, 2);
      expect(logs.map((l) => l.amount).toSet(), {250, 500});
    });

    test('getWaterLogs farklı kullanıcının kayıtlarını döndürmez', () async {
      await repo.addWaterLog(
          'user_A', WaterLogModel(id: '', time: today, amount: 250));
      await repo.addWaterLog(
          'user_B', WaterLogModel(id: '', time: today, amount: 500));

      final aLogs = await repo.getWaterLogs('user_A', today).first;
      expect(aLogs.length, 1);
      expect(aLogs.first.amount, 250);
    });

    test('updateWaterLog mevcut log\'u günceller', () async {
      await repo.addWaterLog(
          userId, WaterLogModel(id: '', time: today, amount: 250));
      final snap = await fake
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .get();
      final logId = snap.docs.first.id;

      await repo.updateWaterLog(
          userId, WaterLogModel(id: logId, time: today, amount: 500));

      final updated = await fake
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .doc(logId)
          .get();
      expect(updated.data()?['amount'], 500);
    });

    test('deleteWaterLog log\'u siler', () async {
      await repo.addWaterLog(
          userId, WaterLogModel(id: '', time: today, amount: 250));
      final snap = await fake
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .get();
      final logId = snap.docs.first.id;

      await repo.deleteWaterLog(userId, logId);

      final exists = await fake
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .doc(logId)
          .get();
      expect(exists.exists, false);
    });

    test('clearWaterLogs o güne ait tüm logları siler', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.addWaterLog(
          userId, WaterLogModel(id: '', time: today, amount: 250));
      await repo.addWaterLog(
          userId, WaterLogModel(id: '', time: today, amount: 500));
      // dün eklenen log silinmemeli
      await repo.addWaterLog(
          userId, WaterLogModel(id: '', time: yesterday, amount: 1000));

      await repo.clearWaterLogs(userId, today);

      final remaining = await fake
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .get();
      // yalnız dünkü log kalmalı
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.data()['amount'], 1000);
    });
  });

  group('WaterRepository — summaries', () {
    late FakeFirebaseFirestore fake;
    late WaterRepository repo;
    const userId = 'user_1';
    final now = DateTime(2026, 6, 14, 12, 0);

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = WaterRepository(firestore: fake);
    });

    test('setWaterSummary ve getWaterSummary round-trip', () async {
      final summary = WaterSummaryModel(
        id: '2026-06-14',
        targetMl: 2500,
        exerciseLevel: 'moderate',
        weatherTemp: 25.0,
        weatherHumidity: 60.0,
        weatherStatus: 'Clear',
        isWeatherFetched: true,
        updatedAt: now,
      );

      await repo.setWaterSummary(userId, summary);
      final read = await repo.getWaterSummary(userId, '2026-06-14');

      expect(read, isNotNull);
      expect(read!.targetMl, 2500);
      expect(read.exerciseLevel, 'moderate');
      expect(read.weatherTemp, 25.0);
      expect(read.isWeatherFetched, true);
    });

    test('getWaterSummary olmayan tarih için null döner', () async {
      final read = await repo.getWaterSummary(userId, '2099-01-01');
      expect(read, isNull);
    });

    test('watchWaterSummary güncellemeleri akıtır', () async {
      final summary = WaterSummaryModel(
        id: '2026-06-14',
        targetMl: 2500,
        exerciseLevel: 'sedentary',
        updatedAt: now,
      );
      await repo.setWaterSummary(userId, summary);

      final emissions = <WaterSummaryModel?>[];
      final sub = repo.watchWaterSummary(userId, '2026-06-14').listen(
            emissions.add,
          );
      await Future.delayed(const Duration(milliseconds: 10));

      await repo.setWaterSummary(
          userId, summary.copyWith(targetMl: 3000));
      await Future.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last?.targetMl, 3000);
    });

    test('setWaterSummary aynı id ile yazıldığında üzerine yazar', () async {
      await repo.setWaterSummary(
          userId,
          WaterSummaryModel(
            id: '2026-06-14',
            targetMl: 2000,
            exerciseLevel: 'sedentary',
            updatedAt: now,
          ));
      await repo.setWaterSummary(
          userId,
          WaterSummaryModel(
            id: '2026-06-14',
            targetMl: 2800,
            exerciseLevel: 'moderate',
            updatedAt: now,
          ));

      final read = await repo.getWaterSummary(userId, '2026-06-14');
      expect(read!.targetMl, 2800);
      expect(read.exerciseLevel, 'moderate');
    });
  });
}
