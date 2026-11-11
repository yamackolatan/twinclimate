import '../models/fingerprint.dart';
import '../models/matching.dart';
import '../models/session.dart';
import 'match_engine.dart';

/// "Ouderkerk aan de Amstel" when named, otherwise "38 km north".
String spotTitle(Spot spot) => spot.name ?? _capitalise(spotDirection(spot));

/// "38 km north · 12 m altitude" (direction only when it isn't the title).
String spotDetails(Spot spot) => [
  if (spot.name != null) spotDirection(spot),
  if (spot.elevationM != null) '${spot.elevationM!.round()} m altitude',
].join(' · ');

/// "Start between 07:00 and 09:00 → you'd train 07:00–10:30", the time
/// window the owner asked for.
String windowText(PlaceResult r) {
  final first = formatTime(r.windowFirstStart);
  final last = formatTime(r.windowLastStart);
  final end = formatTime(r.windowEnd);
  if (first == last) return 'Start at $first → you\'d train $first–$end';
  return 'Start between $first and $last → you\'d train $first–$end';
}

/// "Sat 24 Oct · best start 08:00" — or, for typical weather over a
/// period, "Typical day around 1 Dec · best start 08:00".
String bestStartText(PlaceResult r, {bool typicalDay = false}) =>
    '${typicalDay ? 'Typical day around ${formatDayMonth(r.best.start)}' : formatDay(r.best.start)} · '
    'best start ${formatTime(r.best.start)}';

/// Forecast vs race-typical numbers, e.g. "19°C vs 18°C race typical".
List<String> comparisonParts(SessionConditions c, ConditionStats target) => [
  '${c.temperature.round()}°C vs ${target.temperature.mean.round()}°C '
      'race typical',
  'humidity ${c.humidity.round()}% vs ${target.humidity.mean.round()}%',
  'wind ${c.wind.round()} vs ${target.wind.mean.round()} km/h',
  'rain ${(c.rainLikelihood * 100).round()}% vs '
      '${(target.rainChance * 100).round()}%',
];

String scoreText(double score) => '${score.round()}%';

/// The score bars in words, for phones where tooltips need a long press:
/// "Best start 08:00 scores 82% · every start 07:00–09:00 scores 75% or
/// more".
String scoreBarsText(PlaceResult r) {
  final best =
      'Best start ${formatTime(r.best.start)} scores ${scoreText(r.best.score)}';
  if (r.windowFirstStart == r.windowLastStart) {
    return '$best · other start times score lower';
  }
  final inWindow = [
    for (final o in r.dayScores)
      if (!o.start.isBefore(r.windowFirstStart) &&
          !o.start.isAfter(r.windowLastStart))
        o.score,
  ];
  final lowest = inWindow.reduce((a, b) => a < b ? a : b);
  return '$best · every start ${formatTime(r.windowFirstStart)}–'
      '${formatTime(r.windowLastStart)} scores ${scoreText(lowest)} or more';
}

/// Travel range for "Widen range": double it, up to the 300 km maximum;
/// null when it's already at the maximum.
double? widerRange(double rangeKm) {
  if (rangeKm >= maxRangeKm) return null;
  final doubled = (rangeKm * 2 / 10).round() * 10.0;
  return doubled > maxRangeKm ? maxRangeKm : doubled;
}

/// Longest travel range the form offers.
const double maxRangeKm = 300;

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
