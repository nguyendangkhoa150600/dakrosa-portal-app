import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/mobile_model.dart';
import '../../models/wincc_model.dart';
import '../../theme/app_theme.dart';
import '../../services/localization_service.dart';

class Dakrosa2UnitPdlCanvas extends StatelessWidget {
  final String unitId;
  final MobileHydro hydro;
  final WinccSnapshot? winccSnapshot;

  const Dakrosa2UnitPdlCanvas({
    Key? key,
    required this.unitId,
    required this.hydro,
    required this.winccSnapshot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildDakrosa2UnitPdlCanvas(context, unitId, hydro);
  }

  Widget _buildDakrosa2UnitPdlCanvas(BuildContext context, String unitId, MobileHydro hydro) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 900,
          height: 600,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.network(
                  "https://dakrosa.svnagentic.site/dakrosa/scada/Dakrosa2_UnitPDL.svg",
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
              ..._buildDakrosa2UnitGauges(context, unitId, hydro, 1.0, 1.0),
              ..._buildDakrosa2UnitReadouts(unitId, hydro, 1.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDakrosa2UnitGauges(BuildContext context, String unitId, MobileHydro hydro, double scaleX, double scaleY) {
    final list = <Widget>[];
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;
    final isVi = appLocale.value.languageCode == 'vi';

    final uNum = unitId.substring(1);

    final gaugeDefs = [
      {"label": isVi ? "Nhiệt độ Stator 1" : "Stator Temp 1", "unit": "°C", "x": 133.0, "y": 91.0, "k": "u${uNum}_temp1"},
      {"label": isVi ? "Nhiệt độ Stator 2" : "Stator Temp 2", "unit": "°C", "x": 234.0, "y": 91.0, "k": "u${uNum}_temp2"},
      {"label": isVi ? "Nhiệt độ Stator 3" : "Stator Temp 3", "unit": "°C", "x": 335.0, "y": 91.0, "k": "u${uNum}_temp3"},
      {"label": isVi ? "Nhiệt độ Stator 4" : "Stator Temp 4", "unit": "°C", "x": 133.0, "y": 240.0, "k": "u${uNum}_temp4"},
      {"label": isVi ? "Nhiệt độ Stator 5" : "Stator Temp 5", "unit": "°C", "x": 234.0, "y": 240.0, "k": "u${uNum}_temp5"},
      {"label": isVi ? "Nhiệt độ Stator 6" : "Stator Temp 6", "unit": "°C", "x": 335.0, "y": 240.0, "k": "u${uNum}_temp6"},
      {"label": isVi ? "Gối trục hướng máy phát" : "Generator guide bearing", "unit": "°C", "x": 561.0, "y": 91.0, "k": "u${uNum}_temp7"},
      {"label": isVi ? "Gối trục hướng máy bơm" : "Pump guide bearing", "unit": "°C", "x": 662.0, "y": 91.0, "k": "u${uNum}_temp8"},
      {"label": isVi ? "Gối trục hướng tua bin" : "Turbine guide bearing", "unit": "°C", "x": 561.0, "y": 240.0, "k": "u${uNum}_temp9"},
      {"label": isVi ? "Gối đỡ ổ chặn" : "Thrust bearing", "unit": "°C", "x": 662.0, "y": 240.0, "k": "u${uNum}_temp10"},
    ];

    for (final def in gaugeDefs) {
      final double x = def["x"] as double;
      final double y = def["y"] as double;
      final String label = def["label"] as String;
      final String unit = def["unit"] as String;
      final String k = def["k"] as String;

      final val = isScadaOnline ? scada.readouts[k] : null;
      final valueText = val == null ? "—" : val.toStringAsFixed(1);

      list.add(
        Positioned(
          left: x * scaleX,
          top: y * scaleY,
          width: 90.0 * scaleX,
          height: 90.0 * scaleY,
          child: CustomPaint(
            painter: _ScadaGaugePainter(
              label: label,
              valueText: valueText,
              unit: unit,
              isOnline: val != null,
            ),
          ),
        ),
      );
    }

    return list;
  }

  List<Widget> _buildDakrosa2UnitReadouts(String unitId, MobileHydro hydro, double scaleX, double scaleY) {
    final list = <Widget>[];
    final scada = hydro.scada;
    final isScadaOnline = hydro.online && scada != null;

    final uNum = unitId.substring(1);

    final readoutDefs = [
      {"tag": "I1", "x": 139.0, "y": 489.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u${uNum}_I1"},
      {"tag": "I2", "x": 139.0, "y": 509.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u${uNum}_I2"},
      {"tag": "I3", "x": 139.0, "y": 529.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u${uNum}_I3"},

      {"tag": "U12", "x": 240.0, "y": 489.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u${uNum}_U12"},
      {"tag": "U23", "x": 240.0, "y": 509.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u${uNum}_U23"},
      {"tag": "U31", "x": 240.0, "y": 529.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u${uNum}_U31"},

      {"tag": "Cosphi", "x": 341.0, "y": 489.0, "w": 46.0, "h": 16.0, "dec": 3, "k": "u${uNum}_PF"},
      {"tag": "KWh", "x": 341.0, "y": 509.0, "w": 46.0, "h": 16.0, "dec": 1, "k": "u${uNum}_KWh"},
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
                  fontSize: h >= 25 ? 12 : 9,
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
}

class _ScadaGaugePainter extends CustomPainter {
  final String label;
  final String valueText;
  final String unit;
  final bool isOnline;

  const _ScadaGaugePainter({
    required this.label,
    required this.valueText,
    required this.unit,
    required this.isOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);

    final bgPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final fillPaint = Paint()
      ..color = isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius - 4, bgPaint);

    if (isOnline) {
      const double startAngle = -math.pi / 2;
      const double sweepAngle = 1.6 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        startAngle,
        sweepAngle,
        false,
        fillPaint,
      );
    }

    final bool isLarge = size.width > 60;

    final TextPainter labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFF94A3B8),
          fontSize: isLarge ? 8 : 5.5,
          fontWeight: FontWeight.bold,
          fontFamily: "Arial",
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout(maxWidth: size.width - 12);
    labelPainter.paint(
      canvas,
      Offset(
        (size.width - labelPainter.width) / 2,
        (isLarge ? 14 : 7) + (labelPainter.height / 2),
      ),
    );

    final TextPainter valPainter = TextPainter(
      text: TextSpan(
        text: valueText,
        style: TextStyle(
          color: isOnline ? Colors.white : const Color(0xFF64748B),
          fontSize: isLarge ? 15 : 10,
          fontWeight: FontWeight.bold,
          fontFamily: "Arial",
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    valPainter.layout(maxWidth: size.width);
    valPainter.paint(
      canvas,
      Offset(
        (size.width - valPainter.width) / 2,
        (size.height - valPainter.height) / 2,
      ),
    );

    final TextPainter unitPainter = TextPainter(
      text: TextSpan(
        text: unit,
        style: TextStyle(
          color: const Color(0xFF94A3B8),
          fontSize: isLarge ? 10 : 6.5,
          fontWeight: FontWeight.bold,
          fontFamily: "Arial",
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    unitPainter.layout(maxWidth: size.width);
    unitPainter.paint(
      canvas,
      Offset(
        (size.width - unitPainter.width) / 2,
        size.height - (isLarge ? 16 : 8) - (unitPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ScadaGaugePainter oldDelegate) =>
      oldDelegate.label != label ||
      oldDelegate.valueText != valueText ||
      oldDelegate.unit != unit ||
      oldDelegate.isOnline != isOnline;
}
