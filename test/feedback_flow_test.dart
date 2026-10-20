import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/models/comfort.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';
import 'package:twinclimate/screens/quick_session_page.dart';
import 'package:twinclimate/screens/session_result_page.dart';
import 'package:twinclimate/services/prefs_store.dart';

import 'app_flow_test.dart' show FakeWeatherService;

/// Recorded weather for the finished session: feels like 17° all day.
class WarmWeather extends FakeWeatherService {
  @override
  Future<List<HourWeather>> fetchHourly({
    required Place place,
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final hours = await super.fetchHourly(
      place: place,
      firstDay: firstDay,
      lastDay: lastDay,
    );
    return [
      for (final h in hours)
        HourWeather(
          time: h.time,
          temperatureC: 18,
          apparentC: 17,
          humidityPercent: 60,
          precipProbabilityPercent: 5,
          precipitationMm: 0,
          windKmh: 8,
          gustKmh: 15,
          weatherCode: 1,
          isDay: h.isDay,
        ),
    ];
  }
}

SessionRecord finishedRun(
  String id, {
  Duration ago = const Duration(hours: 1),
  bool allPacked = false,
}) {
  final end = DateTime.now().subtract(ago);
  return SessionRecord(
    id: id,
    sport: Sport.run,
    placeName: 'Vondelpark',
    latitude: 41.1839,
    longitude: 28.9869,
    start: end.subtract(const Duration(minutes: 90)),
    end: end,
    forecastFeelsC: 16,
    suggested: const {BodyPart.torso: 'Light short-sleeve tech tee'},
    allPacked: allPacked,
  );
}

Future<PrefsStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return PrefsStore.load();
}

Future<void> pumpHome(WidgetTester tester, PrefsStore store) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: QuickSessionPage(store: store, weather: WarmWeather()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('two-tap feedback, the wear check, and what was learned', (
    tester,
  ) async {
    final store = await freshStore();
    await store.recordSession(finishedRun('first'));
    await pumpHome(tester, store);

    expect(find.text('How did your run at Vondelpark feel?'), findsOneWidget);
    await tester.tap(find.text('Too warm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Where did you feel too warm?'), findsOneWidget);
    await tester.tap(find.text('Torso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Checklist wasn't ticked, so the optional check appears.
    expect(
      find.text(
        'We suggested: Light short-sleeve tech tee. Did you wear '
        'that?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Noted. One more report like this and we\'ll suggest a '
        'lighter top when it\'s between 16 and 20°C.',
      ),
      findsOneWidget,
    );

    // Filed under the recorded weather, not the forecast.
    final entry = store.feedback.single;
    expect(entry.measured, isTrue);
    expect(entry.feelsC, 17);
    expect(entry.worn, Worn.asSuggested);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.textContaining('How did your run'), findsNothing);
  });

  testWidgets('packed everything → no wear question; second report learns', (
    tester,
  ) async {
    final store = await freshStore();
    await store.addFeedback(
      FeedbackEntry(
        id: 'earlier',
        sport: Sport.run,
        date: DateTime.now().subtract(const Duration(days: 5)),
        feelsC: 18,
        measured: true,
        feeling: Feeling.tooWarm,
        part: BodyPart.torso,
        worn: Worn.asSuggested,
      ),
    );
    await store.recordSession(finishedRun('second', allPacked: true));
    await pumpHome(tester, store);

    await tester.tap(find.text('Too warm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Torso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Did you wear that?'), findsNothing);
    expect(
      find.text(
        'Learned: you run warm between 16 and 20°C. Next time we\'ll suggest '
        'a lighter top.',
      ),
      findsOneWidget,
    );
    expect(store.feedback.last.worn, Worn.asSuggested);

    // It shows up in Settings → Comfort profile, and can be forgotten.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Comfort profile'));
    await tester.pumpAndSettle();
    expect(find.text('Torso · runs warm between 16 and 20°C'), findsOneWidget);
    expect(find.text('2 reports · kit is 1 step lighter'), findsOneWidget);
    await tester.tap(find.text('Forget'));
    await tester.pumpAndSettle();
    expect(find.text('Torso · runs warm between 16 and 20°C'), findsNothing);
  });

  testWidgets('"Just right" is a single tap', (tester) async {
    final store = await freshStore();
    await store.recordSession(finishedRun('a'));
    await pumpHome(tester, store);
    await tester.tap(find.text('Just right'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Great — we\'ll keep suggesting similar kit'),
      findsOneWidget,
    );
    expect(store.feedback.single.feeling, Feeling.justRight);
  });

  testWidgets('"I didn\'t go" just closes the card', (tester) async {
    final store2 = await freshStore();
    await store2.recordSession(finishedRun('b'));
    await pumpHome(tester, store2);
    await tester.tap(find.text('I didn\'t go'));
    await tester.pumpAndSettle();
    expect(store2.feedback, isEmpty);
    expect(store2.sessionRecords.single.status, SessionStatus.didntGo);
    expect(find.textContaining('How did your run'), findsNothing);
  });

  testWidgets('says so when the recorded weather differed from the forecast', (
    tester,
  ) async {
    final store = await freshStore();
    final run = finishedRun('cool');
    await store.recordSession(
      SessionRecord(
        id: run.id,
        sport: run.sport,
        placeName: run.placeName,
        latitude: run.latitude,
        longitude: run.longitude,
        start: run.start,
        end: run.end,
        forecastFeelsC: 12,
        suggested: run.suggested,
      ),
    );
    await pumpHome(tester, store);
    await tester.tap(find.text('Just right'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'It actually felt like 17° (the forecast said '
        '12°).\nGreat',
      ),
      findsOneWidget,
    );
  });

  testWidgets('several answers: warm torso and legs, cold hands', (
    tester,
  ) async {
    final store = await freshStore();
    await store.recordSession(finishedRun('multi'));
    await pumpHome(tester, store);

    // Both feelings can be on at once.
    await tester.tap(find.text('Too warm'));
    await tester.pump();
    await tester.tap(find.text('Too cold'));
    await tester.pump();
    expect(
      find.text('Both: some parts too cold, others too warm.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Where did you feel too warm?'), findsOneWidget);
    expect(find.text('Where did you feel too cold?'), findsOneWidget);

    FilterChip chip(String label, int row) => tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, label).at(row),
    );
    FilledButton done() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'));

    // Done waits until each row has an answer.
    expect(done().onPressed, isNull);
    await tester.tap(find.widgetWithText(FilterChip, 'Torso').at(0));
    await tester.tap(find.widgetWithText(FilterChip, 'Legs').at(0));
    await tester.pump();
    expect(done().onPressed, isNull);
    await tester.tap(find.widgetWithText(FilterChip, 'Hands').at(1));
    await tester.pump();
    expect(done().onPressed, isNotNull);

    // A part can't be both too warm and too cold.
    await tester.tap(find.widgetWithText(FilterChip, 'Torso').at(1));
    await tester.pump();
    expect(chip('Torso', 0).selected, isFalse);
    expect(chip('Torso', 1).selected, isTrue);
    await tester.tap(find.widgetWithText(FilterChip, 'Torso').at(0));
    await tester.pump();
    expect(chip('Torso', 0).selected, isTrue);
    expect(chip('Torso', 1).selected, isFalse);

    // "Everywhere" replaces specific parts in its row.
    await tester.tap(find.widgetWithText(FilterChip, 'Everywhere').at(1));
    await tester.pump();
    expect(chip('Hands', 1).selected, isFalse);
    await tester.tap(find.widgetWithText(FilterChip, 'Hands').at(1));
    await tester.pump();
    expect(chip('Everywhere', 1).selected, isFalse);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    // Several parts: one general question instead of one per item.
    expect(find.text('Did you wear the kit we suggested?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    final answers = {for (final e in store.feedback) (e.feeling, e.part)};
    expect(answers, {
      (Feeling.tooWarm, BodyPart.torso),
      (Feeling.tooWarm, BodyPart.legs),
      (Feeling.tooCold, BodyPart.hands),
    });
    expect(
      find.textContaining('Noted. One more report like this'),
      findsOneWidget,
    );
  });

  testWidgets('no card before the session has finished', (tester) async {
    final store = await freshStore();
    final start = DateTime.now().subtract(const Duration(minutes: 20));
    await store.recordSession(
      SessionRecord(
        id: 'now',
        sport: Sport.run,
        placeName: 'Vondelpark',
        latitude: 41.18,
        longitude: 28.99,
        start: start,
        end: start.add(const Duration(minutes: 90)),
        forecastFeelsC: 16,
        suggested: const {},
      ),
    );
    await pumpHome(tester, store);
    expect(find.textContaining('How did your run'), findsNothing);
  });

  testWidgets('opening a kit list remembers the session and packing ticks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await freshStore();
    final plan = SessionPlan(
      sport: Sport.run,
      place: presetPlaces.first,
      start: DateTime.now().add(const Duration(days: 1)),
      distanceKm: 10,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SessionResultPage(
          plan: plan,
          weather: FakeWeatherService(),
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final record = store.sessionRecords.single;
    expect(record.placeName, 'Vondelpark');
    expect(record.suggested[BodyPart.torso], isNotNull);

    final torsoItem = record.suggested[BodyPart.torso]!;
    await tester.tap(find.text(torsoItem));
    await tester.pumpAndSettle();
    expect(store.sessionRecords.single.packed, contains(torsoItem));
    expect(
      store.sessionRecords.single.packedSuggestionFor(BodyPart.torso),
      isTrue,
    );
  });
}
