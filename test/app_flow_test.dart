import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/weather.dart';
import 'package:twinclimate/screens/quick_session_page.dart';
import 'package:twinclimate/services/prefs_store.dart';
import 'package:twinclimate/services/weather_service.dart';

/// Canned weather so the flow can be tested without the network.
class FakeWeatherService implements WeatherService {
  @override
  Future<List<Place>> searchPlaces(String query) async => const [
    Place(
      name: 'Kalmar',
      region: 'Kalmar County',
      country: 'Sweden',
      latitude: 56.66,
      longitude: 16.36,
    ),
  ];

  @override
  Future<List<HourWeather>> fetchHourly({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final hours = <HourWeather>[];
    var day = DateTime(firstDay.year, firstDay.month, firstDay.day);
    final end = DateTime(
      lastDay.year,
      lastDay.month,
      lastDay.day,
    ).add(const Duration(days: 1));
    while (day.isBefore(end)) {
      for (var h = 0; h < 24; h++) {
        hours.add(
          HourWeather(
            time: DateTime(day.year, day.month, day.day, h),
            temperatureC: 16,
            apparentC: 14,
            humidityPercent: 70,
            precipProbabilityPercent: 55,
            precipitationMm: 1.2,
            windKmh: 18,
            gustKmh: 30,
            weatherCode: 61,
            isDay: h >= 6 && h < 20,
          ),
        );
      }
      day = day.add(const Duration(days: 1));
    }
    return hours;
  }

  @override
  Future<List<PastHour>> fetchHistory({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async => const [];

  @override
  Future<List<SpotHistory>> fetchHistoryMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async => throw UnimplementedError();

  @override
  Future<List<SpotForecast>> fetchHourlyMany({
    required List<(double, double)> points,
    required DateTime firstDay,
    required DateTime lastDay,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('plan a session and get forecast + kit checklist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();

    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionPage(store: store, weather: FakeWeatherService()),
      ),
    );

    // The form starts with no place chosen.
    expect(find.text('Quick Session'), findsOneWidget);
    expect(find.text('Pick a place'), findsOneWidget);

    // One tap on a preset quick pick...
    await tester.tap(find.text('Vondelpark'));
    await tester.pump();

    // ...and ask for the answer.
    await tester.tap(find.text('What should I wear?'));
    await tester.pumpAndSettle();

    // Result screen: summary, hourly cards and the five kit sections.
    expect(find.text('Feels like 14° at the start'), findsOneWidget);
    for (final section in ['HEAD', 'TORSO', 'HANDS', 'LEGS', 'FEET']) {
      expect(find.text(section), findsOneWidget, reason: 'missing $section');
    }

    // Rainy forecast -> a rain-triggered jacket with the rain chance as
    // its reason.
    expect(find.textContaining('55% rain chance'), findsWidgets);

    // The kit list is a packing checklist.
    expect(find.textContaining('0 /'), findsOneWidget);
    await tester.tap(find.text('Cap with a brim'));
    await tester.pump();
    expect(find.textContaining('1 /'), findsOneWidget);
  });
}
