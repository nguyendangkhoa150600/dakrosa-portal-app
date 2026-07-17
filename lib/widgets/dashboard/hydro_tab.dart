import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/solar_model.dart';
import '../../models/wincc_model.dart';
import '../../theme/app_theme.dart';
import '../hydro_scada_explorer.dart';
import '../../services/localization_service.dart';

class _MetricItem {
  final String label;
  final String value;
  final String unit;

  _MetricItem(this.label, this.value, this.unit);
}

class HydroTab extends StatelessWidget {
  final String selectedStation;
  final WinccSnapshot? winccSnapshot;
  final List<StationInfo> stations;
  final Map<String, WinccSnapshot> winccSnapshots;
  final SolarData? solarData;

  const HydroTab({
    Key? key,
    required this.selectedStation,
    required this.winccSnapshot,
    required this.stations,
    required this.winccSnapshots,
    required this.solarData,
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

  Widget _buildMetricPanel(BuildContext context, String title, List<_MetricItem> items) {
    return Container(
      width: 320,
      height: 380,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  context.trArgs('indexCount', [items.length]),
                  style: const TextStyle(
                    color: AppTheme.faint,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.hairline, height: 1, thickness: 1),
          Expanded(
            child: Scrollbar(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(color: AppTheme.hairline, height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            item.value,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.unit.isNotEmpty) ...[
                            const SizedBox(width: 3),
                            Text(
                              item.unit,
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGridSection(BuildContext context) {
    final List<_MetricItem> totals = [];
    final solarPower = solarData?.currentKw ?? 0.0;
    
    double hydroPowerKw = 0.0;
    int runningUnits = 0;

    for (final s in stations) {
      if (!s.hasError) {
        hydroPowerKw += (s.power ?? 0.0) * 1000.0;
      }
    }

    for (final s in stations) {
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
      }
    }

    totals.add(_MetricItem(context.tr('metricSolar'), _formatNumber(context, solarPower, 1), "kW"));
    totals.add(_MetricItem(context.tr('metricHydro'), _formatNumber(context, hydroPowerKw, 1), "kW"));
    totals.add(_MetricItem(context.tr('metricTotal'), _formatNumber(context, solarPower + hydroPowerKw, 1), "kW"));
    totals.add(_MetricItem(context.tr('metricStationsOnline'), "${stations.where((s) => !s.hasError).length}", "station"));
    totals.add(_MetricItem(context.tr('metricUnitsRunning'), "$runningUnits", "unit"));
    totals.add(_MetricItem(context.tr('metricInvertersRunning'), "${solarData?.activeInverters ?? 3}", "inverter"));

    final List<_MetricItem> d1 = [];
    final snap1 = winccSnapshots["Dakrosa1"];
    if (snap1 != null) {
      final tags = snap1.tags;
      final double p = (tags['bus_P']?.last ?? 0.0) * 1000.0;
      final double q = (tags['bus_Q']?.last ?? 0.0) * 1000.0;
      final double s = (tags['bus_S']?.last ?? 0.0) * 1000.0;
      final double u = tags['bus_U12']?.last ?? tags['bus_U_avg']?.last ?? 0.0;
      final double i = tags['bus_I1']?.last ?? tags['bus_I_avg']?.last ?? 0.0;
      final double pf = tags['bus_PF']?.last ?? 1.0;
      final double energy5m = snap1.energy5min['bus_MWh_5min'] ?? 0.0;
      
      int d1ActiveUnits = 0;
      for (int k = 1; k <= 3; k++) {
        final speed = tags['H$k-Speed']?.last ?? tags['u${k}_speed']?.last;
        final power = tags['H$k-KW']?.last ?? tags['u${k}_P']?.last;
        if ((speed != null && speed > 10) || (power != null && power > 10)) {
          d1ActiveUnits++;
        }
      }

      d1.add(_MetricItem(context.tr('activePowerP'), _formatNumber(context, p, 1), "kW"));
      d1.add(_MetricItem(context.tr('reactivePowerQ'), _formatNumber(context, q, 1), "kVAr"));
      d1.add(_MetricItem(context.tr('apparentPowerS'), _formatNumber(context, s, 1), "kVA"));
      d1.add(_MetricItem(context.tr('busVoltage'), _formatNumber(context, u, 2), "kV"));
      d1.add(_MetricItem(context.tr('busCurrent'), _formatNumber(context, i, 0), "A"));
      d1.add(_MetricItem(context.tr('cosPhiFactor') + context.tr('derivedQualifier'), _formatNumber(context, pf, 3), ""));
      d1.add(_MetricItem(context.tr('yield5Min'), _formatNumber(context, energy5m, 3), "MWh"));
      d1.add(_MetricItem(context.tr('metricUnitsRunning') + context.tr('derivedQualifier'), "$d1ActiveUnits", "unit"));
      
      int age = 0;
      if (snap1.receivedAt != null) {
        try {
          final parsed = DateTime.parse(snap1.receivedAt!);
          age = DateTime.now().difference(parsed).inSeconds.abs();
        } catch (_) {}
      }
      d1.add(_MetricItem(context.tr('dataAge'), _formatNumber(context, age.toDouble(), 0), "s"));
    }

    final List<_MetricItem> d2 = [];
    final snap2 = winccSnapshots["Dakrosa2"];
    if (snap2 != null) {
      final tags = snap2.tags;
      
      void addTagMetric(String label, String tagKey, String unit, int dec, {double multiplier = 1.0}) {
        final val = tags[tagKey]?.last;
        if (val != null) {
          d2.add(_MetricItem(label, _formatNumber(context, val * multiplier, dec), unit));
        }
      }

      final double p = (tags['bus_P']?.last ?? 0.0) * 1000.0;
      final double q = (tags['bus_Q']?.last ?? 0.0) * 1000.0;
      final double s = (tags['bus_S']?.last ?? 0.0) * 1000.0;
      final double u = tags['bus_U12']?.last ?? tags['bus_U_avg']?.last ?? 0.0;
      final double i = tags['bus_I1']?.last ?? tags['bus_I_avg']?.last ?? 0.0;
      final double f = tags['bus_F']?.last ?? 50.0;
      final double pf = tags['bus_PF']?.last ?? 1.0;
      final double energy5m = snap2.energy5min['bus_MWh_5min'] ?? 0.0;
      
      int d2ActiveUnits = 0;
      for (int k = 1; k <= 3; k++) {
        final speed = tags['u${k}_speed']?.last;
        final power = tags['u${k}_P']?.last;
        if ((speed != null && speed > 10) || (power != null && power > 10)) {
          d2ActiveUnits++;
        }
      }

      d2.add(_MetricItem(context.tr('activePowerP'), _formatNumber(context, p, 1), "kW"));
      d2.add(_MetricItem(context.tr('reactivePowerQ'), _formatNumber(context, q, 1), "kVAr"));
      d2.add(_MetricItem(context.tr('apparentPowerS'), _formatNumber(context, s, 1), "kVA"));
      d2.add(_MetricItem(context.tr('busVoltage'), _formatNumber(context, u, 2), "kV"));
      d2.add(_MetricItem(context.tr('busCurrent'), _formatNumber(context, i, 1), "A"));
      d2.add(_MetricItem(context.tr('frequency'), _formatNumber(context, f, 2), "Hz"));
      d2.add(_MetricItem(context.tr('cosPhiFactor'), _formatNumber(context, pf, 3), ""));
      d2.add(_MetricItem(context.tr('yield5Min'), _formatNumber(context, energy5m, 3), "MWh"));
      
      final double todayEnergy = snap2.energy5min['bus_MWh_today'] ?? (snap2.energy5min['bus_MWh_5min'] ?? 0.0) * 12.0; 
      d2.add(_MetricItem(context.tr('yieldToday'), _formatNumber(context, todayEnergy, 3), "MWh"));
      d2.add(_MetricItem(context.tr('metricUnitsRunning'), "$d2ActiveUnits", "unit"));

      // 1. Generator bus telemetry
      addTagMetric(context.tr('genBusP'), "hv_P", "kW", 1, multiplier: 1000.0);
      addTagMetric(context.tr('genBusQ'), "hv_Q", "kVAr", 1, multiplier: 1000.0);
      addTagMetric(context.tr('genBusS'), "hv_S", "kVA", 1, multiplier: 1000.0);
      addTagMetric(context.tr('genBusU12'), "hv_U12", "V", 1);
      addTagMetric(context.tr('genBusU23'), "hv_U23", "V", 1);
      addTagMetric(context.tr('genBusU31'), "hv_U31", "V", 1);
      addTagMetric(context.tr('genBusI1'), "hv_I1", "A", 1);
      addTagMetric(context.tr('genBusI2'), "hv_I2", "A", 1);
      addTagMetric(context.tr('genBusI3'), "hv_I3", "A", 1);
      addTagMetric(context.tr('genBusIAvg'), "hv_I_avg", "A", 1);
      addTagMetric(context.tr('genBusUAvg'), "hv_U_avg", "V", 1);
      addTagMetric(context.tr('genBusU1N'), "hv_U1N", "V", 1);
      addTagMetric(context.tr('genBusF'), "hv_F", "Hz", 2);
      addTagMetric(context.tr('genBusPF'), "hv_PF", "", 3);

      // 2. Unit level details for H1, H2, H3
      for (int u = 1; u <= 3; u++) {
        final prefix = "u$u";
        addTagMetric(context.trArgs('unitPowerP', [u]), "${prefix}_P", "kW", 1);
        addTagMetric(context.trArgs('unitPowerQ', [u]), "${prefix}_Q", "kVAr", 1);
        addTagMetric(context.trArgs('unitCurrent', [u]), "${prefix}_I_avg", "A", 1);
        addTagMetric(context.trArgs('unitVoltage', [u]), "${prefix}_U_avg", "V", 1);
        addTagMetric(context.trArgs('unitSpeed', [u]), "${prefix}_speed", "rpm", 0);
        addTagMetric(context.trArgs('unitCosPhi', [u]), "${prefix}_PF", "", 3);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr('detailIndexTable'),
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricPanel(context, context.tr('totalSystem'), totals),
                if (d1.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildMetricPanel(context, context.tr('stationD1'), d1),
                ],
                if (d2.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildMetricPanel(context, context.tr('stationD2'), d2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryStationsList = <Widget>[];
    for (final s in stations) {
      final snap = winccSnapshots[s.station];
      if (snap != null) {
        summaryStationsList.add(
          HydroStationCard(
            stationInfo: s,
            snapshot: snap,
            formatNumberVi: (val, dec) => _formatNumber(context, val, dec),
            getSignalTone: _getSignalTone,
            getSignalStatus: (tone, age, healthy) => _getSignalStatus(context, tone, age, healthy),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('giamsatthuydien'),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                context.trArgs('stationCount', [stations.length]),
                style: const TextStyle(
                  color: AppTheme.faint,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        ...summaryStationsList,

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(color: AppTheme.hairline, height: 1),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            context.trArgs('scadaOnlineDiagram', [selectedStation == "Dakrosa1" ? "Dakrosa 1" : "Dakrosa 2"]),
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        HydroScadaExplorer(
          station: selectedStation,
          winccSnapshot: winccSnapshot,
        ),
        _buildMetricGridSection(context),
      ],
    );
  }
}

class HydroStationCard extends StatefulWidget {
  final StationInfo stationInfo;
  final WinccSnapshot snapshot;
  final String Function(double, int) formatNumberVi;
  final String Function(int?, bool) getSignalTone;
  final String Function(String, int?, bool) getSignalStatus;

  const HydroStationCard({
    Key? key,
    required this.stationInfo,
    required this.snapshot,
    required this.formatNumberVi,
    required this.getSignalTone,
    required this.getSignalStatus,
  }) : super(key: key);

  @override
  State<HydroStationCard> createState() => _HydroStationCardState();
}

class _HydroStationCardState extends State<HydroStationCard> {
  bool _isExpanded = false;

  Widget _buildUnitDetailRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.faint, fontSize: 8.5, fontWeight: FontWeight.bold),
        ),
        Text(
          val,
          style: const TextStyle(color: AppTheme.ink, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStationUnitGrid(String station, WinccSnapshot snap) {
    final tags = snap.tags;
    final isKw = station == "Dakrosa2";
    final isDakrosa1 = station == "Dakrosa1";
    final list = <Widget>[];

    for (int i = 1; i <= 3; i++) {
      final speed = tags['u${i}_speed']?.last ?? tags['H${i}-Speed']?.last ?? 0.0;
      final power = tags['u${i}_P']?.last ?? tags['H${i}-KW']?.last ?? 0.0;
      final running = speed > 10.0 || power > 10.0;

      final current = tags['u${i}_I_avg']?.last ?? tags['H${i}-Itb']?.last ?? 0.0;
      final voltage = tags['u${i}_U_avg']?.last ?? tags['H${i}-Uptb']?.last ?? 0.0;
      final f = tags['bus_F']?.last ?? 50.0;
      final pf = tags['u${i}_PF']?.last ?? tags['H${i}-PF']?.last ?? tags['bus_PF']?.last ?? 1.0;
      
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
      final double todayMwh = snap.energy5min['u${i}_MWh_5min'] ?? 0.0;

      final statusText = isDakrosa1
          ? ((tags['H$i-Speed']?.last == null && tags['H$i-KW']?.last == null && tags['u${i}_speed']?.last == null && tags['u${i}_P']?.last == null)
              ? context.tr('statusUndefined')
              : (running ? context.tr('statusRunningEst') : context.tr('statusStoppedEst')))
          : (running ? context.tr('statusRunning') : context.tr('statusStopped'));
      final statusColor = running ? AppTheme.green : AppTheme.faint;
      
      final String unitPowerStr = isKw
          ? "${widget.formatNumberVi(power, 1)} kW"
          : "${widget.formatNumberVi(power, 2)} MW";

      list.add(
        Container(
          width: 175,
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
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
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                unitPowerStr,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _buildUnitDetailRow(context.tr('lblCurrent'), "${widget.formatNumberVi(current, 1)} A"),
                  const SizedBox(height: 4),
                  _buildUnitDetailRow(context.tr('lblVoltage'), isKw ? "${widget.formatNumberVi(voltage, 0)} V" : "${widget.formatNumberVi(voltage / 1000.0, 2)} kV"),
                  const SizedBox(height: 4),
                  _buildUnitDetailRow(context.tr('lblFrequency'), "${widget.formatNumberVi(f, 1)} Hz"),
                  const SizedBox(height: 4),
                  _buildUnitDetailRow(context.tr('lblFactor'), widget.formatNumberVi(pf, 3)),
                  const SizedBox(height: 4),
                  _buildUnitDetailRow(context.tr('lblSpeed'), "${widget.formatNumberVi(speed, 0)} rpm"),
                  const SizedBox(height: 4),
                  _buildUnitDetailRow(
                    isDakrosa1 ? context.tr('lblGuideVane') : context.tr('lblTemp'),
                    isDakrosa1 ? "${widget.formatNumberVi(gv, 1)}%" : "${widget.formatNumberVi(tempVal, 1)}°C",
                  ),
                  const SizedBox(height: 4),
                  _buildUnitDetailRow(context.tr('lblToday'), "${widget.formatNumberVi(todayMwh, 2)} MWh"),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: list),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stationInfo;
    final snap = widget.snapshot;
    final tags = snap.tags;
    final isKw = s.station == "Dakrosa2";
    final isDakrosa1 = s.station == "Dakrosa1";

    final double powerMw = (s.power ?? 0.0);
    final String powerStr = isKw 
        ? "${widget.formatNumberVi(powerMw * 1000.0, 1)} kW" 
        : "${widget.formatNumberVi(powerMw, 2)} MW";

    final now = DateTime.now();
    int? ageSec;
    if (snap.receivedAt != null) {
      try {
        final parsed = DateTime.parse(snap.receivedAt!);
        ageSec = now.difference(parsed).inSeconds.abs();
      } catch (_) {}
    }
    final healthy = !s.hasError;
    final tone = widget.getSignalTone(ageSec, healthy);
    final statusText = widget.getSignalStatus(tone, ageSec, healthy);

    Color dotColor = AppTheme.red;
    if (tone == "success") dotColor = AppTheme.green;
    if (tone == "warning") dotColor = AppTheme.amber;

    final double u = tags['bus_U12']?.last ?? tags['bus_U_avg']?.last ?? 0.0;
    final double f = tags['bus_F']?.last ?? 50.0;
    final double pf = tags['bus_PF']?.last ?? 1.0;
    final double todayMwh = snap.energy5min['bus_MWh_5min'] ?? 0.0;

    String ageText = context.tr('updatedSecondsAgoPlaceholder');
    if (ageSec != null) {
      if (ageSec < 60) {
        ageText = context.trArgs('updatedSecondsAgo', [ageSec]);
      } else {
        ageText = context.trArgs('updatedMinutesSecondsAgo', [ageSec ~/ 60, ageSec % 60]);
      }
    }

    String timeText = "";
    if (snap.receivedAt != null && snap.receivedAt!.length >= 19) {
      timeText = snap.receivedAt!.substring(11, 19);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: healthy ? AppTheme.greenSoft : AppTheme.hairline,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: healthy ? AppTheme.green : AppTheme.faint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      healthy ? context.tr('signalOk') : context.tr('signalLost'),
                      style: TextStyle(
                        color: healthy ? AppTheme.green : AppTheme.faint,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: dotColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.station,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            powerStr,
            style: const TextStyle(
              color: AppTheme.amber,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ageText,
                style: const TextStyle(color: AppTheme.secondary, fontSize: 11),
              ),
              Text(
                timeText,
                style: const TextStyle(color: AppTheme.faint, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.hairline, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.trArgs('lblU', [widget.formatNumberVi(u, 2)]), style: const TextStyle(color: AppTheme.ink, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      context.trArgs('lblFactorShort', [widget.formatNumberVi(pf, 3)]) + (isDakrosa1 ? context.tr('derivedQualifier') : ''),
                      style: const TextStyle(color: AppTheme.ink, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.trArgs('lblF', [widget.formatNumberVi(f, 2)]), style: const TextStyle(color: AppTheme.ink, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(context.trArgs('lblTodayShort', [widget.formatNumberVi(todayMwh, 2)]), style: const TextStyle(color: AppTheme.ink, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.hairline, height: 1),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? context.tr('detailsTitleClose') : context.tr('detailsTitle'),
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    color: AppTheme.secondary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            _buildStationUnitGrid(s.station, snap),
          ],
        ],
      ),
    );
  }
}
