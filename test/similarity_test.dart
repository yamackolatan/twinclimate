import 'package:flutter_test/flutter_test.dart';
import 'package:twinclimate/data.dart';
import 'package:twinclimate/models.dart';
import 'package:twinclimate/similarity.dart';

City byName(String name) => cities.firstWhere((c) => c.name == name);

void main() {
  test('every city has 12 months of data', () {
    for (final city in cities) {
      expect(city.highC.length, 12, reason: city.name);
      expect(city.lowC.length, 12, reason: city.name);
      expect(city.precipMm.length, 12, reason: city.name);
      for (var m = 0; m < 12; m++) {
        expect(city.highC[m], greaterThan(city.lowC[m]),
            reason: '${city.name} month $m high should exceed low');
        expect(city.precipMm[m], greaterThanOrEqualTo(0), reason: city.name);
      }
    }
  });

  test('a city is a perfect twin of itself', () {
    for (final city in cities) {
      expect(twinScore(city, city).score, 100);
    }
  });

  test('score is symmetric', () {
    final london = byName('London');
    final tokyo = byName('Tokyo');
    expect(twinScore(london, tokyo).score,
        closeTo(twinScore(tokyo, london).score, 1e-9));
  });

  test('similar climates score higher than different ones', () {
    final london = byName('London');
    final amsterdam = byName('Amsterdam');
    final singapore = byName('Singapore');
    final londonAmsterdam = twinScore(london, amsterdam).score;
    final londonSingapore = twinScore(london, singapore).score;
    expect(londonAmsterdam, greaterThan(85));
    expect(londonSingapore, lessThan(40));
    expect(londonAmsterdam, greaterThan(londonSingapore));
  });

  test('cross-hemisphere twins are matched with flipped seasons', () {
    final capeTown = byName('Cape Town');
    final losAngeles = byName('Los Angeles');
    final result = twinScore(capeTown, losAngeles);
    expect(result.seasonsFlipped, isTrue);
    expect(result.score, greaterThan(70));
  });

  test('ranking excludes the home city and is sorted best-first', () {
    final istanbul = byName('Istanbul');
    final ranked = rankTwins(istanbul, cities);
    expect(ranked.length, cities.length - 1);
    expect(ranked.any((r) => r.$1 == istanbul), isFalse);
    for (var i = 1; i < ranked.length; i++) {
      expect(ranked[i - 1].$2.score, greaterThanOrEqualTo(ranked[i].$2.score));
    }
  });

  test('score labels cover the full range', () {
    expect(scoreLabel(95), 'Climate twins');
    expect(scoreLabel(75), 'Close cousins');
    expect(scoreLabel(55), 'Same family');
    expect(scoreLabel(35), 'Distant relatives');
    expect(scoreLabel(10), 'Different worlds');
  });
}
