/// Clock time at a training place, which may be in another time zone than
/// the phone (e.g. planning a session in Kalmar from Istanbul).
///
/// Forecast hours are local to the place (Open-Meteo `timezone=auto`), so
/// "now", "today" and "has this start passed?" must be judged on the
/// place's clock too. Times are plain [DateTime]s holding the place's
/// wall-clock fields, like the forecast hours.
library;

/// Wall-clock time at a place [utcOffsetSeconds] ahead of UTC at the
/// instant [moment]. With no known offset, [moment] is returned unchanged
/// (the phone's own clock — right for places in the phone's time zone).
DateTime clockAt(DateTime moment, int? utcOffsetSeconds) {
  if (utcOffsetSeconds == null) return moment;
  final t = moment.toUtc().add(Duration(seconds: utcOffsetSeconds));
  return DateTime(
    t.year,
    t.month,
    t.day,
    t.hour,
    t.minute,
    t.second,
    t.millisecond,
  );
}

/// "Times are local time in Kalmar (1 h ahead of you)." — or null when the
/// place keeps the phone's time (or its offset isn't known).
String? timeDifferenceNote(
  String placeName,
  int? utcOffsetSeconds,
  DateTime now,
) {
  if (utcOffsetSeconds == null) return null;
  final minutes = utcOffsetSeconds ~/ 60 - now.timeZoneOffset.inMinutes;
  if (minutes == 0) return null;
  final h = minutes.abs() ~/ 60;
  final m = minutes.abs() % 60;
  final amount = m == 0
      ? '$h h'
      : h == 0
      ? '$m min'
      : '$h h $m min';
  return 'Times are local time in $placeName '
      '($amount ${minutes > 0 ? 'ahead of' : 'behind'} you).';
}
