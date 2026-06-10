import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../models/calorie_daily_log.dart';
import '../providers/calorie_provider.dart';

/// Son 30 günün kalori özetini grafik + liste olarak gösterir.
///
/// Her gün için: toplam kalori, hedef, hedefe oran. Hedefin altında yeşil,
/// üstünde turuncu/kırmızı renk kodu.
class CalorieHistoryScreen extends StatefulWidget {
  static const String routeName = 'calorie-history';

  const CalorieHistoryScreen({super.key});

  @override
  State<CalorieHistoryScreen> createState() => _CalorieHistoryScreenState();
}

class _CalorieHistoryScreenState extends State<CalorieHistoryScreen> {
  int _rangeDays = 7;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalorieProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kalori Geçmişi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: StreamBuilder<List<CalorieDailyLog>>(
        stream: provider.watchRecent(days: _rangeDays),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Geçmiş yüklenemedi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }
          final logs = snapshot.data ?? const [];
          // En yeni üstte (provider.watchRecent zaten reverse ediyor).
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _RangeSelector(
                value: _rangeDays,
                onChanged: (v) => setState(() => _rangeDays = v),
              ),
              const SizedBox(height: 16),
              if (logs.isEmpty)
                const _EmptyState()
              else ...[
                _ChartCard(logs: logs),
                const SizedBox(height: 16),
                _StatsCard(logs: logs),
                const SizedBox(height: 16),
                const Text(
                  'Günlük Detay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
                ),
                const SizedBox(height: 8),
                ...logs.map((log) => _DayCard(log: log)),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Aralık seçici ──────────────────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RangeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = const [7, 14, 30];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((d) {
        final selected = d == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: d == options.first || d == options.last ? 0 : 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : Colors.white,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$d gün',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.nightSky,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Grafik ─────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<CalorieDailyLog> logs;
  const _ChartCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    // En eski sola, en yeni sağa
    final ordered = logs.reversed.toList();
    final maxY = ordered
        .map((l) => l.totalCalories)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final goal = ordered.isNotEmpty ? ordered.last.dailyGoal : 2000;
    final yMax = (maxY > goal ? maxY : goal.toDouble()) * 1.15;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Trend',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: yMax > 0 ? yMax : 100,
                barGroups: List.generate(ordered.length, (i) {
                  final l = ordered[i];
                  final over = l.totalCalories > l.dailyGoal;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: l.totalCalories.toDouble(),
                        color: over ? Colors.orange : AppColors.primary,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: goal.toDouble(),
                    color: Colors.grey,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      labelResolver: (_) => 'Hedef $goal',
                    ),
                  ),
                ]),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= ordered.length) {
                          return const SizedBox.shrink();
                        }
                        // Aralık genişse her gün etiketi sıkışır; modulus
                        // ile seyrek göster.
                        final mod = ordered.length > 14 ? 5 : 2;
                        if (i % mod != 0) return const SizedBox.shrink();
                        final parts = ordered[i].date.split('-');
                        if (parts.length != 3) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${parts[2]}.${parts[1]}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── İstatistik kartı ───────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final List<CalorieDailyLog> logs;
  const _StatsCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final activeLogs = logs.where((l) => l.totalCalories > 0).toList();
    final avg = activeLogs.isEmpty
        ? 0
        : (activeLogs.map((l) => l.totalCalories).reduce((a, b) => a + b) /
                activeLogs.length)
            .round();
    final overGoal = logs
        .where((l) => l.totalCalories > l.dailyGoal && l.totalCalories > 0)
        .length;
    final underGoal = logs
        .where((l) =>
            l.totalCalories > 0 && l.totalCalories <= l.dailyGoal)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'Ortalama',
              value: '$avg',
              unit: 'kcal/gün',
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1, height: 36, color: Colors.grey.shade200,
          ),
          Expanded(
            child: _StatBox(
              label: 'Hedef Altı',
              value: '$underGoal',
              unit: 'gün',
              color: Colors.green,
            ),
          ),
          Container(
            width: 1, height: 36, color: Colors.grey.shade200,
          ),
          Expanded(
            child: _StatBox(
              label: 'Hedef Üstü',
              value: '$overGoal',
              unit: 'gün',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        Text(unit,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ─── Gün kartı ──────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final CalorieDailyLog log;
  const _DayCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final parts = log.date.split('-');
    String dateLabel = log.date;
    if (parts.length == 3) {
      try {
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        dateLabel = DateFormat('d MMM EEEE', 'tr_TR').format(dt);
      } catch (_) {}
    }

    final over = log.totalCalories > log.dailyGoal;
    final empty = log.totalCalories == 0;
    final color = empty
        ? Colors.grey
        : over
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.nightSky,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empty
                      ? 'Kayıt yok'
                      : '${log.meals.length} öğün',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.totalCalories} kcal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Hedef: ${log.dailyGoal}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Henüz Geçmiş Yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.nightSky,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Öğün eklemeye başla, geçmişin burada birikecek.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
