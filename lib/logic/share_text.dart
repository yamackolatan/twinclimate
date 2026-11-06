import '../models/gear.dart';
import '../models/session.dart';
import '../models/weather.dart';
import 'gear_engine.dart';
import 'weather_text.dart';

/// Plain-text summary of a session and its kit, for sharing with a
/// training partner or pasting into a chat.
String sessionShareText(
  SessionPlan plan,
  SessionForecast forecast,
  List<GearItem> kit, {
  bool typical = false,
}) {
  final start = forecast.atStart;
  final lines = <String>[
    '${plan.sport.label} ${plan.distanceLabel} at ${plan.place.name}',
    '${formatDay(plan.start)}, ${plan.windowLabel}',
    '${typical ? 'Typically feels' : 'Feels'} like ${start.apparentC.round()}° '
        'at the start · ${weatherDescription(start.weatherCode)} · '
        '${windPhrase(forecast.maxWindKmh, forecast.maxGustKmh)}',
    if (forecast.rainLikely)
      'Rain chance up to ${forecast.maxPrecipProbabilityPercent.round()}%',
    '',
    'What to wear and bring:',
  ];
  for (final MapEntry(key: part, value: items) in groupKit(kit).entries) {
    for (final item in items) {
      lines.add(
        '• ${part.label}: ${item.name}${item.optional ? ' (optional)' : ''}',
      );
    }
  }
  lines
    ..add('')
    ..add('Planned with TwinClimate — yamackolatan.github.io/twinclimate');
  return lines.join('\n');
}
