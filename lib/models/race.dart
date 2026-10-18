import 'dart:convert';

import 'fingerprint.dart';
import 'place.dart';
import 'session.dart';

/// Legs always happen in this order (owner decision: duathlons with
/// run-bike-run are out of scope for now).
const List<Sport> legOrder = [Sport.swim, Sport.bike, Sport.run];

/// The most races a user can save at once (owner decision).
const int maxRaces = 3;

/// One part of a race: e.g. the 180 km bike leg, expected to take 6 h.
class RaceLeg {
  const RaceLeg({
    required this.sport,
    required this.distanceKm,
    required this.minutes,
  });

  final Sport sport;
  final double distanceKm;

  /// Expected duration of the leg. Transitions are ignored.
  final int minutes;

  /// Typical duration for [km] at the sport's amateur pace, rounded to
  /// 5 minutes (at least 5).
  static int estimateMinutes(Sport sport, double km) {
    final raw = km * sport.hoursPerKm * 60;
    final rounded = (raw / 5).round() * 5;
    return rounded < 5 ? 5 : rounded;
  }

  RaceLeg copyWith({double? distanceKm, int? minutes}) => RaceLeg(
    sport: sport,
    distanceKm: distanceKm ?? this.distanceKm,
    minutes: minutes ?? this.minutes,
  );

  factory RaceLeg.fromJson(Map<String, dynamic> json) => RaceLeg(
    sport: Sport.values.byName(json['sport'] as String),
    distanceKm: (json['distanceKm'] as num).toDouble(),
    minutes: json['minutes'] as int,
  );

  Map<String, dynamic> toJson() => {
    'sport': sport.name,
    'distanceKm': distanceKm,
    'minutes': minutes,
  };
}

/// A leg placed on the clock: starts [startOffset] minutes after the race
/// start and ends [endOffset] minutes after it.
class LegWindow {
  const LegWindow(this.leg, this.startOffset, this.endOffset);

  final RaceLeg leg;
  final int startOffset;
  final int endOffset;
}

/// A race the user is training for. Optional: the app works with none.
class Race {
  const Race({
    required this.id,
    required this.name,
    required this.place,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.legs,
    this.fingerprint,
  });

  final String id;
  final String name;
  final Place place;

  /// Race day (only year/month/day are used).
  final DateTime date;

  final int startHour;
  final int startMinute;

  /// In [legOrder]; at least one.
  final List<RaceLeg> legs;

  /// Cached race-day climate. Only valid while [fingerprintKey] matches,
  /// see [validFingerprint].
  final RaceFingerprint? fingerprint;

  int get startMinutesOfDay => startHour * 60 + startMinute;

  int get totalMinutes => legs.fold(0, (sum, leg) => sum + leg.minutes);

  bool get isMultisport => legs.length > 1;

  List<LegWindow> get legWindows {
    final windows = <LegWindow>[];
    var offset = 0;
    for (final leg in legs) {
      windows.add(LegWindow(leg, offset, offset + leg.minutes));
      offset += leg.minutes;
    }
    return windows;
  }

  /// "07:00" style clock time [offsetMinutes] after the start.
  String clockAt(int offsetMinutes) {
    final total = (startMinutesOfDay + offsetMinutes) % (24 * 60);
    final h = total ~/ 60;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// "07:00–18:45"
  String get windowLabel => '${clockAt(0)}–${clockAt(totalMinutes)}';

  /// "Swim 07:00–08:15 · Bike 08:15–14:15 · Run 14:15–18:45"
  String get legTimeline => [
    for (final w in legWindows)
      '${w.leg.sport.label} ${clockAt(w.startOffset)}–${clockAt(w.endOffset)}',
  ].join(' · ');

  /// Everything the fingerprint depends on: where, which calendar day, and
  /// which hours each leg covers. Renaming a race, or a distance change
  /// that keeps the same times, does not trigger a recalculation.
  String get fingerprintKey => [
    place.latitude.toStringAsFixed(3),
    place.longitude.toStringAsFixed(3),
    date.month,
    date.day,
    startMinutesOfDay,
    for (final w in legWindows)
      '${w.leg.sport.name}:${w.startOffset}-${w.endOffset}',
  ].join('|');

  RaceFingerprint? get validFingerprint =>
      fingerprint != null && fingerprint!.key == fingerprintKey
      ? fingerprint
      : null;

  Race withFingerprint(RaceFingerprint? value) => Race(
    id: id,
    name: name,
    place: place,
    date: date,
    startHour: startHour,
    startMinute: startMinute,
    legs: legs,
    fingerprint: value,
  );

  factory Race.fromJson(Map<String, dynamic> json) => Race(
    id: json['id'] as String,
    name: json['name'] as String,
    place: Place.fromJson(json['place'] as Map<String, dynamic>),
    date: DateTime.parse(json['date'] as String),
    startHour: json['startHour'] as int,
    startMinute: json['startMinute'] as int,
    legs: [
      for (final leg in json['legs'] as List)
        RaceLeg.fromJson(leg as Map<String, dynamic>),
    ],
    fingerprint: json['fingerprint'] == null
        ? null
        : RaceFingerprint.fromJson(json['fingerprint'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'place': place.toJson(),
    'date': dateParam(date),
    'startHour': startHour,
    'startMinute': startMinute,
    'legs': [for (final leg in legs) leg.toJson()],
    if (fingerprint != null) 'fingerprint': fingerprint!.toJson(),
  };

  static String encodeList(List<Race> races) =>
      jsonEncode([for (final r in races) r.toJson()]);

  static List<Race> decodeList(String encoded) => [
    for (final item in jsonDecode(encoded) as List)
      Race.fromJson(item as Map<String, dynamic>),
  ];
}

/// A quick-fill button in the race form, e.g. "Ironman".
class RacePreset {
  const RacePreset(this.label, this.legs);

  final String label;
  final List<RaceLeg> legs;
}

const List<RacePreset> triathlonPresets = [
  RacePreset('Sprint', [
    RaceLeg(sport: Sport.swim, distanceKm: 0.75, minutes: 20),
    RaceLeg(sport: Sport.bike, distanceKm: 20, minutes: 45),
    RaceLeg(sport: Sport.run, distanceKm: 5, minutes: 30),
  ]),
  RacePreset('Olympic', [
    RaceLeg(sport: Sport.swim, distanceKm: 1.5, minutes: 35),
    RaceLeg(sport: Sport.bike, distanceKm: 40, minutes: 80),
    RaceLeg(sport: Sport.run, distanceKm: 10, minutes: 55),
  ]),
  RacePreset('70.3', [
    RaceLeg(sport: Sport.swim, distanceKm: 1.9, minutes: 45),
    RaceLeg(sport: Sport.bike, distanceKm: 90, minutes: 180),
    RaceLeg(sport: Sport.run, distanceKm: 21.1, minutes: 135),
  ]),
  RacePreset('Ironman', [
    RaceLeg(sport: Sport.swim, distanceKm: 3.8, minutes: 75),
    RaceLeg(sport: Sport.bike, distanceKm: 180, minutes: 360),
    RaceLeg(sport: Sport.run, distanceKm: 42.2, minutes: 270),
  ]),
];

const List<RacePreset> runPresets = [
  RacePreset('10 km', [RaceLeg(sport: Sport.run, distanceKm: 10, minutes: 60)]),
  RacePreset('Half', [
    RaceLeg(sport: Sport.run, distanceKm: 21.1, minutes: 130),
  ]),
  RacePreset('Marathon', [
    RaceLeg(sport: Sport.run, distanceKm: 42.2, minutes: 270),
  ]),
];

/// Quick-fill buttons that fit the chosen sports (none for other mixes).
List<RacePreset> presetsFor(Set<Sport> sports) {
  if (sports.length == 3) return triathlonPresets;
  if (sports.length == 1 && sports.contains(Sport.run)) return runPresets;
  return const [];
}

/// Sensible starting leg when a sport is ticked in the form.
RaceLeg defaultLeg(Sport sport) => RaceLeg(
  sport: sport,
  distanceKm: sport.defaultKm,
  minutes: RaceLeg.estimateMinutes(sport, sport.defaultKm),
);

/// "2026-08-29"
String dateParam(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
