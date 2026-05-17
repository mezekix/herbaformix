import 'progress_entry_model.dart';

class DistributorCustomerInsights {
  final ProgressEntryModel? latestProgress;
  final int todayWaterMl;
  final int waterGoalMl;
  final int completedRoutinesLast7Days;
  final int totalRoutinesLast7Days;
  final DateTime? lastActivityAt;

  const DistributorCustomerInsights({
    required this.latestProgress,
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
}