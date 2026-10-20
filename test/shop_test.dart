import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/data/decathlon_catalogue.dart';
import 'package:twinclimate/logic/gear_engine.dart';
import 'package:twinclimate/logic/shop_logic.dart';
import 'package:twinclimate/models/fingerprint.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/place.dart';
import 'package:twinclimate/models/product.dart';
import 'package:twinclimate/models/race.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/screens/session_result_page.dart';
import 'package:twinclimate/services/prefs_store.dart';

import 'app_flow_test.dart' show FakeWeatherService;
import 'gear_engine_test.dart' show forecast;

Product _p(String id, String category, {double? rating, int? reviews}) =>
    Product(
      id: id,
      category: category,
      name: id,
      url: 'https://www.decathlon.nl/p/$id',
      fit: 'test',
      rating: rating,
      reviewCount: reviews,
    );

Race _race(List<RaceLeg> legs) => Race(
  id: 'r',
  name: 'Test race',
  place: presetPlaces.first,
  date: DateTime(2027, 8, 29),
  startHour: 7,
  startMinute: 0,
  legs: legs,
);

ConditionStats _stats({
  double temp = 18,
  double humidity = 78,
  double wind = 18,
  double rain = 0.3,
}) => ConditionStats(
  temperature: Stat(temp, 2),
  apparent: Stat(temp - 1, 2),
  humidity: Stat(humidity, 8),
  wind: Stat(wind, 5),
  gust: Stat(wind + 10, 8),
  rainChance: rain,
  wetDayRainMm: 3,
  dayCount: 110,
  hourCount: 1000,
);

void main() {
  group('catalogue', () {
    test('ids are unique and every link goes to decathlon.nl', () {
      final ids = {for (final p in decathlonCatalogue) p.id};
      expect(ids.length, decathlonCatalogue.length);
      for (final p in decathlonCatalogue) {
        expect(p.url, startsWith('https://www.decathlon.nl/'), reason: p.id);
        expect(p.url, isNot(contains('&amp;')), reason: p.id);
        expect(productCategories, contains(p.category), reason: p.id);
        expect(p.fit.trim(), isNotEmpty);
      }
    });

    test('every product type used by the kit has at least one product', () {
      final used = {for (final types in itemProductTypes.values) ...types};
      for (final type in used) {
        expect(productsFor(type), isNotEmpty, reason: type);
      }
    });

    test('every kit item is mapped to products or deliberately not', () {
      final missing = <String>{};
      for (final sport in Sport.values) {
        for (var t = -14.0; t <= 36; t += 1) {
          for (final rainy in [false, true]) {
            for (final windy in [false, true]) {
              for (final sunny in [false, true]) {
                for (final km in [5.0, 15.0, 42.0, 100.0]) {
                  final kit = buildKit(
                    sport,
                    forecast(
                      apparentC: t,
                      precipProbability: rainy ? 80 : 5,
                      precipitationMm: rainy ? 3 : 0,
                      weatherCode: rainy ? 63 : 1,
                      windKmh: windy ? 35 : 8,
                      gustKmh: windy ? 55 : 12,
                      radiation: sunny ? 700 : 0,
                    ),
                    distanceKm: km,
                  );
                  for (final item in kit) {
                    if (!itemProductTypes.containsKey(item.name) &&
                        !noShopItems.contains(item.name)) {
                      missing.add(item.name);
                    }
                  }
                }
              }
            }
          }
        }
      }
      expect(missing, isEmpty);
    });
  });

  group('product ranking', () {
    test('many good reviews beat a few perfect ones; unrated last', () {
      final popular = _p('popular', 'x', rating: 4.7, reviews: 1000);
      final few = _p('few', 'x', rating: 5, reviews: 3);
      final none = _p('none', 'x');
      expect(popular.score, greaterThan(few.score));
      expect(few.score, greaterThan(none.score));
      expect(
        productsFor('x', catalogue: [none, few, popular]).map((p) => p.id),
        ['popular', 'few', 'none'],
      );
    });

    test('labels', () {
      expect(
        _p('a', 'x', rating: 4.7, reviews: 1187).ratingLabel,
        '4.7★ (1,187)',
      );
      expect(_p('a', 'x').ratingLabel, isNull);
    });
  });

  group('which kit items get a shop link', () {
    final catalogue = [
      _p('rain', 'run_jacket_rain', rating: 4.5, reviews: 100),
      _p('tee', 'run_tee_light', rating: 4.8, reviews: 5000),
      _p('gloves', 'run_gloves_thin', rating: 4.6, reviews: 300),
      _p('cap', 'run_cap', rating: 4.6, reviews: 300),
      _p('tights', 'run_tights', rating: 4.6, reviews: 300),
    ];
    const kit = [
      GearItem(part: BodyPart.head, name: 'Cap with a brim', reason: 'r'),
      GearItem(part: BodyPart.torso, name: 'Short-sleeve tee', reason: 'r'),
      GearItem(part: BodyPart.hands, name: 'Thin gloves', reason: 'r'),
      GearItem(part: BodyPart.legs, name: 'Running tights', reason: 'r'),
      GearItem(
        part: BodyPart.torso,
        name: 'Light water-resistant jacket',
        reason: 'r',
        trigger: GearTrigger.rain,
      ),
      GearItem(
        part: BodyPart.feet,
        name: 'Your usual running shoes',
        reason: 'r',
      ),
    ];

    test('at most 3, rain gear first, then torso, hands', () {
      final offered = itemsToOffer(kit, ownedTypes: {}, catalogue: catalogue);
      expect(offered.map((i) => i.name), [
        'Light water-resistant jacket',
        'Short-sleeve tee',
        'Thin gloves',
      ]);
    });

    test('never for gear the user has', () {
      final offered = itemsToOffer(
        kit,
        ownedTypes: {'run_jacket_rain', 'run_gloves_thin'},
        catalogue: catalogue,
      );
      expect(offered.map((i) => i.name), [
        'Short-sleeve tee',
        'Cap with a brim',
        'Running tights',
      ]);
    });
  });

  group('race-day kit', () {
    test('triathlon on a cool, wet, windy day', () {
      final picks = raceKit(
        race: _race(triathlonPresets.last.legs),
        conditions: _stats(temp: 17, rain: 0.4, wind: 20),
        sport: Sport.run,
      );
      expect(picks.length, 5);
      final types = picks.map((p) => p.product.category).toList();
      expect(types.first, 'swim_wetsuit');
      expect(types, containsAll(['swim_trisuit', 'race_gel']));
      expect(types.toSet().length, types.length);
      for (final pick in picks) {
        expect(pick.why, isNotEmpty);
      }
    });

    test('hot marathon: no wetsuit, electrolytes and sun gear', () {
      final picks = raceKit(
        race: _race(runPresets.last.legs),
        conditions: _stats(temp: 26, humidity: 60, rain: 0.1, wind: 8),
        sport: Sport.run,
        count: 10,
      );
      final types = picks.map((p) => p.product.category).toSet();
      expect(types, isNot(contains('swim_wetsuit')));
      expect(
        types,
        containsAll([
          'race_gel',
          'race_electrolytes',
          'run_cap',
          'race_sunscreen',
        ]),
      );
    });

    test('skips what the user owns', () {
      final picks = raceKit(
        race: _race(triathlonPresets.last.legs),
        conditions: _stats(temp: 17),
        sport: Sport.run,
        ownedTypes: {'swim_wetsuit'},
      );
      expect(
        picks.map((p) => p.product.category),
        isNot(contains('swim_wetsuit')),
      );
    });
  });

  testWidgets('kit list offers Decathlon options; "I have this" hides them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();
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

    final links = find.text("Don't have one? See options at Decathlon");
    expect(links, findsNWidgets(maxShopLinks));
    expect(
      store.shopStats.keys.where((k) => k.startsWith('shown:')),
      isNotEmpty,
    );

    // Links appear in body-part order (head first).
    await tester.tap(links.first);
    await tester.pumpAndSettle();
    expect(find.text('Options at Decathlon'), findsOneWidget);
    expect(find.text('View at decathlon.nl'), findsWidgets);
    expect(
      store.shopStats.keys.where((k) => k.startsWith('opened:')),
      isNotEmpty,
      reason: '${store.shopStats}',
    );

    await tester.tap(find.text('I already have this'));
    await tester.pumpAndSettle();
    final opened = store.shopStats.keys
        .where((k) => k.startsWith('opened:'))
        .map((k) => k.substring('opened:'.length));
    expect(store.ownedTypes, containsAll(opened));
    // Another item takes its place, still at most three links.
    expect(links.evaluate().length, lessThanOrEqualTo(maxShopLinks));

    // Switched off: no links at all.
    await store.setShopSuggestionsOn(false);
    await tester.pumpWidget(
      MaterialApp(
        home: SessionResultPage(
          key: const ValueKey('again'),
          plan: plan,
          weather: FakeWeatherService(),
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(links, findsNothing);
  });
}
