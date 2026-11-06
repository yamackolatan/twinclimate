import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/logic/gear_engine.dart';
import 'package:twinclimate/logic/share_text.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';
import 'package:twinclimate/screens/session_result_page.dart';
import 'package:twinclimate/services/place_namer.dart';
import 'package:twinclimate/services/prefs_store.dart';
import 'package:twinclimate/widgets/place_search_sheet.dart';

import 'app_flow_test.dart' show FakeWeatherService;

class _Namer implements PlaceNamer {
  @override
  Future<String?> nameFor(double latitude, double longitude) async => 'De Pijp';
}

HourWeather _hour(DateTime t) => HourWeather(
  time: t,
  temperatureC: 9,
  apparentC: 7,
  humidityPercent: 80,
  precipProbabilityPercent: 70,
  precipitationMm: 1,
  windKmh: 20,
  gustKmh: 30,
  weatherCode: 61,
  isDay: true,
);

void main() {
  test('share text lists the session, weather and every kit item', () {
    final plan = SessionPlan(
      sport: Sport.run,
      place: presetPlaces.first,
      start: DateTime(2026, 11, 7, 8),
      distanceKm: 10,
    );
    final forecast = SessionForecast([
      _hour(DateTime(2026, 11, 7, 8)),
      _hour(DateTime(2026, 11, 7, 9)),
    ]);
    final kit = buildKitForPlan(plan, forecast);
    final text = sessionShareText(plan, forecast, kit);
    expect(text, contains('Run 10 km at Vondelpark'));
    expect(text, contains('Sat 7 Nov, 08:00–09:00'));
    expect(text, contains('Feels like 7°'));
    expect(text, contains('Rain chance up to 70%'));
    for (final item in kit) {
      expect(text, contains(item.name));
    }
  });

  testWidgets('"Use my location" returns a named place at your position', (
    tester,
  ) async {
    Place? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  picked = await showModalBottomSheet<Place>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => PlaceSearchSheet(
                      weather: FakeWeatherService(),
                      savedPlaces: const [],
                      namer: _Namer(),
                      locate: () async => (52.354, 4.893),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(picked?.name, 'De Pijp');
    expect(picked?.latitude, 52.354);
  });

  testWidgets('"1 h later" re-runs the session an hour later', (tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8);
    SessionPlan? moved;
    await tester.pumpWidget(
      MaterialApp(
        home: SessionResultPage(
          plan: SessionPlan(
            sport: Sport.run,
            place: presetPlaces.first,
            start: start,
            distanceKm: 10,
          ),
          weather: FakeWeatherService(),
          store: store,
          onPlanChanged: (p) => moved = p,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('08:00–09:00'), findsOneWidget);
    await tester.tap(find.text('1 h later'));
    await tester.pumpAndSettle();
    expect(moved?.start, start.add(const Duration(hours: 1)));
    expect(find.textContaining('09:00–10:00'), findsOneWidget);
  });
}
