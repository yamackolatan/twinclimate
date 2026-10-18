import 'session.dart';

/// Mean and standard deviation of one weather variable. The "typical
/// range" shown to the user is mean ± one standard deviation.
class Stat {
  const Stat(this.mean, this.sd);

  final double mean;
  final double sd;

  double get low => mean - sd;
  double get high => mean + sd;

  factory Stat.fromJson(Map<String, dynamic> json) =>
      Stat((json['mean'] as num).toDouble(), (json['sd'] as num).toDouble());

  Map<String, dynamic> toJson() => {'mean': mean, 'sd': sd};
}

/// Typical conditions over a set of hours (whole race, or one leg).
class ConditionStats {
  const ConditionStats({
    required this.temperature,
    required this.apparent,
    required this.humidity,
    required this.wind,
    required this.gust,
    required this.rainChance,
    required this.wetDayRainMm,
    required this.dayCount,
    required this.hourCount,
  });

  final Stat temperature;
  final Stat apparent;
  final Stat humidity;
  final Stat wind;
  final Stat gust;

  /// Share (0-1) of past race days with at least [wetDayThresholdMm] of
  /// rain during these hours.
  final double rainChance;

  /// Average rain during these hours on those wet days (0 if none).
  final double wetDayRainMm;

  /// Past race days (years × days around the date) that had data.
  final int dayCount;

  /// Hourly readings behind the numbers.
  final int hourCount;

  /// Owner decision: a day counts as wet with at least 1 mm of rain during
  /// the race hours.
  static const wetDayThresholdMm = 1.0;

  factory ConditionStats.fromJson(Map<String, dynamic> json) => ConditionStats(
    temperature: Stat.fromJson(json['temperature'] as Map<String, dynamic>),
    apparent: Stat.fromJson(json['apparent'] as Map<String, dynamic>),
    humidity: Stat.fromJson(json['humidity'] as Map<String, dynamic>),
    wind: Stat.fromJson(json['wind'] as Map<String, dynamic>),
    gust: Stat.fromJson(json['gust'] as Map<String, dynamic>),
    rainChance: (json['rainChance'] as num).toDouble(),
    wetDayRainMm: (json['wetDayRainMm'] as num).toDouble(),
    dayCount: json['dayCount'] as int,
    hourCount: json['hourCount'] as int,
  );

  Map<String, dynamic> toJson() => {
    'temperature': temperature.toJson(),
    'apparent': apparent.toJson(),
    'humidity': humidity.toJson(),
    'wind': wind.toJson(),
    'gust': gust.toJson(),
    'rainChance': rainChance,
    'wetDayRainMm': wetDayRainMm,
    'dayCount': dayCount,
    'hourCount': hourCount,
  };
}

/// Typical conditions for one leg of the race.
class LegFingerprint {
  const LegFingerprint({
    required this.sport,
    required this.startOffset,
    required this.endOffset,
    required this.stats,
  });

  final Sport sport;

  /// Minutes after the race start.
  final int startOffset;
  final int endOffset;

  final ConditionStats stats;

  factory LegFingerprint.fromJson(Map<String, dynamic> json) => LegFingerprint(
    sport: Sport.values.byName(json['sport'] as String),
    startOffset: json['startOffset'] as int,
    endOffset: json['endOffset'] as int,
    stats: ConditionStats.fromJson(json['stats'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'sport': sport.name,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'stats': stats.toJson(),
  };
}

/// Average temperature at one clock hour during the race window.
class ProfileHour {
  const ProfileHour(this.hour, this.temperature);

  /// Clock hour, 0-23.
  final int hour;
  final double temperature;

  factory ProfileHour.fromJson(Map<String, dynamic> json) =>
      ProfileHour(json['hour'] as int, (json['temperature'] as num).toDouble());

  Map<String, dynamic> toJson() => {'hour': hour, 'temperature': temperature};
}

/// A race's typical race-day climate: 10 years of history, ±5 days
/// around the race date, race hours only (PRD decision 8).
class RaceFingerprint {
  const RaceFingerprint({
    required this.key,
    required this.computedAt,
    required this.firstYear,
    required this.lastYear,
    required this.yearCount,
    required this.overall,
    required this.legs,
    required this.profile,
  });

  /// The Race.fingerprintKey this was computed for.
  final String key;

  final DateTime computedAt;
  final int firstYear;
  final int lastYear;
  final int yearCount;

  final ConditionStats overall;

  /// One per leg, in race order.
  final List<LegFingerprint> legs;

  /// Hour-by-hour average temperature across the race window.
  final List<ProfileHour> profile;

  factory RaceFingerprint.fromJson(Map<String, dynamic> json) =>
      RaceFingerprint(
        key: json['key'] as String,
        computedAt: DateTime.parse(json['computedAt'] as String),
        firstYear: json['firstYear'] as int,
        lastYear: json['lastYear'] as int,
        yearCount: json['yearCount'] as int,
        overall: ConditionStats.fromJson(
          json['overall'] as Map<String, dynamic>,
        ),
        legs: [
          for (final leg in json['legs'] as List)
            LegFingerprint.fromJson(leg as Map<String, dynamic>),
        ],
        profile: [
          for (final hour in json['profile'] as List)
            ProfileHour.fromJson(hour as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'computedAt': computedAt.toIso8601String(),
    'firstYear': firstYear,
    'lastYear': lastYear,
    'yearCount': yearCount,
    'overall': overall.toJson(),
    'legs': [for (final leg in legs) leg.toJson()],
    'profile': [for (final hour in profile) hour.toJson()],
  };
}
