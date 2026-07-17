import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/solar_model.dart';
import '../../theme/app_theme.dart';
import '../yield_chart.dart';
import '../../services/localization_service.dart';

class PerformanceTab extends StatelessWidget {
  final SolarData? solarData;
  final SolarSeries? solarSeries;
  final String solarPeriod;
  final ValueChanged<String> onPeriodChanged;

  const PerformanceTab({
    Key? key,
    required this.solarData,
    required this.solarSeries,
    required this.solarPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  double? _estimateIrradiance() {
    if (solarData == null || solarData!.currentKw == null || solarData!.capacityKwp == null || solarData!.capacityKwp! <= 0) {
      return null;
    }
    final ratio = solarData!.currentKw! / solarData!.capacityKwp!;
    return (ratio * 1000).clamp(0.0, 1200.0);
  }

  String _formatNumber(BuildContext context, double value, int fractionDigits) {
    final isVi = appLocale.value.languageCode == 'vi';
    String str = value.toStringAsFixed(fractionDigits);
    List<String> parts = str.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    final separator = isVi ? '.' : ',';
    final decimalSeparator = isVi ? ',' : '.';
    
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match m) => "${m[1]}$separator");
    
    if (decimalPart.isNotEmpty) {
      return "$integerPart$decimalSeparator$decimalPart";
    }
    return integerPart;
  }

  Widget _buildYieldSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('yieldOverTime'),
                  style: const TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.hairline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildPeriodTab(context, "day", context.tr('periodDay')),
                    _buildPeriodTab(context, "month", context.tr('periodMonth')),
                    _buildPeriodTab(context, "year", context.tr('periodYear')),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          if (solarSeries != null)
            YieldChart(series: solarSeries!, isSolar: true)
          else
            const SizedBox(
              height: 200,
              child: Center(child: CupertinoActivityIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(BuildContext context, String k, String label) {
    final active = solarPeriod == k;
    return GestureDetector(
      onTap: () => onPeriodChanged(k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.ink : AppTheme.faint,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildDoubleYieldCards(BuildContext context) {
    double monthVal = 3.77;
    double annualVal = 259.4;
    double lifetimeGwh = 2.09;
    double capacityKwp = 6.14;

    if (solarData != null) {
      final m = solarData!.monthKwh ?? 3770;
      final y = solarData!.yearKwh ?? 259400;
      monthVal = m >= 1000 ? m / 1000 : m;
      annualVal = y >= 1000 ? y / 1000 : y;
      lifetimeGwh = (solarData!.lifetimeKwh ?? 2090000.0) / 1000000.0;
      capacityKwp = (solarData!.capacityKwp ?? 6140.0) / 1000.0;
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.calendar,
                  title: context.trArgs('yieldMonthLabel', ["07"]),
                  value: "${_formatNumber(context, monthVal, 2)} MWh",
                  goal: context.trArgs('yieldGoalMwh', ["4.20"]),
                  percent: (monthVal / 4.2).clamp(0.0, 1.0),
                  color: const Color(0xFFFFB300),
                ),
              ),
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.calendar_today,
                  title: context.trArgs('yieldYearLabel', ["2026"]),
                  value: "${_formatNumber(context, annualVal, 2)} MWh",
                  goal: context.trArgs('yieldGoalMwh', ["300.00"]),
                  percent: (annualVal / 300.0).clamp(0.0, 1.0),
                  color: const Color(0xFFF85E00),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.bolt_fill,
                  title: context.tr('totalYieldLabel'),
                  value: "${_formatNumber(context, lifetimeGwh, 2)} GWh",
                  goal: context.tr('sinceCommissioning'),
                  percent: 1.0,
                  color: AppTheme.blue,
                ),
              ),
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.settings,
                  title: context.tr('systemCapacity'),
                  value: "${_formatNumber(context, capacityKwp, 2)} MWp",
                  goal: context.tr('gridConnectedCapacity'),
                  percent: 1.0,
                  color: AppTheme.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String title,
    required String value,
    required String goal,
    required double percent,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.faint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.faint, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: AppTheme.ink, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppTheme.hairline,
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goal,
            style: const TextStyle(color: AppTheme.faint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonOffsetCard(BuildContext context) {
    double co2Val = 1.417;
    if (solarData != null) {
      final rawCo2 = solarData!.co2TodayKg ?? 1417.0;
      co2Val = rawCo2 / 1000.0;
    }

    final isVi = appLocale.value.languageCode == 'vi';
    final treesVal = _formatNumber(context, co2Val * 38, 0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.leaf_arrow_circlepath, size: 16, color: AppTheme.green),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('carbonOffset'),
                      style: const TextStyle(color: AppTheme.faint, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatNumber(context, co2Val, 3),
                      style: const TextStyle(color: AppTheme.ink, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isVi ? "Tấn CO2" : "Tons CO2",
                      style: const TextStyle(color: AppTheme.secondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.trArgs('treesPlantedEquivalent', [treesVal]),
                  style: const TextStyle(color: AppTheme.faint, fontSize: 11.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppTheme.greenSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.tree, color: AppTheme.green, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTile(IconData icon, String label, String value, String sub) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.amber, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.ink, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(color: AppTheme.secondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: AppTheme.ink, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ghi = _estimateIrradiance();
    final monthKwh = solarData?.monthKwh ?? 3770.0;
    final yearKwh = solarData?.yearKwh ?? 259400.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYieldSection(context),
        _buildDoubleYieldCards(context),
        _buildCarbonOffsetCard(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.hairline),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('compositePerformance'),
                  style: const TextStyle(color: AppTheme.faint, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _buildPerformanceTile(
                  CupertinoIcons.sun_max, 
                  context.tr('ghiIrradianceEquiv'), 
                  "${ghi != null ? _formatNumber(context, ghi, 0) : '912'} W/m²", 
                  context.tr('estimatedFromPower')
                ),
                const Divider(color: AppTheme.hairline, height: 16),
                _buildPerformanceTile(
                  CupertinoIcons.gauge, 
                  context.tr('dailyPrEfficiency'), 
                  "${solarData?.specificYieldToday != null ? _formatNumber(context, solarData!.specificYieldToday!, 2) : '0.00'} kWh/kWp", 
                  context.tr('today')
                ),
                const Divider(color: AppTheme.hairline, height: 16),
                _buildPerformanceTile(
                  CupertinoIcons.calendar, 
                  context.tr('monthlyYield'), 
                  "${_formatNumber(context, monthKwh / 1000.0, 2)} MWh", 
                  context.trArgs('yieldGoalMwh', ["4.2"])
                ),
                const Divider(color: AppTheme.hairline, height: 16),
                _buildPerformanceTile(
                  CupertinoIcons.calendar_today, 
                  context.tr('yearlyYield'), 
                  "${_formatNumber(context, yearKwh / 1000.0, 2)} MWh", 
                  context.trArgs('yieldGoalMwh', ["300"])
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
