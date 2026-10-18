import 'fingerprint.dart';
import 'race.dart';
import 'session.dart';

/// "Specific date" or "Best day in a period" (PRD decision 2).
enum MatchMode { specificDate, period }

/// How much each condition counts in the match score. Values are relative;
/// they're normalised to sum to 1 when scoring.
class MatchWeights {
  const MatchWeights({
    required this.temperature,
    required this.humidity,
    required this.wind,
    required this.rain,
  });

  final double temperature;
  final double humidity;
  final double wind;
  final double rain;

  /// Sport defaults (PRD decision 9): run → temperature & humidity, bike →
  /// wind, swim → air temperature and wind (water temperature comes later).
  factory MatchWeights.forSport(Sport sport) => switch (sport) {
    Sport.run => const MatchWeights(
      temperature: 0.35,
      humidity: 0.30,
      wind: 0.20,
      rain: 0.15,
    ),
    Sport.bike => const MatchWeights(
      temperature: 0.30,
      humidity: 0.15,
      wind: 0.35,
      rain: 0.20,
    ),
    Sport.swim => const MatchWeights(
      temperature: 0.40,
      humidity: 0.15,
      wind: 0.35,
      rain: 0.10,
    ),
  };

  double get _total => temperature + humidity + wind + rain;

  /// Normalised copy (sums to 1). All-zero falls back to equal weights.
  MatchWeights get normalised {
    final total = _total;
    if (total <= 0) {
      return const MatchWeights(
        temperature: 0.25,
        humidity: 0.25,
        wind: 0.25,
        rain: 0.25,
      );
    }
    return MatchWeights(
      temperature: temperature / total,
      humidity: humidity / total,
      wind: wind / total,
      rain: rain / total,
    );
  }

  MatchWeights copyWith({
    double? temperature,
    double? humidity,
    double? wind,
    double? rain,
  }) => MatchWeights(
    temperature: temperature ?? this.temperature,
    humidity: humidity ?? this.humidity,
    wind: wind ?? this.wind,
    rain: rain ?? this.rain,
  );
}

/// When the user can train: the earliest start and latest finish of the
/// day (owner request), and whether sessions must be in daylight.
class TrainingWindow {
  const TrainingWindow({
    this.fromMinutes = 6 * 60,
    this.untilMinutes = 20 * 60,
    this.daylightOnly = true,
  });

  /// Earliest start, minutes after midnight.
  final int fromMinutes;

  /// Latest finish, minutes after midnight (same day).
  final int untilMinutes;

  final bool daylightOnly;

  bool get isValid => untilMinutes > fromMinutes;

  /// The session fits between the earliest start and the latest finish.
  bool fits(int durationMinutes) =>
      untilMinutes - fromMinutes >= durationMinutes;

  /// Start times to try (minutes after midnight): every hour from the
  /// earliest start while the session still finishes in time.
  List<int> startMinutes(int durationMinutes) => [
    for (var m = fromMinutes; m + durationMinutes <= untilMinutes; m += 60) m,
  ];

  /// "06:00–20:00"
  String get label => '${clock(fromMinutes)}–${clock(untilMinutes)}';

  static String clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  TrainingWindow copyWith({
    int? fromMinutes,
    int? untilMinutes,
    bool? daylightOnly,
  }) => TrainingWindow(
    fromMinutes: fromMinutes ?? this.fromMinutes,
    untilMinutes: untilMinutes ?? this.untilMinutes,
    daylightOnly: daylightOnly ?? this.daylightOnly,
  );
}

/// What the user asked to match.
class MatchRequest {
  const MatchRequest({
    required this.race,
    required this.sport,
    required this.home,
    required this.distanceKm,
    required this.rangeKm,
    required this.mode,
    required this.date,
    required this.periodDays,
    required this.weights,
    this.window = const TrainingWindow(),
  });

  final Race race;

  /// The training sport; picks which race leg to match.
  final Sport sport;

  /// Starting point (the place picked in the form).
  final ({String name, double latitude, double longitude}) home;

  final double distanceKm;
  final double rangeKm;
  final MatchMode mode;

  /// The training day for [MatchMode.specificDate].
  final DateTime date;

  /// Days to scan from today for [MatchMode.period].
  final int periodDays;

  final MatchWeights weights;

  /// When the user can train that day.
  final TrainingWindow window;

  double get durationHours => distanceKm * sport.hoursPerKm;

  int get durationMinutes => (durationHours * 60).round();
}

/// Race conditions to aim for: the matching leg if the race has one,
/// otherwise the whole race window (owner decision 1).
class MatchTarget {
  const MatchTarget({
    required this.stats,
    required this.label,
    required this.isLeg,
  });

  final ConditionStats stats;

  /// e.g. "run leg 14:15–18:45" or "race hours 09:00–13:30".
  final String label;

  final bool isLeg;

  static MatchTarget? forRace(Race race, Sport sport) {
    final fingerprint = race.validFingerprint;
    if (fingerprint == null) return null;
    for (final leg in fingerprint.legs) {
      if (leg.sport == sport && race.isMultisport) {
        return MatchTarget(
          stats: leg.stats,
          label:
              '${sport.label.toLowerCase()} leg '
              '${race.clockAt(leg.startOffset)}–${race.clockAt(leg.endOffset)}',
          isLeg: true,
        );
      }
    }
    return MatchTarget(
      stats: fingerprint.overall,
      label: 'race hours ${race.windowLabel}',
      isLeg: false,
    );
  }
}

/// A point to check, placed in rings around the starting point.
class Spot {
  const Spot({
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.bearingDegrees,
    this.elevationM,
    this.name,
  });

  final double latitude;
  final double longitude;
  final double distanceKm;
  final double bearingDegrees;
  final double? elevationM;

  /// Filled in later from OpenStreetMap, when available.
  final String? name;

  bool get isHome => distanceKm < 0.5;

  Spot copyWith({double? elevationM, String? name}) => Spot(
    latitude: latitude,
    longitude: longitude,
    distanceKm: distanceKm,
    bearingDegrees: bearingDegrees,
    elevationM: elevationM ?? this.elevationM,
    name: name ?? this.name,
  );
}

/// Average forecast conditions during one session window.
class SessionConditions {
  const SessionConditions({
    required this.temperature,
    required this.humidity,
    required this.wind,
    required this.rainLikelihood,
  });

  final double temperature;
  final double humidity;
  final double wind;

  /// 0-1: the highest rain probability during the window.
  final double rainLikelihood;
}

/// One place-and-start-time combination with its score.
class MatchOption {
  const MatchOption({
    required this.start,
    required this.conditions,
    required this.score,
  });

  final DateTime start;
  final SessionConditions conditions;

  /// 0-100 similarity to the race target.
  final double score;
}

/// A recommended place: its best option plus the window of good start
/// times on that day (owner request: advise a time window, not just one
/// start time).
class PlaceResult {
  const PlaceResult({
    required this.spot,
    required this.best,
    required this.windowFirstStart,
    required this.windowLastStart,
    required this.durationMinutes,
    required this.dayScores,
  });

  final Spot spot;
  final MatchOption best;

  /// Earliest and latest start times on [best]'s day that still score
  /// close to the best (see `goodWindow`).
  final DateTime windowFirstStart;
  final DateTime windowLastStart;

  final int durationMinutes;

  /// Score for every scanned start hour on the best day, in order.
  final List<MatchOption> dayScores;

  /// When training would finish if starting at the latest good time.
  DateTime get windowEnd =>
      windowLastStart.add(Duration(minutes: durationMinutes));
}

/// The full answer for a [MatchRequest].
class MatchResult {
  const MatchResult({
    required this.target,
    required this.results,
    required this.spotsChecked,
    required this.notes,
  });

  final MatchTarget target;

  /// Top results, best first, each a different place.
  final List<PlaceResult> results;

  final int spotsChecked;

  /// Adaptation advice when even the best match is weak (< 70%).
  final List<String> notes;

  double get bestScore => results.isEmpty ? 0 : results.first.best.score;
}
