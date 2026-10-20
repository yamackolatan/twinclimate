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
/// period, "On a typical day · best start 08:00".
String bestStartText(PlaceResult r, {bool typicalDay = false}) =>
    '${typicalDay ? 'On a typical day' : formatDay(r.best.start)} · '
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

String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
