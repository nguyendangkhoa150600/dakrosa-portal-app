import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/solar_model.dart';
import '../../theme/app_theme.dart';
import '../yield_chart.dart';
import '../../services/localization_service.dart';

class SolarTab extends StatelessWidget {
  final SolarData? solarData;
  final SolarSeries? solarSeries;
  final String solarPeriod;
  final ValueChanged<String> onPeriodChanged;

  const SolarTab({
    Key? key,
    required this.solarData,
    required this.solarSeries,
    required this.solarPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

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

  Widget _buildQuickMetrics(BuildContext context) {
    final panelTemp = solarData?.panelTemp != null ? _formatNumber(context, solarData!.panelTemp!, 0) : '48';
    final ghi = solarData?.ghi != null ? _formatNumber(context, solarData!.ghi!, 0) : '912';
    final activeInverters = solarData?.activeInverters ?? "3/3";
    final pr = solarData?.pr != null ? _formatNumber(context, solarData!.pr!, 2) : "0.89";
    final totalYield = solarData?.lifetimeKwh != null 
        ? _formatNumber(context, solarData!.lifetimeKwh! / 1000000.0, 2)
        : "2.09";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildQuickCard(CupertinoIcons.sun_max, context.tr('weatherSunny'), "32°C", isWarning: true),
          _buildQuickCard(
            CupertinoIcons.flame, 
            context.tr('radiationGhi'), 
            "$ghi W/m²", 
            subText: context.trArgs('panelTempLabel', [panelTemp]),
            isWarning: true
          ),
          _buildQuickCard(CupertinoIcons.wifi, context.tr('inverterStatusLabel'), activeInverters, subText: context.tr('allInvertersRunning'), isSuccess: true),
          _buildQuickCard(CupertinoIcons.shield, context.tr('performancePrLabel'), pr, isSuccess: true),
          _buildQuickCard(CupertinoIcons.bolt_horizontal, context.tr('totalYieldLabel'), "$totalYield GWh", isSuccess: true),
        ],
      ),
    );
  }

  Widget _buildQuickCard(IconData icon, String label, String value, {String? subText, bool isSuccess = false, bool isWarning = false}) {
    Color indicatorColor = AppTheme.faint;
    if (isSuccess) indicatorColor = AppTheme.green;
    if (isWarning) indicatorColor = AppTheme.amber;

    return Container(
      width: 155,
      height: 115,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: indicatorColor),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppTheme.faint, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: AppTheme.ink, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (subText != null) ...[
            const SizedBox(height: 2),
            Text(
              subText,
              style: const TextStyle(color: AppTheme.secondary, fontSize: 10),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    String valueStr = "—";
    String unit = "MW";
    String rightValue = "—";
    String leftValue = "—";

    if (solarData != null) {
      final kw = solarData!.currentKw ?? 0.0;
      valueStr = (kw >= 1000) ? _formatNumber(context, kw / 1000, 2) : _formatNumber(context, kw, 0);
      unit = (kw >= 1000) ? "MW" : "kW";
      rightValue = "${_formatNumber(context, (solarData!.capacityKwp ?? 6140) / 1000, 2)} MWp";
      leftValue = "60.9%";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.solarGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF85E00).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: GridPaper(
                color: Colors.white,
                interval: 20,
                divisions: 1,
                subdivisions: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('currentCapacityLabel'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('activeNowLabel'),
                            style: const TextStyle(color: AppTheme.ink, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valueStr,
                      style: AppTheme.monoTextStyle.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('acEfficiency'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leftValue,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.tr('dcPower'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rightValue,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildDevicesSection(BuildContext context) {
    final inverters = solarData?.inverters ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('inverterStatusLabel'),
              style: const TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                context.tr('viewAll'),
                style: const TextStyle(color: Color(0xFFF85E00), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: inverters.length,
          itemBuilder: (context, idx) {
            final inv = inverters[idx];
            final statusText = context.tr('statusRunning');
            const statusColor = AppTheme.green;
            final String acPowerStr = "${_formatNumber(context, inv.acPower ?? 0.0, 2)} MW";
            final String todayKwhStr = "${_formatNumber(context, inv.todayKwh ?? 0.0, 1)} kWh";
            final shareStr = "${_formatNumber(context, inv.share ?? 0.0, 1)}%";

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.hairline),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.hairline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(CupertinoIcons.device_laptop, color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.label,
                          style: const TextStyle(color: AppTheme.ink, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: const TextStyle(color: statusColor, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        acPowerStr,
                        style: const TextStyle(color: AppTheme.ink, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${context.tr('today')}: $todayKwhStr ($shareStr)",
                        style: const TextStyle(color: AppTheme.faint, fontSize: 11),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildAlertsSection(context),
      ],
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('alertsMaintenance'),
          style: const TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildAlertRow(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          color: AppTheme.amber,
          title: context.tr('highRadiationWarning'),
          detail: context.tr('highRadiationWarningDetail'),
          time: "10:18",
        ),
        _buildAlertRow(
          icon: CupertinoIcons.info_circle_fill,
          color: AppTheme.blue,
          title: context.tr('periodicCleaning'),
          detail: context.tr('periodicCleaningDetail'),
          time: context.tr('yesterday'),
        ),
        _buildAlertRow(
          icon: CupertinoIcons.checkmark_circle_fill,
          color: AppTheme.green,
          title: context.tr('stableSystem'),
          detail: context.tr('stableSystemDetail'),
          time: "06/07 09:00",
        ),
      ],
    );
  }

  Widget _buildAlertRow({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(color: AppTheme.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(color: AppTheme.faint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickMetrics(context),
        _buildMainCard(context),
        _buildYieldSection(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildDevicesSection(context),
        ),
      ],
    );
  }
}
