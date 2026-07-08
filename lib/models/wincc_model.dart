class WinccTagStat {
  final int count;
  final double? last;
  final double min;
  final double max;
  final double avg;
  final String lastTs;

  WinccTagStat({
    required this.count,
    this.last,
    required this.min,
    required this.max,
    required this.avg,
    required this.lastTs,
  });

  factory WinccTagStat.fromJson(Map<String, dynamic> json) {
    return WinccTagStat(
      count: (json['count'] as num?)?.toInt() ?? 0,
      last: (json['last'] as num?)?.toDouble(),
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      avg: (json['avg'] as num?)?.toDouble() ?? 0.0,
      lastTs: json['last_ts'] ?? '',
    );
  }
}

class DerivedEnergyToday {
  final double? station;
  final Map<String, double?> units;
  final String since;

  DerivedEnergyToday({this.station, required this.units, required this.since});

  factory DerivedEnergyToday.fromJson(Map<String, dynamic> json) {
    final rawUnits = json['units'] as Map<String, dynamic>? ?? {};
    final parsedUnits = rawUnits.map((k, v) => MapEntry(k, (v as num?)?.toDouble()));
    return DerivedEnergyToday(
      station: (json['station'] as num?)?.toDouble(),
      units: parsedUnits,
      since: json['since'] ?? '',
    );
  }
}

class DerivedUnitTemp {
  final double max;
  final int points;

  DerivedUnitTemp({required this.max, required this.points});

  factory DerivedUnitTemp.fromJson(Map<String, dynamic> json) {
    return DerivedUnitTemp(
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class DerivedInfo {
  final String rawAt;
  final DerivedEnergyToday? energyToday;
  final Map<String, DerivedUnitTemp> temps;

  DerivedInfo({required this.rawAt, this.energyToday, required this.temps});

  factory DerivedInfo.fromJson(Map<String, dynamic> json) {
    final rawTemps = json['temps'] as Map<String, dynamic>? ?? {};
    final parsedTemps = rawTemps.map((k, v) => MapEntry(k, DerivedUnitTemp.fromJson(v as Map<String, dynamic>)));
    return DerivedInfo(
      rawAt: json['raw_at'] ?? '',
      energyToday: json['energy_today'] != null ? DerivedEnergyToday.fromJson(json['energy_today'] as Map<String, dynamic>) : null,
      temps: parsedTemps,
    );
  }
}

class StationInfo {
  final String station;
  final String? receivedAt;
  final String? snapshotUtc;
  final String? version;
  final int tags;
  final double? power;
  final bool hasError;

  StationInfo({
    required this.station,
    this.receivedAt,
    this.snapshotUtc,
    this.version,
    required this.tags,
    this.power,
    required this.hasError,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      station: json['station'] ?? '',
      receivedAt: json['received_at'] as String?,
      snapshotUtc: json['snapshot_utc'] as String?,
      version: json['version'] as String?,
      tags: (json['tags'] as num?)?.toInt() ?? 0,
      power: (json['power'] as num?)?.toDouble(),
      hasError: json['has_error'] ?? false,
    );
  }
}

class WinccSnapshot {
  final String? source;
  final String? station;
  final String? version;
  final String? snapshotUtc;
  final Map<String, WinccTagStat> tags;
  final Map<String, double> energy5min;
  final int? tagErrors;
  final String? error;
  final String? receivedAt;

  WinccSnapshot({
    this.source,
    this.station,
    this.version,
    this.snapshotUtc,
    required this.tags,
    required this.energy5min,
    this.tagErrors,
    this.error,
    this.receivedAt,
  });

  factory WinccSnapshot.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as Map<String, dynamic>? ?? {};
    final parsedTags = <String, WinccTagStat>{};
    rawTags.forEach((k, v) {
      if (v is Map<String, dynamic> && v.containsKey('count')) {
        parsedTags[k] = WinccTagStat.fromJson(v);
      }
    });

    final rawEnergy = json['energy_5min'] as Map<String, dynamic>? ?? {};
    final parsedEnergy = rawEnergy.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0));

    return WinccSnapshot(
      source: json['source'] as String?,
      station: json['station'] as String?,
      version: json['version'] as String?,
      snapshotUtc: json['snapshot_utc'] as String?,
      tags: parsedTags,
      energy5min: parsedEnergy,
      tagErrors: (json['tag_errors'] as num?)?.toInt(),
      error: json['error'] as String?,
      receivedAt: json['received_at'] as String?,
    );
  }
}
