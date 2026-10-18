import 'dart:convert';

import 'gear.dart';
import 'session.dart';

/// Felt-temperature ranges the profile learns in. They follow the kit
/// ranges (owner request, Oct 2026: finer ranges — kit changes every few
/// degrees between about 7 and 20 °C, and below 10 °C each degree counts),
/// with the two coldest and two warmest kit ranges merged.
enum TempZone {
  freezing('below 0°C', 0),
  veryCold('between 0 and 4°C', 4),
  cold('between 4 and 7°C', 7),
  chilly('between 7 and 10°C', 10),
  cool('between 10 and 13°C', 13),
  mild('between 13 and 16°C', 16),
  mildWarm('between 16 and 20°C', 20),
  warm('above 20°C', double.infinity);

  const TempZone(this.phrase, this.upperC);

  /// "between 13 and 16°C", used in reasons and messages.
  final String phrase;

  /// The zone covers felt temperatures below this (and from the previous
  /// zone's upper bound).
  final double upperC;

  static TempZone of(double feelsC) =>
      TempZone.values.firstWhere((z) => feelsC < z.upperC);
}

enum Feeling { tooCold, justRight, tooWarm }

/// What the user wore compared with what was suggested.
enum Worn {
  /// Wore the suggestion (said so, or the packing checklist shows it).
  asSuggested,
  warmer,
  lighter,

  /// Skipped the question; treated like [asSuggested].
  unknown,
}

/// A session the user opened the kit list for. Kept so the app can ask how
/// it went once it's over, and knows what was suggested and packed.
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.sport,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.start,
    required this.end,
    required this.forecastFeelsC,
    required this.suggested,
    this.packed = const {},
    this.allPacked = false,
    this.status = SessionStatus.pending,
  });

  /// Same sport, spot and start time → same id (reopening replaces it).
  final String id;
  final Sport sport;
  final String placeName;
  final double latitude;
  final double longitude;

  /// Local time at the place.
  final DateTime start;
  final DateTime end;

  /// Mean "feels like" over the session, from the forecast shown.
  final double forecastFeelsC;

  /// The main suggested clothing item per body part, e.g. torso → "Light
  /// short-sleeve tech tee". Parts with nothing suggested are absent.
  final Map<BodyPart, String> suggested;

  /// Names of kit items ticked on the packing checklist.
  final Set<String> packed;
  final bool allPacked;

  final SessionStatus status;

  static String idFor(Sport sport, double lat, double lon, DateTime start) =>
      '${sport.name}|${lat.toStringAsFixed(3)}|${lon.toStringAsFixed(3)}|'
      '${start.toIso8601String()}';

  /// The checklist shows the suggestion for [part] was packed (free
  /// information: no need to ask "did you wear that?").
  bool packedSuggestionFor(BodyPart? part) {
    if (allPacked) return true;
    if (part == null) return false;
    final item = suggested[part];
    return item != null && packed.contains(item);
  }

  SessionRecord copyWith({
    Set<String>? packed,
    bool? allPacked,
    SessionStatus? status,
  }) => SessionRecord(
    id: id,
    sport: sport,
    placeName: placeName,
    latitude: latitude,
    longitude: longitude,
    start: start,
    end: end,
    forecastFeelsC: forecastFeelsC,
    suggested: suggested,
    packed: packed ?? this.packed,
    allPacked: allPacked ?? this.allPacked,
    status: status ?? this.status,
  );

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    id: json['id'] as String,
    sport: Sport.values.byName(json['sport'] as String),
    placeName: json['placeName'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    forecastFeelsC: (json['forecastFeelsC'] as num).toDouble(),
    suggested: {
      for (final e in (json['suggested'] as Map<String, dynamic>).entries)
        BodyPart.values.byName(e.key): e.value as String,
    },
    packed: {for (final p in json['packed'] as List) p as String},
    allPacked: json['allPacked'] as bool,
    status: SessionStatus.values.byName(json['status'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sport': sport.name,
    'placeName': placeName,
    'latitude': latitude,
    'longitude': longitude,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'forecastFeelsC': forecastFeelsC,
    'suggested': {for (final e in suggested.entries) e.key.name: e.value},
    'packed': packed.toList(),
    'allPacked': allPacked,
    'status': status.name,
  };
}

enum SessionStatus {
  pending,
  answered,
  didntGo,
  dismissed,

  /// Not asked because the profile is already stable ("ask less").
  skippedStable,
}

/// One answer to "How did it feel?".
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.sport,
    required this.date,
    required this.feelsC,
    required this.measured,
    required this.feeling,
    required this.part,
    required this.worn,
  });

  final String id;
  final Sport sport;

  /// When the session started.
  final DateTime date;

  /// Felt temperature during the session: recorded weather when
  /// [measured], otherwise the forecast that was shown.
  final double feelsC;
  final bool measured;

  final Feeling feeling;

  /// Null means "everywhere".
  final BodyPart? part;

  final Worn worn;

  TempZone get zone => TempZone.of(feelsC);

  /// Feedback explained by the user's own clothing choice is not learned
  /// from: too warm in something warmer than suggested, or too cold in
  /// something lighter.
  bool get explainedByClothing =>
      (feeling == Feeling.tooWarm && worn == Worn.warmer) ||
      (feeling == Feeling.tooCold && worn == Worn.lighter);

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
    id: json['id'] as String,
    sport: Sport.values.byName(json['sport'] as String),
    date: DateTime.parse(json['date'] as String),
    feelsC: (json['feelsC'] as num).toDouble(),
    measured: json['measured'] as bool,
    feeling: Feeling.values.byName(json['feeling'] as String),
    part: json['part'] == null
        ? null
        : BodyPart.values.byName(json['part'] as String),
    worn: Worn.values.byName(json['worn'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sport': sport.name,
    'date': date.toIso8601String(),
    'feelsC': feelsC,
    'measured': measured,
    'feeling': feeling.name,
    'part': part?.name,
    'worn': worn.name,
  };

  static String encodeList(List<FeedbackEntry> list) =>
      jsonEncode([for (final e in list) e.toJson()]);

  static List<FeedbackEntry> decodeList(String encoded) => [
    for (final item in jsonDecode(encoded) as List)
      FeedbackEntry.fromJson(item as Map<String, dynamic>),
  ];
}

/// Learning state for one sport + body part + zone.
class LearnedComfort {
  const LearnedComfort(this.net, this.reports);

  /// In points: a report counts 2 points in its own range and 1 point in
  /// each neighbouring range. Positive = runs warm, negative = runs cold.
  final int net;

  /// Reports given in this range itself.
  final int reports;

  /// Owner decision 2: two matching reports (4 points) = one step, at most
  /// two. One step = one kit range lighter (or warmer).
  int get steps =>
      net.sign * (net.abs() ~/ pointsPerStep).clamp(0, maxComfortSteps);
}

const int maxComfortSteps = 2;

/// Two reports in the same range make one step.
const int pointsPerStep = 4;

/// Everything the app knows about how warm or cold a user runs.
class ComfortProfile {
  ComfortProfile({
    required List<FeedbackEntry> feedback,
    this.manualSettings = const {},
    Map<String, DateTime> forgotten = const {},
  }) : _learned = _learn(feedback, forgotten),
       feedback = List.unmodifiable(feedback);

  /// All answers, oldest first.
  final List<FeedbackEntry> feedback;

  /// Settings sliders per sport and body part (−2 … +2).
  final Map<Sport, Map<BodyPart, int>> manualSettings;
  final Map<String, LearnedComfort> _learned;

  /// No feedback, no slider changes: sport defaults only.
  static final ComfortProfile empty = ComfortProfile(feedback: const []);

  static String key(Sport sport, BodyPart part, TempZone zone) =>
      '${sport.name}|${part.name}|${zone.name}';

  /// Settings slider value: −2 (runs cold) … +2 (runs warm).
  int manual(Sport sport, BodyPart part) => manualSettings[sport]?[part] ?? 0;

  LearnedComfort learned(Sport sport, BodyPart part, TempZone zone) =>
      _learned[key(sport, part, zone)] ?? const LearnedComfort(0, 0);

  /// Total steps (learned + slider), capped at ±2.
  int steps(Sport sport, BodyPart part, TempZone zone) =>
      (learned(sport, part, zone).steps + manual(sport, part)).clamp(
        -maxComfortSteps,
        maxComfortSteps,
      );

  /// Answers for [sport] in [zone], newest first.
  List<FeedbackEntry> recent(Sport sport, TempZone zone) => [
    for (final e in feedback.reversed)
      if (e.sport == sport && e.zone == zone) e,
  ];

  /// Owner decision ("ask less once it knows you"): four or more
  /// "just right" answers in a row for this sport and zone.
  bool isStable(Sport sport, TempZone zone) {
    final answers = recent(sport, zone);
    if (answers.length < 4) return false;
    return answers.take(4).every((e) => e.feeling == Feeling.justRight);
  }

  static Map<String, LearnedComfort> _learn(
    List<FeedbackEntry> feedback,
    Map<String, DateTime> forgotten,
  ) {
    final net = <String, int>{};
    final reports = <String, int>{};
    for (final e in feedback) {
      if (e.explainedByClothing) continue;
      final own = e.zone.index;
      for (final part in e.part == null ? BodyPart.values : [e.part!]) {
        // Own range counts fully, neighbouring ranges half, so the finer
        // ranges still learn quickly without mixing summer and winter.
        for (final (index, points) in [(own, 2), (own - 1, 1), (own + 1, 1)]) {
          if (index < 0 || index >= TempZone.values.length) continue;
          final k = key(e.sport, part, TempZone.values[index]);
          final forgetAt = forgotten[k];
          if (forgetAt != null && !e.date.isAfter(forgetAt)) continue;
          final current = net[k] ?? 0;
          switch (e.feeling) {
            case Feeling.tooWarm:
              net[k] = current + points;
            case Feeling.tooCold:
              net[k] = current - points;
            case Feeling.justRight:
              // Cancels part of earlier reports, so one odd day doesn't
              // stick — never overshooting past zero.
              net[k] = current.sign * (current.abs() - points).clamp(0, 99);
          }
          if (index == own && e.feeling != Feeling.justRight) {
            reports[k] = (reports[k] ?? 0) + 1;
          }
        }
      }
    }
    return {
      for (final k in net.keys) k: LearnedComfort(net[k]!, reports[k] ?? 0),
    };
  }
}
