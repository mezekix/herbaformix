// DistributorCustomerInsights için saf logic testleri — isAtRisk kuralı kritik,
// distribütör panelinde "müşteri kayıyor" uyarısının tek kaynağı bu.
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/distributor_customer_insights.dart';
import 'package:herbaformix/models/progress_entry_model.dart';

void main() {
  group('DistributorCustomerInsights', () {
    final now = DateTime.now();

    DistributorCustomerInsights make({
      ProgressEntryModel? latestProgress,
      List<ProgressEntryModel> progressEntries = const [],
      int todayWaterMl = 0,
      int waterGoalMl = 2000,
      int completedRoutinesLast7Days = 0,
      int totalRoutinesLast7Days = 0,
      DateTime? lastActivityAt,
      DateTime? lastCompletedRoutineAt,
      DateTime? programStartDate,
    }) {
      return DistributorCustomerInsights(
        latestProgress: latestProgress,
        progressEntries: progressEntries,
        todayWaterMl: todayWaterMl,
        waterGoalMl: waterGoalMl,
        completedRoutinesLast7Days: completedRoutinesLast7Days,
        totalRoutinesLast7Days: totalRoutinesLast7Days,
        lastActivityAt: lastActivityAt,
        lastCompletedRoutineAt: lastCompletedRoutineAt,
        programStartDate: programStartDate,
      );
    }

    group('completionRate', () {
      test('toplam 0 ise 0 döner (bölme hatası yok)', () {
        final i = make();
        expect(i.completionRate, 0);
      });

      test('5/10 → 0.5', () {
        final i = make(
            completedRoutinesLast7Days: 5, totalRoutinesLast7Days: 10);
        expect(i.completionRate, 0.5);
      });

      test('hepsi tamam → 1.0', () {
        final i = make(
            completedRoutinesLast7Days: 7, totalRoutinesLast7Days: 7);
        expect(i.completionRate, 1.0);
      });
    });

    group('isAtRisk', () {
      test('programStartDate null → risk yok (henüz program yok)', () {
        final i = make(
          lastCompletedRoutineAt: now.subtract(const Duration(days: 30)),
        );
        expect(i.isAtRisk, false);
      });

      test('grace period içindeyse risk yok (program 3 gün önce başladı)', () {
        final i = make(
          programStartDate: now.subtract(const Duration(days: 3)),
          lastCompletedRoutineAt: null,
        );
        expect(i.isAtRisk, false);
      });

      test('grace bitti + hiç tamamlanmış rutin yok → risk', () {
        final i = make(
          programStartDate: now.subtract(const Duration(days: 30)),
          lastCompletedRoutineAt: null,
        );
        expect(i.isAtRisk, true);
      });

      test('grace bitti + son tamamlanan rutin 4 gün önce → risk yok', () {
        final i = make(
          programStartDate: now.subtract(const Duration(days: 30)),
          lastCompletedRoutineAt: now.subtract(const Duration(days: 4)),
        );
        expect(i.isAtRisk, false);
      });

      test('grace bitti + son tamamlanan rutin 5 gün önce → risk', () {
        final i = make(
          programStartDate: now.subtract(const Duration(days: 30)),
          lastCompletedRoutineAt: now.subtract(const Duration(days: 5)),
        );
        expect(i.isAtRisk, true);
      });

      test('grace bitti + son tamamlanan rutin 10 gün önce → risk', () {
        final i = make(
          programStartDate: now.subtract(const Duration(days: 30)),
          lastCompletedRoutineAt: now.subtract(const Duration(days: 10)),
        );
        expect(i.isAtRisk, true);
      });
    });

    group('totalWeightChange', () {
      ProgressEntryModel entry(double weight, DateTime date) =>
          ProgressEntryModel(id: 'x', date: date, weight: weight);

      test('0 veya 1 kayıt → 0 (değişim yok)', () {
        expect(make().totalWeightChange, 0);
        expect(
            make(progressEntries: [entry(80, now)]).totalWeightChange, 0);
      });

      test('zayıflama (kilo kaybı) → negatif değer', () {
        final i = make(progressEntries: [
          entry(85, now.subtract(const Duration(days: 30))),
          entry(80, now),
        ]);
        expect(i.totalWeightChange, -5.0);
      });

      test('kilo alma → pozitif değer', () {
        final i = make(progressEntries: [
          entry(60, now.subtract(const Duration(days: 30))),
          entry(65, now),
        ]);
        expect(i.totalWeightChange, 5.0);
      });

      test('aynı ağırlık → 0', () {
        final i = make(progressEntries: [
          entry(70, now.subtract(const Duration(days: 30))),
          entry(70, now),
        ]);
        expect(i.totalWeightChange, 0);
      });
    });
  });
}
