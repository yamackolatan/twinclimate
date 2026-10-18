import 'dart:math' as math;

import '../models/fingerprint.dart';
import '../models/race.dart';
import '../models/weather.dart';

/// How many past years a fingerprint looks at (PRD decision 8).
const int fingerprintYearCount = 10;

/// Days either side of the race date (PRD decision 8).
const int fingerprintDaySpread = 5;

/// The weather archive lags real time by several days; only use years whose
/// whole window ended at least this long ago.
const Duration _archiveLag = Duration(days: 7);

class FingerprintException implements Exception {
  FingerprintException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Extra calendar days a race spills past midnight (0 for most races).
int _overnightDays(Race race) =>
    (race.startMinutesOfDay + race.totalMinutes) ~/ (24 * 60);

/// The [fingerprintYearCount] most recent years whose race window
/// (race date ± [fingerprintDaySpread] days) is already in the archive,
/// oldest first.
List<int> fingerprintYears(Race race, DateTime today) => historyYears(
  month: race.date.month,
  day: race.date.day,
  extraDays: _overnightDays(race),
  today: today,
);

/// The [fingerprintYearCount] most recent years whose window — the given
/// calendar day ± [fingerprintDaySpread] days, plus [extraDays] — is
/// already in the archive, oldest first.
List<int> historyYears({
  required int month,
  required int day,
  required DateTime today,
  int extraDays = 0,
}) {
  final cutoff = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).subtract(_archiveLag);
  final years = <int>[];
  for (
    var year = today.year;
    years.length < fingerprintYearCount && year > today.year - 40;
    year--
  ) {
    final windowEnd = DateTime.utc(
      year,
      month,
      day + fingerprintDaySpread + extraDays,
    );
    if (windowEnd.isBefore(cutoff)) years.add(year);
  }
  return years.reversed.toList();
}

/// First and last calendar day of history needed for [year].
(DateTime, DateTime) historyRange(Race race, int year) => (
  DateTime.utc(year, race.date.month, race.date.day - fingerprintDaySpread),
  DateTime.utc(
    year,
    race.date.month,
    race.date.day + fingerprintDaySpread + _overnightDays(race),
  ),
);

/// Collects hourly readings for one time window (whole race or one leg)
/// across all past race days.
class _Accumulator {
  final temperature = <double>[];
  final apparent = <double>[];
  final humidity = <double>[];
  final wind = <double>[];
  final gust = <double>[];
  final dailyRainMm = <double>[];

  void addDay(List<PastHour> hours) {
    if (hours.isEmpty) return;
    var rain = 0.0;
    for (final h in hours) {
      temperature.add(h.temperatureC);
      apparent.add(h.apparentC);
      humidity.add(h.humidityPercent);
      wind.add(h.windKmh);
      gust.add(h.gustKmh);
      rain += h.precipitationMm;
    }
    dailyRainMm.add(rain);
  }

  ConditionStats toStats() {
    final wet = [
      for (final mm in dailyRainMm)
        if (mm >= ConditionStats.wetDayThresholdMm) mm,
    ];
    return ConditionStats(
      temperature: _stat(temperature),
      apparent: _stat(apparent),
      humidity: _stat(humidity),
      wind: _stat(wind),
      gust: _stat(gust),
      rainChance: wet.length / dailyRainMm.length,
      wetDayRainMm: wet.isEmpty ? 0 : _mean(wet),
      dayCount: dailyRainMm.length,
      hourCount: temperature.length,
    );
  }
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

Stat _stat(List<double> values) {
  final mean = _mean(values);
  final variance =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
      values.length;
  return Stat(mean, math.sqrt(variance));
}

/// Hour slots overlapping [from, to): e.g. 08:15–14:15 gives
/// 08:00, 09:00, ..., 14:00.
List<DateTime> _slots(DateTime from, DateTime to) {
  final slots = <DateTime>[];
  var slot = DateTime.utc(from.year, from.month, from.day, from.hour);
  while (slot.isBefore(to)) {
    slots.add(slot);
    slot = slot.add(const Duration(hours: 1));
  }
  return slots;
}

/// Builds the race-day climate from recorded [hours] (local wall-clock
/// times stored as UTC, see [PastHour]) for the given [years].
RaceFingerprint buildFingerprint({
  required Race race,
  required List<PastHour> hours,
  required List<int> years,
  required DateTime computedAt,
}) {
  final byTime = {for (final h in hours) h.time: h};
  final overall = _Accumulator();
  final legs = [for (final _ in race.legs) _Accumulator()];
  final profileSum = <int, double>{};
  final profileCount = <int, int>{};
  final profileHour = <int, int>{};

  for (final year in years) {
    for (var d = -fingerprintDaySpread; d <= fingerprintDaySpread; d++) {
      final start = DateTime.utc(
        year,
        race.date.month,
        race.date.day + d,
        race.startHour,
        race.startMinute,
      );
      final end = start.add(Duration(minutes: race.totalMinutes));

      final raceSlots = _slots(start, end);
      overall.addDay([
        for (final slot in raceSlots)
          if (byTime[slot] != null) byTime[slot]!,
      ]);
      for (var i = 0; i < raceSlots.length; i++) {
        final reading = byTime[raceSlots[i]];
        if (reading == null) continue;
        profileSum[i] = (profileSum[i] ?? 0) + reading.temperatureC;
        profileCount[i] = (profileCount[i] ?? 0) + 1;
        profileHour[i] = raceSlots[i].hour;
      }

      final windows = race.legWindows;
      for (var l = 0; l < windows.length; l++) {
        final legSlots = _slots(
          start.add(Duration(minutes: windows[l].startOffset)),
          start.add(Duration(minutes: windows[l].endOffset)),
        );
        legs[l].addDay([
          for (final slot in legSlots)
            if (byTime[slot] != null) byTime[slot]!,
        ]);
      }
    }
  }

  if (overall.temperature.isEmpty) {
    throw FingerprintException(
      'No past weather records were found for this place and date.',
    );
  }

  final windows = race.legWindows;
  return RaceFingerprint(
    key: race.fingerprintKey,
    computedAt: computedAt,
    firstYear: years.first,
    lastYear: years.last,
    yearCount: years.length,
    overall: overall.toStats(),
    legs: [
      for (var l = 0; l < windows.length; l++)
        if (legs[l].temperature.isNotEmpty)
          LegFingerprint(
            sport: windows[l].leg.sport,
            startOffset: windows[l].startOffset,
            endOffset: windows[l].endOffset,
            stats: legs[l].toStats(),
          ),
    ],
    profile: [
      for (final i in profileSum.keys.toList()..sort())
        ProfileHour(profileHour[i]!, profileSum[i]! / profileCount[i]!),
    ],
  );
}
