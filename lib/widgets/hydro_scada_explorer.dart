import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/mobile_model.dart';
import '../models/wincc_model.dart';
import '../theme/app_theme.dart';
import 'scada/dakrosa1_scada_canvas.dart';
import 'scada/dakrosa2_scada_canvas.dart';
import 'scada/dakrosa2_unit_pdl_canvas.dart';
import '../services/localization_service.dart';

class HydroScadaExplorer extends StatefulWidget {
  final String station;
  final WinccSnapshot? winccSnapshot;

  const HydroScadaExplorer({
    Key? key,
    required this.station,
    required this.winccSnapshot,
  }) : super(key: key);

  @override
  State<HydroScadaExplorer> createState() => _HydroScadaExplorerState();
}

class _HydroScadaExplorerState extends State<HydroScadaExplorer> {
  String _selectedDakrosa2Screen = "a22"; // "a22" | "u1" | "u2" | "u3"

  // Mapper to transform the raw WinccSnapshot tags into the unified MobileHydro model
  MobileHydro _buildMobileHydro() {
    final station = widget.station;
    final snapshot = widget.winccSnapshot;

    if (snapshot == null) {
      return MobileHydro(
        station: station,
        online: false,
        runningUnits: 0,
        unitCount: 3,
        metrics: [],
        units: [],
      );
    }

    final tags = snapshot.tags;

    double? getTagVal(String key) {
      return tags[key]?.last;
    }

    double? getUnitVal(String unitId, String d2Suffix, String d1Suffix) {
      final uNum = unitId.substring(1);
      return getTagVal("${unitId}_$d2Suffix") ?? getTagVal("H$uNum-$d1Suffix");
    }

    // Build values and readouts maps for MobileHydroScada
    final valuesMap = <String, double>{};
    final readoutsMap = <String, double>{};

    final rawKeys = [
      "scada_471_close_raw",
      "u1_qf_close_raw",
      "u2_qf_close_raw",
      "u3_qf_close_raw",
      "u1_comgroup_raw",
      "u2_comgroup_raw",
      "u3_comgroup_raw",
      "scada_aux_lcu41_iw0_raw",
      "scada_open_full_raw",
      "scada_close_full_raw",
      "scada_motor_status_raw",
      "scada_overload_raw",
      "scada_phase_fault_raw",
      "scada_remote_local_raw",
      "scada_opening_raw",
      "scada_pressure_1_raw",
      "scada_pressure_2_raw",
      "scada_high_pressure_raw",
      "u1_excitation_voltage_raw",
      "u2_excitation_voltage_raw",
      "u3_excitation_voltage_raw",
      "u1_excitation_current_raw",
      "u2_excitation_current_raw",
      "u3_excitation_current_raw",
    ];

    for (final key in rawKeys) {
      final val = getTagVal(key);
      if (val != null) {
        valuesMap[key] = val;
      }
    }

    final readoutKeys = [
      // u1
      "u1_P", "u1_Q", "u1_I_avg", "u1_U_avg", "u1_speed",
      "u1_I1", "u1_I2", "u1_I3", "u1_U12", "u1_U23", "u1_U31",
      "u1_PF", "u1_KWh",
      // u2
      "u2_P", "u2_Q", "u2_I_avg", "u2_U_avg", "u2_speed",
      "u2_I1", "u2_I2", "u2_I3", "u2_U12", "u2_U23", "u2_U31",
      "u2_PF", "u2_KWh",
      // u3
      "u3_P", "u3_Q", "u3_I_avg", "u3_U_avg", "u3_speed",
      "u3_I1", "u3_I2", "u3_I3", "u3_U12", "u3_U23", "u3_U31",
      "u3_PF", "u3_KWh",
      // bus
      "bus_P", "bus_Q", "bus_I_avg", "bus_U_avg", "bus_F", "bus_PF",
      // hv
      "hv_P", "hv_Q", "hv_I_avg", "hv_U_avg", "hv_U1N", "hv_F"
    ];

    for (int u = 1; u <= 3; u++) {
      for (int t = 1; t <= 10; t++) {
        readoutKeys.add("u${u}_temp$t");
      }
    }

    for (final key in readoutKeys) {
      final val = getTagVal(key);
      if (val != null) {
        readoutsMap[key] = val;
      }
    }

    final scadaData = MobileHydroScada(
      readOnly: true,
      source: snapshot.source ?? "wincc",
      updatedAt: snapshot.receivedAt,
      values: valuesMap,
      readouts: readoutsMap,
    );

    final unitsList = <MobileHydroUnit>[];
    int runningUnitsCount = 0;

    for (int i = 1; i <= 3; i++) {
      final unitId = "u$i";
      final speed = getUnitVal(unitId, "speed", "Speed") ?? 0.0;
      final power = getUnitVal(unitId, "P", "KW") ?? 0.0;
      final running = speed > 10.0 || power > 10.0;
      if (running) runningUnitsCount++;

      unitsList.add(
        MobileHydroUnit(
          id: unitId,
          name: "Tổ máy H$i",
          running: running,
          powerKw: power,
          reactivePowerKvar: getUnitVal(unitId, "Q", "KVAr"),
          apparentPowerKva: null,
          voltageV: getUnitVal(unitId, "U_avg", "Uptb"),
          currentA: getUnitVal(unitId, "I_avg", "Itb"),
          frequencyHz: getTagVal("bus_F") ?? getTagVal("bus_frequency"),
          powerFactor: getUnitVal(unitId, "PF", "PF"),
          guideVanePercent: getUnitVal(unitId, "guide_vane", "Cánh hướng"),
          speedRpm: speed,
          metrics: [],
        ),
      );
    }

    return MobileHydro(
      station: station,
      online: snapshot.error == null,
      receivedAt: snapshot.receivedAt,
      snapshotUtc: snapshot.snapshotUtc,
      powerKw: getTagVal("bus_P") ?? getTagVal("bus_power"),
      reactivePowerKvar: getTagVal("bus_Q") ?? getTagVal("bus_reactive"),
      apparentPowerKva: getTagVal("bus_S") ?? getTagVal("bus_apparent"),
      voltageKv: getTagVal("bus_U12") ?? getTagVal("bus_voltage") ?? getTagVal("bus_voltage_kv"),
      currentA: getTagVal("bus_I_avg") ?? getTagVal("bus_current"),
      frequencyHz: getTagVal("bus_F") ?? getTagVal("bus_frequency"),
      powerFactor: getTagVal("bus_PF") ?? getTagVal("bus_power_factor"),
      runningUnits: runningUnitsCount,
      unitCount: 3,
      metrics: [],
      units: unitsList,
      scada: scadaData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDakrosa1 = widget.station == "Dakrosa1";
    final hydro = _buildMobileHydro();

    return Container(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("operatingDiagram"),
                        style: const TextStyle(
                          color: AppTheme.faint,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDakrosa1
                            ? context.tr("dakrosa1DiagramTitle")
                            : context.tr("dakrosa2DiagramTitle"),
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusIndicator(hydro),
              ],
            ),
          ),

          // Station 2b Tab control (for Dakrosa 2 explorer)
          if (!isDakrosa1) _buildDakrosa2TabBar(),

          // Main Canvas with InteractiveViewer
          ClipRRect(
            borderRadius: ((!isDakrosa1 && _selectedDakrosa2Screen == "a22") || isDakrosa1)
                ? BorderRadius.zero
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
            child: Container(
              color: const Color(0xFF0F172A),
              height: 240,
              width: double.infinity,
              child: Stack(
                children: [
                  InteractiveViewer(
                    maxScale: 5.0,
                    minScale: 1.0,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: isDakrosa1
                            ? (1920 / 1080)
                            : (1920 / 847),
                        child: _buildCanvasContent(isDakrosa1, hydro),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.zoom_in, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            context.tr("zoomHint"),
                            style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FullscreenScadaPage(
                              isDakrosa1: isDakrosa1,
                              hydro: hydro,
                              screenId: _selectedDakrosa2Screen,
                              winccSnapshot: widget.winccSnapshot,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.fullscreen,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isDakrosa1) ...[
            Dakrosa1TelemetryPanel(
              hydro: hydro,
              winccSnapshot: widget.winccSnapshot,
            ),
          ] else if (_selectedDakrosa2Screen == "a22") ...[
            Dakrosa2TelemetryPanel(
              hydro: hydro,
              winccSnapshot: widget.winccSnapshot,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(MobileHydro hydro) {
    final bool isScadaOnline = hydro.online && hydro.scada != null;
    final color = isScadaOnline ? AppTheme.green : AppTheme.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isScadaOnline ? context.tr("winccOnline") : context.tr("signalLost"),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDakrosa2TabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildDakrosa2TabItem("a22", context.tr("scada22kvDiagram")),
            _buildDakrosa2TabItem("u1", context.trArgs("turbineH", [1])),
            _buildDakrosa2TabItem("u2", context.trArgs("turbineH", [2])),
            _buildDakrosa2TabItem("u3", context.trArgs("turbineH", [3])),
          ],
        ),
      ),
    );
  }

  Widget _buildDakrosa2TabItem(String screenId, String label) {
    final active = _selectedDakrosa2Screen == screenId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDakrosa2Screen = screenId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _buildCanvasContent(bool isDakrosa1, MobileHydro hydro) {
    if (isDakrosa1) {
      return Dakrosa1CanvasDiagram(hydro: hydro);
    } else {
      if (_selectedDakrosa2Screen == "a22") {
        return Dakrosa2CanvasDiagram(hydro: hydro);
      } else {
        return Dakrosa2UnitPdlCanvas(
          unitId: _selectedDakrosa2Screen,
          hydro: hydro,
          winccSnapshot: widget.winccSnapshot,
        );
      }
    }
  }
}

class FullscreenScadaPage extends StatefulWidget {
  final bool isDakrosa1;
  final MobileHydro hydro;
  final String screenId;
  final WinccSnapshot? winccSnapshot;

  const FullscreenScadaPage({
    Key? key,
    required this.isDakrosa1,
    required this.hydro,
    required this.screenId,
    required this.winccSnapshot,
  }) : super(key: key);

  @override
  State<FullscreenScadaPage> createState() => _FullscreenScadaPageState();
}

class _FullscreenScadaPageState extends State<FullscreenScadaPage> {
  bool _isRotated = false;

  @override
  Widget build(BuildContext context) {
    Widget canvas;
    if (widget.isDakrosa1) {
      canvas = Dakrosa1CanvasDiagram(hydro: widget.hydro);
    } else {
      if (widget.screenId == "a22") {
        canvas = Dakrosa2CanvasDiagram(hydro: widget.hydro);
      } else {
        canvas = Dakrosa2UnitPdlCanvas(
          unitId: widget.screenId,
          hydro: widget.hydro,
          winccSnapshot: widget.winccSnapshot,
        );
      }
    }

    if (_isRotated) {
      canvas = RotatedBox(
        quarterTurns: 1,
        child: canvas,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isDakrosa1
                        ? context.tr("dakrosa1FullscreenTitle")
                        : context.trArgs("dakrosa2FullscreenTitle", [
                            widget.screenId == "a22"
                                ? context.tr("scada22kvDiagram")
                                : context.trArgs("turbineH", [widget.screenId.substring(1).toUpperCase()])
                          ]),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isRotated ? CupertinoIcons.device_phone_portrait : CupertinoIcons.device_phone_landscape,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isRotated = !_isRotated;
                          });
                        },
                        tooltip: context.tr("fullscreenRotateTooltip"),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: context.tr("close"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Canvas View Area
            Expanded(
              child: InteractiveViewer(
                maxScale: 10.0,
                minScale: 0.5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: widget.isDakrosa1
                        ? (1920 / 1080)
                        : (1920 / 847),
                    child: canvas,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
