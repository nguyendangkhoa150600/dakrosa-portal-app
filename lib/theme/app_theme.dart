import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu sắc chuẩn Premium
  static const Color bg = Color(0xFFF6F8FA);
  static const Color surface = Colors.white;
  static const Color hairline = Color(0xFFECEEF2);
  
  static const Color ink = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF475569);
  static const Color faint = Color(0xFF94A3B8);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueSoft = Color(0x1A2563EB);

  static const Color green = Color(0xFF10B981);
  static const Color greenSoft = Color(0x1F10B981);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0x1FF59E0B);

  static const Color red = Color(0xFFEF4444);
  static const Color redSoft = Color(0x1FEF4444);

  // Gradient cam vàng cao cấp cho Solar (khớp mockup)
  static const LinearGradient solarGradient = LinearGradient(
    colors: [Color(0xFFFE8C00), Color(0xFFF85E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient xanh teal cao cấp cho Thủy điện (WinCC)
  static const LinearGradient hydroGradient = LinearGradient(
    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow mịn màng cho thẻ chỉ số
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.06),
      offset: const Offset(0, 12),
      blurRadius: 32,
      spreadRadius: -12,
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        background: bg,
        surface: surface,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: ink, fontSize: 16),
        bodyMedium: TextStyle(color: secondary, fontSize: 14),
      ),
    );
  }

  // Kiểu chữ monospace cho số SCADA
  static TextStyle get monoTextStyle {
    return const TextStyle(
      fontFamily: 'monospace',
      fontFeatures: [FontFeature.tabularFigures()],
      letterSpacing: -0.5,
    );
  }
}
