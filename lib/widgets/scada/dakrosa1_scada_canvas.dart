import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/mobile_model.dart';
import '../../models/wincc_model.dart';
import '../../theme/app_theme.dart';
import '../../services/localization_service.dart';

class Dakrosa1CanvasDiagram extends StatelessWidget {
  final MobileHydro hydro;

  const Dakrosa1CanvasDiagram({
    Key? key,
    required this.hydro,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1920,
          height: 1080,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.network(
                  "https://dakrosa.svnagentic.site/dakrosa/scada/Dakrosa1_MAIN.svg",
                  placeholderBuilder: (BuildContext context) => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppTheme.blue,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
              ..._buildDakrosa1Readouts(hydro, 1.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDakrosa1Readouts(MobileHydro hydro, double scaleX, double scaleY) {
    final list = <Widget>[];

    void addReadout(String key, double x, double y, double scale, int decimals, {String unit = ""}) {
      double? rawVal;
      final isScadaOnline = hydro.online;

      if (key.startsWith("u")) {
        final unitId = key.substring(0, 2);
        final field = key.substring(3);
        final u = hydro.units.firstWhere((element) => element.id == unitId, orElse: () => hydro.units[0]);
        
        if (field == "voltage") rawVal = u.voltageV;
        else if (field == "current") rawVal = u.currentA;
        else if (field == "power") rawVal = u.powerKw;
        else if (field == "reactive") rawVal = u.reactivePowerKvar;
        else if (field == "frequency") rawVal = u.frequencyHz;
        else if (field == "power_factor") rawVal = u.powerFactor;
        else if (field == "speed") rawVal = u.speedRpm;
        else if (field == "guide_vane") rawVal = u.guideVanePercent;
        else if (field == "header_power") rawVal = u.powerKw;
        else if (field == "header_reactive") rawVal = u.reactivePowerKvar;
      } else {
        if (key == "bus_voltage") rawVal = hydro.voltageKv;
        else if (key == "bus_current") rawVal = hydro.currentA;
        else if (key == "bus_power") rawVal = hydro.powerKw;
        else if (key == "bus_reactive") rawVal = hydro.reactivePowerKvar;
        else if (key == "bus_apparent") rawVal = hydro.apparentPowerKva;
        else if (key == "bus_frequency") rawVal = hydro.frequencyHz;
        else if (key == "bus_power_factor") rawVal = hydro.powerFactor;
      }

      final double? computedVal = (isScadaOnline && rawVal != null) ? rawVal * scale : null;
      final String text = computedVal == null ? "—" : computedVal.toStringAsFixed(decimals);
      final isNull = computedVal == null;

      list.add(
        Positioned(
          left: x * scaleX,
          top: y * scaleY,
          width: 60 * scaleX,
          height: 20 * scaleY,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF64748B), width: 0.5),
            ),
            padding: const EdgeInsets.only(right: 3),
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  color: isNull ? const Color(0xFF94A3B8) : const Color(0xFF050505),
                  fontFamily: "Arial",
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Map<String, dynamic>> getUnitReadoutLayout(String uId, double valueX, double topP, double topQ) {
      return [
        {"key": "${uId}_voltage", "x": valueX, "y": 790.0, "scale": 0.001, "dec": 2},
        {"key": "${uId}_current", "x": valueX, "y": 820.0, "scale": 1.0, "dec": 1},
        {"key": "${uId}_power", "x": valueX, "y": 850.0, "scale": 0.001, "dec": 3},
        {"key": "${uId}_reactive", "x": valueX, "y": 880.0, "scale": 0.001, "dec": 3},
        {"key": "${uId}_frequency", "x": valueX, "y": 910.0, "scale": 1.0, "dec": 2},
        {"key": "${uId}_power_factor", "x": valueX, "y": 940.0, "scale": 1.0, "dec": 3},
        {"key": "${uId}_speed", "x": valueX, "y": 970.0, "scale": 1.0, "dec": 0},
        {"key": "${uId}_guide_vane", "x": valueX, "y": 1000.0, "scale": 1.0, "dec": 1},
        {"key": "${uId}_header_power", "x": topP, "y": 40.0, "scale": 0.001, "dec": 3},
        {"key": "${uId}_header_reactive", "x": topQ, "y": 40.0, "scale": 0.001, "dec": 3},
      ];
    }

    final readoutsList = [
      ...getUnitReadoutLayout("u1", 410, 600, 760),
      ...getUnitReadoutLayout("u2", 810, 970, 1130),
      ...getUnitReadoutLayout("u3", 1210, 1360, 1520),
      {"key": "bus_voltage", "x": 1530.0, "y": 210.0, "scale": 1.0, "dec": 2},
      {"key": "bus_current", "x": 1530.0, "y": 240.0, "scale": 1.0, "dec": 1},
      {"key": "bus_power", "x": 1530.0, "y": 270.0, "scale": 0.001, "dec": 3},
      {"key": "bus_reactive", "x": 1690.0, "y": 270.0, "scale": 0.001, "dec": 3},
      {"key": "bus_apparent", "x": 1850.0, "y": 270.0, "scale": 0.001, "dec": 3},
      {"key": "bus_frequency", "x": 1690.0, "y": 300.0, "scale": 1.0, "dec": 2},
      {"key": "bus_power_factor", "x": 1530.0, "y": 300.0, "scale": 1.0, "dec": 3},
    ];

    for (var r in readoutsList) {
      addReadout(r["key"] as String, r["x"] as double, r["y"] as double, r["scale"] as double, r["dec"] as int);
    }

    return list;
  }
}

class Dakrosa1TelemetryPanel extends StatefulWidget {
  final MobileHydro hydro;
  final WinccSnapshot? winccSnapshot;

  const Dakrosa1TelemetryPanel({
    Key? key,
    required this.hydro,
    required this.winccSnapshot,
  }) : super(key: key);

  @override
  State<Dakrosa1TelemetryPanel> createState() => _Dakrosa1TelemetryPanelState();
}

class _Dakrosa1TelemetryPanelState extends State<Dakrosa1TelemetryPanel> {
  bool _d1UnitTelemetryExpanded = false;

  List<Map<String, dynamic>> getDakrosa1UnitReadouts(BuildContext context, MobileHydroUnit u, bool isScadaOnline) {
    final double? p = u.powerKw != null ? u.powerKw! / 1000.0 : null;
    final double? q = u.reactivePowerKvar != null ? u.reactivePowerKvar! / 1000.0 : null;
    final double? v = u.voltageV != null ? u.voltageV! / 1000.0 : null;

    return [
      {"label": context.tr("activePower"), "value": p, "unit": "MW", "dec": 3},
      {"label": context.tr("reactivePower"), "value": q, "unit": "MVAr", "dec": 3},
      {"label": context.tr("voltage"), "value": v, "unit": "kV", "dec": 2},
      {"label": context.tr("current"), "value": u.currentA, "unit": "A", "dec": 1},
      {"label": context.tr("frequency"), "value": u.frequencyHz, "unit": "Hz", "dec": 2},
      {"label": context.tr("powerFactor"), "value": u.powerFactor, "unit": "", "dec": 3},
      {"label": context.tr("speed"), "value": u.speedRpm, "unit": "rpm", "dec": 0},
      {"label": context.tr("guideVane"), "value": u.guideVanePercent, "unit": "%", "dec": 1},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.winccSnapshot;
    final isScadaOnline = widget.hydro.online && snap != null;

    return Container(
      color: const Color(0xFF0F172A),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _d1UnitTelemetryExpanded = !_d1UnitTelemetryExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF334155), width: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.triangle_fill, color: Color(0xFFFACC15), size: 10),
                      const SizedBox(width: 6),
                      Text(
                        context.tr("dakrosa1TelemetryHeader"),
                        style: const TextStyle(
                          color: Color(0xFFFACC15),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _d1UnitTelemetryExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    color: const Color(0xFF94A3B8),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          if (_d1UnitTelemetryExpanded) ...[
            Container(
              height: 280,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.hydro.units.length,
                itemBuilder: (context, index) {
                  final u = widget.hydro.units[index];
                  final uNum = index + 1;
                  final readouts = getDakrosa1UnitReadouts(context, u, isScadaOnline);
                  
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155), width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.trArgs("generatorWithNum", [uNum]),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isScadaOnline ? context.tr("hasSignal") : context.tr("noSignal"),
                              style: TextStyle(
                                color: isScadaOnline ? AppTheme.green : AppTheme.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Divider(color: Color(0xFF334155), height: 1),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 4,
                                  itemBuilder: (context, idx) {
                                    final item = readouts[idx];
                                    final double? val = item["value"] as double?;
                                    final String text = val == null ? "—" : val.toStringAsFixed(item["dec"] as int);
                                    final displayVal = val == null ? text : "$text ${item["unit"]!}".trim();
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["label"] as String,
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            displayVal,
                                            style: TextStyle(
                                              color: val == null ? const Color(0xFF64748B) : Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 4,
                                  itemBuilder: (context, idx) {
                                    final item = readouts[idx + 4];
                                    final double? val = item["value"] as double?;
                                    final String text = val == null ? "—" : val.toStringAsFixed(item["dec"] as int);
                                    final displayVal = val == null ? text : "$text ${item["unit"]!}".trim();
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["label"] as String,
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            displayVal,
                                            style: TextStyle(
                                              color: val == null ? const Color(0xFF64748B) : Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                context.tr("scadaDisclaimer"),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
