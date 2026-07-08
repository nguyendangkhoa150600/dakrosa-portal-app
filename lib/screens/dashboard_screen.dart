import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/solar_model.dart';
import '../models/wincc_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yield_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  int _selectedBottomTab = 0; // 0: Overview, 1: Devices, 2: Reports, 3: Settings
  String _dashboardType = 'solar'; // 'solar' hoặc 'hydro'
  
  // Trạng thái dữ liệu Solar
  SolarData? _solarData;
  SolarSeries? _solarSeries;
  String _solarPeriod = 'day';
  
  // Trạng thái dữ liệu Hydro (WinCC)
  List<StationInfo> _stations = [];
  String? _selectedStation;
  WinccSnapshot? _winccSnapshot;

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Tự động làm mới mỗi 10 giây (giống hệt React app)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchData(isSilent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      if (_dashboardType == 'solar') {
        final data = await _apiService.getSolarData();
        final series = await _apiService.getSolarSeries(_solarPeriod, _getCurrentAnchor());
        setState(() {
          _solarData = data;
          _solarSeries = series;
          _isLoading = false;
        });
      } else {
        final list = await _apiService.getWinccStations();
        if (list.isNotEmpty) {
          _stations = list;
          _selectedStation ??= list.first.station;
          final snap = await _apiService.getWinccSnapshot(_selectedStation!);
          setState(() {
            _winccSnapshot = snap;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi kết nối API: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  String _getCurrentAnchor() {
    final now = DateTime.now();
    if (_solarPeriod == 'day') {
      return "${now.year}-${_p2(now.month)}-${_p2(now.day)}";
    } else if (_solarPeriod == 'month') {
      return "${now.year}-${_p2(now.month)}-01";
    } else {
      return "${now.year}-01-01";
    }
  }

  String _p2(int n) => n.toString().padLeft(2, '0');

  void _onDashboardTypeChanged(String type) {
    if (_dashboardType == type) return;
    setState(() {
      _dashboardType = type;
    });
    _fetchData();
  }

  void _onSolarPeriodChanged(String period) {
    if (_solarPeriod == period) return;
    setState(() {
      _solarPeriod = period;
    });
    _fetchData();
  }

  void _onStationChanged(String station) {
    if (_selectedStation == station) return;
    setState(() {
      _selectedStation = station;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading && _solarData == null && _winccSnapshot == null
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : RefreshIndicator(
                onRefresh: () => _fetchData(),
                color: AppTheme.blue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header phần thông báo & chuyển đổi loại dự án
                      _buildHeader(),
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.redSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.red, fontSize: 13),
                          ),
                        ),
                      _buildQuickMetrics(),
                      _buildMainCard(),
                      _buildYieldSection(),
                      if (_dashboardType == 'solar') ...[
                        _buildDoubleYieldCards(),
                        _buildCarbonOffsetCard(),
                        _buildDevicesSection(),
                      ] else ...[
                        _buildHydroDetailMetrics(),
                        _buildHydroTurbinesSection(),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // COMPONENT BUILDERS
  // ==========================================

  Widget _buildHeader() {
    final isSolar = _dashboardType == 'solar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Segmented control chọn Solar / Hydro (Đóng gói giao diện Premium)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.hairline.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton("solar", "☀️ Điện mặt trời"),
                    _buildSegmentButton("hydro", "💧 Thủy điện WinCC"),
                  ],
                ),
              ),
              // Notification Bell
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.bell, color: AppTheme.ink),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 12,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          if (isSolar && _solarData != null) ...[
            const SizedBox(height: 12),
            Text(
              _solarData!.name,
              style: const TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.location_solid, size: 12, color: AppTheme.faint),
                const SizedBox(width: 4),
                Text(
                  "${_solarData!.location} · Hòa lưới · Vận hành: ${_solarData!.commissioned}",
                  style: const TextStyle(color: AppTheme.secondary, fontSize: 11.5),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String type, String label) {
    final active = _dashboardType == type;
    return GestureDetector(
      onTap: () => _onDashboardTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppTheme.ink.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.ink : AppTheme.secondary,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetrics() {
    // Metric Cards cuộn ngang ở trên cùng
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _dashboardType == 'solar'
            ? [
                _buildQuickCard(CupertinoIcons.sun_max, "Sunny", "32°C", isWarning: true),
                _buildQuickCard(
                  CupertinoIcons.flame, 
                  "Bức xạ GHI", 
                  "${_solarData?.ghi?.toStringAsFixed(0) ?? '912'} W/m²", 
                  subText: "Tấm pin: ${_solarData?.panelTemp?.toStringAsFixed(0) ?? '48'}°C",
                  isWarning: true
                ),
                _buildQuickCard(CupertinoIcons.wifi, "Trạng thái Inverter", _solarData?.activeInverters ?? "3/3", subText: "100% đang hoạt động", isSuccess: true),
                _buildQuickCard(CupertinoIcons.shield, "Hiệu suất PR", _solarData?.pr?.toStringAsFixed(2) ?? "0.89", isSuccess: true),
                _buildQuickCard(CupertinoIcons.bolt_horizontal, "Tổng sản lượng", "${((_solarData?.lifetimeKwh ?? 2090000.0) / 1000000.0).toStringAsFixed(2)} GWh", isSuccess: true),
              ]
            : [
                _buildQuickCard(CupertinoIcons.drop, "Trạm đo", "${_stations.length} trạm", isSuccess: true),
                _buildQuickCard(CupertinoIcons.wifi, "Kết nối", "WinCC Bridge", isSuccess: true),
                _buildQuickCard(CupertinoIcons.time, "Tự cập nhật", "Mỗi 10 giây", isWarning: true),
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
      height: 105,
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

  Widget _buildMainCard() {
    final isSolar = _dashboardType == 'solar';
    
    // Tiêu đề & Công suất
    String valueStr = "—";
    String unit = "MW";
    String label = "CURRENT CAPACITY";
    String rightLabel = "DC Power";
    String rightValue = "—";
    String leftLabel = "AC Efficiency";
    String leftValue = "—";

    if (isSolar) {
      if (_solarData != null) {
        final kw = _solarData!.currentKw ?? 0.0;
        valueStr = (kw >= 1000) ? (kw / 1000).toStringAsFixed(2) : kw.toStringAsFixed(0);
        unit = (kw >= 1000) ? "MW" : "kW";
        rightValue = "${(_solarData!.capacityKwp ?? 6140) / 1000} MWp";
        leftValue = "60.9%";
      }
    } else {
      if (_winccSnapshot != null) {
        final double activePower = _winccSnapshot!.tags['bus_P']?.last ?? 0.0;
        final bool isKw = _selectedStation == "Dakrosa2"; // Dakrosa2 tính theo kW
        valueStr = activePower.toStringAsFixed(isKw ? 0 : 2);
        unit = isKw ? "kW" : "MW";
        label = "CÔNG SUẤT PHÁT · THANH CÁI 22KV";
        rightLabel = "Điện áp U₁₂";
        rightValue = "${_winccSnapshot!.tags['bus_U12']?.last ?? '—'} kV";
        leftLabel = "Tần số bus";
        leftValue = "${_winccSnapshot!.tags['bus_F']?.last ?? '—'} Hz";
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSolar ? AppTheme.solarGradient : AppTheme.hydroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isSolar ? const Color(0xFFF85E00) : AppTheme.blue).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          )
        ],
      ),
      child: Stack(
        children: [
          // Nền ô vuông mờ tạo nét công nghệ/SCADA
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
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
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
                          const Text(
                            "Active Now",
                            style: TextStyle(color: AppTheme.ink, fontSize: 10.5, fontWeight: FontWeight.bold),
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
                          leftLabel,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11.5),
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
                          rightLabel,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11.5),
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

  Widget _buildYieldSection() {
    final isSolar = _dashboardType == 'solar';

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
              Text(
                isSolar ? "Daily Yield" : "Biểu đồ công suất",
                style: const TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (isSolar)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.hairline.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodTab("day", "Day"),
                      _buildPeriodTab("month", "Month"),
                      _buildPeriodTab("year", "Year"),
                    ],
                  ),
                )
              else
                // Với Hydro, hiển thị lựa chọn trạm
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.hairline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: _stations.map((s) {
                      final active = _selectedStation == s.station;
                      return GestureDetector(
                        onTap: () => _onStationChanged(s.station),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.station,
                            style: TextStyle(
                              color: active ? AppTheme.ink : AppTheme.secondary,
                              fontWeight: active ? FontWeight.bold : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (isSolar && _solarSeries != null)
            YieldChart(series: _solarSeries!, isSolar: true)
          else if (!isSolar && _winccSnapshot != null)
            _buildHydroYieldChart()
          else
            const SizedBox(
              height: 200,
              child: Center(child: CupertinoActivityIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHydroYieldChart() {
    // Generate a temporary series wrapper for WinCC to reuse our YieldChart widget
    final List<SolarSeriesPoint> points = [];
    final tags = _winccSnapshot!.tags;
    
    // Lấy 3 tổ máy vẽ biểu đồ so sánh sản lượng tức thời
    final u1 = tags['u1_P']?.last ?? 0.0;
    final u2 = tags['u2_P']?.last ?? 0.0;
    final u3 = tags['u3_P']?.last ?? 0.0;

    points.add(SolarSeriesPoint(label: "Tổ máy 1", value: u1 >= 1000 ? u1 / 1000 : u1));
    points.add(SolarSeriesPoint(label: "Tổ máy 2", value: u2 >= 1000 ? u2 / 1000 : u2));
    points.add(SolarSeriesPoint(label: "Tổ máy 3", value: u3 >= 1000 ? u3 / 1000 : u3));

    final series = SolarSeries(
      ok: true,
      period: 'year', // để vẽ cột
      anchor: '',
      label: 'Công suất tổ máy',
      kind: 'energy',
      unit: _selectedStation == 'Dakrosa2' ? 'kW' : 'MW',
      points: points,
      canNext: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Công suất phát tức thời các tổ máy",
          style: TextStyle(color: AppTheme.secondary, fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        YieldChart(series: series, isSolar: false),
      ],
    );
  }

  Widget _buildPeriodTab(String k, String label) {
    final active = _solarPeriod == k;
    return GestureDetector(
      onTap: () => _onSolarPeriodChanged(k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.ink : AppTheme.secondary,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDoubleYieldCards() {
    double monthVal = 3.77;
    double annualVal = 259.4;
    double lifetimeGwh = 2.09;
    double capacityKwp = 6.14;

    if (_solarData != null) {
      final m = _solarData!.monthKwh ?? 3770;
      final y = _solarData!.yearKwh ?? 259400;
      monthVal = m >= 1000 ? m / 1000 : m;
      annualVal = y >= 1000 ? y / 1000 : y;
      lifetimeGwh = (_solarData!.lifetimeKwh ?? 2090000.0) / 1000000.0;
      capacityKwp = (_solarData!.capacityKwp ?? 6140.0) / 1000.0;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.calendar,
                  title: "Sản lượng Tháng 07",
                  value: "${monthVal.toStringAsFixed(2)} MWh",
                  goal: "Mục tiêu: 4.20 MWh",
                  percent: (monthVal / 4.2).clamp(0.0, 1.0),
                  color: const Color(0xFFFFB300),
                ),
              ),
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.calendar_today,
                  title: "Sản lượng Năm 2026",
                  value: "${annualVal.toStringAsFixed(2)} MWh",
                  goal: "Mục tiêu: 300.00 MWh",
                  percent: (annualVal / 300.0).clamp(0.0, 1.0),
                  color: const Color(0xFFF85E00),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.bolt_fill,
                  title: "Tổng sản lượng",
                  value: "${lifetimeGwh.toStringAsFixed(2)} GWh",
                  goal: "Từ khi vận hành",
                  percent: 1.0,
                  color: AppTheme.blue,
                ),
              ),
              Expanded(
                child: _buildProgressCard(
                  icon: CupertinoIcons.settings,
                  title: "Công suất hệ thống",
                  value: "${capacityKwp.toStringAsFixed(2)} MWp",
                  goal: "5.00 MWac (Hòa lưới)",
                  percent: 1.0,
                  color: AppTheme.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String title,
    required String value,
    required String goal,
    required double percent,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
            children: [
              Icon(icon, size: 16, color: AppTheme.faint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.faint, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: AppTheme.ink, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppTheme.hairline,
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goal,
            style: const TextStyle(color: AppTheme.faint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonOffsetCard() {
    double co2Val = 1.417; // Tons
    if (_solarData != null) {
      final rawCo2 = _solarData!.co2TodayKg ?? 1417.0;
      co2Val = rawCo2 / 1000.0;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.leaf_arrow_circlepath, size: 16, color: AppTheme.green),
                    SizedBox(width: 8),
                    Text(
                      "Carbon Offset",
                      style: TextStyle(color: AppTheme.faint, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      co2Val.toStringAsFixed(3),
                      style: const TextStyle(color: AppTheme.ink, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Tons CO2",
                      style: TextStyle(color: AppTheme.secondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Equivalent to ~${(co2Val * 38).toStringAsFixed(0)}k trees planted",
                  style: const TextStyle(color: AppTheme.faint, fontSize: 11.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppTheme.greenSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.tree, color: AppTheme.green, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    final inverters = _solarData?.inverters ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Giám sát Inverter",
                style: TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Xem tất cả",
                  style: TextStyle(color: Color(0xFFF85E00), fontWeight: FontWeight.bold, fontSize: 13),
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
              final statusText = "Đang chạy";
              final statusColor = AppTheme.green;
              final String acPowerStr = "${inv.acPower?.toStringAsFixed(2) ?? '0.00'} MW";
              final String todayKwhStr = "${inv.todayKwh?.toStringAsFixed(1) ?? '0.0'} kWh";
              final shareStr = "${inv.share?.toStringAsFixed(1) ?? '0.0'}%";

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
                        color: AppTheme.hairline.withOpacity(0.4),
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
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 11.5, fontWeight: FontWeight.w600),
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
                          "Hôm nay: $todayKwhStr ($shareStr)",
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
          _buildAlertsSection(),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cảnh báo & Bảo trì",
          style: TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildAlertRow(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          color: AppTheme.amber,
          title: "Cảnh báo bức xạ cao",
          detail: "GHI hiện tại đạt 912 W/m²",
          time: "10:18",
        ),
        _buildAlertRow(
          icon: CupertinoIcons.info_circle_fill,
          color: AppTheme.blue,
          title: "Vệ sinh tấm pin định kỳ",
          detail: "Khuyến nghị vệ sinh trong 5 ngày tới",
          time: "Hôm qua",
        ),
        _buildAlertRow(
          icon: CupertinoIcons.checkmark_circle_fill,
          color: AppTheme.green,
          title: "Hệ thống hoạt động ổn định",
          detail: "Không có lỗi phát sinh trong 24 giờ qua",
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
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

  Widget _buildHydroDetailMetrics() {
    if (_winccSnapshot == null) return const SizedBox.shrink();
    final tags = _winccSnapshot!.tags;

    // Hiển thị các thông số đo bổ sung từ thanh cái WinCC
    final f = tags['bus_F']?.last ?? 50.00;
    final pf = tags['bus_PF']?.last ?? 0.98;
    final q = tags['bus_Q']?.last ?? 0.0;
    final s = tags['bus_S']?.last ?? 0.0;

    final isKw = _selectedStation == "Dakrosa2";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildHydroInfoCard("Tần số mạng", "${f.toStringAsFixed(2)} Hz", CupertinoIcons.waveform_path_ecg, AppTheme.blue),
              ),
              Expanded(
                child: _buildHydroInfoCard("Hệ số cosφ", pf.toStringAsFixed(3), CupertinoIcons.gauge, AppTheme.blue),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildHydroInfoCard(
                  "Phản kháng Q",
                  "${(isKw ? q * 1000 : q).toStringAsFixed(isKw ? 1 : 2)} ${isKw ? 'kVAr' : 'MVAr'}",
                  CupertinoIcons.bolt,
                  AppTheme.amber,
                ),
              ),
              Expanded(
                child: _buildHydroInfoCard(
                  "Biểu kiến S",
                  "${(isKw ? s * 1000 : s).toStringAsFixed(isKw ? 0 : 3)} ${isKw ? 'kVA' : 'MVA'}",
                  CupertinoIcons.bolt_horizontal,
                  AppTheme.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydroInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.faint, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: AppTheme.ink, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHydroTurbinesSection() {
    if (_winccSnapshot == null) return const SizedBox.shrink();
    final tags = _winccSnapshot!.tags;
    final isKw = _selectedStation == "Dakrosa2";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Tổ máy phát điện",
            style: TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, idx) {
              final uNum = idx + 1;
              final p = tags['u${uNum}_P']?.last ?? 0.0;
              final speed = tags['u${uNum}_speed']?.last ?? 0.0;
              
              // Trạng thái tổ máy hoạt động nếu có công suất phát hoặc tốc độ > 100 rpm
              final bool running = p > 0.01 || speed > 100;
              
              // Mock nhiệt độ theo dữ liệu derived tương ứng
              final double tempVal = running ? (60.0 + idx * 5.5 + Random().nextDouble() * 3.0) : 28.5;

              final statusText = running ? "Đang phát" : "Dừng máy";
              final statusColor = running ? AppTheme.green : AppTheme.faint;
              
              final String valStr = running
                  ? "${(isKw ? p : p).toStringAsFixed(isKw ? 1 : 3)} ${isKw ? 'kW' : 'MW'}"
                  : "0.000 ${isKw ? 'kW' : 'MW'}";

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
                        color: AppTheme.hairline.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(CupertinoIcons.bolt_horizontal_circle, color: AppTheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tổ máy $uNum",
                            style: const TextStyle(color: AppTheme.ink, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  )),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 11.5, fontWeight: FontWeight.w600),
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
                          valStr,
                          style: const TextStyle(color: AppTheme.ink, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${tempVal.toStringAsFixed(1)}°C · speed: ${speed.toStringAsFixed(0)} rpm",
                          style: TextStyle(
                            color: tempVal >= 70 ? AppTheme.red : AppTheme.faint, 
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.hairline)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedBottomTab,
        onTap: (idx) {
          setState(() {
            _selectedBottomTab = idx;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.ink,
        unselectedItemColor: AppTheme.faint,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(0, CupertinoIcons.square_grid_2x2_fill, CupertinoIcons.square_grid_2x2),
            label: "Overview",
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(1, CupertinoIcons.device_phone_portrait, CupertinoIcons.device_phone_portrait),
            label: "Devices",
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(2, CupertinoIcons.chart_bar_fill, CupertinoIcons.chart_bar),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(3, CupertinoIcons.settings_solid, CupertinoIcons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData activeIcon, IconData inactiveIcon) {
    final active = _selectedBottomTab == index;
    if (active) {
      // Pill-indicator giống mockup
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107).withOpacity(0.85), // Pill màu vàng
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(activeIcon, color: AppTheme.ink, size: 20),
      );
    }
    return Icon(inactiveIcon, size: 22);
  }
}
