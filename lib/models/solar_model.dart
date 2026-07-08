class SolarBucket {
  final String t;
  final double kw;

  SolarBucket({required this.t, required this.kw});

  factory SolarBucket.fromJson(Map<String, dynamic> json) {
    return SolarBucket(
      t: json['t'] ?? '',
      kw: (json['kw'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SolarDay {
  final String date;
  final double kwh;

  SolarDay({required this.date, required this.kwh});

  factory SolarDay.fromJson(Map<String, dynamic> json) {
    return SolarDay(
      date: json['date'] ?? '',
      kwh: (json['kwh'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SolarSeriesPoint {
  final String label;
  final double value;
  final double? hourFrac;
  final bool? isCurrent;

  SolarSeriesPoint({
    required this.label,
    required this.value,
    this.hourFrac,
    this.isCurrent,
  });

  factory SolarSeriesPoint.fromJson(Map<String, dynamic> json) {
    return SolarSeriesPoint(
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      hourFrac: (json['hourFrac'] as num?)?.toDouble(),
      isCurrent: json['isCurrent'] as bool?,
    );
  }
}

class SolarSeries {
  final bool ok;
  final String period;
  final String anchor;
  final String label;
  final String kind;
  final String unit;
  final double? totalKwh;
  final double? peakKw;
  final List<SolarSeriesPoint> points;
  final bool canNext;
  final String? error;

  SolarSeries({
    required this.ok,
    required this.period,
    required this.anchor,
    required this.label,
    required this.kind,
    required this.unit,
    this.totalKwh,
    this.peakKw,
    required this.points,
    required this.canNext,
    this.error,
  });

  factory SolarSeries.fromJson(Map<String, dynamic> json) {
    return SolarSeries(
      ok: json['ok'] ?? false,
      period: json['period'] ?? 'day',
      anchor: json['anchor'] ?? '',
      label: json['label'] ?? '',
      kind: json['kind'] ?? 'energy',
      unit: json['unit'] ?? 'kWh',
      totalKwh: (json['total_kwh'] as num?)?.toDouble(),
      peakKw: (json['peak_kw'] as num?)?.toDouble(),
      points: (json['points'] as List?)?.map((x) => SolarSeriesPoint.fromJson(x)).toList() ?? [],
      canNext: json['can_next'] ?? false,
      error: json['error'] as String?,
    );
  }
}

class SolarInverter {
  final String label;
  final double? todayKwh;
  final double? share;
  final double? acPower;

  SolarInverter({
    required this.label,
    this.todayKwh,
    this.share,
    this.acPower,
  });

  factory SolarInverter.fromJson(Map<String, dynamic> json) {
    return SolarInverter(
      label: json['label'] ?? '',
      todayKwh: (json['today_kwh'] as num?)?.toDouble(),
      share: (json['share'] as num?)?.toDouble(),
      acPower: (json['ac_power'] as num?)?.toDouble(),
    );
  }
}

class SolarData {
  final bool ok;
  final bool configured;
  final String name;
  final double? capacityKwp;
  final String? location;
  final String? commissioned;
  final String? inverterModel;
  final int? inverterCount;
  final double? specificYieldToday;
  final double? specificYieldYear;
  final List<SolarInverter> inverters;
  final double? currentKw;
  final String? currentAt;
  final double? todayKwh;
  final double? monthKwh;
  final double? yearKwh;
  final double? lifetimeKwh;
  final double? peakTodayKw;
  final double? co2TodayKg;
  final List<SolarBucket> curve;
  final List<SolarDay> days;
  final String updatedAt;
  final String? error;

  // Chỉ số bổ sung từ SCADA mặt trời
  final double? ghi;
  final double? panelTemp;
  final double? pr;
  final String? activeInverters;

  SolarData({
    required this.ok,
    required this.configured,
    required this.name,
    this.capacityKwp,
    this.location,
    this.commissioned,
    this.inverterModel,
    this.inverterCount,
    this.specificYieldToday,
    this.specificYieldYear,
    required this.inverters,
    this.currentKw,
    this.currentAt,
    this.todayKwh,
    this.monthKwh,
    this.yearKwh,
    this.lifetimeKwh,
    this.peakTodayKw,
    this.co2TodayKg,
    required this.curve,
    required this.days,
    required this.updatedAt,
    this.error,
    this.ghi,
    this.panelTemp,
    this.pr,
    this.activeInverters,
  });

  factory SolarData.fromJson(Map<String, dynamic> json) {
    return SolarData(
      ok: json['ok'] ?? false,
      configured: json['configured'] ?? false,
      name: json['name'] ?? '',
      capacityKwp: (json['capacity_kwp'] as num?)?.toDouble(),
      location: json['location'] as String?,
      commissioned: json['commissioned'] as String?,
      inverterModel: json['inverter_model'] as String?,
      inverterCount: (json['inverter_count'] as num?)?.toInt(),
      specificYieldToday: (json['specific_yield_today'] as num?)?.toDouble(),
      specificYieldYear: (json['specific_yield_year'] as num?)?.toDouble(),
      inverters: (json['inverters'] as List?)?.map((x) => SolarInverter.fromJson(x)).toList() ?? [],
      currentKw: (json['current_kw'] as num?)?.toDouble(),
      currentAt: json['current_at'] as String?,
      todayKwh: (json['today_kwh'] as num?)?.toDouble(),
      monthKwh: (json['month_kwh'] as num?)?.toDouble(),
      yearKwh: (json['year_kwh'] as num?)?.toDouble(),
      lifetimeKwh: (json['lifetime_kwh'] as num?)?.toDouble(),
      peakTodayKw: (json['peak_today_kw'] as num?)?.toDouble(),
      co2TodayKg: (json['co2_today_kg'] as num?)?.toDouble(),
      curve: (json['curve'] as List?)?.map((x) => SolarBucket.fromJson(x)).toList() ?? [],
      days: (json['days'] as List?)?.map((x) => SolarDay.fromJson(x)).toList() ?? [],
      updatedAt: json['updated_at'] ?? '',
      error: json['error'] as String?,
      ghi: (json['ghi'] as num?)?.toDouble(),
      panelTemp: (json['panel_temp'] as num?)?.toDouble(),
      pr: (json['pr'] as num?)?.toDouble(),
      activeInverters: json['active_inverters'] as String?,
    );
  }
}
