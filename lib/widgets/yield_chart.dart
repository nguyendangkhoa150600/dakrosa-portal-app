import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/solar_model.dart';
import '../theme/app_theme.dart';

class YieldChart extends StatelessWidget {
  final SolarSeries series;
  final bool isSolar; // true: cam, false: xanh dương

  const YieldChart({
    super.key,
    required this.series,
    this.isSolar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (series.points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Không có dữ liệu hiển thị",
            style: TextStyle(color: AppTheme.faint),
          ),
        ),
      );
    }

    final brandColor = isSolar ? const Color(0xFFF85E00) : AppTheme.blue;
    final gradientColors = isSolar
        ? [const Color(0xFFFE8C00).withOpacity(0.35), const Color(0xFFF85E00).withOpacity(0.01)]
        : [AppTheme.blue.withOpacity(0.35), AppTheme.blue.withOpacity(0.01)];

    if (series.kind == 'power') {
      // Vẽ Area Line Chart cho chế độ Ngày (Day)
      final spots = <FlSpot>[];
      for (int i = 0; i < series.points.length; i++) {
        final pt = series.points[i];
        final x = pt.hourFrac ?? (i / (series.points.length - 1));
        // Đổi giá trị từ kW sang MW nếu giá trị lớn để hiển thị gọn
        final y = pt.value >= 1000 ? pt.value / 1000.0 : pt.value;
        spots.add(FlSpot(x, y));
      }

      final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.15;

      return SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxY / 3,
              verticalInterval: 0.25, // Mỗi 6 tiếng
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppTheme.hairline,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: AppTheme.hairline.withOpacity(0.6),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 0.25, // 0.0, 0.25, 0.5, 0.75, 1.0 -> tương ứng 00h, 06h, 12h, 18h, 24h
                  getTitlesWidget: (value, meta) {
                    String text = '';
                    if (value == 0.0) text = '00:00';
                    if (value == 0.25) text = '06:00';
                    if (value == 0.5) text = '12:00';
                    if (value == 0.75) text = '18:00';
                    if (value == 1.0) text = '24:00';
                    if (text.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: AppTheme.faint,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 1.0,
            minY: 0,
            maxY: maxY == 0 ? 10.0 : maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => brandColor,
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((barSpot) {
                    final index = (barSpot.x * (series.points.length - 1)).round().clamp(0, series.points.length - 1);
                    final pt = series.points[index];
                    final String valStr = pt.value >= 1000 
                        ? "${(pt.value / 1000).toStringAsFixed(2)} MW" 
                        : "${pt.value.toStringAsFixed(0)} kW";
                    return LineTooltipItem(
                      "$valStr (${pt.label})",
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: brandColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Vẽ Bar Chart cho chế độ Tháng/Năm (Month/Year)
      final List<BarChartGroupData> barGroups = [];
      final maxVal = series.points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

      for (int i = 0; i < series.points.length; i++) {
        final pt = series.points[i];
        final isCurrent = pt.isCurrent ?? false;
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: pt.value,
                color: isCurrent ? brandColor : brandColor.withOpacity(0.25),
                width: series.period == 'year' ? 18 : 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal * 1.1,
                  color: AppTheme.hairline.withOpacity(0.3),
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= series.points.length) {
                      return const SizedBox.shrink();
                    }
                    final label = series.points[idx].label;
                    
                    // Với chế độ tháng, chỉ hiển thị nhãn cách quãng để đỡ chật chội
                    if (series.period == 'month' && idx % 5 != 0 && idx != series.points.length - 1) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: series.points[idx].isCurrent == true ? AppTheme.ink : AppTheme.faint,
                          fontSize: 10,
                          fontWeight: series.points[idx].isCurrent == true ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => brandColor,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final pt = series.points[groupIndex];
                  final String valStr = pt.value >= 1000
                      ? "${(pt.value / 1000).toStringAsFixed(2)} MWh"
                      : "${pt.value.toStringAsFixed(1)} kWh";
                  return BarTooltipItem(
                    "${pt.label}: $valStr",
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
  }
}
