import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place.dart';
import '../models/weather.dart';

/// Everything the app needs from a weather provider. Keep all provider
/// calls behind this interface so the provider stays swappable (PRD rule).
abstract class WeatherService {
  Future<List<Place>> searchPlaces(String query);

  /// Hourly forecast for [place], from [firstDay] through [lastDay]
  /// (inclusive), in the place's local time.
  Future<List<HourWeather>> fetchHourly({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  });

  /// Recorded hourly weather for [place], from [firstDay] through
  /// [lastDay] (inclusive), in the place's local time. Hours with missing
  /// data are left out.
  Future<List<PastHour>> fetchHistory({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  });

  /// Recorded hourly weather for several coordinates at once, one per point
  /// in the same order (local time, see [PastHour]).
  Future<List<SpotHistory>> fetchHistoryMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  });

  /// Hourly forecasts for several coordinates at once, one per point in
  /// the same order, each in that point's local time and with its ground
  /// height (0 over the sea).
  Future<List<SpotForecast>> fetchHourlyMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  });
}

class WeatherServiceException implements Exception {
  WeatherServiceException(this.message, {this.retryable = true});
  final String message;

  /// False when trying again soon cannot help (e.g. the daily limit).
  final bool retryable;

  @override
  String toString() => message;
}

/// Open-Meteo implementation. Free and keyless; supports browsers (CORS).
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _hourlyVariables = [
    'temperature_2m',
    'apparent_temperature',
    'relative_humidity_2m',
    'precipitation_probability',
    'precipitation',
    'wind_speed_10m',
    'wind_gusts_10m',
    'weather_code',
    'is_day',
    'shortwave_radiation',
  ];

  @override
  Future<List<Place>> searchPlaces(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '8',
      'language': 'en',
      'format': 'json',
    });
    final json = await _getJson(uri, 'place search');
    final results = json['results'] as List? ?? const [];
    return [
      for (final raw in results)
        Place(
          name: (raw as Map<String, dynamic>)['name'] as String? ?? '?',
          region: raw['admin1'] as String? ?? '',
          country: raw['country'] as String? ?? '',
          latitude: (raw['latitude'] as num).toDouble(),
          longitude: (raw['longitude'] as num).toDouble(),
        ),
    ];
  }

  @override
  Future<List<HourWeather>> fetchHourly({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': place.latitude.toStringAsFixed(4),
      'longitude': place.longitude.toStringAsFixed(4),
      'hourly': _hourlyVariables.join(','),
      'timezone': 'auto',
      'start_date': _dateParam(firstDay),
      'end_date': _dateParam(lastDay),
    });
    final json = await _getJson(uri, 'forecast');
    final hours = _parseForecast(json);
    if (hours.isEmpty) {
      throw WeatherServiceException(
        'The forecast came back empty for this date.',
      );
    }
    return hours;
  }

  @override
  Future<List<SpotForecast>> fetchHourlyMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': points.map((p) => p.$1.toStringAsFixed(4)).join(','),
      'longitude': points.map((p) => p.$2.toStringAsFixed(4)).join(','),
      'hourly': _hourlyVariables.join(','),
      'timezone': 'auto',
      'start_date': _dateParam(firstDay),
      'end_date': _dateParam(lastDay),
    });
    final decoded = await _get(uri, 'forecast');
    // One point comes back as an object, several as a list.
    final items = decoded is List ? decoded : [decoded];
    if (items.length != points.length) {
      throw WeatherServiceException(
        'The forecast came back incomplete. Try again in a moment.',
      );
    }
    return [
      for (final item in items.cast<Map<String, dynamic>>())
        SpotForecast(
          elevationM: (item['elevation'] as num?)?.toDouble() ?? 1,
          hours: _parseForecast(item),
        ),
    ];
  }

  static List<HourWeather> _parseForecast(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>?;
    final times = hourly?['time'] as List?;
    if (hourly == null || times == null) return const [];
    return [
      for (var i = 0; i < times.length; i++)
        HourWeather(
          time: DateTime.parse(times[i] as String),
          temperatureC: _number(hourly['temperature_2m'], i),
          apparentC: _number(hourly['apparent_temperature'], i),
          humidityPercent: _number(hourly['relative_humidity_2m'], i),
          precipProbabilityPercent: _number(
            hourly['precipitation_probability'],
            i,
          ),
          precipitationMm: _number(hourly['precipitation'], i),
          windKmh: _number(hourly['wind_speed_10m'], i),
          gustKmh: _number(hourly['wind_gusts_10m'], i),
          weatherCode: _number(hourly['weather_code'], i).round(),
          isDay: _number(hourly['is_day'], i) > 0,
          radiationWm2: _number(hourly['shortwave_radiation'], i),
        ),
    ];
  }

  static const _historyVariables = [
    'temperature_2m',
    'apparent_temperature',
    'relative_humidity_2m',
    'precipitation',
    'wind_speed_10m',
    'wind_gusts_10m',
  ];

  /// Extras for "typical weather": sunshine and cloud (optional per hour).
  static const _historyExtras = ['shortwave_radiation', 'cloud_cover'];

  @override
  Future<List<PastHour>> fetchHistory({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final uri = Uri.https('archive-api.open-meteo.com', '/v1/archive', {
      'latitude': place.latitude.toStringAsFixed(4),
      'longitude': place.longitude.toStringAsFixed(4),
      'hourly': [..._historyVariables, ..._historyExtras].join(','),
      'timezone': 'auto',
      'start_date': _dateParam(firstDay),
      'end_date': _dateParam(lastDay),
    });
    return _parseHistory(await _getJson(uri, 'weather history'));
  }

  @override
  Future<List<SpotHistory>> fetchHistoryMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final uri = Uri.https('archive-api.open-meteo.com', '/v1/archive', {
      'latitude': points.map((p) => p.$1.toStringAsFixed(4)).join(','),
      'longitude': points.map((p) => p.$2.toStringAsFixed(4)).join(','),
      'hourly': [..._historyVariables, 'shortwave_radiation'].join(','),
      'timezone': 'auto',
      'start_date': _dateParam(firstDay),
      'end_date': _dateParam(lastDay),
    });
    final decoded = await _get(uri, 'weather history');
    final items = decoded is List ? decoded : [decoded];
    if (items.length != points.length) {
      throw WeatherServiceException(
        'The weather history came back incomplete. Try again in a moment.',
      );
    }
    return [
      for (final item in items.cast<Map<String, dynamic>>())
        SpotHistory(
          elevationM: (item['elevation'] as num?)?.toDouble() ?? 1,
          hours: _parseHistory(item),
        ),
    ];
  }

  static List<PastHour> _parseHistory(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>?;
    final times = hourly?['time'] as List?;
    if (hourly == null || times == null) return const [];
    final hours = <PastHour>[];
    for (var i = 0; i < times.length; i++) {
      final values = [
        for (final name in _historyVariables) _maybeNumber(hourly[name], i),
      ];
      if (values.contains(null)) continue;
      hours.add(
        PastHour(
          time: DateTime.parse('${times[i]}Z'),
          temperatureC: values[0]!,
          apparentC: values[1]!,
          humidityPercent: values[2]!,
          precipitationMm: values[3]!,
          windKmh: values[4]!,
          gustKmh: values[5]!,
          radiationWm2: _maybeNumber(hourly['shortwave_radiation'], i),
          cloudCoverPercent: _maybeNumber(hourly['cloud_cover'], i),
        ),
      );
    }
    return hours;
  }

  static double? _maybeNumber(Object? list, int index) {
    if (list is! List || index >= list.length) return null;
    final value = list[index];
    return value is num ? value.toDouble() : null;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, String what) async =>
      await _get(uri, what) as Map<String, dynamic>;

  Future<Object?> _get(Uri uri, String what) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw WeatherServiceException(
        'Could not reach the weather service for the $what. '
        'Check your internet connection and try again.',
      );
    }
    if (response.statusCode == 429) {
      final minutely = response.body.toLowerCase().contains('minutely');
      throw WeatherServiceException(
        minutely
            ? 'The free weather service is busy with requests from this '
                  'connection — wait a minute and try again.'
            : 'The free weather service has had too many requests from this '
                  'internet connection today. Try again later.',
        retryable: false,
      );
    }
    if (response.statusCode != 200) {
      throw WeatherServiceException(
        'The weather service answered with an error (code '
        '${response.statusCode}) for the $what. Try again in a moment.',
      );
    }
    return jsonDecode(response.body);
  }

  /// Far-horizon hours occasionally come back null; treat those as 0
  /// rather than crashing.
  static double _number(Object? list, int index) {
    if (list is! List || index >= list.length) return 0;
    final value = list[index];
    return value is num ? value.toDouble() : 0;
  }

  static String _dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
