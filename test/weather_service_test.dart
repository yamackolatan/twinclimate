import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/services/weather_service.dart';

void main() {
  test('hours without a temperature are skipped, not read as 0 °C', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'hourly': {
            'time': [
              '2026-11-07T08:00',
              '2026-11-07T09:00',
              '2026-11-07T10:00',
            ],
            'temperature_2m': [6.0, null, 8.0],
            'apparent_temperature': [4.0, 5.0, null],
            'relative_humidity_2m': [80, null, 82],
            'precipitation_probability': [20, 30, null],
            'wind_speed_10m': [20, 21, 22],
          },
        }),
        200,
      ),
    );
    final hours = await OpenMeteoWeatherService(client: client).fetchHourly(
      place: presetPlaces.first,
      firstDay: DateTime(2026, 11, 7),
      lastDay: DateTime(2026, 11, 7),
    );
    expect(hours, hasLength(1));
    expect(hours.single.time, DateTime(2026, 11, 7, 8));
    expect(hours.single.apparentC, 4);
  });

  test('the per-minute limit is recognised as "wait a minute"', () async {
    final client = MockClient(
      (request) async => http.Response(
        '{"error":true,"reason":"Minutely API request limit exceeded"}',
        429,
      ),
    );
    await expectLater(
      OpenMeteoWeatherService(client: client).fetchHourly(
        place: presetPlaces.first,
        firstDay: DateTime(2026, 11, 7),
        lastDay: DateTime(2026, 11, 7),
      ),
      throwsA(
        isA<WeatherServiceException>()
            .having((e) => e.perMinuteLimit, 'perMinuteLimit', isTrue)
            .having((e) => e.retryable, 'retryable', isFalse),
      ),
    );
  });
}
