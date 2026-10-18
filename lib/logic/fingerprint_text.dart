import '../models/fingerprint.dart';
import '../models/race.dart';
import '../models/session.dart';

/// "17–20°C" (or "about 18°C" when the range collapses).
String temperatureRange(Stat stat) => _range(stat, '°C');

String _range(Stat stat, String unit, {double floor = -999, double ceil = 999}) {
  final low = stat.low.clamp(floor, ceil).round();
  final high = stat.high.clamp(floor, ceil).round();
  if (low == high) return 'about $low$unit';
  return '$low–$high$unit';
}

String humidityWord(double meanPercent) {
  if (meanPercent >= 75) return 'humid';
  if (meanPercent >= 60) return 'moderately humid';
  return 'fairly dry';
}

String windRange(Stat stat) => _range(stat, ' km/h', floor: 0);

/// "30%"
String rainChanceText(ConditionStats stats) =>
    '${(stats.rainChance * 100).round()}%';

/// "Kalmar on 29 Aug, 07:00–18:45: typically 17–20°C, humid, 10–20 km/h
/// wind, 30% rain chance"
String fingerprintHeadline(Race race, RaceFingerprint fingerprint) {
  final o = fingerprint.overall;
  return '${race.place.name} on ${formatDayMonth(race.date)}, '
      '${race.windowLabel}: typically ${temperatureRange(o.temperature)}, '
      '${humidityWord(o.humidity.mean)}, ${windRange(o.wind)} wind, '
      '${rainChanceText(o)} rain chance';
}

/// Short version for the home-screen card.
String fingerprintShortLine(RaceFingerprint fingerprint) {
  final o = fingerprint.overall;
  return 'Typically ${temperatureRange(o.temperature)}, '
      '${humidityWord(o.humidity.mean)}, ${windRange(o.wind)} wind, '
      '${rainChanceText(o)} rain chance';
}

/// How temperature changes over the race (owner decision 3), e.g.
/// "About 15°C at the 07:00 start, warmest around 14:00 (about 20°C),
/// about 18°C at the 18:45 finish."
String profileLine(Race race, RaceFingerprint fingerprint) {
  final profile = fingerprint.profile;
  if (profile.isEmpty) return '';
  final first = profile.first;
  final last = profile.last;
  final warmest = profile.reduce((a, b) => b.temperature > a.temperature ? b : a);
  final coolest = profile.reduce((a, b) => b.temperature < a.temperature ? b : a);
  final startText = 'About ${first.temperature.round()}°C at the '
      '${race.clockAt(0)} start';
  if (warmest.temperature - coolest.temperature < 1.5) {
    return 'Steady around ${first.temperature.round()}°C through the race.';
  }
  final finishText = 'about ${last.temperature.round()}°C at the '
      '${race.clockAt(race.totalMinutes)} finish';
  if (warmest != first && warmest != last) {
    return '$startText, warmest around ${_hour(warmest.hour)} '
        '(about ${warmest.temperature.round()}°C), $finishText.';
  }
  if (coolest != first && coolest != last) {
    return '$startText, coolest around ${_hour(coolest.hour)} '
        '(about ${coolest.temperature.round()}°C), $finishText.';
  }
  return '$startText, $finishText.';
}

String _hour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

/// Label/value rows for the detail screen.
List<(String, String)> conditionRows(ConditionStats stats) {
  final wet = (stats.rainChance * stats.dayCount).round();
  return [
    ('Temperature', temperatureRange(stats.temperature)),
    ('Feels like', temperatureRange(stats.apparent)),
    (
      'Humidity',
      '${_range(stats.humidity, '%', floor: 0, ceil: 100)} · '
          '${humidityWord(stats.humidity.mean)}'
    ),
    (
      'Wind',
      '${windRange(stats.wind)}, gusts up to about '
          '${stats.gust.high.round()} km/h'
    ),
    (
      'Rain',
      wet == 0
          ? 'Dry on all ${stats.dayCount} past race days'
          : '${rainChanceText(stats)} chance — wet on $wet of '
              '${stats.dayCount} past race days, about '
              '${stats.wetDayRainMm.toStringAsFixed(stats.wetDayRainMm < 10 ? 1 : 0)} mm '
              'on those days'
    ),
  ];
}

/// One-line leg summary, e.g. "Bike 08:15–14:15: 16–21°C, 10–20 km/h wind,
/// 25% rain chance".
String legLine(LegFingerprint leg) =>
    '${temperatureRange(leg.stats.temperature)}, '
    '${humidityWord(leg.stats.humidity.mean)}, '
    '${windRange(leg.stats.wind)} wind, '
    '${rainChanceText(leg.stats)} rain chance';

/// "Based on hourly weather records for 24 Aug – 3 Sep, 2016–2025, ..."
String sourceNote(Race race, RaceFingerprint fingerprint) {
  final from = DateTime(2000, race.date.month, race.date.day - 5);
  final to = DateTime(2000, race.date.month, race.date.day + 5);
  return 'Based on hourly weather records (ERA5, via Open-Meteo) for '
      '${formatDayMonth(from)} – ${formatDayMonth(to)} in '
      '${fingerprint.firstYear}–${fingerprint.lastYear}, race hours only '
      '(${fingerprint.overall.hourCount} hourly readings). Ranges show where '
      'most race days fall. Rain chance is the share of those days with at '
      'least 1 mm of rain during the race hours. This is modelled weather on '
      'a grid of roughly 9 km, so at steep coasts or mountains it can differ '
      'from local weather stations by a degree or two.';
}
