import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/step_tracker_provider.dart';

class StepTrackerScreen extends StatefulWidget {
  static const String routeName = 'step-tracker';
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    final userId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == null) return;
    _started = true;
    context.read<StepTrackerProvider>().startListening(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adım Sayar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Hedefi düzenle',
            onPressed: () => _showGoalDialog(context),
          ),
        ],
      ),
      body: Consumer<StepTrackerProvider>(
        builder: (context, tracker, _) {
          if (tracker.status == StepTrackerStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!tracker.isReady) return _UnavailableView(tracker: tracker);

          final remaining = NumberFormat.decimalPattern(
            'tr_TR',
          ).format(tracker.remainingSteps);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProgressCard(tracker: tracker),
              const SizedBox(height: 16),
              Text(
                tracker.remainingSteps == 0
                    ? 'Günlük hedefini tamamladın, harika!'
                    : 'Hedefe $remaining adım kaldı.',
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              const Text(
                'Son 7 gün',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nightSky,
                ),
              ),
              const SizedBox(height: 12),
              _WeeklyChart(
                records: tracker.lastSevenDays,
                goal: tracker.dailyGoal,
              ),
              const SizedBox(height: 20),
              const _LocalOnlyNote(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showGoalDialog(BuildContext context) async {
    final tracker = context.read<StepTrackerProvider>();
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _StepGoalDialog(initialGoal: tracker.dailyGoal, tracker: tracker),
    );
  }
}

class _StepGoalDialog extends StatefulWidget {
  const _StepGoalDialog({required this.initialGoal, required this.tracker});

  final int initialGoal;
  final StepTrackerProvider tracker;

  @override
  State<_StepGoalDialog> createState() => _StepGoalDialogState();
}

class _StepGoalDialogState extends State<_StepGoalDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Günlük adım hedefi'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(suffixText: 'adım'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () async {
            final goal = int.tryParse(_controller.text);
            if (goal == null) return;
            await widget.tracker.setDailyGoal(goal);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.tracker});
  final StepTrackerProvider tracker;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern('tr_TR');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_walk_rounded,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: 10),
          Text(
            format.format(tracker.todaySteps),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '/ ${format.format(tracker.dailyGoal)} adım',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: tracker.progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.records, required this.goal});
  final List<StepDayRecord> records;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final maxSteps = records.fold<int>(
      goal,
      (value, item) => item.steps > value ? item.steps : value,
    );
    return Container(
      height: 175,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textMutedLighter.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: records.map((record) {
          final fraction = record.steps / maxSteps;
          final metGoal = record.steps >= goal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: fraction.clamp(0.03, 1.0).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: metGoal ? AppColors.mango : AppColors.aqua,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.E('tr_TR').format(record.date).substring(0, 1),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.tracker});
  final StepTrackerProvider tracker;

  @override
  Widget build(BuildContext context) {
    final permissionDenied =
        tracker.status == StepTrackerStatus.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk_outlined,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              tracker.errorMessage ?? 'Adım sayar kullanılamıyor.',
              textAlign: TextAlign.center,
            ),
            if (permissionDenied) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: tracker.requestPermissionAgain,
                child: const Text('İzin ver'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocalOnlyNote extends StatelessWidget {
  const _LocalOnlyNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Adım verileri şu an yalnızca bu cihazda tutulur. Telefon yeniden başlatılırsa o günkü sayaç yeni başlangıçtan devam eder.',
      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }
}
