import 'dart:math' as math;

import '../models/fingerprint.dart';
import '../models/matching.dart';
import '../models/session.dart';
import '../models/weather.dart';

/// Spots per ring, from the starting point outwards (43 in total).
const List<int> _ringCounts = [1, 6, 8, 12, 16];

/// Results shown (PRD: top 5, each a different place — owner decision 3).
const int resultCount = 5;

/// Below this the best match is called weak and adaptation notes appear.
const double goodMatchScore = 70;

const double _earthRadiusKm = 6371;

/// Spots in rings around ([latitude], [longitude]) out to [rangeKm], so the
/// search covers every direction (coast, inland, hills).
List<Spot> generateSpots(double latitude, double longitude, double rangeKm) {
  final spots = <Spot>[];
  for (var ring = 0; ring < _ringCounts.length; ring++) {
    final distance = rangeKm * ring / (_ringCounts.length - 1);
    final count = _ringCounts[ring];
    // Alternate rings are rotated half a step so spots don't line up.
    final offset = ring.isOdd ? 0.0 : 180.0 / count;
    for (var i = 0; i < count; i++) {
      final bearing = ring == 0 ? 0.0 : (offset + 360.0 * i / count) % 360;
      final (lat, lon) = destination(latitude, longitude, bearing, distance);
      spots.add(
        Spot(
          latitude: lat,
          longitude: lon,
          distanceKm: distance,
          bearingDegrees: bearing,
        ),
      );
    }
  }
  return spots;
}

/// Point [distanceKm] away from a start point in direction [bearing]
/// (degrees clockwise from north).
(double, double) destination(
  double latitude,
  double longitude,
  double bearing,
  double distanceKm,
) {
  final d = distanceKm / _earthRadiusKm;
  final b = bearing * math.pi / 180;
  final lat1 = latitude * math.pi / 180;
  final lon1 = longitude * math.pi / 180;
  final lat2 = math.asin(
    math.sin(lat1) * math.cos(d) + math.cos(lat1) * math.sin(d) * math.cos(b),
  );
  final lon2 =
      lon1 +
      math.atan2(
        math.sin(b) * math.sin(d) * math.cos(lat1),
        math.cos(d) - math.sin(lat1) * math.sin(lat2),
      );
  return (lat2 * 180 / math.pi, ((lon2 * 180 / math.pi) + 540) % 360 - 180);
}

const List<String> _compass = [
  'north',
  'north-east',
  'east',
  'south-east',
  'south',
  'south-west',
  'west',
  'north-west',
];

/// "38 km north" (or "your starting point").
String spotDirection(Spot spot) {
  if (spot.isHome) return 'your starting point';
  final index = ((spot.bearingDegrees + 22.5) % 360 ~/ 45).toInt();
  return '${spot.distanceKm.round()} km ${_compass[index]}';
}

/// Average conditions for a session starting at [start] lasting
/// [durationMinutes], from hourly forecast [byHour] (keyed by local hour).
/// Null if any hour of the window is missing or, with [requireDaylight],
/// falls after dark.
SessionConditions? sessionConditions(
  Map<DateTime, HourWeather> byHour,
  DateTime start,
  int durationMinutes, {
  bool requireDaylight = true,
}) {
  final end = start.add(Duration(minutes: math.max(durationMinutes, 1)));
  final hours = <HourWeather>[];
  var slot = DateTime(start.year, start.month, start.day, start.hour);
  while (slot.isBefore(end)) {
    final reading = byHour[slot];
    if (reading == null || (requireDaylight && !reading.isDay)) return null;
    hours.add(reading);
    slot = slot.add(const Duration(hours: 1));
  }
  // Must also finish before dark, judged at the hour nearest the finish.
  final finishHour = DateTime(
    end.year,
    end.month,
    end.day,
    end.hour,
  ).add(Duration(hours: end.minute >= 30 ? 1 : 0));
  final atFinish = byHour[finishHour];
  if (requireDaylight && atFinish != null && !atFinish.isDay) return null;
  double mean(double Function(HourWeather) f) =>
      hours.map(f).reduce((a, b) => a + b) / hours.length;
  return SessionConditions(
    temperature: mean((h) => h.temperatureC),
    humidity: mean((h) => h.humidityPercent),
    wind: mean((h) => h.windKmh),
    rainLikelihood:
        hours.map((h) => h.precipProbabilityPercent).reduce(math.max) / 100,
  );
}

/// How alike [c] is to the race [target], 0-100.
///
/// Each condition's gap is measured in the race's own normal spread
/// (standard deviation, with a small floor so very steady races aren't
/// impossibly strict). The weighted average gap D maps to a score with
/// 100 · e^(−D²/2.88): D = 0 → 100 %, one normal spread off → about 70 %,
/// two → about 25 %.
double similarityScore(
  SessionConditions c,
  ConditionStats target,
  MatchWeights weights,
) {
  final w = weights.normalised;
  final gap =
      w.temperature * _gap(c.temperature, target.temperature, floor: 2) +
      w.humidity * _gap(c.humidity, target.humidity, floor: 8) +
      w.wind * _gap(c.wind, target.wind, floor: 4) +
      w.rain * (c.rainLikelihood - target.rainChance).abs() / 0.35;
  return 100 * math.exp(-gap * gap / 2.88);
}

double _gap(double value, Stat stat, {required double floor}) =>
    (value - stat.mean).abs() / math.max(stat.sd, floor);

/// Scans every day and every hourly start time inside the user's training
/// [window] for one spot, and returns its best day as a [PlaceResult], or
/// null if no start time could be scored.
PlaceResult? bestForSpot({
  required Spot spot,
  required Map<DateTime, HourWeather> byHour,
  required List<DateTime> days,
  required int durationMinutes,
  required ConditionStats target,
  required MatchWeights weights,
  required TrainingWindow window,
  DateTime? notBefore,
}) {
  PlaceResult? best;
  for (final day in days) {
    final options = <MatchOption>[];
    for (final minutes in window.startMinutes(durationMinutes)) {
      final start = DateTime(
        day.year,
        day.month,
        day.day,
      ).add(Duration(minutes: minutes));
      if (notBefore != null && start.isBefore(notBefore)) continue;
      final conditions = sessionConditions(
        byHour,
        start,
        durationMinutes,
        requireDaylight: window.daylightOnly,
      );
      if (conditions == null) continue;
      options.add(
        MatchOption(
          start: start,
          conditions: conditions,
          score: similarityScore(conditions, target, weights),
        ),
      );
    }
    if (options.isEmpty) continue;
    final dayResult = _dayResult(spot, options, durationMinutes);
    if (best == null || dayResult.best.score > best.best.score) {
      best = dayResult;
    }
  }
  return best;
}

/// Best start on one day plus the run of neighbouring start times that
/// stay close to it: within 8 points (never below 70 %) for good matches,
/// within 5 points for weak ones.
PlaceResult _dayResult(
  Spot spot,
  List<MatchOption> options,
  int durationMinutes,
) {
  var bestIndex = 0;
  for (var i = 1; i < options.length; i++) {
    if (options[i].score > options[bestIndex].score) bestIndex = i;
  }
  final bestScore = options[bestIndex].score;
  final threshold = bestScore >= goodMatchScore
      ? math.max(goodMatchScore, bestScore - 8)
      : bestScore - 5;
  bool consecutive(int a, int b) =>
      options[b].start.difference(options[a].start).inHours == 1;
  var first = bestIndex;
  while (first > 0 &&
      consecutive(first - 1, first) &&
      options[first - 1].score >= threshold) {
    first--;
  }
  var last = bestIndex;
  while (last < options.length - 1 &&
      consecutive(last, last + 1) &&
      options[last + 1].score >= threshold) {
    last++;
  }
  return PlaceResult(
    spot: spot,
    best: options[bestIndex],
    windowFirstStart: options[first].start,
    windowLastStart: options[last].start,
    durationMinutes: durationMinutes,
    dayScores: options,
  );
}

/// Best first, each a different place; ties go to the closer spot.
List<PlaceResult> rankResults(List<PlaceResult> all) {
  final sorted = [...all]
    ..sort((a, b) {
      final byScore = b.best.score.round().compareTo(a.best.score.round());
      if (byScore != 0) return byScore;
      return a.spot.distanceKm.compareTo(b.spot.distanceKm);
    });
  return sorted.take(resultCount).toList();
}

/// Explains an empty result: nothing in the user's training window could
/// be scored.
String noTimeFoundNote(TrainingWindow window, int durationMinutes) {
  final length = formatDuration(durationMinutes / 60);
  if (!window.fits(durationMinutes)) {
    return 'Your training window (${window.label}) is shorter than this '
        'session (about $length). Widen the window or shorten the session.';
  }
  return window.daylightOnly
      ? 'No start time between ${window.label} fits a session of about '
            '$length in daylight on the chosen date. Try a wider window, '
            'turn off "Daylight only", or pick another date.'
      : 'No start time between ${window.label} fits a session of about '
            '$length on the chosen date. Try a wider window or another date.';
}

/// Honest advice when even the best option is a weak match (PRD decision
/// 11), based on how the best option differs from the race.
List<String> adaptationNotes({
  required PlaceResult? best,
  required ConditionStats target,
  required Sport sport,
  required double rangeKm,
}) {
  if (best == null) return const [];
  if (best.best.score >= goodMatchScore) return const [];
  final c = best.best.conditions;
  final notes = <String>[];
  final dT = c.temperature - target.temperature.mean;
  // Quoted as the difference of the rounded numbers the card shows.
  final shownDT = (c.temperature.round() - target.temperature.mean.round())
      .abs();
  if (dT >= 3) {
    notes.add(
      'About $shownDT°C warmer than race day. '
      '${switch (sport) {
        Sport.run => 'Run at an easier pace (roughly 10–15 sec/km slower) and drink more than you would on race day.',
        Sport.bike => 'Ride a little below race power and drink more than you would on race day.',
        Sport.swim => 'Expect to feel warmer than on race day; keep the effort controlled.',
      }}',
    );
  } else if (dT <= -3) {
    notes.add(
      'About $shownDT°C cooler than race day, so race day '
      'will feel harder. Consider heat acclimatisation: in the last two '
      'weeks before the race, add a few easy sessions in extra layers or '
      'in a warm indoor space.',
    );
  }
  final dH = c.humidity - target.humidity.mean;
  if (dH <= -15) {
    notes.add(
      'Drier air than race day (${c.humidity.round()}% vs '
      '${target.humidity.mean.round()}%). Sweat evaporates more easily '
      'here, so plan race-day drinking from the race conditions, not '
      'from this session.',
    );
  } else if (dH >= 15) {
    notes.add(
      'More humid than race day (${c.humidity.round()}% vs '
      '${target.humidity.mean.round()}%): expect a higher heart rate '
      'for the same pace.',
    );
  }
  final dW = c.wind - target.wind.mean;
  if (dW <= -8) {
    notes.add(
      'Less wind than race day (${c.wind.round()} vs '
      '${target.wind.mean.round()} km/h). When you can, practise holding '
      'your effort into a headwind.',
    );
  } else if (dW >= 8) {
    notes.add(
      'Windier than race day (${c.wind.round()} vs '
      '${target.wind.mean.round()} km/h): judge effort by feel or heart '
      'rate rather than pace.',
    );
  }
  if (notes.isEmpty) {
    notes.add(
      'Nothing within ${rangeKm.round()} km is a close match. Try '
      'a longer travel range or "Best day in a period".',
    );
  }
  return notes;
}
