import 'progress_entry_model.dart';

class DistributorCustomerInsights {
  final ProgressEntryModel? latestProgress;
  final List<ProgressEntryModel> progressEntries; // son 90 günlük tüm kayıtlar
  final int todayWaterMl;
  final int waterGoalMl;
  final int completedRoutinesLast7Days;
  final int totalRoutinesLast7Days;
  final DateTime? lastActivityAt;

  const DistributorCustomerInsights({
    required this.latestProgress,
    this.progressEntries = const [],
    required this.todayWaterMl,
    required this.waterGoalMl,
    required this.completedRoutinesLast7Days,
    required this.totalRoutinesLast7Days,
    required this.lastActivityAt,
  });

  double get completionRate {
    if (totalRoutinesLast7Days == 0) return 0;
    return completedRoutinesLast7Days / totalRoutinesLast7Days;
  }

  bool get isAtRisk {
    final inactiveForTooLong = lastActivityAt == null ||
        DateTime.now().difference(lastActivityAt!).inDays >= 3;
    return inactiveForTooLong || completionRate < 0.5;
  }

  /// Toplam kilo değişimi (negatif = kayıp).
  double get totalWeightChange {
    if (progressEntries.length < 2) return 0;
    return progressEntries.last.weight - progressEntries.first.weight;
  }
}