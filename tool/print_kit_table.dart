// Prints the main kit item per body part across felt temperatures, for
// reviewing the kit ranges.  dart run tool/print_kit_table.dart
import 'dart:io';

import 'package:twinclimate/logic/gear_engine.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';

void main() {
  for (final sport in [Sport.run, Sport.bike]) {
    stdout.writeln('\n== ${sport.label} ==');
    for (final t in <double>[26, 22, 18, 14.5, 11.5, 8.5, 5.5, 2, -2.5, -8]) {
      final hours = [
        for (final h in [8, 9])
          HourWeather(
              time: DateTime(2026, 1, 1, h),
              temperatureC: t,
              apparentC: t,
              humidityPercent: 60,
              precipProbabilityPercent: 5,
              precipitationMm: 0,
              windKmh: 8,
              gustKmh: 14,
              weatherCode: 3,
              isDay: true),
      ];
      final kit = buildKit(sport, SessionForecast(hours));
      final main = mainSuggestions(kit);
      stdout.writeln('${t.toString().padLeft(5)}°: ${[
        for (final p in BodyPart.values)
          '${p.label}: ${main[p] ?? '-'}'
      ].join(' | ')}');
    }
  }
}
