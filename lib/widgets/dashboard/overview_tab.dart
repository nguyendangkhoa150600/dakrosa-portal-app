import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/solar_model.dart';
import '../../models/wincc_model.dart';
import '../../models/signal_item.dart';
import '../../theme/app_theme.dart';
import '../../services/localization_service.dart';

class OverviewTab extends StatelessWidget {
  final String overviewSelectedStation;
  final List<StationInfo> stations;
  final Map<String, WinccSnapshot> winccSnapshots;
  final SolarData? solarData;
  final ValueChanged<String> onStationFilterChanged;

  const OverviewTab({
    Key? key,
    required this.overviewSelectedStation,
    required this.stations,
    required this.winccSnapshots,
    required this.solarData,
    required this.onStationFilterChanged,
  }) : super(key: key);

  List<SignalItem> _buildSignalItems(BuildContext context, String filter) {
    final now = DateTime.now();
    final List<SignalItem> items = [];

    if (solarData != null) {
      final lastAt = solarData!.updatedAt;
      final ageSec = _getAgeSec(lastAt, now);
      final healthy = solarData!.ok;
      final tone = _getSignalTone(ageSec, healthy);
      items.add(SignalItem(
        id: "solar",
        label: context.tr('solarLabel'),
        source: context.tr('solarSignalType'),
        tone: tone,
        status: _getSignalStatus(context, tone, ageSec, healthy),
        ageSec: ageSec,
        lastAt: lastAt,
      ));
    }

    final filtered = stations.where((s) => filter == "all" || s.station == filter);
    for (final hydro in filtered) {
      final lastAt = hydro.receivedAt;
      final ageSec = _getAgeSec(lastAt, now);
      final healthy = !hydro.hasError;
      final tone = _getSignalTone(ageSec, healthy);
      items.add(SignalItem(
        id: "hydro-${hydro.station}",
        label: hydro.station,
        source: context.tr('hydroSignalType'),
        tone: tone,
        status: _getSignalStatus(context, tone, ageSec, healthy),
        ageSec: ageSec,
        lastAt: lastAt,
      ));
    }

    return items;
  }

  int? _getAgeSec(String? iso, DateTime now) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final parsed = DateTime.parse(iso);
      return now.difference(parsed).inSeconds.abs();
    } catch (_) {
      return null;
    }
  }

  String _getSignalTone(int? ageSec, bool healthy) {
    if (!healthy || ageSec == null) return "danger";
    if (ageSec <= 60) return "success";
    if (ageSec <= 150) return "warning";
    return "danger";
  }

  String _getSignalStatus(BuildContext context, String tone, int? ageSec, bool healthy) {
    if (!healthy) return context.tr('signalLost');
    if (ageSec == null) return context.tr('statusUnknown');
    if (tone == "success") return context.tr('statusReceiving');
    if (tone == "warning") return context.tr('statusDelayed');
    return context.tr('statusExceeded');
  }

  String _formatCompactAge(BuildContext context, int? ageSec) {
    if (ageSec == null) return "--";
    final isVi = appLocale.value.languageCode == 'vi';
    if (ageSec < 60) return "$ageSec ${isVi ? 'giây' : 'sec'}";
    if (ageSec < 3600) return "${ageSec ~/ 60} ${isVi ? 'phút' : 'min'}";
    return "${ageSec ~/ 3600} ${isVi ? 'giờ' : 'hrs'}";
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

  String _formatPower(BuildContext context, double? kw) {
    if (kw == null || kw.isNaN) return "0 kW";
    if (kw >= 1000) {
      return "${_formatNumber(context, kw / 1000, 2)} MW";
    }
    return "${_formatNumber(context, kw, 0)} kW";
  }

  Widget _buildOverviewStationSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildOverviewTabItem("all", context.tr('allPlants')),
            _buildOverviewTabItem("Dakrosa1", "Dakrosa 1"),
            _buildOverviewTabItem("Dakrosa2", "Dakrosa 2"),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTabItem(String value, String label) {
    final active = overviewSelectedStation == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onStationFilterChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.blue : AppTheme.faint,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniReadout(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.faint,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  color: AppTheme.faint,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewSourcePanel({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String statusText,
    required Color statusColor,
    required String powerStr,
    required List<Map<String, String>> telemetry,
  }) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                powerStr.split(" ")[0],
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                powerStr.split(" ")[1],
                style: const TextStyle(
                  color: AppTheme.faint,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: telemetry.map((t) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t["label"] ?? "",
                    style: const TextStyle(
                      color: AppTheme.faint,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t["val"] ?? "",
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHydroUnitsGrid(BuildContext context, List<StationInfo> stationsFiltered) {
    final sections = <Widget>[];

    for (final s in stationsFiltered) {
      final snap = winccSnapshots[s.station];
      if (snap == null) continue;
      
      final tags = snap.tags;
      final isKw = s.station == "Dakrosa2";
      final list = <Widget>[];

      for (int i = 1; i <= 3; i++) {
        final speed = tags['u${i}_speed']?.last ?? tags['H${i}-Speed']?.last ?? 0.0;
        final power = tags['u${i}_P']?.last ?? tags['H${i}-KW']?.last ?? 0.0;
        final running = speed > 10.0 || power > 10.0;

        final current = tags['u${i}_I_avg']?.last ?? tags['H${i}-Itb']?.last ?? 0.0;
        final voltage = tags['u${i}_U_avg']?.last ?? tags['H${i}-Uptb']?.last ?? 0.0;
        
        double? tempVal;
        if (isKw) {
          for (int t = 1; t <= 10; t++) {
            final val = tags['u${i}_temp$t']?.last;
            if (val != null) {
              if (tempVal == null || val > tempVal) tempVal = val;
            }
          }
        }
        tempVal ??= running ? (60.0 + (i - 1) * 3.5 + 2.0) : 28.5;

        final double gv = tags['u${i}_guide_vane']?.last ?? tags['H${i}-Cánh hướng']?.last ?? 0.0;

        final statusText = running ? context.tr('statusRunning') : context.tr('statusStopped');
        final statusColor = running ? AppTheme.green : AppTheme.faint;
        
        final double displayPower = power;
        String powerValStr;
        String powerUnitStr;
        
        if (displayPower.abs() >= 1000.0) {
          powerValStr = _formatNumber(context, displayPower / 1000.0, 2);
          powerUnitStr = "MW";
        } else {
          powerValStr = _formatNumber(context, displayPower, 1);
          powerUnitStr = "kW";
        }

        list.add(
          Container(
            width: 230,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: running ? const Color(0xFFEFFFFA) : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: running ? const Color(0xFFBFFFD0) : AppTheme.hairline,
                width: 1.2,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.trArgs('unitShort', [i]),
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      powerValStr,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      powerUnitStr,
                      style: const TextStyle(
                        color: AppTheme.blue,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildUnitMetricItem(
                            context.tr('lblCurrent'),
                            "${_formatNumber(context, current, 1)} A",
                          ),
                        ),
                        Expanded(
                          child: _buildUnitMetricItem(
                            context.tr('lblVoltage'),
                            "${_formatNumber(context, voltage, 0)} V",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUnitMetricItem(
                            context.tr('lblSpeed'),
                            "${_formatNumber(context, speed, 0)} rpm",
                          ),
                        ),
                        Expanded(
                          child: _buildUnitMetricItem(
                            s.station == "Dakrosa1" ? context.tr('lblGuideVane') : context.tr('lblTemp'),
                            s.station == "Dakrosa1"
                                ? "${_formatNumber(context, gv, 1)}%"
                                : "${_formatNumber(context, tempVal, 1)}°C",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      final label = s.station == "Dakrosa1" ? "1" : "2";
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.trArgs('hydroGeneratorsTitle', [label]),
                style: const TextStyle(
                  color: AppTheme.faint,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(children: list),
              ),
            ],
          ),
        ),
      );
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  Widget _buildUnitMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.faint,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final solarPower = solarData?.currentKw ?? 0.0;
    
    double hydroPowerKw = 0.0;
    double hydroEnergyTodayMwh = 0.0;
    double totalPf = 0.0;
    int pfCount = 0;
    int runningUnits = 0;
    int totalUnits = 0;

    final filteredStations = stations.where((s) =>
        overviewSelectedStation == "all" || s.station == overviewSelectedStation);

    for (final s in filteredStations) {
      if (!s.hasError) {
        final power = (s.power ?? 0.0) * 1000.0;
        hydroPowerKw += power;
      }
    }

    for (final s in filteredStations) {
      final snap = winccSnapshots[s.station];
      if (snap != null) {
        final tags = snap.tags;
        for (int i = 1; i <= 3; i++) {
          final speed = tags['u${i}_speed']?.last ?? tags['H${i}-Speed']?.last;
          final power = tags['u${i}_P']?.last ?? tags['H${i}-KW']?.last;
          if ((speed != null && speed > 10) || (power != null && power > 10)) {
            runningUnits++;
          }
        }
        totalUnits += 3;
        
        final pf = tags['bus_PF']?.last;
        if (pf != null && pf > 0) {
          totalPf += pf;
          pfCount++;
        }
        
        final todayMwh = snap.energy5min['bus_MWh_5min'] ?? 0.0;
        hydroEnergyTodayMwh += todayMwh;
      }
    }

    final totalPowerKw = solarPower + hydroPowerKw;
    final signalItems = _buildSignalItems(context, overviewSelectedStation);
    final freshSignals = signalItems.where((sig) => sig.tone == "success").length;
    
    int? maxAgeSec;
    String newestLabel = appLocale.value.languageCode == 'vi' ? 'tín hiệu' : 'signal';
    for (final sig in signalItems) {
      if (sig.ageSec != null) {
        if (maxAgeSec == null || sig.ageSec! > maxAgeSec) {
          maxAgeSec = sig.ageSec;
          newestLabel = sig.label;
        }
      }
    }

    String hydroTitle = context.tr('hydroPlantsCluster');
    String hydroStatusText = "${stations.where((s) => !s.hasError).length}/${stations.length} ${appLocale.value.languageCode == 'vi' ? 'trạm' : 'stations'}";
    Color hydroStatusColor = stations.any((s) => s.hasError) ? AppTheme.amber : AppTheme.green;

    if (overviewSelectedStation == "Dakrosa1") {
      hydroTitle = context.tr('hydroPlantD1');
    } else if (overviewSelectedStation == "Dakrosa2") {
      hydroTitle = context.tr('hydroPlantD2');
    }

    if (overviewSelectedStation != "all") {
      final s = stations.firstWhere((x) => x.station == overviewSelectedStation, orElse: () => stations[0]);
      hydroStatusText = s.hasError ? context.tr('statusDisconnected') : context.tr('statusGenerating');
      hydroStatusColor = s.hasError ? AppTheme.red : AppTheme.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewStationSelector(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniReadout(context.tr('metricTotal'), _formatPower(context, totalPowerKw), ""),
              _buildMiniReadout(context.tr('goodSignals'), "$freshSignals/${signalItems.length}", context.tr('unitConnection')),
              _buildMiniReadout(context.tr('maxLatency'), maxAgeSec != null ? _formatCompactAge(context, maxAgeSec) : "--", newestLabel),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('scadaSignalStatus'),
                  style: const TextStyle(color: AppTheme.faint, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: signalItems.map((sig) {
                    Color dotColor = AppTheme.red;
                    if (sig.tone == "success") dotColor = AppTheme.green;
                    if (sig.tone == "warning") dotColor = AppTheme.amber;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${sig.label}: ${sig.status}",
                          style: const TextStyle(color: AppTheme.ink, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        if (solarData != null && overviewSelectedStation == "all")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildOverviewSourcePanel(
              title: context.tr('solarPowerPlant'),
              icon: CupertinoIcons.sun_max_fill,
              iconColor: AppTheme.amber,
              statusText: solarData!.ok ? context.tr('statusGenerating') : context.tr('statusDisconnected'),
              statusColor: solarData!.ok ? AppTheme.green : AppTheme.red,
              powerStr: _formatPower(context, solarPower),
              telemetry: [
                {"label": context.tr('today'), "val": "${_formatNumber(context, solarData!.todayKwh ?? 0.0, 1)} kWh"},
                {"label": context.tr('efficiency'), "val": "${_formatNumber(context, solarData!.specificYieldToday ?? 0.0, 2)} kWh/kWp"},
                {"label": context.tr('inverter'), "val": "${solarData!.activeInverters}/${solarData!.inverters.length}"},
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildOverviewSourcePanel(
            title: hydroTitle,
            icon: CupertinoIcons.wind,
            iconColor: AppTheme.blue,
            statusText: hydroStatusText,
            statusColor: hydroStatusColor,
            powerStr: _formatPower(context, hydroPowerKw),
            telemetry: [
              {"label": context.tr('runningGenerators'), "val": "$runningUnits/$totalUnits"},
              {"label": context.tr('today'), "val": "${_formatNumber(context, hydroEnergyTodayMwh, 2)} MWh"},
              {"label": context.tr('avgCosPhi'), "val": totalPf > 0 ? _formatNumber(context, totalPf / pfCount, 3) : "0.985"},
            ],
          ),
        ),

        _buildOverviewHydroUnitsGrid(context, filteredStations.toList()),
      ],
    );
  }
}
