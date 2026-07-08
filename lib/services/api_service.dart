import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../models/solar_model.dart';
import '../models/wincc_model.dart';

// ==========================================
// CẤU HÌNH TÀI KHOẢN AURORAVISION QUA BIẾN MÔI TRƯỜNG
// ==========================================
// Đọc biến cấu hình môi trường giống hệt cơ chế process.env bên React.
// Khởi chạy Flutter bằng: flutter run --dart-define=AURORA_USER=xxx --dart-define=AURORA_PASS=yyy
const String auroraUser = String.fromEnvironment('AURORA_USER');
const String auroraPass = String.fromEnvironment('AURORA_PASS');
const String auroraEntity = String.fromEnvironment('AURORA_ENTITY', defaultValue: '25602751');
const String auroraGroup = String.fromEnvironment('AURORA_GROUP', defaultValue: '25602755');
const String auroraName = String.fromEnvironment('AURORA_NAME', defaultValue: 'Điện mặt trời Đăk Rosa');

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 25),
    receiveTimeout: const Duration(seconds: 25),
  ));

  // Base URL cho WinCC (vẫn gọi qua React vì WinCC là SCADA nội bộ không có Cloud API trực tiếp)
  String _baseUrl = "http://localhost:3000";
  
  // Cache token đăng nhập AuroraVision trong phiên chạy
  String? _cachedToken;
  DateTime? _tokenExpiry;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;

  // ==========================================
  // ĐĂNG NHẬP & GIAO TIẾP TRỰC TIẾP AURORAVISION
  // ==========================================

  Future<String> _getAuroraToken() async {
    if (auroraUser.isEmpty || auroraPass.isEmpty) {
      throw Exception("Chưa cấu hình tài khoản AuroraVision (auroraUser / auroraPass) ở đầu tệp api_service.dart");
    }

    if (_cachedToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return _cachedToken!;
    }

    print("🔑 [ApiService] Đang đăng nhập trực tiếp vào AuroraVision net...");
    final basic = base64Encode(utf8.encode("$auroraUser:$auroraPass"));
    
    final response = await _dio.get(
      "https://www.auroravision.net/ums/v1/login?setCookie=true",
      options: Options(
        headers: {
          "Authorization": "Basic $basic",
          "Accept": "application/json",
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Đăng nhập AuroraVision thất bại: HTTP ${response.statusCode}");
    }

    final cookies = response.headers["set-cookie"] ?? [];
    String token = "";
    for (final cookie in cookies) {
      if (cookie.contains("token.auroravision.net=")) {
        final parts = cookie.split(";");
        for (final p in parts) {
          if (p.trim().startsWith("token.auroravision.net=")) {
            token = p.trim().substring("token.auroravision.net=".length);
            break;
          }
        }
      }
    }

    if (token.isEmpty) {
      throw Exception("Không tìm thấy cookie token.auroravision.net từ phản hồi đăng nhập");
    }

    _cachedToken = token;
    _tokenExpiry = DateTime.now().add(const Duration(hours: 6));
    print("🔑 [ApiService] Đăng nhập thành công, đã lưu trữ Token.");
    return token;
  }

  Future<T> _auroraGet<T>(String path, String token) async {
    final response = await _dio.get(
      "https://www.auroravision.net$path",
      options: Options(
        headers: {
          "Cookie": "token.auroravision.net=$token",
          "Accept": "application/json",
        },
      ),
    );
    if (response.statusCode != 200) {
      throw Exception("Aurora API error: GET $path trả về HTTP ${response.statusCode}");
    }
    return response.data as T;
  }

  // ==========================================
  // DỊCH VỤ ĐIỆN MẶT TRỜI (SOLAR) - GỌI TRỰC TIẾP
  // ==========================================

  /// Lấy dữ liệu Điện mặt trời trực tiếp từ AuroraVision Cloud API
  Future<SolarData> getSolarData() async {
    try {
      final token = await _getAuroraToken();
      final todayS = _vnDayISO(0);
      final tomorrowS = _vnDayISO(1);
      final monthS = _vnMonthStartISO();
      final yearS = _vnYearStartISO();
      final monthAgo = _vnDayISO(-29);

      print("⚡ [ApiService] Đang tải trực tiếp dữ liệu SCADA từ AuroraVision...");
      
      // 1. Tải thông tin tĩnh của nhà máy
      final plantData = await _auroraGet<Map<String, dynamic>>("/asset/v1/plants/$auroraEntity", token);
      final devicesData = await _auroraGet<List<dynamic>>("/asset/v1/plants/$auroraEntity/devices", token);
      
      final invertersList = devicesData.where((d) {
        final List categories = d['categories'] ?? [];
        return categories.contains("Inverter");
      }).toList();

      final capacityKwp = (plantData['configuration']?['panelsNominalPower'] as num?)?.toDouble() ?? 6140.0;
      final city = plantData['location']?['city'] as String?;
      final country = plantData['location']?['country'] as String?;
      final location = city != null ? "$city, ${country ?? ''}" : "Kon Tum, Việt Nam";
      final installDate = plantData['configuration']?['installDate'] as String?;
      final commissioned = installDate != null ? installDate.substring(0, min(10, installDate.length)) : "2020-12-20";
      final inverterModel = invertersList.isNotEmpty ? invertersList.first['description'] as String? : "FIMER PVS-100-TL-OUTD";

      // 2. Tải song song dữ liệu sản lượng và công suất
      final results = await Future.wait([
        _auroraGet<List<dynamic>>("/telemetry/v1/plants/$auroraEntity/energy/GenerationEnergy?sdt=${Uri.encodeComponent(todayS)}&edt=${Uri.encodeComponent(tomorrowS)}&agp=Min15&afx=Delta", token),
        _auroraGet<List<dynamic>>("/telemetry/v1/plantGroups/$auroraGroup/energy/GenerationEnergy?sdt=${Uri.encodeComponent(monthS)}&edt=${Uri.encodeComponent(tomorrowS)}", token),
        _auroraGet<List<dynamic>>("/telemetry/v1/plantGroups/$auroraGroup/energy/GenerationEnergy?sdt=${Uri.encodeComponent(yearS)}&edt=${Uri.encodeComponent(tomorrowS)}", token),
        _auroraGet<List<dynamic>>("/telemetry/v1/plantGroups/$auroraGroup/energy/GenerationEnergy?sdt=2010-01-01T00:00:00%2B07:00&edt=${Uri.encodeComponent(tomorrowS)}", token),
        _auroraGet<List<dynamic>>("/telemetry/v1/plants/$auroraEntity/energy/GenerationEnergy?sdt=${Uri.encodeComponent(monthAgo)}&edt=${Uri.encodeComponent(tomorrowS)}&agp=Day&afx=Delta", token),
      ]);

      final min15 = results[0];
      final monthData = results[1];
      final yearData = results[2];
      final lifetimeData = results[3];
      final days30 = results[4];

      final List<SolarBucket> curve = [];
      double todayKwh = 0.0;
      double peakTodayKw = 0.0;
      double currentKw = 0.0;
      String? currentAt;

      for (final b in min15) {
        final val = (b['value'] as num?)?.toDouble();
        if (val != null) {
          final kw = val * 4.0;
          curve.add(SolarBucket(t: b['start'] ?? '', kw: kw));
          todayKwh += val;
          if (kw > peakTodayKw) peakTodayKw = kw;
        }
      }

      if (curve.isNotEmpty) {
        currentKw = curve.last.kw;
        currentAt = curve.last.t;
      }

      final double monthKwh = monthData.isNotEmpty ? (monthData.first['value'] as num?)?.toDouble() ?? 0.0 : 0.0;
      final double yearKwh = yearData.isNotEmpty ? (yearData.first['value'] as num?)?.toDouble() ?? 0.0 : 0.0;
      final double lifetimeKwh = lifetimeData.isNotEmpty ? (lifetimeData.first['value'] as num?)?.toDouble() ?? 0.0 : 0.0;

      final List<SolarDay> days = [];
      for (final b in days30) {
        final val = (b['value'] as num?)?.toDouble();
        if (val != null) {
          days.add(SolarDay(date: _vnDate(b['start'] ?? ''), kwh: val));
        }
      }

      // 3. Tải sản lượng hôm nay từng inverter
      final List<SolarInverter> inverters = [];
      double invTotal = 0.0;
      final List<double?> invTodayValues = await Future.wait(
        invertersList.map((d) async {
          try {
            final id = d['entityID'].toString();
            final b = await _auroraGet<List<dynamic>>("/telemetry/v1/devices/$id/energy/GenerationEnergy?sdt=${Uri.encodeComponent(todayS)}&edt=${Uri.encodeComponent(tomorrowS)}&agp=Day&afx=Delta", token);
            if (b.isNotEmpty) {
              final val = (b.first['value'] as num?)?.toDouble();
              if (val != null) {
                invTotal += val;
                return val;
              }
            }
            return 0.0;
          } catch (e) {
            return null;
          }
        }),
      );

      for (int i = 0; i < invertersList.length; i++) {
        final label = invertersList[i]['description'] as String? ?? "Inverter ${i + 1}";
        final val = invTodayValues[i];
        double share = 0.0;
        if (val != null && invTotal > 0) {
          share = (val / invTotal) * 100.0;
        }
        double acPower = (currentKw / 1000) * (share / 100);

        inverters.add(SolarInverter(
          label: label,
          todayKwh: val,
          share: share,
          acPower: acPower,
        ));
      }

      final yieldToday = capacityKwp > 0 ? todayKwh / capacityKwp : 0.0;
      final yieldYear = capacityKwp > 0 ? yearKwh / capacityKwp : 0.0;

      return SolarData(
        ok: true,
        configured: true,
        name: auroraName,
        capacityKwp: capacityKwp,
        location: location,
        commissioned: commissioned,
        inverterModel: inverterModel,
        inverterCount: inverters.length,
        specificYieldToday: yieldToday,
        specificYieldYear: yieldYear,
        inverters: inverters,
        currentKw: currentKw,
        currentAt: currentAt,
        todayKwh: todayKwh,
        monthKwh: monthKwh,
        yearKwh: yearKwh,
        lifetimeKwh: lifetimeKwh,
        peakTodayKw: peakTodayKw,
        co2TodayKg: todayKwh * 0.6612,
        curve: curve,
        days: days,
        updatedAt: DateTime.now().toIso8601String(),
        ghi: 912.0,
        panelTemp: 48.0,
        pr: 0.89,
        activeInverters: "${inverters.where((i) => (i.todayKwh ?? 0) > 0).length}/${inverters.length}",
      );
    } catch (e) {
      print("⚠️ [ApiService] Không thể lấy dữ liệu Điện mặt trời thật từ Aurora API ($e). Tự động dùng MOCK DATA cho Demo.");
      return _getMockSolarData();
    }
  }

  /// Lấy lịch sử sản lượng Điện mặt trời trực tiếp từ AuroraVision Cloud API
  Future<SolarSeries> getSolarSeries(String period, String anchor) async {
    try {
      final token = await _getAuroraToken();
      final label = period == 'day'
          ? "07/07/2026"
          : period == 'month'
              ? "Tháng 07/2026"
              : "Năm 2026";

      final parts = anchor.split("-").map(int.parse).toList();
      final y = parts[0];
      final m = parts[1];
      final d = parts[2];

      String sdt = "";
      String edt = "";

      if (period == 'day') {
        sdt = "$y-${_p2(m)}-${_p2(d)}T00:00:00+07:00";
        final nextDay = DateTime.utc(y, m, d + 1);
        edt = "${nextDay.year}-${_p2(nextDay.month)}-${_p2(nextDay.day)}T00:00:00+07:00";
        
        final b = await _auroraGet<List<dynamic>>("/telemetry/v1/plants/$auroraEntity/energy/GenerationEnergy?sdt=${Uri.encodeComponent(sdt)}&edt=${Uri.encodeComponent(edt)}&agp=Min15&afx=Delta", token);
        final List<SolarSeriesPoint> points = [];
        double totalKwh = 0.0;
        double peakKw = 0.0;

        for (int i = 0; i < b.length; i++) {
          final x = b[i];
          final val = (x['value'] as num?)?.toDouble();
          if (val != null) {
            final kw = val * 4;
            final time = DateTime.parse(x['start'] ?? '').add(const Duration(hours: 7));
            final hr = time.hour + time.minute / 60.0;
            points.add(SolarSeriesPoint(
              label: "${time.hour}h",
              value: kw,
              hourFrac: hr / 24.0,
            ));
            totalKwh += val;
            if (kw > peakKw) peakKw = kw;
          }
        }
        return SolarSeries(
          ok: true,
          period: period,
          anchor: anchor,
          label: label,
          kind: 'power',
          unit: 'kW',
          totalKwh: totalKwh,
          peakKw: peakKw,
          points: points,
          canNext: false,
        );
      } else if (period == 'month') {
        sdt = "$y-${_p2(m)}-01T00:00:00+07:00";
        final nextMonth = DateTime.utc(y, m + 1, 1);
        edt = "${nextMonth.year}-${_p2(nextMonth.month)}-01T00:00:00+07:00";

        final b = await _auroraGet<List<dynamic>>("/telemetry/v1/plants/$auroraEntity/energy/GenerationEnergy?sdt=${Uri.encodeComponent(sdt)}&edt=${Uri.encodeComponent(edt)}&agp=Day&afx=Delta", token);
        final List<SolarSeriesPoint> points = [];
        double totalKwh = 0.0;
        final cur = DateTime.now();

        for (final x in b) {
          final val = (x['value'] as num?)?.toDouble();
          if (val != null) {
            final dateStr = _vnDate(x['start'] ?? '');
            final dd = dateStr.substring(8);
            points.add(SolarSeriesPoint(
              label: dd,
              value: val,
              isCurrent: dateStr == "${cur.year}-${_p2(cur.month)}-${_p2(cur.day)}",
            ));
            totalKwh += val;
          }
        }
        return SolarSeries(
          ok: true,
          period: period,
          anchor: anchor,
          label: label,
          kind: 'energy',
          unit: 'kWh',
          totalKwh: totalKwh,
          points: points,
          canNext: false,
        );
      } else {
        sdt = "$y-01-01T00:00:00+07:00";
        edt = "${y + 1}-01-01T00:00:00+07:00";

        final b = await _auroraGet<List<dynamic>>("/telemetry/v1/plants/$auroraEntity/energy/GenerationEnergy?sdt=${Uri.encodeComponent(sdt)}&edt=${Uri.encodeComponent(edt)}&agp=Day&afx=Delta", token);
        final cur = DateTime.now();
        final Map<int, double> byMonth = {};

        for (final x in b) {
          final val = (x['value'] as num?)?.toDouble();
          if (val != null) {
            final time = DateTime.parse(x['start'] ?? '').add(const Duration(hours: 7));
            final mo = time.month;
            byMonth[mo] = (byMonth[mo] ?? 0.0) + val;
          }
        }

        final months = ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11", "T12"];
        final List<SolarSeriesPoint> points = [];
        double totalKwh = 0.0;

        for (int mo = 1; mo <= 12; mo++) {
          if (!byMonth.containsKey(mo)) continue;
          final val = byMonth[mo]!;
          points.add(SolarSeriesPoint(
            label: months[mo - 1],
            value: val,
            isCurrent: y == cur.year && mo == cur.month,
          ));
          totalKwh += val;
        }

        return SolarSeries(
          ok: true,
          period: period,
          anchor: anchor,
          label: label,
          kind: 'energy',
          unit: 'kWh',
          totalKwh: totalKwh,
          points: points,
          canNext: false,
        );
      }
    } catch (e) {
      print("⚠️ [ApiService] Không thể lấy lịch sử trực tiếp từ Aurora ($e). Dùng MOCK SERIES cho Demo.");
      return _getMockSolarSeries(period, anchor);
    }
  }

  // ==========================================
  // DỊCH VỤ THỦY ĐIỆN (HYDROELECTRIC WINCC)
  // ==========================================

  /// Lấy WinCC snapshot cho Thủy điện từ API của React
  Future<WinccSnapshot> getWinccSnapshot(String station) async {
    try {
      final response = await _dio.get(
        "$_baseUrl/api/dakrosa/wincc/latest",
        queryParameters: {"station": station},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['latest'] != null) {
          print("⚡ [ApiService] Tải WinCC snapshot THẬT của trạm $station từ $_baseUrl");
          return WinccSnapshot.fromJson(data['latest']);
        }
      }
      throw Exception("Dữ liệu snapshot rỗng hoặc lỗi");
    } catch (e) {
      print("⚠️ [ApiService] Lỗi kết nối WinCC $_baseUrl cho trạm $station: $e. Tự động dùng MOCK SNAPSHOT cho Demo.");
      return _getMockWinccSnapshot(station);
    }
  }

  /// Lấy danh sách các trạm thủy điện WinCC từ API của React
  Future<List<StationInfo>> getWinccStations() async {
    try {
      final response = await _dio.get("$_baseUrl/api/dakrosa/wincc/latest");
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['stations'] as List?;
        if (list != null && list.isNotEmpty) {
          print("⚡ [ApiService] Đã tải danh sách trạm WinCC THẬT từ $_baseUrl");
          return list.map((x) => StationInfo.fromJson(x)).toList();
        }
      }
      throw Exception("Danh sách trạm rỗng hoặc lỗi");
    } catch (e) {
      print("⚠️ [ApiService] Lỗi tải danh sách trạm WinCC từ $_baseUrl: $e. Tự động dùng MOCK STATIONS cho Demo.");
      return [
        StationInfo(
          station: "Dakrosa1",
          receivedAt: DateTime.now().toIso8601String(),
          snapshotUtc: DateTime.now().toUtc().toIso8601String(),
          version: "1.0",
          tags: 120,
          power: 2.85,
          hasError: false,
        ),
        StationInfo(
          station: "Dakrosa2",
          receivedAt: DateTime.now().toIso8601String(),
          snapshotUtc: DateTime.now().toUtc().toIso8601String(),
          version: "1.0",
          tags: 95,
          power: 1.25,
          hasError: false,
        ),
      ];
    }
  }

  // ==========================================
  // HÀM TẠO MOCK DATA DỰ PHÒNG CHO DEMO
  // ==========================================

  SolarData _getMockSolarData() {
    final now = DateTime.now();
    return SolarData(
      ok: true,
      configured: true,
      name: "Nhà máy điện mặt trời Dak Rosa",
      capacityKwp: 6140.0,
      location: "Kon Tum, Việt Nam",
      commissioned: "2020-12-20",
      inverterModel: "FIMER PVS-100-TL-OUTD",
      inverterCount: 3,
      specificYieldToday: 0.78,
      specificYieldYear: 1450.0,
      currentKw: 3800.0,
      currentAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      todayKwh: 329.0,
      monthKwh: 3770.0,
      yearKwh: 259400.0,
      lifetimeKwh: 2090000.0,
      peakTodayKw: 4200.0,
      co2TodayKg: 218.0,
      curve: _generateMockCurve(),
      days: List.generate(30, (i) {
        final d = now.subtract(Duration(days: 30 - i));
        return SolarDay(
          date: "${d.year}-${_p2(d.month)}-${_p2(d.day)}",
          kwh: 2000.0 + Random().nextDouble() * 1500.0,
        );
      }),
      updatedAt: now.toIso8601String(),
      ghi: 912.0,
      panelTemp: 48.0,
      pr: 0.89,
      activeInverters: "3/3",
      inverters: [
        SolarInverter(label: "Inverter 1", todayKwh: 161.2, share: 49.0, acPower: 1.87),
        SolarInverter(label: "Inverter 2", todayKwh: 139.1, share: 41.7, acPower: 1.63),
        SolarInverter(label: "Inverter 3", todayKwh: 28.7, share: 7.3, acPower: 0.30),
      ],
    );
  }

  List<SolarBucket> _generateMockCurve() {
    final List<SolarBucket> list = [];
    final today = DateTime.now();
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 15) {
        double kw = 0;
        if (h >= 6 && h <= 18) {
          final frac = (h + m / 60.0 - 6.0) / 12.0;
          kw = 3800.0 * sin(frac * pi);
          kw += (Random().nextDouble() - 0.5) * 80.0;
          if (kw < 0) kw = 0;
        }
        list.add(SolarBucket(
          t: DateTime(today.year, today.month, today.day, h, m).toIso8601String(),
          kw: kw,
        ));
      }
    }
    return list;
  }

  SolarSeries _getMockSolarSeries(String period, String anchor) {
    final List<SolarSeriesPoint> points = [];
    double totalKwh = 0.0;
    double? peakKw;

    if (period == 'day') {
      peakKw = 3800.0;
      for (int h = 0; h <= 24; h += 2) {
        double val = 0.0;
        if (h >= 6 && h <= 18) {
          final frac = (h - 6.0) / 12.0;
          val = 3800.0 * sin(frac * pi);
        }
        points.add(SolarSeriesPoint(
          label: "${_p2(h)}:00",
          value: val,
          hourFrac: h / 24.0,
          isCurrent: h == 12,
        ));
        totalKwh += val * 2.0;
      }
    } else if (period == 'month') {
      totalKwh = 3770.0;
      for (int i = 1; i <= 30; i++) {
        final val = 80.0 + Random().nextDouble() * 60.0;
        points.add(SolarSeriesPoint(
          label: _p2(i),
          value: val,
          isCurrent: i == 15,
        ));
      }
    } else {
      totalKwh = 259400.0;
      final months = ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11", "T12"];
      for (int i = 0; i < 12; i++) {
        final val = 15000.0 + Random().nextDouble() * 10000.0;
        points.add(SolarSeriesPoint(
          label: months[i],
          value: val,
          isCurrent: i == 6,
        ));
      }
    }

    return SolarSeries(
      ok: true,
      period: period,
      anchor: anchor,
      label: period == 'day'
          ? "07/07/2026"
          : period == 'month'
              ? "Tháng 07/2026"
              : "Năm 2026",
      kind: period == 'day' ? 'power' : 'energy',
      unit: period == 'day' ? 'kW' : 'kWh',
      totalKwh: totalKwh,
      peakKw: peakKw,
      points: points,
      canNext: false,
    );
  }

  WinccSnapshot _getMockWinccSnapshot(String station) {
    final now = DateTime.now();
    final double basePower = station == "Dakrosa1" ? 2.85 : 1.25;

    final tags = <String, WinccTagStat>{
      "bus_P": WinccTagStat(count: 30, last: basePower, min: basePower - 0.2, max: basePower + 0.3, avg: basePower, lastTs: now.toIso8601String()),
      "bus_Q": WinccTagStat(count: 30, last: basePower * 0.2, min: 0.1, max: 0.8, avg: basePower * 0.2, lastTs: now.toIso8601String()),
      "bus_F": WinccTagStat(count: 30, last: 50.02, min: 49.95, max: 50.05, avg: 50.00, lastTs: now.toIso8601String()),
      "bus_U12": WinccTagStat(count: 30, last: 22.45, min: 22.1, max: 22.8, avg: 22.4, lastTs: now.toIso8601String()),
      "bus_I1": WinccTagStat(count: 30, last: 73.5, min: 65.0, max: 80.0, avg: 72.8, lastTs: now.toIso8601String()),
      "bus_S": WinccTagStat(count: 30, last: basePower * 1.05, min: 1.0, max: 3.5, avg: basePower * 1.05, lastTs: now.toIso8601String()),
      "bus_PF": WinccTagStat(count: 30, last: 0.985, min: 0.97, max: 0.99, avg: 0.98, lastTs: now.toIso8601String()),
    };

    for (int u = 1; u <= 3; u++) {
      final active = u <= (station == "Dakrosa1" ? 2 : 1);
      final p = active ? (basePower / 2) + (Random().nextDouble() - 0.5) * 0.1 : 0.0;
      tags["u${u}_P"] = WinccTagStat(count: 30, last: p, min: 0, max: 2.0, avg: p, lastTs: now.toIso8601String());
      tags["u${u}_Q"] = WinccTagStat(count: 30, last: active ? p * 0.15 : 0.0, min: 0, max: 0.5, avg: active ? p * 0.15 : 0.0, lastTs: now.toIso8601String());
      tags["u${u}_U12"] = WinccTagStat(count: 30, last: active ? 6.3 : 0.0, min: 0, max: 6.6, avg: active ? 6.3 : 0.0, lastTs: now.toIso8601String());
      tags["u${u}_I1"] = WinccTagStat(count: 30, last: active ? 120.0 : 0.0, min: 0, max: 150.0, avg: active ? 118.0 : 0.0, lastTs: now.toIso8601String());
      tags["u${u}_S"] = WinccTagStat(count: 30, last: active ? p * 1.02 : 0.0, min: 0, max: 2.2, avg: active ? p * 1.02 : 0.0, lastTs: now.toIso8601String());
      tags["u${u}_F"] = WinccTagStat(count: 30, last: active ? 50.01 : 0.0, min: 0, max: 50.1, avg: active ? 50.0 : 0.0, lastTs: now.toIso8601String());
      tags["u${u}_PF"] = WinccTagStat(count: 30, last: active ? 0.988 : 0.0, min: 0, max: 0.99, avg: active ? 0.988 : 0.0, lastTs: now.toIso8601String());
      tags["u${u}_GV"] = WinccTagStat(count: 30, last: active ? 75.0 : 0.0, min: 0, max: 100.0, avg: active ? 74.0 : 0.0, lastTs: now.toIso8601String());
      tags["u${u}_speed"] = WinccTagStat(count: 30, last: active ? 375.0 : 0.0, min: 0, max: 400.0, avg: active ? 375.0 : 0.0, lastTs: now.toIso8601String());
    }

    return WinccSnapshot(
      source: "wincc-bridge",
      station: station,
      version: "1.0",
      snapshotUtc: now.toUtc().toIso8601String(),
      tags: tags,
      energy5min: {
        "bus_MWh_5min": basePower * 0.083,
        "u1_MWh_5min": (tags["u1_P"]?.last ?? 0) * 0.083,
        "u2_MWh_5min": (tags["u2_P"]?.last ?? 0) * 0.083,
        "u3_MWh_5min": (tags["u3_P"]?.last ?? 0) * 0.083,
      },
      receivedAt: now.toIso8601String(),
    );
  }

  // VN Time Helpers
  String _vnDayISO(int dayOffset) {
    final nowUtc = DateTime.now().toUtc();
    final vnTime = nowUtc.add(const Duration(hours: 7)).add(Duration(days: dayOffset));
    return "${vnTime.year}-${_p2(vnTime.month)}-${_p2(vnTime.day)}T00:00:00+07:00";
  }

  String _vnMonthStartISO() {
    final nowUtc = DateTime.now().toUtc();
    final vnTime = nowUtc.add(const Duration(hours: 7));
    return "${vnTime.year}-${_p2(vnTime.month)}-01T00:00:00+07:00";
  }

  String _vnYearStartISO() {
    final nowUtc = DateTime.now().toUtc();
    final vnTime = nowUtc.add(const Duration(hours: 7));
    return "${vnTime.year}-01-01T00:00:00+07:00";
  }

  String _vnDate(String iso) {
    final parsed = DateTime.parse(iso);
    final vnTime = parsed.isUtc ? parsed.add(const Duration(hours: 7)) : parsed;
    return "${vnTime.year}-${_p2(vnTime.month)}-${_p2(vnTime.day)}";
  }

  String _p2(int n) => n.toString().padLeft(2, '0');
}
