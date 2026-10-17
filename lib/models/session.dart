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
  });

  final Sport sport;
  final Place place;

  /// Local time at the place (Open-Meteo is queried with timezone=auto,
  /// so forecast hours are local to the place too).
  final DateTime start;

  final double distanceKm;

  double get durationHours => distanceKm * sport.hoursPerKm;

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
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];
const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Sat 13 Jun"
String formatDay(DateTime d) =>
    '${_weekdayNames[d.weekday - 1]} ${d.day} ${_monthNames[d.month - 1]}';

/// "13 Jun"
String formatDayMonth(DateTime d) => '${d.day} ${_monthNames[d.month - 1]}';

/// "Sat 13 Jun 2026"
String formatFullDate(DateTime d) => '${formatDay(d)} ${d.year}';
