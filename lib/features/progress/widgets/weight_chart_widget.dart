import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_colors.dart';
import '../../../models/progress_entry_model.dart';

enum ChartRange { week, month, threeMonths }

/// Gerçek verilerle çizilen kilo değişimi grafiği.
class WeightChartWidget extends StatefulWidget {
  final List<ProgressEntryModel> entries;
  final double? targetWeight;
  final double? initialWeight; // Profildeki mevcut kilo (ölçüm yokken kullanılır)

  const WeightChartWidget({
    super.key,
    required this.entries,
    this.targetWeight,
    this.initialWeight,
  });

  @override
  State<WeightChartWidget> createState() => _WeightChartWidgetState();
}

class _WeightChartWidgetState extends State<WeightChartWidget> {
  ChartRange _range = ChartRange.month;

  List<ProgressEntryModel> get _filteredEntries {
    final now = DateTime.now();
    final cutoff = switch (_range) {
      ChartRange.week => now.subtract(const Duration(days: 7)),
      ChartRange.month => now.subtract(const Duration(days: 30)),
      ChartRange.threeMonths => now.subtract(const Duration(days: 90)),
    };
    return widget.entries
        .where((e) => e.date.isAfter(cutoff))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    final hasData = entries.length >= 2;

    // Kilo değişimi hesapla
    final totalChange = hasData
        ? widget.entries.last.weight - widget.entries.first.weight
        : 0.0;
    final latestWeight = widget.entries.isNotEmpty
        ? widget.entries.last.weight
        : widget.initialWeight; // ölçüm yoksa profildeki mevcut kilo
    final targetWeight = widget.targetWeight;
    final remaining = (latestWeight != null && targetWeight != null)
        ? latestWeight - targetWeight
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kilo Değişimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                ),
              ),
              _buildRangeTabs(),
            ],
          ),
          const SizedBox(height: 8),

          // Toplam değişim etiketi
          if (hasData)
            Text(
              '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} kg',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: totalChange < 0 ? AppColors.primary : Colors.red,
              ),
            ),
          const SizedBox(height: 16),

          // Grafik
          SizedBox(
            height: 140,
            child: hasData
                ? _buildChart(entries)
                : _buildEmptyState(),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hedef Kilo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    targetWeight != null
                        ? '${targetWeight.toStringAsFixed(1)} kg'
                        : '—',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nightSky,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Kalan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining != null
                        ? '${remaining.abs().toStringAsFixed(1)} kg'
                        : '—',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<ProgressEntryModel> entries) {
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final weights = entries.map((e) => e.weight).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxY = (weights.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade100,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (maxY - minY) / 3,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)} kg',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (entries.length / 3).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d MMM', 'tr_TR').format(entries[idx].date),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: index == spots.length - 1 ? 5 : 3,
                color: index == spots.length - 1
                    ? AppColors.primary
                    : Colors.white,
                strokeWidth: 2,
                strokeColor: AppColors.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.nightSky,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final idx = s.spotIndex;
              final entry = entries[idx];
              return LineTooltipItem(
                '${entry.weight.toStringAsFixed(1)} kg\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: DateFormat('d MMM', 'tr_TR').format(entry.date),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz yeterli veri yok',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
          Text(
            'En az 2 ölçüm ekle',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab('1H', ChartRange.week),
          _buildTab('1A', ChartRange.month),
          _buildTab('3A', ChartRange.threeMonths),
        ],
      ),
    );
  }

  Widget _buildTab(String text, ChartRange range) {
    final isActive = _range == range;
    return GestureDetector(
      onTap: () => setState(() => _range = range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.primary : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
