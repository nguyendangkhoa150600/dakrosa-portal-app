import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/mobile_model.dart';
import '../../models/wincc_model.dart';
import '../../theme/app_theme.dart';
import '../../services/localization_service.dart';

class Dakrosa2CanvasDiagram extends StatelessWidget {
  final MobileHydro hydro;

  const Dakrosa2CanvasDiagram({
    Key? key,
    required this.hydro,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;

    double openingPercent = 0.0;
    if (isScadaOnline) {
      final openingRaw = scada.values["scada_opening_raw"];
      if (openingRaw != null) {
        openingPercent = math.max(0.0, math.min(100.0, openingRaw));
      }
    }
    final double openingHeight = (314.0 * openingPercent) / 100.0;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1920,
          height: 847,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.network(
                  "https://dakrosa.svnagentic.site/dakrosa/scada/A_22kV.svg?v=96efbd4b",
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

              if (openingPercent > 0)
                Positioned(
                  left: 83,
                  top: (397 - openingHeight),
                  width: 104,
                  height: openingHeight,
                  child: Container(
                    color: const Color(0xFF00FFFF).withValues(alpha: 0.28),
                  ),
                ),

              ..._buildDakrosa2Readouts(hydro, 1.0, 1.0),
              ..._buildDakrosa2Breakers(hydro, 1.0, 1.0),
              ..._buildDakrosa2Indicators(hydro, 1.0, 1.0),
              ..._buildDakrosa2Generators(hydro, 1.0, 1.0),
              _buildDakrosa2EnergyPanel(1.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDakrosa2Readouts(MobileHydro hydro, double scaleX, double scaleY) {
    final list = <Widget>[];
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;

    final readoutDefs = [
      {"tag": "H1-Itb", "x": 420.0, "y": 745.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u1_I_avg", "type": "readout"},
      {"tag": "H1-Uptb", "x": 420.0, "y": 765.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u1_U_avg", "type": "readout"},
      {"tag": "H1-KW", "x": 420.0, "y": 785.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u1_P", "type": "readout"},
      {"tag": "H1-KVAr", "x": 420.0, "y": 805.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u1_Q", "type": "readout"},
      {"tag": "H1-Speed", "x": 420.0, "y": 825.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u1_speed", "type": "readout"},

      {"tag": "H2-Itb", "x": 866.0, "y": 745.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u2_I_avg", "type": "readout"},
      {"tag": "H2-Uptb", "x": 866.0, "y": 765.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u2_U_avg", "type": "readout"},
      {"tag": "H2-KW", "x": 866.0, "y": 785.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u2_P", "type": "readout"},
      {"tag": "H2-KVAr", "x": 866.0, "y": 805.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u2_Q", "type": "readout"},
      {"tag": "H2-Speed", "x": 866.0, "y": 825.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u2_speed", "type": "readout"},

      {"tag": "H3-Itb", "x": 1312.0, "y": 745.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u3_I_avg", "type": "readout"},
      {"tag": "H3-Uptb", "x": 1312.0, "y": 765.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u3_U_avg", "type": "readout"},
      {"tag": "H3-KW", "x": 1312.0, "y": 785.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u3_P", "type": "readout"},
      {"tag": "H3-KVAr", "x": 1312.0, "y": 805.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u3_Q", "type": "readout"},
      {"tag": "H3-Speed", "x": 1312.0, "y": 825.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "u3_speed", "type": "readout"},

      {"tag": "T2-Itb", "x": 622.0, "y": 308.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "bus_I_avg", "type": "readout"},
      {"tag": "T2-Uptb", "x": 622.0, "y": 328.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "bus_U_avg", "type": "readout"},
      {"tag": "T2-KW", "x": 622.0, "y": 348.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "bus_P", "type": "readout"},
      {"tag": "T2-KVAr", "x": 622.0, "y": 368.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "bus_Q", "type": "readout"},
      {"tag": "T2-F", "x": 622.0, "y": 388.0, "w": 46.0, "h": 16.0, "dec": 2, "k": "bus_F", "type": "readout"},
      {"tag": "T2-Cosphi", "x": 622.0, "y": 408.0, "w": 46.0, "h": 16.0, "dec": 3, "k": "bus_PF", "type": "readout"},

      {"tag": "T1-Itb", "x": 1780.0, "y": 272.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "hv_I_avg", "type": "readout"},
      {"tag": "T1-Uptb", "x": 1780.0, "y": 292.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "hv_U_avg", "type": "readout"},
      {"tag": "T1-KW", "x": 1780.0, "y": 312.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "hv_P", "type": "readout"},
      {"tag": "T1-KVAr", "x": 1780.0, "y": 332.0, "w": 46.0, "h": 16.0, "dec": 0, "k": "hv_Q", "type": "readout"},
      {"tag": "T1-F", "x": 1780.0, "y": 352.0, "w": 46.0, "h": 16.0, "dec": 2, "k": "hv_F", "type": "readout"},
      {"tag": "T1-U1N", "x": 1780.0, "y": 372.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "hv_U1N", "type": "readout"},
    ];

    for (final def in readoutDefs) {
      final double x = def["x"] as double;
      final double y = def["y"] as double;
      final double w = def["w"] as double;
      final double h = def["h"] as double;
      final int dec = def["dec"] as int;
      final String k = def["k"] as String;

      final val = isScadaOnline ? scada.readouts[k] : null;
      final String text = val == null ? "—" : val.toStringAsFixed(dec);
      final isNull = val == null;

      final isLarge = h >= 30;

      list.add(
        Positioned(
          left: x * scaleX,
          top: y * scaleY,
          width: w * scaleX,
          height: h * scaleY,
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
                  fontSize: isLarge ? 16 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return list;
  }

  List<Widget> _buildDakrosa2Breakers(MobileHydro hydro, double scaleX, double scaleY) {
    final list = <Widget>[];
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;

    final breakerDefs = [
      {"id": "471", "x": 1218.0, "y": 313.0, "w": 28.0, "h": 28.0, "k": "scada_471_close_raw"},
      {"id": "QF1", "x": 328.0, "y": 663.0, "w": 28.0, "h": 28.0, "k": "u1_qf_close_raw"},
      {"id": "QF2", "x": 774.0, "y": 663.0, "w": 28.0, "h": 28.0, "k": "u2_qf_close_raw"},
      {"id": "QF3", "x": 1220.0, "y": 663.0, "w": 28.0, "h": 28.0, "k": "u3_qf_close_raw"},
    ];

    for (final def in breakerDefs) {
      final double x = def["x"] as double;
      final double y = def["y"] as double;
      final double w = def["w"] as double;
      final double h = def["h"] as double;
      final String k = def["k"] as String;

      final val = isScadaOnline ? scada.values[k] : null;
      Color color = const Color(0xFF64748B);
      if (val != null) {
        color = (val == 1.0) ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
      }

      list.add(
        Positioned(
          left: x * scaleX,
          top: y * scaleY,
          width: w * scaleX,
          height: h * scaleY,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.88),
              border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
            ),
          ),
        ),
      );
    }

    return list;
  }

  List<Widget> _buildDakrosa2Indicators(MobileHydro hydro, double scaleX, double scaleY) {
    final list = <Widget>[];
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;

    final indicatorDefs = [
      {"id": "H1_run", "x": 420.0, "y": 725.0, "k": "u1_P"},
      {"id": "H2_run", "x": 866.0, "y": 725.0, "k": "u2_P"},
      {"id": "H3_run", "x": 1312.0, "y": 725.0, "k": "u3_P"},
    ];

    for (final def in indicatorDefs) {
      final double x = def["x"] as double;
      final double y = def["y"] as double;
      final String k = def["k"] as String;

      final val = isScadaOnline ? scada.readouts[k] : null;
      Color color = const Color(0xFF64748B);
      if (val != null) {
        color = (val > 10.0) ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      }

      list.add(
        Positioned(
          left: (x + 10.0) * scaleX,
          top: (y + 10.0) * scaleY,
          child: Container(
            width: 16.0 * scaleX,
            height: 16.0 * scaleY,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
            ),
          ),
        ),
      );
    }

    return list;
  }

  List<Widget> _buildDakrosa2Generators(MobileHydro hydro, double scaleX, double scaleY) {
    final list = <Widget>[];
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;

    final genDefs = [
      {"id": "G1", "x": 312.0, "y": 726.0, "w": 60.0, "h": 60.0, "k": "u1_P"},
      {"id": "G2", "x": 758.0, "y": 726.0, "w": 60.0, "h": 60.0, "k": "u2_P"},
      {"id": "G3", "x": 1204.0, "y": 726.0, "w": 60.0, "h": 60.0, "k": "u3_P"},
    ];

    for (final def in genDefs) {
      final double x = def["x"] as double;
      final double y = def["y"] as double;
      final double w = def["w"] as double;
      final double h = def["h"] as double;
      final String k = def["k"] as String;

      final val = isScadaOnline ? scada.readouts[k] : null;
      Color color = const Color(0xFF64748B);
      if (val != null) {
        color = (val > 10.0) ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      }

      list.add(
        Positioned(
          left: (x + w / 2 - 28.0) * scaleX,
          top: (y + h / 2 - 28.0) * scaleY,
          child: Container(
            width: 56.0 * scaleX,
            height: 56.0 * scaleY,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.86),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFFF00), width: 1.5),
            ),
          ),
        ),
      );
    }

    return list;
  }

  Widget _buildDakrosa2EnergyPanel(double scaleX, double scaleY) {
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;

    final double? apImport = isScadaOnline ? scada.values["scada_aux_lcu41_iw0_raw"] : null;
    final double? apExport = isScadaOnline ? scada.values["scada_open_full_raw"] : null;
    final double? aqImport = isScadaOnline ? scada.values["scada_close_full_raw"] : null;
    final double? aqExport = isScadaOnline ? scada.values["scada_motor_status_raw"] : null;

    Widget buildRow(String label, String unit, double? value) {
      final valStr = value == null ? "—" : value.toStringAsFixed(1);
      return Container(
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF500),
          border: Border(bottom: BorderSide(color: Colors.white, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF050505), fontFamily: "Arial", fontSize: 9, fontWeight: FontWeight.bold)),
            Text(valStr, style: const TextStyle(color: Color(0xFF050505), fontFamily: "Arial", fontSize: 9, fontWeight: FontWeight.bold)),
            Text(unit, style: const TextStyle(color: Color(0xFF050505), fontFamily: "Arial", fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Positioned(
      left: 1740.0 * scaleX,
      top: 154.0 * scaleY,
      width: 140.0 * scaleX,
      height: 90.0 * scaleY,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF500),
          border: Border.all(color: const Color(0xFF202020), width: 1.0),
        ),
        child: Column(
          children: [
            buildRow("AP+ =", "kWh", apImport),
            buildRow("AP- =", "kWh", apExport),
            buildRow("AQ+ =", "kVArh", aqImport),
            buildRow("AQ- =", "kVArh", aqExport),
          ],
        ),
      ),
    );
  }
}

class Dakrosa2TelemetryPanel extends StatefulWidget {
  final MobileHydro hydro;
  final WinccSnapshot? winccSnapshot;

  const Dakrosa2TelemetryPanel({
    Key? key,
    required this.hydro,
    required this.winccSnapshot,
  }) : super(key: key);

  @override
  State<Dakrosa2TelemetryPanel> createState() => _Dakrosa2TelemetryPanelState();
}

class _Dakrosa2TelemetryPanelState extends State<Dakrosa2TelemetryPanel> {
  bool _unitTelemetryExpanded = false;
  bool _rawTelemetryExpanded = false;

  static const Map<String, String> _rawLabelsVi = {
    "scada_471_close_raw": "Trạng thái máy cắt 471",
    "u1_qf_close_raw": "Trạng thái QF tổ máy 1",
    "u2_qf_close_raw": "Trạng thái QF tổ máy 2",
    "u3_qf_close_raw": "Trạng thái QF tổ máy 3",
    "u1_comgroup_raw": "Nhóm tín hiệu tổ máy 1",
    "u2_comgroup_raw": "Nhóm tín hiệu tổ máy 2",
    "u3_comgroup_raw": "Nhóm tín hiệu tổ máy 3",
    "scada_aux_lcu41_iw0_raw": "Tín hiệu phụ LCU41",
    "scada_open_full_raw": "Giới hạn mở hoàn toàn",
    "scada_close_full_raw": "Giới hạn đóng hoàn toàn",
    "scada_motor_status_raw": "Trạng thái động cơ",
    "scada_overload_raw": "Quá tải động cơ",
    "scada_phase_fault_raw": "Lỗi pha",
    "scada_remote_local_raw": "Chế độ tại chỗ/từ xa",
    "scada_opening_raw": "Độ mở cửa nhận nước",
    "scada_pressure_1_raw": "Áp suất 1",
    "scada_pressure_2_raw": "Áp suất 2",
    "scada_high_pressure_raw": "Áp suất cao",
    "u1_excitation_voltage_raw": "Điện áp kích từ tổ máy 1",
    "u2_excitation_voltage_raw": "Điện áp kích từ tổ máy 2",
    "u3_excitation_voltage_raw": "Điện áp kích từ tổ máy 3",
    "u1_excitation_current_raw": "Dòng kích từ tổ máy 1",
    "u2_excitation_current_raw": "Dòng kích từ tổ máy 2",
    "u3_excitation_current_raw": "Dòng kích từ tổ máy 3",
  };

  static const Map<String, String> _rawLabelsEn = {
    "scada_471_close_raw": "Breaker 471 status",
    "u1_qf_close_raw": "Unit 1 QF status",
    "u2_qf_close_raw": "Unit 2 QF status",
    "u3_qf_close_raw": "Unit 3 QF status",
    "u1_comgroup_raw": "Unit 1 signal group",
    "u2_comgroup_raw": "Unit 2 signal group",
    "u3_comgroup_raw": "Unit 3 signal group",
    "scada_aux_lcu41_iw0_raw": "LCU41 auxiliary signal",
    "scada_open_full_raw": "Fully open limit",
    "scada_close_full_raw": "Fully closed limit",
    "scada_motor_status_raw": "Motor status",
    "scada_overload_raw": "Motor overload",
    "scada_phase_fault_raw": "Phase fault",
    "scada_remote_local_raw": "Local/Remote mode",
    "scada_opening_raw": "Water intake opening",
    "scada_pressure_1_raw": "Pressure 1",
    "scada_pressure_2_raw": "Pressure 2",
    "scada_high_pressure_raw": "High pressure",
    "u1_excitation_voltage_raw": "Unit 1 excitation voltage",
    "u2_excitation_voltage_raw": "Unit 2 excitation voltage",
    "u3_excitation_voltage_raw": "Unit 3 excitation voltage",
    "u1_excitation_current_raw": "Unit 1 excitation current",
    "u2_excitation_current_raw": "Unit 2 excitation current",
    "u3_excitation_current_raw": "Unit 3 excitation current",
  };

  List<Map<String, String>> getUnitReadoutDefinitions(BuildContext context, int u) {
    return [
      {"label": "${context.tr("current")} L1", "key": "u${u}_I1", "unit": "A", "dec": "1"},
      {"label": "${context.tr("current")} L2", "key": "u${u}_I2", "unit": "A", "dec": "1"},
      {"label": "${context.tr("current")} L3", "key": "u${u}_I3", "unit": "A", "dec": "1"},
      {"label": "${context.tr("voltage")} U12", "key": "u${u}_U12", "unit": "V", "dec": "1"},
      {"label": "${context.tr("voltage")} U23", "key": "u${u}_U23", "unit": "V", "dec": "1"},
      {"label": "${context.tr("voltage")} U31", "key": "u${u}_U31", "unit": "V", "dec": "1"},
      {"label": context.tr("powerFactor"), "key": "u${u}_PF", "unit": "", "dec": "3"},
      {"label": context.tr("totalGeneration"), "key": "u${u}_KWh", "unit": "kWh", "dec": "1"},
      {"label": "${context.tr("temperature")} 1", "key": "u${u}_temp1", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 2", "key": "u${u}_temp2", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 3", "key": "u${u}_temp3", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 4", "key": "u${u}_temp4", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 5", "key": "u${u}_temp5", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 6", "key": "u${u}_temp6", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 7", "key": "u${u}_temp7", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 8", "key": "u${u}_temp8", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 9", "key": "u${u}_temp9", "unit": "°C", "dec": "1"},
      {"label": "${context.tr("temperature")} 10", "key": "u${u}_temp10", "unit": "°C", "dec": "1"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnitTelemetryDetailsPanel(context, widget.hydro),
        _buildRawTelemetryDetailsPanel(context, widget.hydro),
      ],
    );
  }

  Widget _buildUnitTelemetryDetailsPanel(BuildContext context, MobileHydro hydro) {
    final snap = widget.winccSnapshot;
    
    int total = 0;
    int available = 0;
    
    final unitStats = <int, int>{};
    final unitTotals = <int, int>{};
    
    for (int u = 1; u <= 3; u++) {
      final defs = getUnitReadoutDefinitions(context, u);
      unitTotals[u] = defs.length;
      total += defs.length;
      
      int uAvail = 0;
      for (final def in defs) {
        final val = snap?.tags[def["key"]]?.last;
        if (val != null) {
          uAvail++;
        }
      }
      unitStats[u] = uAvail;
      available += uAvail;
    }

    return Container(
      color: const Color(0xFF0F172A),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _unitTelemetryExpanded = !_unitTelemetryExpanded;
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
                        context.trArgs("readoutsWithDataHeader", [available, total]),
                        style: const TextStyle(
                          color: Color(0xFFFACC15),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _unitTelemetryExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    color: const Color(0xFF94A3B8),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          
          if (_unitTelemetryExpanded) ...[
            Container(
              height: 280,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final uNum = index + 1;
                  final defs = getUnitReadoutDefinitions(context, uNum);
                  
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
                              context.trArgs("turbineH", [uNum]),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              context.trArgs("hasDataCount", [unitStats[uNum], unitTotals[uNum]]),
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
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
                                  itemCount: 9,
                                  itemBuilder: (context, idx) {
                                    final item = defs[idx];
                                    final val = snap?.tags[item["key"]]?.last;
                                    final text = val == null ? "—" : val.toStringAsFixed(int.parse(item["dec"]!));
                                    final displayVal = val == null ? text : "$text ${item["unit"]!}".trim();
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["label"]!,
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            displayVal,
                                            style: TextStyle(
                                              color: val == null ? const Color(0xFF64748B) : Colors.white,
                                              fontSize: 10,
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
                                  itemCount: 9,
                                  itemBuilder: (context, idx) {
                                    final item = defs[idx + 9];
                                    final val = snap?.tags[item["key"]]?.last;
                                    final text = val == null ? "—" : val.toStringAsFixed(int.parse(item["dec"]!));
                                    final displayVal = val == null ? text : "$text ${item["unit"]!}".trim();
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["label"]!,
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            displayVal,
                                            style: TextStyle(
                                              color: val == null ? const Color(0xFF64748B) : Colors.white,
                                              fontSize: 10,
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
                context.tr("dakrosa2TelemetryFootnote"),
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

  Widget _buildRawTelemetryDetailsPanel(BuildContext context, MobileHydro hydro) {
    final snap = widget.winccSnapshot;
    final isVi = appLocale.value.languageCode == 'vi';
    final rawLabels = isVi ? _rawLabelsVi : _rawLabelsEn;
    final keys = rawLabels.keys.toList();

    return Container(
      color: const Color(0xFF0F172A),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _rawTelemetryExpanded = !_rawTelemetryExpanded;
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
                      const Icon(CupertinoIcons.triangle_fill, color: Color(0xFF38BDF8), size: 10),
                      const SizedBox(width: 6),
                      Text(
                        context.tr("additionalStatusHeader"),
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _rawTelemetryExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    color: const Color(0xFF94A3B8),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          if (_rawTelemetryExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final label = rawLabels[key]!;
                  final val = snap?.tags[key]?.last;
                  final String text = val == null ? "—" : val.toString();

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155), width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          text,
                          style: TextStyle(
                            color: val == null ? const Color(0xFF64748B) : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                context.tr("dakrosa2StatusFootnote"),
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
