import 'place.dart';

/// The three supported sports, each with a distance range for the slider
/// and a typical amateur pace used to estimate session duration.
enum Sport {
  run(
    label: 'Run',
    minKm: 1,
    maxKm: 42,
    defaultKm: 10,
    stepKm: 1,
    hoursPerKm: 0.1, // 6:00 min/km
  ),
  bike(
    label: 'Bike',
    minKm: 5,
    maxKm: 200,
    defaultKm: 40,
    stepKm: 5,
    hoursPerKm: 0.04, // 25 km/h
  ),
  swim(
    label: 'Swim',
    minKm: 0.5,
    maxKm: 5,
    defaultKm: 1.5,
    stepKm: 0.25,
    hoursPerKm: 1 / 2.4, // 2:30 min/100 m
  );

  const Sport({
    required this.label,
    required this.minKm,
    required this.maxKm,
    required this.defaultKm,
    required this.stepKm,
    required this.hoursPerKm,
  });

  final String label;
  final double minKm;
  final double maxKm;
  final double defaultKm;
  final double stepKm;
  final double hoursPerKm;

  int get sliderDivisions => ((maxKm - minKm) / stepKm).round();
}

/// A planned training session: what, where, when, how far.
class SessionPlan {
  const SessionPlan({
    required this.sport,
    required this.place,
    required this.start,
    required this.distanceKm,
    this.paceHoursPerKm,
    this.pool = false,
  });

  final Sport sport;
  final Place place;

  /// The user's own pace; null means the sport's typical amateur pace.
  final double? paceHoursPerKm;

  /// Swim in a pool rather than open water (no wetsuit/neoprene advice).
  final bool pool;

  /// Local time at the place (Open-Meteo is queried with timezone=auto,
  /// so forecast hours are local to the place too).
  final DateTime start;

  final double distanceKm;

  double get durationHours => distanceKm * (paceHoursPerKm ?? sport.hoursPerKm);

  /// The same session at another start time.
  SessionPlan movedTo(DateTime newStart) => SessionPlan(
    sport: sport,
    place: place,
    start: newStart,
    distanceKm: distanceKm,
    paceHoursPerKm: paceHoursPerKm,
    pool: pool,
  );

  DateTime get end =>
      start.add(Duration(minutes: (durationHours * 60).round()));

  /// Forecast hours bracketing the session: from the hour at or before the
  /// start to the hour at or after the end, e.g. 08:00 + 1.5 h ->
  /// [08:00, 09:00, 10:00]. Always at least two.
  List<DateTime> get windowHours {
    final hours = <DateTime>[];
    var hour = DateTime(start.year, start.month, start.day, start.hour);
    while (hours.isEmpty || hours.last.isBefore(end) || hours.length < 2) {
      hours.add(hour);
      hour = hour.add(const Duration(hours: 1));
    }
    return hours;
  }

  String get windowLabel => '${formatTime(start)}–${formatTime(end)}';

  String get distanceLabel => formatDistance(distanceKm);

  String get durationLabel => formatDuration(durationHours);
}

String formatTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  final text = km
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return '$text km';
}

String formatDuration(double hours) {
  final totalMinutes = (hours * 60).round();
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

const List<String> _weekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Pace as the sport usually states it: "5:30 /km" (run), "28 km/h"
/// (bike), "2:10 /100 m" (swim).
String formatPace(Sport sport, double hoursPerKm) {
  String minSec(double minutes) {
    final total = (minutes * 60).round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  return switch (sport) {
    Sport.run => '${minSec(hoursPerKm * 60)} /km',
    Sport.bike => '${(1 / hoursPerKm).round()} km/h',
    Sport.swim => '${minSec(hoursPerKm * 6)} /100 m',
  };
}

/// Pace choices per sport, slowest first, as hours per km.
List<double> paceChoices(Sport sport) => switch (sport) {
  // 9:00 down to 3:30 min/km in 15 s steps.
  Sport.run => [for (var s = 540; s >= 210; s -= 15) s / 3600],
  // 15 to 40 km/h.
  Sport.bike => [for (var k = 15; k <= 40; k++) 1 / k],
  // 3:30 down to 1:20 per 100 m in 5 s steps.
  Sport.swim => [for (var s = 210; s >= 80; s -= 5) s * 10 / 3600],
};

/// "Sat 13 Jun"
String formatDay(DateTime d) =>
    '${_weekdayNames[d.weekday - 1]} ${d.day} ${_monthNames[d.month - 1]}';

/// "13 Jun"
String formatDayMonth(DateTime d) => '${d.day} ${_monthNames[d.month - 1]}';

/// "Sat 13 Jun 2026"
String formatFullDate(DateTime d) => '${formatDay(d)} ${d.year}';
