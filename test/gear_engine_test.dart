import 'package:flutter_test/flutter_test.dart';
import 'package:twinclimate/logic/gear_engine.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/models/weather.dart';

/// Builds a two-hour session forecast with the given conditions.
SessionForecast forecast({
  double apparentC = 18,
  double precipProbability = 5,
  double precipitationMm = 0,
  double windKmh = 10,
  double gustKmh = 18,
  double humidity = 55,
  int weatherCode = 1,
  bool isDay = true,
}) {
  HourWeather hour(int h) => HourWeather(
        time: DateTime(2026, 6, 13, h),
        temperatureC: apparentC + 1,
        apparentC: apparentC,
        humidityPercent: humidity,
        precipProbabilityPercent: precipProbability,
        precipitationMm: precipitationMm,
        windKmh: windKmh,
        gustKmh: gustKmh,
        weatherCode: weatherCode,
        isDay: isDay,
      );
  return SessionForecast([hour(8), hour(9)]);
}

List<GearItem> itemsFor(List<GearItem> kit, BodyPart part) =>
    [for (final item in kit) if (item.part == part) item];

void main() {
  group('every kit, every condition', () {
    test('items always carry a non-empty reason (hard product rule)', () {
      for (final sport in Sport.values) {
        for (var t = -8.0; t <= 32; t += 4) {
          for (final rainy in [false, true]) {
            final kit = buildKit(
              sport,
              forecast(
                apparentC: t,
                precipProbability: rainy ? 70 : 5,
                precipitationMm: rainy ? 3 : 0,
                weatherCode: rainy ? 63 : 1,
              ),
              distanceKm: 15,
            );
            expect(kit, isNotEmpty);
            for (final item in kit) {
              expect(item.name.trim(), isNotEmpty,
                  reason: '$sport at $t° rainy=$rainy');
              expect(item.reason.trim(), isNotEmpty,
                  reason: '${item.name} ($sport at $t°) must have a reason');
            }
            // No duplicate suggestions within a body part.
            for (final part in BodyPart.values) {
              final names = [for (final i in itemsFor(kit, part)) i.name];
              expect(names.toSet().length, names.length,
                  reason: 'duplicate item for $part ($sport at $t°)');
            }
          }
        }
      }
    });

    test('torso and feet are never left empty for run and bike', () {
      for (final sport in [Sport.run, Sport.bike]) {
        for (var t = -8.0; t <= 32; t += 4) {
          final kit = buildKit(sport, forecast(apparentC: t));
          expect(itemsFor(kit, BodyPart.torso), isNotEmpty,
              reason: '$sport at $t°');
          expect(itemsFor(kit, BodyPart.feet), isNotEmpty,
              reason: '$sport at $t°');
        }
      }
    });
  });

  group('run', () {
    test('warm dry day: light top, shorts, nothing rain-triggered', () {
      final kit = buildKit(Sport.run, forecast(apparentC: 20));
      expect(itemsFor(kit, BodyPart.torso).first.name,
          contains('Light short-sleeve'));
      // Properly hot days escalate to a singlet.
      final hotKit = buildKit(Sport.run, forecast(apparentC: 26));
      expect(itemsFor(hotKit, BodyPart.torso).first.name, contains('Singlet'));
      expect(itemsFor(kit, BodyPart.legs).single.name, 'Shorts');
      expect(kit.where((i) => i.trigger == GearTrigger.rain), isEmpty);
      expect(itemsFor(kit, BodyPart.hands), isEmpty);
    });

    test('runners are breeze-tolerant: shorts survive cool air', () {
      // 8° feels-like: legs are treated as 11° (cool) -> still shorts.
      final kit = buildKit(Sport.run, forecast(apparentC: 8));
      expect(itemsFor(kit, BodyPart.legs).single.name, 'Shorts');
    });

    test('cold day: tights, gloves and a beanie appear', () {
      final kit = buildKit(Sport.run, forecast(apparentC: 1));
      expect(itemsFor(kit, BodyPart.legs).single.name,
          contains('tights'));
      expect(itemsFor(kit, BodyPart.hands), isNotEmpty);
      expect(
          itemsFor(kit, BodyPart.head).any(
              (i) => i.name.toLowerCase().contains('beanie')),
          isTrue);
    });

    test('rainy day: rain-triggered jacket and socks, reasons cite the rain',
        () {
      final kit = buildKit(
        Sport.run,
        forecast(
            apparentC: 14,
            precipProbability: 70,
            precipitationMm: 3,
            weatherCode: 63),
      );
      final rainItems = kit.where((i) => i.trigger == GearTrigger.rain);
      expect(rainItems, isNotEmpty);
      expect(
          itemsFor(kit, BodyPart.torso)
              .any((i) => i.name.toLowerCase().contains('jacket')),
          isTrue);
      expect(
          rainItems.any((i) => i.reason.contains('70%')),
          isTrue,
          reason: 'reasons should cite the actual rain chance');
    });

    test('windy (but dry) day: windbreaker is suggested and wind-tagged', () {
      final kit =
          buildKit(Sport.run, forecast(apparentC: 12, windKmh: 32, gustKmh: 50));
      expect(kit.any((i) => i.trigger == GearTrigger.wind), isTrue);
    });

    test('long runs get tested-socks advice', () {
      final kit = buildKit(Sport.run, forecast(apparentC: 18), distanceKm: 20);
      expect(
          itemsFor(kit, BodyPart.feet)
              .any((i) => i.name.contains('long runs')),
          isTrue);
    });
  });

  group('bike', () {
    test('helmet is always on the list, whatever the weather', () {
      for (var t = -8.0; t <= 32; t += 8) {
        final kit = buildKit(Sport.bike, forecast(apparentC: t));
        expect(
            itemsFor(kit, BodyPart.head).any((i) => i.name == 'Helmet'),
            isTrue,
            reason: 'no helmet at $t°');
      }
    });

    test('cyclists run cold: gloves appear in mild air', () {
      // 14° feels-like is treated as 11° on the hands -> full-finger gloves.
      final kit = buildKit(Sport.bike, forecast(apparentC: 14));
      expect(
          itemsFor(kit, BodyPart.hands)
              .any((i) => i.name.toLowerCase().contains('full-finger')),
          isTrue);
    });

    test('rain brings overshoes and a rain jacket', () {
      final kit = buildKit(
        Sport.bike,
        forecast(
            apparentC: 10,
            precipProbability: 80,
            precipitationMm: 4,
            weatherCode: 63),
      );
      expect(
          itemsFor(kit, BodyPart.feet)
              .any((i) => i.name.toLowerCase().contains('overshoes')),
          isTrue);
      expect(
          itemsFor(kit, BodyPart.torso)
              .any((i) => i.name.toLowerCase().contains('rain jacket')),
          isTrue);
    });
  });

  group('swim', () {
    test('cool air means a wetsuit (required, not optional)', () {
      final kit = buildKit(Sport.swim, forecast(apparentC: 10));
      final wetsuits = itemsFor(kit, BodyPart.torso)
          .where((i) => i.name == 'Wetsuit');
      expect(wetsuits, isNotEmpty);
      expect(wetsuits.first.optional, isFalse);
    });

    test('hot air: no wetsuit needed', () {
      final kit = buildKit(Sport.swim, forecast(apparentC: 27));
      expect(
          itemsFor(kit, BodyPart.torso).any((i) => i.name == 'Wetsuit'),
          isFalse);
    });

    test('windy shore: after-swim warm layer is wind-tagged', () {
      final kit = buildKit(
          Sport.swim, forecast(apparentC: 20, windKmh: 30, gustKmh: 48));
      expect(
          kit.any((i) =>
              i.trigger == GearTrigger.wind &&
              i.name.toLowerCase().contains('after')),
          isTrue);
    });
  });

  group('temperature bands and sport baselines', () {
    test('bands split where the spec says', () {
      expect(bandFor(-1), TempBand.freezing);
      expect(bandFor(0), TempBand.cold);
      expect(bandFor(6), TempBand.cool);
      expect(bandFor(12), TempBand.mild);
      expect(bandFor(18), TempBand.warm);
      expect(bandFor(24), TempBand.hot);
    });

    test('zero-data baseline matches the PRD', () {
      // Runners: breeze-tolerant on legs and torso.
      expect(sportPartAdjustment(Sport.run, BodyPart.legs), greaterThan(0));
      expect(sportPartAdjustment(Sport.run, BodyPart.torso), greaterThan(0));
      // Cyclists: want warmth on hands, torso, head.
      expect(sportPartAdjustment(Sport.bike, BodyPart.hands), lessThan(0));
      expect(sportPartAdjustment(Sport.bike, BodyPart.torso), lessThan(0));
      expect(sportPartAdjustment(Sport.bike, BodyPart.head), lessThan(0));
    });
  });
}
