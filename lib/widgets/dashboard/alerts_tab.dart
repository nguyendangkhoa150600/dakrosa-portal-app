import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/solar_model.dart';
import '../../models/wincc_model.dart';
import '../../models/alert_item.dart';
import '../../theme/app_theme.dart';
import '../../services/localization_service.dart';

class AlertsTab extends StatelessWidget {
  final String? errorMessage;
  final SolarData? solarData;
  final WinccSnapshot? winccSnapshot;
  final List<StationInfo> stations;

  const AlertsTab({
    Key? key,
    required this.errorMessage,
    required this.solarData,
    required this.winccSnapshot,
    required this.stations,
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

  List<AlertItem> _buildAlerts(BuildContext context) {
    final List<AlertItem> out = [];
    final timeStr = DateTime.now().toLocal().toString().substring(11, 16);

    if (errorMessage != null) {
      out.add(AlertItem(
        tone: "warning",
        title: context.tr('signalInterruptedTitle'),
        body: context.tr('signalInterruptedBody'),
        time: timeStr,
      ));
    }

    if (solarData != null && solarData!.inverters.isNotEmpty) {
      final active = solarData!.inverters.where((inv) => (inv.todayKwh ?? 0) > 0).length;
      final total = solarData!.inverters.length;
      if (active < total) {
        out.add(AlertItem(
          tone: "info",
          title: context.tr('checkInverterNoGeneration'),
          body: context.trArgs('inverterNoGenerationBody', [total - active, total]),
          time: timeStr,
        ));
      }
    }

    if (winccSnapshot != null) {
      final tags = winccSnapshot!.tags;
      for (int i = 1; i <= 3; i++) {
        final double? speed = tags['u${i}_speed']?.last;
        final bool running = speed != null && speed > 10;
        final double tempVal = running ? (60.0 + (i - 1) * 5.5) : 28.5;
        if (tempVal >= 70) {
          out.add(AlertItem(
            tone: "warning",
            title: context.trArgs('highTempAlertTitle', [winccSnapshot!.station, i]),
            body: context.trArgs('highTempAlertBody', [_formatNumber(context, tempVal, 1)]),
            time: timeStr,
          ));
        }
      }
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _buildAlerts(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('incidentLogTitle'),
            style: const TextStyle(color: AppTheme.faint, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.hairline),
              ),
              child: Column(
                children: [
                  const Icon(CupertinoIcons.checkmark_circle, color: AppTheme.green, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('stableSystem'),
                    style: const TextStyle(color: AppTheme.ink, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('noAlertsDetail'),
                    style: const TextStyle(color: AppTheme.secondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              itemBuilder: (context, idx) {
                final alert = alerts[idx];
                Color cardColor = AppTheme.surface;
                Color textColor = AppTheme.ink;
                IconData alertIcon = CupertinoIcons.exclamationmark_triangle_fill;

                if (alert.tone == "warning") {
                  cardColor = AppTheme.redSoft;
                  textColor = AppTheme.red;
                  alertIcon = CupertinoIcons.exclamationmark_triangle_fill;
                } else if (alert.tone == "info") {
                  cardColor = const Color(0xFFE3F2FD);
                  textColor = AppTheme.blue;
                  alertIcon = CupertinoIcons.info_circle_fill;
                } else if (alert.tone == "success") {
                  cardColor = const Color(0xFFE8F5E9);
                  textColor = AppTheme.green;
                  alertIcon = CupertinoIcons.checkmark_circle_fill;
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: textColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(alertIcon, color: textColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.body,
                              style: const TextStyle(color: AppTheme.ink, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.trArgs('alertTimeLabel', [alert.time]),
                              style: const TextStyle(color: AppTheme.faint, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
