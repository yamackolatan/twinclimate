import 'dart:math' as math;

import 'models.dart';

/// How alike two cities' climates are.
class TwinResult {
  const TwinResult({required this.score, required this.seasonsFlipped});

  /// 0 (nothing alike) to 100 (identical climate).
  final double score;

  /// True when the best match aligns one city's January with the other's
  /// July, i.e. the cities share a climate but their seasons are offset by
  /// half a year (typical for cross-hemisphere twins).
  final bool seasonsFlipped;
}

/// Scores how similar two cities' climates are, 0-100.
///
/// The score is based on the average month-by-month difference in daily
/// highs, daily lows, and precipitation (log-scaled, so 5 mm vs 20 mm
/// matters more than 180 mm vs 220 mm). Both calendar alignment and a
/// six-month shift are tried, and the better one wins, so cross-hemisphere
/// twins like Cape Town and Los Angeles are recognized.
TwinResult twinScore(City a, City b) {
  final direct = _meanDifference(a, b, 0);
  final shifted = _meanDifference(a, b, 6);
  final flipped = shifted < direct;
  return TwinResult(
    score: _toScore(flipped ? shifted : direct),
    seasonsFlipped: flipped,
  );
}

/// All other cities ranked by similarity to [home], best match first.
List<(City, TwinResult)> rankTwins(City home, List<City> all) {
  final ranked = [
    for (final city in all)
      if (city != home) (city, twinScore(home, city)),
  ];
  ranked.sort((a, b) => b.$2.score.compareTo(a.$2.score));
  return ranked;
}

String scoreLabel(double score) {
  if (score >= 85) return 'Climate twins';
  if (score >= 70) return 'Close cousins';
  if (score >= 50) return 'Same family';
  if (score >= 30) return 'Distant relatives';
  return 'Different worlds';
}

/// Mean weighted difference between the two cities with [b]'s months
/// shifted forward by [shift]. Expressed roughly in degrees Celsius.
double _meanDifference(City a, City b, int shift) {
  var high = 0.0;
  var low = 0.0;
  var precip = 0.0;
  for (var m = 0; m < 12; m++) {
    final n = (m + shift) % 12;
    high += (a.highC[m] - b.highC[n]).abs();
    low += (a.lowC[m] - b.lowC[n]).abs();
    precip += (math.log(1 + a.precipMm[m]) - math.log(1 + b.precipMm[n])).abs();
  }
  high /= 12;
  low /= 12;
  precip /= 12;
  // The factor of 5 puts the log-precipitation difference on a scale
  // comparable to degrees of temperature difference.
  return 0.4 * high + 0.4 * low + 0.2 * (precip * 5);
}

/// Maps a mean difference (0 = identical) to a 0-100 score.
double _toScore(double difference) => (100 - 6.5 * difference).clamp(0, 100);
