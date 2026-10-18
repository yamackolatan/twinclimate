import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/logic/feedback_logic.dart';
import 'package:twinclimate/logic/gear_engine.dart';
import 'package:twinclimate/models/comfort.dart';
import 'package:twinclimate/models/gear.dart';
import 'package:twinclimate/models/session.dart';
import 'package:twinclimate/services/prefs_store.dart';

import 'gear_engine_test.dart' show forecast, itemsFor;

var _n = 0;

FeedbackEntry fb(
  Feeling feeling, {
  BodyPart? part = BodyPart.torso,
  double feelsC = 17,
  Sport sport = Sport.run,
  Worn worn = Worn.asSuggested,
  DateTime? date,
}) =>
    FeedbackEntry(
      id: 'f${_n++}',
      sport: sport,
      date: date ?? DateTime(2026, 10, 1).add(Duration(days: _n)),
      feelsC: feelsC,
      measured: true,
      feeling: feeling,
      part: part,
      worn: worn,
    );

ComfortProfile profileOf(List<FeedbackEntry> feedback,
        {Map<Sport, Map<BodyPart, int>> manual = const {},
        Map<String, DateTime> forgotten = const {}}) =>
    ComfortProfile(
        feedback: feedback, manualSettings: manual, forgotten: forgotten);

SessionRecord session({
  required DateTime start,
  Duration length = const Duration(minutes: 90),
  double feels = 17,
  SessionStatus status = SessionStatus.pending,
  Sport sport = Sport.run,
  String id = '',
  bool allPacked = false,
  Set<String> packed = const {},
}) =>
    SessionRecord(
      id: id.isEmpty ? start.toIso8601String() : id,
      sport: sport,
      placeName: 'Belgrad Forest',
      latitude: 41.18,
      longitude: 28.99,
      start: start,
      end: start.add(length),
      forecastFeelsC: feels,
      suggested: const {BodyPart.torso: 'Light short-sleeve tech tee'},
      status: status,
      allPacked: allPacked,
      packed: packed,
    );

void main() {
  test('temperature zones (owner decision 3)', () {
    expect(TempZone.of(-0.1), TempZone.freezing);
    expect(TempZone.of(3.9), TempZone.veryCold);
    expect(TempZone.of(6.9), TempZone.cold);
    expect(TempZone.of(9.9), TempZone.chilly);
    // Owner: 10-12 feels much the same, 13-15 needs other kit.
    expect(TempZone.of(10), TempZone.cool);
    expect(TempZone.of(12.9), TempZone.cool);
    expect(TempZone.of(13), TempZone.mild);
    expect(TempZone.of(15.9), TempZone.mild);
    expect(TempZone.of(16), TempZone.mildWarm);
    expect(TempZone.of(20), TempZone.warm);
    expect(TempZone.mild.phrase, 'between 13 and 16°C');
    expect(TempZone.warm.phrase, 'above 20°C');
  });

  group('learning (owner decision 2)', () {
    LearnedComfort torsoWarm(List<FeedbackEntry> f) =>
        profileOf(f).learned(Sport.run, BodyPart.torso, TempZone.mildWarm);

    test('one report changes nothing yet; two make one step', () {
      expect(torsoWarm([fb(Feeling.tooWarm)]).steps, 0);
      expect(torsoWarm([fb(Feeling.tooWarm), fb(Feeling.tooWarm)]).steps, 1);
    });

    test('"just right" cancels one earlier report', () {
      final l = torsoWarm([
        fb(Feeling.tooWarm),
        fb(Feeling.tooWarm),
        fb(Feeling.justRight),
      ]);
      expect(l.net, 2);
      expect(l.steps, 0);
    });

    test('at most two steps', () {
      expect(torsoWarm([for (var i = 0; i < 8; i++) fb(Feeling.tooWarm)]).steps,
          maxComfortSteps);
    });

    test('too cold goes the other way', () {
      final p = profileOf([
        fb(Feeling.tooCold, part: BodyPart.hands, feelsC: 2),
        fb(Feeling.tooCold, part: BodyPart.hands, feelsC: 3),
      ]);
      expect(p.learned(Sport.run, BodyPart.hands, TempZone.veryCold).steps, -1);
      expect(p.steps(Sport.run, BodyPart.hands, TempZone.veryCold), -1);
    });

    test('"everywhere" counts for all five body parts', () {
      final p = profileOf(
          [fb(Feeling.tooWarm, part: null), fb(Feeling.tooWarm, part: null)]);
      for (final part in BodyPart.values) {
        expect(p.learned(Sport.run, part, TempZone.mildWarm).steps, 1);
      }
    });

    test('zones and sports are learned separately', () {
      final p = profileOf([fb(Feeling.tooWarm), fb(Feeling.tooWarm)]);
      expect(p.learned(Sport.run, BodyPart.torso, TempZone.cold).steps, 0);
      expect(p.learned(Sport.bike, BodyPart.torso, TempZone.mildWarm).steps, 0);
    });

    test('neighbouring ranges get half weight, so learning stays quick', () {
      // Two reports at 17° (16-20 range) and one at 14° (13-16 range).
      final p = profileOf([
        fb(Feeling.tooWarm),
        fb(Feeling.tooWarm),
      ]);
      final next = p.learned(Sport.run, BodyPart.torso, TempZone.mild);
      expect(next.net, 2); // half of two reports
      expect(next.steps, 0);
      final q = profileOf([
        fb(Feeling.tooWarm),
        fb(Feeling.tooWarm),
        fb(Feeling.tooWarm, feelsC: 14),
      ]);
      // One own report + two neighbouring ones = one step.
      expect(q.learned(Sport.run, BodyPart.torso, TempZone.mild).steps, 1);
      // Two ranges away: untouched.
      expect(q.learned(Sport.run, BodyPart.torso, TempZone.chilly).net, 0);
    });

    test('discomfort explained by the user\'s own clothes is not learned', () {
      final p = profileOf([
        fb(Feeling.tooWarm, worn: Worn.warmer),
        fb(Feeling.tooWarm, worn: Worn.warmer),
      ]);
      expect(torsoWarm(p.feedback).net, 0);
      // Still too cold after dressing warmer than suggested: does count.
      final q = profileOf([
        fb(Feeling.tooCold, worn: Worn.warmer),
        fb(Feeling.tooCold, worn: Worn.warmer),
      ]);
      expect(q.learned(Sport.run, BodyPart.torso, TempZone.mildWarm).steps, -1);
    });

    test('"Forget" ignores answers up to that moment', () {
      final a = fb(Feeling.tooWarm, date: DateTime(2026, 10, 1));
      final b = fb(Feeling.tooWarm, date: DateTime(2026, 10, 2));
      final c = fb(Feeling.tooWarm, date: DateTime(2026, 10, 5));
      final p = profileOf([a, b, c], forgotten: {
        ComfortProfile.key(Sport.run, BodyPart.torso, TempZone.mildWarm):
            DateTime(2026, 10, 3),
      });
      expect(p.learned(Sport.run, BodyPart.torso, TempZone.mildWarm).net, 2);
    });

    test('slider adds to what was learned, capped at two steps', () {
      final p = profileOf([fb(Feeling.tooWarm), fb(Feeling.tooWarm)],
          manual: {
            Sport.run: {BodyPart.torso: 2},
          });
      expect(p.steps(Sport.run, BodyPart.torso, TempZone.mildWarm), 2);
    });
  });

  group('kit adapts with a personal reason (brief\'s acceptance test)', () {
    final warmRun = forecast(apparentC: 16);

    test('two "too warm → torso" on warm runs → lighter top, says why', () {
      final standard = buildKit(Sport.run, warmRun);
      final personal = buildKit(Sport.run, warmRun,
          comfort: profileOf([fb(Feeling.tooWarm), fb(Feeling.tooWarm)]));
      final before = itemsFor(standard, BodyPart.torso).first;
      final after = itemsFor(personal, BodyPart.torso).first;
      expect(before.name, 'Short-sleeve tee');
      expect(after.name, 'Light short-sleeve tech tee');
      expect(after.reason,
          startsWith('You run warm between 16 and 20°C, so this is lighter '
              'than usual.'));
    });

    test('unchanged items get no personal note', () {
      final personal = buildKit(Sport.run, warmRun,
          comfort: profileOf([fb(Feeling.tooWarm), fb(Feeling.tooWarm)]));
      for (final part in [BodyPart.head, BodyPart.legs, BodyPart.feet]) {
        for (final item in itemsFor(personal, part)) {
          expect(item.reason, isNot(contains('You run')), reason: item.name);
        }
      }
    });

    test('learning at 16-20°C leaves cold-day kit alone', () {
      final coolRun = forecast(apparentC: 8);
      expect(
          buildKit(Sport.run, coolRun,
                  comfort: profileOf([fb(Feeling.tooWarm), fb(Feeling.tooWarm)]))
              .map((i) => i.name),
          buildKit(Sport.run, coolRun).map((i) => i.name));
    });

    test('Settings slider: cold hands on the bike → warmer gloves', () {
      final mild = forecast(apparentC: 16);
      final standard = itemsFor(buildKit(Sport.bike, mild), BodyPart.hands);
      final personal = itemsFor(
          buildKit(Sport.bike, mild,
              comfort: profileOf(const [], manual: {
                Sport.bike: {BodyPart.hands: -1},
              })),
          BodyPart.hands);
      expect(standard.first.name, 'Fingerless mitts');
      expect(personal.first.name, 'Light full-finger gloves');
      expect(personal.first.reason,
          startsWith('Your comfort profile says your hands run cold, so this '
              'is warmer than usual.'));
    });

    test('every item still carries a reason', () {
      final p = profileOf([
        for (var i = 0; i < 4; i++) fb(Feeling.tooCold, part: null, feelsC: 2),
      ]);
      for (final sport in Sport.values) {
        for (final item in buildKit(sport, forecast(apparentC: 2), comfort: p)) {
          expect(item.reason.trim(), isNotEmpty);
        }
      }
    });

    test('main suggestion per part skips always-on items', () {
      final kit = buildKit(Sport.bike, forecast(apparentC: 16));
      final main = mainSuggestions(kit);
      expect(main[BodyPart.head], isNot('Helmet'));
      expect(main[BodyPart.torso], isNotNull);
    });
  });

  group('what the user is told (PRD decision 4)', () {
    String after(List<FeedbackEntry> earlier, FeedbackEntry entry) =>
        learnedMessage(profileOf(earlier), profileOf([...earlier, entry]), entry);

    test('first report: one more needed', () {
      expect(after(const [], fb(Feeling.tooWarm)),
          'Noted. One more report like this and we\'ll suggest a lighter top '
          'when it\'s between 16 and 20°C.');
    });

    test('second report: learned', () {
      expect(after([fb(Feeling.tooWarm)], fb(Feeling.tooWarm)),
          'Learned: you run warm between 16 and 20°C. Next time we\'ll '
          'suggest a '
          'lighter top.');
    });

    test('cold hands', () {
      expect(
          after([fb(Feeling.tooCold, part: BodyPart.hands, feelsC: 2)],
              fb(Feeling.tooCold, part: BodyPart.hands, feelsC: 3)),
          'Learned: your hands run cold between 0 and 4°C. Next time we\'ll '
          'suggest '
          'warmer gloves.');
    });

    test('just right', () {
      expect(after(const [], fb(Feeling.justRight, part: null, feelsC: 12.4)),
          'Great — we\'ll keep suggesting similar kit when it feels about 12°.');
    });

    test('explained by clothing', () {
      expect(after(const [], fb(Feeling.tooWarm, worn: Worn.warmer)),
          'That makes sense — you wore something warmer than we suggested. '
          'Our lighter suggestion should suit you better next time.');
    });

    test('balancing an earlier opposite report', () {
      expect(after([fb(Feeling.tooCold)], fb(Feeling.tooWarm)),
          'Noted — that balances out an earlier "too cold" report.');
    });
  });

  group('which session to ask about', () {
    final now = DateTime(2026, 10, 18, 12);
    final empty = profileOf(const []);

    test('only after the expected finish (owner decision 1)', () {
      final running = session(start: now.subtract(const Duration(minutes: 30)));
      expect(pickSessionToAsk([running], empty, now).ask, isNull);
      final done = session(start: now.subtract(const Duration(hours: 2)));
      expect(pickSessionToAsk([done], empty, now).ask, done);
    });

    test('stops asking after 3 days', () {
      final old = session(start: now.subtract(const Duration(days: 4)));
      expect(pickSessionToAsk([old], empty, now).ask, isNull);
    });

    test('only the most recent finished session', () {
      final older = session(start: now.subtract(const Duration(hours: 30)));
      final newer = session(start: now.subtract(const Duration(hours: 3)));
      expect(pickSessionToAsk([older, newer], empty, now).ask, newer);
      final answered = session(
          start: now.subtract(const Duration(hours: 3)),
          status: SessionStatus.answered);
      expect(pickSessionToAsk([older, answered], empty, now).ask, isNull);
    });

    test('asks less once the profile is stable (owner decision)', () {
      final stable = profileOf([
        for (var i = 0; i < 4; i++)
          fb(Feeling.justRight, date: DateTime(2026, 10, 1 + i)),
      ]);
      final s1 = session(start: now.subtract(const Duration(hours: 3)));
      expect(pickSessionToAsk([s1], stable, now).skip, s1);
      final skipped = [
        session(
            start: DateTime(2026, 10, 10),
            id: 'a',
            status: SessionStatus.skippedStable),
        session(
            start: DateTime(2026, 10, 12),
            id: 'b',
            status: SessionStatus.skippedStable),
      ];
      expect(pickSessionToAsk([...skipped, s1], stable, now).ask, s1);
    });

    test('packing checklist answers "did you wear that?"', () {
      final s = session(
          start: now,
          packed: const {'Light short-sleeve tech tee'});
      expect(s.packedSuggestionFor(BodyPart.torso), isTrue);
      expect(s.packedSuggestionFor(BodyPart.legs), isFalse);
      expect(s.packedSuggestionFor(null), isFalse);
      expect(session(start: now, allPacked: true).packedSuggestionFor(null),
          isTrue);
    });
  });

  group('saved on the device', () {
    test('reopening a session keeps its packing ticks and answer', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsStore.load();
      final start = DateTime(2026, 10, 18, 8);
      await store.recordSession(session(start: start, id: 's'));
      await store.updateSession('s',
          (r) => r.copyWith(packed: {'Cap'}, status: SessionStatus.answered));
      await store.recordSession(session(start: start, id: 's'));
      final r = store.sessionRecords.single;
      expect(r.packed, {'Cap'});
      expect(r.status, SessionStatus.answered);
    });

    test('feedback, sliders, forget and reset', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await PrefsStore.load();
      await store.addFeedback(fb(Feeling.tooWarm));
      await store.addFeedback(fb(Feeling.tooWarm));
      await store.setComfortManual(Sport.bike, BodyPart.hands, -1);
      var p = store.comfortProfile;
      expect(p.learned(Sport.run, BodyPart.torso, TempZone.mildWarm).steps, 1);
      expect(p.manual(Sport.bike, BodyPart.hands), -1);

      await store.forgetLearned(
          Sport.run, BodyPart.torso, TempZone.mildWarm, DateTime(2030));
      p = store.comfortProfile;
      expect(p.learned(Sport.run, BodyPart.torso, TempZone.mildWarm).net, 0);

      await store.deleteFeedback(store.feedback.first.id);
      expect(store.feedback, hasLength(1));

      await store.resetComfort();
      expect(store.feedback, isEmpty);
      expect(store.comfortProfile.manual(Sport.bike, BodyPart.hands), 0);
    });

    test('damaged comfort data never breaks the app', () async {
      SharedPreferences.setMockInitialValues({
        'sessionRecords': 'oops',
        'comfortFeedback': '[1,2]',
        'comfortManual': '{"run": 5}',
      });
      final store = await PrefsStore.load();
      expect(store.sessionRecords, isEmpty);
      expect(store.feedback, isEmpty);
      expect(store.comfortManual, isEmpty);
    });
  });
}
