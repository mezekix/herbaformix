import 'progress_entry_model.dart';

/// Yeni müşteri "koruma süresi": programa başladıktan sonraki bu kadar gün
/// içinde müşteri riskli sayılmaz (onboarding penceresi).
const int kRiskNewCustomerGraceDays = 7;

/// Riskli sayılma eşiği: bu kadar gün üst üste tamamlanmış rutin yoksa riskli.
const int kRiskInactivityDays = 5;

class DistributorCustomerInsights {
  final ProgressEntryModel? latestProgress;
  final List<ProgressEntryModel> progressEntries; // son 90 günlük tüm kayıtlar
  final int todayWaterMl;
  final int waterGoalMl;
  final int completedRoutinesLast7Days;
  final int totalRoutinesLast7Days;
  final DateTime? lastActivityAt;
  final DateTime? lastCompletedRoutineAt;
  final DateTime? programStartDate;

  const DistributorCustomerInsights({
    required this.latestProgress,
    this.progressEntries = const [],
    required this.todayWaterMl,
    required this.waterGoalMl,
    required this.completedRoutinesLast7Days,
    required this.totalRoutinesLast7Days,
    required this.lastActivityAt,
    this.lastCompletedRoutineAt,
    this.programStartDate,
  });

  double get completionRate {
    if (totalRoutinesLast7Days == 0) return 0;
    return completedRoutinesLast7Days / totalRoutinesLast7Days;
  }

  /// "Riskli müşteri" tanımı:
  ///   1. Aktif programı VAR (programStartDate dolu)
  ///   2. Onboarding penceresini (7 gün) geçmiş
  ///   3. Son 5 gündür HİÇ tamamlanmış rutini yok
  ///
  /// Yeni eklenmiş veya programı olmayan müşteriler riskli sayılmaz —
  /// "riskli" gerçekten aksiyon gerektiren bir alt küme olsun diye.
  bool get isAtRisk {
    if (programStartDate == null) return false;

    final now = DateTime.now();
    final daysSinceStart = now.difference(programStartDate!).inDays;
    if (daysSinceStart < kRiskNewCustomerGraceDays) return false;

    if (lastCompletedRoutineAt == null) return true;
    final daysSinceLastRoutine =
        now.difference(lastCompletedRoutineAt!).inDays;
    return daysSinceLastRoutine >= kRiskInactivityDays;
  }

  /// Toplam kilo değişimi (negatif = kayıp).
  double get totalWeightChange {
    if (progressEntries.length < 2) return 0;
    return progressEntries.last.weight - progressEntries.first.weight;
  }
}
