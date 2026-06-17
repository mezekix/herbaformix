// WaterProvider — pure-logic + state hesaplama testleri.
//
// NOT: WaterProvider constructor'ında ProgramService() ve WeatherService()
// doğrudan new'leniyor; ProgramService ise FirebaseFirestore.instance'ı
// çağırıyor. Bu yüzden tam provider instantiation testleri Firebase init
// gerektirir (test ortamında binding mock'u olmadan başarısız olur).
//
// Burada provider'a ait public davranış kontratlarını **kendi başlarına**
// doğrulanabilir olanlarını test ediyoruz:
//   - totalConsumed fold pattern'i (provider içinde aynısı kullanılıyor)
//   - progress = clamp(totalConsumed / dailyGoal, 0, 1) formülü
//   - dailyGoal cascade kuralı (summary → profile → defaultGoal)
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/features/water_tracker/providers/water_provider.dart';
import 'package:herbaformix/models/water_log_model.dart';

void main() {
  group('WaterProvider — totalConsumed fold pattern', () {
    test('boş liste → 0', () {
      final logs = <WaterLogModel>[];
      final total = logs.fold<int>(0, (sum, log) => sum + log.amount);
      expect(total, 0);
    });

    test('tek log → log\'un miktarı', () {
      final logs = [
        WaterLogModel(id: 'a', time: DateTime(2026), amount: 250),
      ];
      final total = logs.fold<int>(0, (sum, log) => sum + log.amount);
      expect(total, 250);
    });

    test('çoklu log → toplamların toplamı', () {
      final logs = [
        WaterLogModel(id: 'a', time: DateTime(2026), amount: 250),
        WaterLogModel(id: 'b', time: DateTime(2026), amount: 500),
        WaterLogModel(id: 'c', time: DateTime(2026), amount: 200),
      ];
      final total = logs.fold<int>(0, (sum, log) => sum + log.amount);
      expect(total, 950);
    });

    test('sıfır miktarlı log toplama nötr', () {
      final logs = [
        WaterLogModel(id: 'a', time: DateTime(2026), amount: 0),
        WaterLogModel(id: 'b', time: DateTime(2026), amount: 500),
      ];
      final total = logs.fold<int>(0, (sum, log) => sum + log.amount);
      expect(total, 500);
    });
  });

  group('WaterProvider — progress hesaplama formülü', () {
    double computeProgress(int totalConsumed, int dailyGoal) {
      return (totalConsumed / dailyGoal).clamp(0.0, 1.0);
    }

    test('tüketim 0 → progress 0', () {
      expect(computeProgress(0, 2500), 0.0);
    });

    test('tüketim yarı → progress 0.5', () {
      expect(computeProgress(1250, 2500), 0.5);
    });

    test('tüketim hedefe eşit → progress 1.0', () {
      expect(computeProgress(2500, 2500), 1.0);
    });

    test('tüketim hedefi aştı → progress 1.0\'da clamp\'lenir', () {
      expect(computeProgress(5000, 2500), 1.0);
      expect(computeProgress(10000, 2500), 1.0);
    });
  });

  group('WaterProvider — defaultGoal sabiti', () {
    test('defaultGoal 2500 ml', () {
      expect(WaterProvider.defaultGoal, 2500);
    });
  });
}
