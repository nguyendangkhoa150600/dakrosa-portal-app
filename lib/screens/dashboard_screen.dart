import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/solar_model.dart';
import '../models/wincc_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/overview_tab.dart';
import '../widgets/dashboard/solar_tab.dart';
import '../widgets/dashboard/hydro_tab.dart';
import '../widgets/dashboard/performance_tab.dart';
import '../widgets/dashboard/alerts_tab.dart';
import '../services/localization_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  int _selectedBottomTab = 0; // 0: Overview, 1: Solar, 2: Hydro, 3: Performance, 4: Alerts
  
  // Solar state
  SolarData? _solarData;
  SolarSeries? _solarSeries;
  String _solarPeriod = 'day';
  
  // Hydro (WinCC) state
  List<StationInfo> _stations = [];
  String? _selectedStation;
  WinccSnapshot? _winccSnapshot;
  Map<String, WinccSnapshot> _winccSnapshots = {};
  String _overviewSelectedStation = "all";

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Auto-refresh every 10 seconds (same as React app)
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

    String? errorMsg;

    // 1. Fetch Solar Data
    try {
      final solarData = await _apiService.getSolarData();
      final solarSeries = await _apiService.getSolarSeries(_solarPeriod, _getCurrentAnchor());
      setState(() {
        _solarData = solarData;
        _solarSeries = solarSeries;
      });
    } catch (e) {
      print("Lỗi tải dữ liệu Solar: $e");
      errorMsg = "Lỗi kết nối Solar: ${e.toString()}";
    }

    // 2. Fetch Hydro Data
    try {
      final list = await _apiService.getWinccStations();
      if (list.isNotEmpty) {
        _stations = list;
        _selectedStation ??= list.first.station;
        
        final snaps = await Future.wait(
          list.map((s) async {
            try {
              return await _apiService.getWinccSnapshot(s.station);
            } catch (e) {
              print("Lỗi tải snapshot cho trạm ${s.station}: $e");
              return null;
            }
          }),
        );

        final newSnapsMap = <String, WinccSnapshot>{};
        for (int i = 0; i < list.length; i++) {
          final snap = snaps[i];
          if (snap != null) {
            newSnapsMap[list[i].station] = snap;
          }
        }

        setState(() {
          _winccSnapshots = newSnapsMap;
          _winccSnapshot = newSnapsMap[_selectedStation!];
        });
      }
    } catch (e) {
      print("Lỗi tải dữ liệu Hydro: $e");
      final hydroErr = "Lỗi kết nối Thủy điện: ${e.toString()}";
      errorMsg = errorMsg != null ? "$errorMsg\n$hydroErr" : hydroErr;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = errorMsg;
    });
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
      _winccSnapshot = _winccSnapshots[station];
    });
  }

  int _getAlertsCount() {
    int count = 0;
    if (_errorMessage != null) count++;
    if (_solarData != null && _solarData!.inverters.isNotEmpty) {
      final active = _solarData!.inverters.where((inv) => (inv.todayKwh ?? 0) > 0).length;
      if (active < _solarData!.inverters.length) count++;
    }
    if (_winccSnapshot != null) {
      final tags = _winccSnapshot!.tags;
      for (int i = 1; i <= 3; i++) {
        final double? speed = tags['u${i}_speed']?.last;
        final bool running = speed != null && speed > 10;
        final double tempVal = running ? (60.0 + (i - 1) * 5.5) : 28.5;
        if (tempVal >= 70) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody;
    switch (_selectedBottomTab) {
      case 0:
        activeBody = OverviewTab(
          overviewSelectedStation: _overviewSelectedStation,
          stations: _stations,
          winccSnapshots: _winccSnapshots,
          solarData: _solarData,
          onStationFilterChanged: (val) {
            setState(() {
              _overviewSelectedStation = val;
            });
          },
        );
        break;
      case 1:
        activeBody = SolarTab(
          solarData: _solarData,
          solarSeries: _solarSeries,
          solarPeriod: _solarPeriod,
          onPeriodChanged: _onSolarPeriodChanged,
        );
        break;
      case 2:
        activeBody = HydroTab(
          selectedStation: _selectedStation ?? "Dakrosa1",
          winccSnapshot: _winccSnapshot,
          stations: _stations,
          winccSnapshots: _winccSnapshots,
          solarData: _solarData,
        );
        break;
      case 3:
        activeBody = PerformanceTab(
          solarData: _solarData,
          solarSeries: _solarSeries,
          solarPeriod: _solarPeriod,
          onPeriodChanged: _onSolarPeriodChanged,
        );
        break;
      case 4:
        activeBody = AlertsTab(
          errorMessage: _errorMessage,
          solarData: _solarData,
          winccSnapshot: _winccSnapshot,
          stations: _stations,
        );
        break;
      default:
        activeBody = const SizedBox.shrink();
    }

    if (_isLoading && _solarData == null && _winccSnapshot == null) {
      if (_errorMessage != null) {
        return _buildErrorScreen();
      }
      return _buildPremiumLoadingScreen();
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _fetchData(),
              color: AppTheme.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.redSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.red, fontSize: 13),
                        ),
                      ),
                    activeBody,
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.blue),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    String title = context.tr("tabOverview");
    String? subText;
    Widget? trailing;

    if (_selectedBottomTab == 0) {
      title = context.tr("mainTitleOverview");
      subText = context.tr("mainSubtitleOverview");
    } else if (_selectedBottomTab == 1) {
      title = context.tr("mainTitleSolar");
      subText = _solarData != null
          ? context.trArgs("mainSubtitleSolarCommissioned", [_solarData!.location, _solarData!.commissioned])
          : context.tr("mainSubtitleSolarDefault");
    } else if (_selectedBottomTab == 2) {
      title = context.tr("mainTitleWincc");
      trailing = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.hairline.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildStationSegmentButton("Dakrosa1", "Dakrosa 1"),
            _buildStationSegmentButton("Dakrosa2", "Dakrosa 2"),
          ],
        ),
      );
    } else if (_selectedBottomTab == 3) {
      title = context.tr("mainTitlePerformance");
      subText = context.tr("mainSubtitlePerformance");
    } else if (_selectedBottomTab == 4) {
      title = context.tr("mainTitleAlerts");
      final alertsCount = _getAlertsCount();
      subText = context.trArgs("mainSubtitleAlertsCount", [alertsCount]);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null) ...[
                trailing,
                const SizedBox(width: 8),
              ],
              _buildLanguageToggle(),
              if (trailing == null) ...[
                const SizedBox(width: 4),
                _buildNotificationBell(),
              ],
            ],
          ),
          if (subText != null) ...[
            const SizedBox(height: 4),
            Text(
              subText,
              style: const TextStyle(color: AppTheme.faint, fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        final isVi = locale.languageCode == 'vi';
        return GestureDetector(
          onTap: () {
            appLocale.value = isVi ? const Locale('en') : const Locale('vi');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              border: Border.all(color: AppTheme.hairline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isVi ? "🇻🇳 VI" : "🇺🇸 EN",
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(CupertinoIcons.bell, color: AppTheme.ink, size: 20),
          onPressed: () {
            setState(() {
              _selectedBottomTab = 4;
            });
          },
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
        ),
        if (_getAlertsCount() > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppTheme.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStationSegmentButton(String stationName, String label) {
    final active = _selectedStation == stationName;
    return GestureDetector(
      onTap: () => _onStationChanged(stationName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.ink : AppTheme.secondary,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCustomNavItem(0, CupertinoIcons.square_grid_2x2_fill, CupertinoIcons.square_grid_2x2, context.tr("tabOverview")),
                _buildCustomNavItem(1, CupertinoIcons.sun_max_fill, CupertinoIcons.sun_max, context.tr("tabSolar")),
                _buildCustomNavItem(2, CupertinoIcons.wind, CupertinoIcons.wind, context.tr("tabWincc")),
                _buildCustomNavItem(3, CupertinoIcons.graph_square_fill, CupertinoIcons.graph_square, context.tr("tabPerformance")),
                _buildCustomNavItem(4, CupertinoIcons.bell_fill, CupertinoIcons.bell, context.tr("tabAlerts")),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final active = _selectedBottomTab == index;
    final activeColor = AppTheme.blue;
    final inactiveColor = AppTheme.faint;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedBottomTab = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: active ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? activeIcon : inactiveIcon,
                  color: active ? activeColor : inactiveColor,
                  size: 20,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? activeColor : inactiveColor,
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppTheme.blue,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('connectingSystem'),
              style: const TextStyle(color: AppTheme.ink, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('syncingData'),
              style: const TextStyle(color: AppTheme.faint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.redSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.wifi_exclamationmark, color: AppTheme.red, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('connectionFailed'),
                style: const TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? context.tr('checkNetwork'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.secondary, fontSize: 13),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _fetchData(),
                icon: const Icon(CupertinoIcons.refresh, size: 16),
                label: Text(context.tr('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
