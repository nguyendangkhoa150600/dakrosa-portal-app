import 'solar_model.dart';

class MobileApiError {
  final String source;
  final String code;
  final String message;

  MobileApiError({required this.source, required this.code, required this.message});

  factory MobileApiError.fromJson(Map<String, dynamic> json) {
    return MobileApiError(
      source: json['source'] ?? '',
      code: json['code'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class MobileStation {
  final String station;
  final String? receivedAt;
  final String? snapshotUtc;
  final bool online;
  final int? ageSec;
  final double? powerKw;
  final int tags;
  final bool hasError;

  MobileStation({
    required this.station,
    this.receivedAt,
    this.snapshotUtc,
    required this.online,
    this.ageSec,
    this.powerKw,
    required this.tags,
    required this.hasError,
  });

  factory MobileStation.fromJson(Map<String, dynamic> json) {
    return MobileStation(
      station: json['station'] ?? '',
      receivedAt: json['received_at'] as String?,
      snapshotUtc: json['snapshot_utc'] as String?,
      online: json['online'] ?? false,
      ageSec: (json['age_sec'] as num?)?.toInt(),
      powerKw: (json['power_kw'] as num?)?.toDouble(),
      tags: (json['tags'] as num?)?.toInt() ?? 0,
      hasError: json['has_error'] ?? false,
    );
  }
}

class MobileMetric {
  final String key;
  final String label;
  final double? value;
  final String unit;
  final String group;
  final int decimals;

  MobileMetric({
    required this.key,
    required this.label,
    this.value,
    required this.unit,
    required this.group,
    required this.decimals,
  });

  factory MobileMetric.fromJson(Map<String, dynamic> json) {
    return MobileMetric(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] ?? '',
      group: json['group'] ?? '',
      decimals: (json['decimals'] as num?)?.toInt() ?? 0,
    );
  }
}

class MobileHydroUnit {
  final String id;
  final String name;
  final bool running;
  final double? powerKw;
  final double? reactivePowerKvar;
  final double? apparentPowerKva;
  final double? voltageV;
  final double? currentA;
  final double? frequencyHz;
  final double? powerFactor;
  final double? guideVanePercent;
  final double? speedRpm;
  final double? energy5minMwh;
  final double? energyTodayMwh;
  final double? maxTempC;
  final List<MobileMetric> metrics;

  MobileHydroUnit({
    required this.id,
    required this.name,
    required this.running,
    this.powerKw,
    this.reactivePowerKvar,
    this.apparentPowerKva,
    this.voltageV,
    this.currentA,
    this.frequencyHz,
    this.powerFactor,
    this.guideVanePercent,
    this.speedRpm,
    this.energy5minMwh,
    this.energyTodayMwh,
    this.maxTempC,
    required this.metrics,
  });

  factory MobileHydroUnit.fromJson(Map<String, dynamic> json) {
    return MobileHydroUnit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      running: json['running'] ?? false,
      powerKw: (json['power_kw'] as num?)?.toDouble(),
      reactivePowerKvar: (json['reactive_power_kvar'] as num?)?.toDouble(),
      apparentPowerKva: (json['apparent_power_kva'] as num?)?.toDouble(),
      voltageV: (json['voltage_v'] as num?)?.toDouble(),
      currentA: (json['current_a'] as num?)?.toDouble(),
      frequencyHz: (json['frequency_hz'] as num?)?.toDouble(),
      powerFactor: (json['power_factor'] as num?)?.toDouble(),
      guideVanePercent: (json['guide_vane_percent'] as num?)?.toDouble(),
      speedRpm: (json['speed_rpm'] as num?)?.toDouble(),
      energy5minMwh: (json['energy_5min_mwh'] as num?)?.toDouble(),
      energyTodayMwh: (json['energy_today_mwh'] as num?)?.toDouble(),
      maxTempC: (json['max_temp_c'] as num?)?.toDouble(),
      metrics: (json['metrics'] as List?)?.map((x) => MobileMetric.fromJson(x)).toList() ?? [],
    );
  }
}

class MobileHydroScada {
  final bool readOnly;
  final String source;
  final String? updatedAt;
  final Map<String, double> values;
  final Map<String, double> readouts;

  MobileHydroScada({
    required this.readOnly,
    required this.source,
    this.updatedAt,
    required this.values,
    required this.readouts,
  });

  factory MobileHydroScada.fromJson(Map<String, dynamic> json) {
    final valuesMap = <String, double>{};
    if (json['values'] is Map) {
      (json['values'] as Map).forEach((k, v) {
        if (v != null) {
          valuesMap[k.toString()] = (v as num).toDouble();
        }
      });
    }

    final readoutsMap = <String, double>{};
    if (json['readouts'] is Map) {
      (json['readouts'] as Map).forEach((k, v) {
        if (v != null) {
          readoutsMap[k.toString()] = (v as num).toDouble();
        }
      });
    }

    return MobileHydroScada(
      readOnly: json['read_only'] ?? false,
      source: json['source'] ?? '',
      updatedAt: json['updated_at'] as String?,
      values: valuesMap,
      readouts: readoutsMap,
    );
  }
}

class MobileHydro {
  final String station;
  final bool online;
  final int? ageSec;
  final String? receivedAt;
  final String? snapshotUtc;
  final double? powerKw;
  final double? reactivePowerKvar;
  final double? apparentPowerKva;
  final double? voltageKv;
  final double? currentA;
  final double? frequencyHz;
  final double? powerFactor;
  final double? energy5minMwh;
  final double? energyTodayMwh;
  final int runningUnits;
  final int unitCount;
  final List<MobileMetric> metrics;
  final List<MobileHydroUnit> units;
  final MobileHydroScada? scada;

  MobileHydro({
    required this.station,
    required this.online,
    this.ageSec,
    this.receivedAt,
    this.snapshotUtc,
    this.powerKw,
    this.reactivePowerKvar,
    this.apparentPowerKva,
    this.voltageKv,
    this.currentA,
    this.frequencyHz,
    this.powerFactor,
    this.energy5minMwh,
    this.energyTodayMwh,
    required this.runningUnits,
    required this.unitCount,
    required this.metrics,
    required this.units,
    this.scada,
  });

  factory MobileHydro.fromJson(Map<String, dynamic> json) {
    return MobileHydro(
      station: json['station'] ?? '',
      online: json['online'] ?? false,
      ageSec: (json['age_sec'] as num?)?.toInt(),
      receivedAt: json['received_at'] as String?,
      snapshotUtc: json['snapshot_utc'] as String?,
      powerKw: (json['power_kw'] as num?)?.toDouble(),
      reactivePowerKvar: (json['reactive_power_kvar'] as num?)?.toDouble(),
      apparentPowerKva: (json['apparent_power_kva'] as num?)?.toDouble(),
      voltageKv: (json['voltage_kv'] as num?)?.toDouble(),
      currentA: (json['current_a'] as num?)?.toDouble(),
      frequencyHz: (json['frequency_hz'] as num?)?.toDouble(),
      powerFactor: (json['power_factor'] as num?)?.toDouble(),
      energy5minMwh: (json['energy_5min_mwh'] as num?)?.toDouble(),
      energyTodayMwh: (json['energy_today_mwh'] as num?)?.toDouble(),
      runningUnits: (json['running_units'] as num?)?.toInt() ?? 0,
      unitCount: (json['unit_count'] as num?)?.toInt() ?? 0,
      metrics: (json['metrics'] as List?)?.map((x) => MobileMetric.fromJson(x)).toList() ?? [],
      units: (json['units'] as List?)?.map((x) => MobileHydroUnit.fromJson(x)).toList() ?? [],
      scada: json['scada'] != null ? MobileHydroScada.fromJson(json['scada']) : null,
    );
  }
}

class MobileSolar {
  final String status;
  final String name;
  final bool configured;
  final double? currentKw;
  final String? currentAt;
  final double? todayKwh;
  final double? monthKwh;
  final double? yearKwh;
  final double? lifetimeKwh;
  final double? peakTodayKw;
  final double? capacityKwp;
  final double? specificYieldToday;
  final double? specificYieldYear;
  final double? co2TodayKg;
  final String? location;
  final String? commissioned;
  final String? inverterModel;
  final int? inverterCount;
  final int activeInverters;
  final double? capacityUtilizationPercent;
  final List<MobileMetric> metrics;
  final List<SolarInverter> inverters;
  final List<SolarBucket> curve;
  final List<SolarDay> days;
  final String updatedAt;
  final String? error;

  MobileSolar({
    required this.status,
    required this.name,
    required this.configured,
    this.currentKw,
    this.currentAt,
    this.todayKwh,
    this.monthKwh,
    this.yearKwh,
    this.lifetimeKwh,
    this.peakTodayKw,
    this.capacityKwp,
    this.specificYieldToday,
    this.specificYieldYear,
    this.co2TodayKg,
    this.location,
    this.commissioned,
    this.inverterModel,
    this.inverterCount,
    required this.activeInverters,
    this.capacityUtilizationPercent,
    required this.metrics,
    required this.inverters,
    required this.curve,
    required this.days,
    required this.updatedAt,
    this.error,
  });

  factory MobileSolar.fromJson(Map<String, dynamic> json) {
    return MobileSolar(
      status: json['status'] ?? '',
      name: json['name'] ?? '',
      configured: json['configured'] ?? false,
      currentKw: (json['current_kw'] as num?)?.toDouble(),
      currentAt: json['current_at'] as String?,
      todayKwh: (json['today_kwh'] as num?)?.toDouble(),
      monthKwh: (json['month_kwh'] as num?)?.toDouble(),
      yearKwh: (json['year_kwh'] as num?)?.toDouble(),
      lifetimeKwh: (json['lifetime_kwh'] as num?)?.toDouble(),
      peakTodayKw: (json['peak_today_kw'] as num?)?.toDouble(),
      capacityKwp: (json['capacity_kwp'] as num?)?.toDouble(),
      specificYieldToday: (json['specific_yield_today'] as num?)?.toDouble(),
      specificYieldYear: (json['specific_yield_year'] as num?)?.toDouble(),
      co2TodayKg: (json['co2_today_kg'] as num?)?.toDouble(),
      location: json['location'] as String?,
      commissioned: json['commissioned'] as String?,
      inverterModel: json['inverter_model'] as String?,
      inverterCount: (json['inverter_count'] as num?)?.toInt(),
      activeInverters: (json['active_inverters'] as num?)?.toInt() ?? 0,
      capacityUtilizationPercent: (json['capacity_utilization_percent'] as num?)?.toDouble(),
      metrics: (json['metrics'] as List?)?.map((x) => MobileMetric.fromJson(x)).toList() ?? [],
      inverters: (json['inverters'] as List?)?.map((x) => SolarInverter.fromJson(x)).toList() ?? [],
      curve: (json['curve'] as List?)?.map((x) => SolarBucket.fromJson(x)).toList() ?? [],
      days: (json['days'] as List?)?.map((x) => SolarDay.fromJson(x)).toList() ?? [],
      updatedAt: json['updated_at'] ?? '',
      error: json['error'] as String?,
    );
  }
}

class MobileTotals {
  final double? solarCurrentKw;
  final double? hydroCurrentKw;
  final double? totalCurrentKw;
  final int hydroStationCount;
  final int onlineHydroStations;
  final int activeHydroUnits;
  final int hydroUnitCount;
  final int activeInverters;
  final int inverterCount;
  final List<MobileMetric> metrics;

  MobileTotals({
    this.solarCurrentKw,
    this.hydroCurrentKw,
    this.totalCurrentKw,
    required this.hydroStationCount,
    required this.onlineHydroStations,
    required this.activeHydroUnits,
    required this.hydroUnitCount,
    required this.activeInverters,
    required this.inverterCount,
    required this.metrics,
  });

  factory MobileTotals.fromJson(Map<String, dynamic> json) {
    return MobileTotals(
      solarCurrentKw: (json['solar_current_kw'] as num?)?.toDouble(),
      hydroCurrentKw: (json['hydro_current_kw'] as num?)?.toDouble(),
      totalCurrentKw: (json['total_current_kw'] as num?)?.toDouble(),
      hydroStationCount: (json['hydro_station_count'] as num?)?.toInt() ?? 0,
      onlineHydroStations: (json['online_hydro_stations'] as num?)?.toInt() ?? 0,
      activeHydroUnits: (json['active_hydro_units'] as num?)?.toInt() ?? 0,
      hydroUnitCount: (json['hydro_unit_count'] as num?)?.toInt() ?? 0,
      activeInverters: (json['active_inverters'] as num?)?.toInt() ?? 0,
      inverterCount: (json['inverter_count'] as num?)?.toInt() ?? 0,
      metrics: (json['metrics'] as List?)?.map((x) => MobileMetric.fromJson(x)).toList() ?? [],
    );
  }
}

class DakrosaMobileResponse {
  final bool ok;
  final int schemaVersion;
  final String generatedAt;
  final String? station;
  final List<MobileStation> stations;
  final MobileHydro? hydro;
  final List<MobileHydro> hydroStations;
  final MobileTotals totals;
  final MobileSolar solar;
  final List<MobileApiError> errors;

  DakrosaMobileResponse({
    required this.ok,
    required this.schemaVersion,
    required this.generatedAt,
    this.station,
    required this.stations,
    this.hydro,
    required this.hydroStations,
    required this.totals,
    required this.solar,
    required this.errors,
  });

  factory DakrosaMobileResponse.fromJson(Map<String, dynamic> json) {
    return DakrosaMobileResponse(
      ok: json['ok'] ?? false,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      generatedAt: json['generated_at'] ?? '',
      station: json['station'] as String?,
      stations: (json['stations'] as List?)?.map((x) => MobileStation.fromJson(x)).toList() ?? [],
      hydro: json['hydro'] != null ? MobileHydro.fromJson(json['hydro']) : null,
      hydroStations: (json['hydro_stations'] as List?)?.map((x) => MobileHydro.fromJson(x)).toList() ?? [],
      totals: MobileTotals.fromJson(json['totals'] ?? {}),
      solar: MobileSolar.fromJson(json['solar'] ?? {}),
      errors: (json['errors'] as List?)?.map((x) => MobileApiError.fromJson(x)).toList() ?? [],
    );
  }
}
