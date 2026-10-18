// Computes race fingerprints from real Open-Meteo history using the app's
// own code, and prints them for a manual sanity check.
//
//   dart run tool/check_real_weather.dart
//
// Each race makes 10 small requests to the free archive API.

import 'dart:convert';
import 'dart:io';

import 'package:twinclimate/logic/fingerprint_text.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/services/fingerprint_service.dart';
import 'package:twinclimate/services/weather_service.dart';

Race _race(String name, Place place, DateTime date, int hour, int minute,
        List<RaceLeg> legs) =>
    Race(
      id: name,
      name: name,
      place: place,
      date: date,
      startHour: hour,
      startMinute: minute,
      legs: legs,
    );

final races = [
  _race(
    'Ironman Kalmar',
    const Place(
        name: 'Kalmar', region: 'Kalmar', country: 'Sweden',
        latitude: 56.6634, longitude: 16.3568),
    DateTime(2027, 8, 29), 7, 0, triathlonPresets.last.legs,
  ),
  _race(
    'Ironman World Championship Kona',
    const Place(
        name: 'Kailua-Kona', region: 'Hawaii', country: 'United States',
        latitude: 19.6400, longitude: -155.9969),
    DateTime(2027, 10, 9), 6, 25, triathlonPresets.last.legs,
  ),
  _race(
    'Istanbul Marathon',
    const Place(
        name: 'Istanbul', region: 'Istanbul', country: 'Türkiye',
        latitude: 41.0082, longitude: 28.9784),
    DateTime(2026, 11, 8), 9, 0, runPresets.last.legs,
  ),
  _race(
    'Ironman Barcelona',
    const Place(
        name: 'Calella', region: 'Catalonia', country: 'Spain',
        latitude: 41.6140, longitude: 2.6545),
    DateTime(2027, 10, 3), 8, 0, triathlonPresets.last.legs,
  ),
  _race(
    'Ironman Wales',
    const Place(
        name: 'Tenby', region: 'Wales', country: 'United Kingdom',
        latitude: 51.6724, longitude: -4.7036),
    DateTime(2027, 9, 12), 7, 0, triathlonPresets.last.legs,
  ),
];

/// Dart ignores HTTPS_PROXY by default; cloud sandboxes need it (and
/// their CA bundle) to reach the internet.
class _EnvProxyOverrides extends HttpOverrides {
  _EnvProxyOverrides(this.caBundle);

  final String? caBundle;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final security = SecurityContext(withTrustedRoots: true);
    if (caBundle != null) security.setTrustedCertificates(caBundle!);
    return super.createHttpClient(security)
      ..findProxy = HttpClient.findProxyFromEnvironment;
  }
}

Future<void> main(List<String> args) async {
  if (Platform.environment['HTTPS_PROXY'] != null) {
    const sandboxBundle = '/root/.ccr/ca-bundle.crt';
    HttpOverrides.global = _EnvProxyOverrides(
        File(sandboxBundle).existsSync() ? sandboxBundle : null);
  }
  final service = FingerprintService(OpenMeteoWeatherService());
  final only = args.isEmpty ? null : args.first.toLowerCase();
  final results = <Map<String, Object?>>[];
  for (final race in races) {
    if (only != null && !race.name.toLowerCase().contains(only)) continue;
    stdout.writeln('\n=== ${race.name} (${race.place.name}, '
        '${formatDayMonth(race.date)}, ${race.windowLabel}) ===');
    try {
      final watch = Stopwatch()..start();
      final fp = await service.compute(race);
      stdout.writeln('Computed in ${watch.elapsedMilliseconds} ms, '
          'years ${fp.firstYear}-${fp.lastYear}, '
          '${fp.overall.hourCount} hourly readings');
      stdout.writeln(fingerprintHeadline(race, fp));
      stdout.writeln(profileLine(race, fp));
      for (final (label, value) in conditionRows(fp.overall)) {
        stdout.writeln('  $label: $value');
      }
      if (race.isMultisport) {
        for (final leg in fp.legs) {
          stdout.writeln('  ${leg.sport.label} '
              '${race.clockAt(leg.startOffset)}–${race.clockAt(leg.endOffset)}: '
              '${legLine(leg)}');
        }
      }
      results.add({'race': race.name, 'fingerprint': fp.toJson()});
    } catch (e) {
      stdout.writeln('FAILED: $e');
      exitCode = 1;
    }
  }
  if (Platform.environment['FINGERPRINT_JSON'] case final path?) {
    File(path).writeAsStringSync(jsonEncode(results));
  }
}
