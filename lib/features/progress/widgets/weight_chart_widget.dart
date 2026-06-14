import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_colors.dart';
import '../../../models/progress_entry_model.dart';
import '../models/measurement_type.dart';

export '../models/measurement_type.dart';

enum ChartRange { week, month, threeMonths }

/// Gerçek verilerle çizilen ölçüm değişimi grafiği.
/// [MeasurementType] parametresiyle kilo, bel, kalça vb. tüm ölçümler için kullanılabilir.
class WeightChartWidget extends StatefulWidget {
  final List<ProgressEntryModel> entries;
  final double? targetWeight;
  final double? initialWeight; // Profildeki mevcut kilo (ölçüm yokken kullanılır)
  final bool isPrivacyMode;
  final MeasurementType measurementType;
  final String? userGoal; // 'weight_loss', 'weight_gain', 'healthy_living'

  const WeightChartWidget({
    super.key,
    required this.entries,
    this.targetWeight,
    this.initialWeight,
    this.isPrivacyMode = false,
    this.measurementType = MeasurementType.weight,
    this.userGoal,
  });

  @override
  State<WeightChartWidget> createState() => _WeightChartWidgetState();
}

class _WeightChartWidgetState extends State<WeightChartWidget> {
  ChartRange _range = ChartRange.month;

  /// Seçili ölçüm türüne göre entry'den değer çeker.
  double? _getValue(ProgressEntryModel entry) =>
      entry.valueFor(widget.measurementType);

  /// Değeri olmayan entry'leri filtreler.
  List<ProgressEntryModel> get _validEntries =>
      widget.entries.where((e) => _getValue(e) != null).toList();

  List<ProgressEntryModel> get _filteredEntries {
    final now = DateTime.now();
    final cutoff = switch (_range) {
      ChartRange.week => now.subtract(const Duration(days: 7)),
      ChartRange.month => now.subtract(const Duration(days: 30)),
      ChartRange.threeMonths => now.subtract(const Duration(days: 90)),
    };
    return _validEntries.where((e) => e.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    final hasData = entries.length >= 2;
    final isWeight = widget.measurementType == MeasurementType.weight;
    final unit = widget.measurementType.unit;

    // Değişim hesapla
    final totalChange = hasData
        ? _getValue(entries.last)! - _getValue(entries.first)!
        : 0.0;
    final latestValue = _validEntries.isNotEmpty
        ? _getValue(_validEntries.last)!
        : (isWeight ? widget.initialWeight : null);
    final targetWeight = isWeight ? widget.targetWeight : null;
    final remaining = (latestValue != null && targetWeight != null)
        ? latestValue - targetWeight
        : null;

    // Hedef bazlı renk: weight_loss ise azalış yeşil, weight_gain ise artış yeşil
    final isWeightLoss = widget.userGoal == 'weight_loss';
    final isGoodChange = isWeightLoss ? totalChange < 0 : totalChange > 0;
    final changeColor = totalChange == 0
        ? AppColors.nightSky
        : (isGoodChange ? AppColors.primary : Colors.red);

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
              Text(
                widget.isPrivacyMode ? 'Gelişim Trendi' : widget.measurementType.label,
                style: const TextStyle(
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
              widget.isPrivacyMode 
                ? 'BMI takibi aktif' 
                : '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} $unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isPrivacyMode ? Colors.grey.shade500 : changeColor,
              ),
            ),
          const SizedBox(height: 16),

          // Grafik
          SizedBox(
            height: 140,
            child: hasData
                ? Semantics(
                    label: _semanticsSummary(entries, totalChange, unit, isWeight),
                    excludeSemantics: true,
                    child: _buildChart(entries),
                  )
                : Semantics(
                    label: '${widget.measurementType.label} grafiği — henüz yeterli veri yok',
                    excludeSemantics: true,
                    child: _buildEmptyState(),
                  ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Footer (sadece kilo için hedef/kalan göster)
          if (isWeight) ...[
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
                      widget.isPrivacyMode 
                        ? '***'
                        : (targetWeight != null ? '${targetWeight.toStringAsFixed(1)} kg' : '—'),
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
                      widget.isPrivacyMode
                          ? '***'
                          : (remaining != null ? '${remaining.abs().toStringAsFixed(1)} kg' : '—'),
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
          ] else ...[
            // Kilo dışı ölçümler için son değer göster
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son Ölçüm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latestValue != null
                          ? '${latestValue.toStringAsFixed(1)} $unit'
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
                      'Değişim',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasData
                          ? '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} $unit'
                          : '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Ekran okuyucu için grafik özetini Türkçe metne çevirir.
  String _semanticsSummary(
    List<ProgressEntryModel> entries,
    double totalChange,
    String unit,
    bool isWeight,
  ) {
    final rangeLabel = switch (_range) {
      ChartRange.week => 'son 1 hafta',
      ChartRange.month => 'son 1 ay',
      ChartRange.threeMonths => 'son 3 ay',
    };
    if (widget.isPrivacyMode) {
      return '${widget.measurementType.label} grafiği — gizlilik modu aktif, $rangeLabel ${entries.length} ölçüm.';
    }
    final first = _getValue(entries.first)!.toStringAsFixed(1);
    final last = _getValue(entries.last)!.toStringAsFixed(1);
    final changeText = totalChange == 0
        ? 'değişim yok'
        : '${totalChange > 0 ? 'artış' : 'azalış'} ${totalChange.abs().toStringAsFixed(1)} $unit';
    final target = (isWeight && widget.targetWeight != null)
        ? ' Hedef ${widget.targetWeight!.toStringAsFixed(1)} $unit.'
        : '';
    return '${widget.measurementType.label} grafiği. $rangeLabel ${entries.length} ölçüm. '
        'İlk $first $unit, son $last $unit. Toplam $changeText.$target';
  }

  Widget _buildChart(List<ProgressEntryModel> entries) {
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _getValue(e.value)!);
    }).toList();

    final values = entries.map((e) => _getValue(e)!).toList();

    // Hedef kilo çizgisi için minY/maxY'yi genişlet
    double rawMin = values.reduce((a, b) => a < b ? a : b);
    double rawMax = values.reduce((a, b) => a > b ? a : b);
    final target = widget.targetWeight;
    if (target != null) {
      if (target < rawMin) rawMin = target;
      if (target > rawMax) rawMax = target;
    }
    final minY = (rawMin - 2).floorToDouble();
    final maxY = (rawMax + 2).ceilToDouble();
    final unit = widget.measurementType.unit;

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
              showTitles: !widget.isPrivacyMode,
              reservedSize: 40,
              interval: (maxY - minY) / 3,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)} $unit',
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
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (target != null && widget.measurementType == MeasurementType.weight)
              HorizontalLine(
                y: target,
                color: Colors.orange.shade400,
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: !widget.isPrivacyMode,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                  labelResolver: (line) => 'Hedef ${target.toStringAsFixed(1)}',
                ),
              ),
          ],
        ),
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
              final value = _getValue(entry);
              final isWeight = widget.measurementType == MeasurementType.weight;
              return LineTooltipItem(
                widget.isPrivacyMode && isWeight
                  ? 'BMI: ${entry.bmi?.toStringAsFixed(1) ?? "—"}\n'
                  : '${value?.toStringAsFixed(1) ?? "—"} $unit\n',
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
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'En az 2 ölçüm ekle',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
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
          _buildTab('1H', ChartRange.week, '1 hafta'),
          _buildTab('1A', ChartRange.month, '1 ay'),
          _buildTab('3A', ChartRange.threeMonths, '3 ay'),
        ],
      ),
    );
  }

  Widget _buildTab(String text, ChartRange range, String semanticLabel) {
    final isActive = _range == range;
    return Semantics(
      button: true,
      selected: isActive,
      label: semanticLabel,
      child: GestureDetector(
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
      ),
    );
  }
}
