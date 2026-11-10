import '../models/session.dart';
import 'gear_engine.dart' show twilight;
import '../models/weather.dart';

/// A clearly better start time on the same day, with the reason.
class BetterTime {
  const BetterTime(this.start, this.why);

  final DateTime start;

  /// "Drier: rain chance 10% instead of 60%".
  final String why;
}

/// Felt temperature most people find comfortable for each sport.
double _idealFeelsC(Sport sport) => switch (sport) {
  Sport.run => 12,
  Sport.bike => 18,
  Sport.swim => 24,
};

class _Look {
  _Look(this.forecast, this.dark);
  final SessionForecast forecast;
  final bool dark;
}

/// Looks up to [spanHours] earlier and later the same day for a start
/// time that is clearly nicer (drier, in daylight, closer to comfortable,
/// calmer). Returns null when the chosen time is about as good as it gets.
/// [day] is the forecast for the whole day (or days) around the session.
BetterTime? betterTime({
  required SessionPlan plan,
  required List<HourWeather> day,
  required DateTime now,
  int spanHours = 4,
}) {
  if (plan.pool) return null;
  final byHour = {
    for (final h in day)
      DateTime(h.time.year, h.time.month, h.time.day, h.time.hour): h,
  };

  _Look? look(SessionPlan p) {
    final hours = [for (final t in p.windowHours) byHour[t]];
    if (hours.any((h) => h == null)) return null;
    final covered = [for (final h in hours) h!];
    final f = SessionForecast(covered);
    final rise = f.sunrise;
    final set = f.sunset;
    final dark = rise != null && set != null
        ? p.start.isBefore(rise.subtract(twilight)) ||
              p.end.isAfter(set.add(twilight))
        : covered.any((h) => !h.isDay);
    return _Look(f, dark);
  }

  double score(_Look l) {
    final f = l.forecast;
    final windOver = (f.maxWindKmh - 15).clamp(0, 100);
    return f.maxPrecipProbabilityPercent * 0.5 +
        f.totalPrecipitationMm * 15 +
        windOver * 1.2 +
        (f.kitFeelsC - _idealFeelsC(plan.sport)).abs() * 2 +
        (l.dark ? 25 : 0);
  }

  final current = look(plan);
  if (current == null) return null;
  final currentScore = score(current);
  SessionPlan? bestPlan;
  _Look? best;
  var bestScore = currentScore;
  for (var offset = -spanHours; offset <= spanHours; offset++) {
    if (offset == 0) continue;
    final start = plan.start.add(Duration(hours: offset));
    if (start.day != plan.start.day || start.isBefore(now)) continue;
    final moved = plan.movedTo(start);
    final candidate = look(moved);
    if (candidate == null) continue;
    final s = score(candidate);
    // Prefer the smallest change among equally good times.
    if (s < bestScore - 0.5) {
      bestScore = s;
      best = candidate;
      bestPlan = moved;
    }
  }
  if (best == null || bestPlan == null || currentScore - bestScore < 12) {
    return null;
  }
  final now0 = current.forecast;
  final then = best.forecast;
  final rainNow = now0.maxPrecipProbabilityPercent.round();
  final rainThen = then.maxPrecipProbabilityPercent.round();
  final String why;
  if (rainNow - rainThen >= 20) {
    why = 'Drier: rain chance $rainThen% instead of $rainNow%';
  } else if (current.dark && !best.dark) {
    why = 'In daylight';
  } else if (now0.maxWindKmh - then.maxWindKmh >= 8) {
    why =
        'Less wind: ${then.maxWindKmh.round()} km/h instead of '
        '${now0.maxWindKmh.round()}';
  } else {
    final diff = (then.meanApparentC - now0.meanApparentC).round();
    why = diff > 0
        ? '$diff° warmer'
        : diff < 0
        ? '${-diff}° cooler'
        : 'More comfortable conditions';
  }
  return BetterTime(bestPlan.start, why);
}
