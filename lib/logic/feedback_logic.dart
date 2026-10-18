import '../models/comfort.dart';
import '../models/gear.dart';
import 'gear_engine.dart';

/// How long after a session ends the feedback card keeps asking.
const Duration feedbackWindow = Duration(days: 3);

/// With a stable profile ("ask less"), this many finished sessions in a row
/// are skipped before asking again.
const int stableSkips = 2;

/// What the home screen should do with finished sessions.
class FeedbackPick {
  const FeedbackPick({this.ask, this.skip});

  /// The session to ask about, if any.
  final SessionRecord? ask;

  /// A session to quietly mark as skipped because the profile is stable.
  final SessionRecord? skip;
}

/// Picks the session to ask about: only the most recent session whose
/// expected finish has passed (owner decision 1), within
/// [feedbackWindow], and only while it's still unanswered — so browsing
/// several plans never piles up questions. Once the profile is stable for
/// that sport and zone, only every third such session is asked about.
FeedbackPick pickSessionToAsk(
  List<SessionRecord> records,
  ComfortProfile profile,
  DateTime now,
) {
  final finished = [
    for (final r in records)
      if (!r.end.isAfter(now) && now.difference(r.end) <= feedbackWindow) r,
  ]..sort((a, b) => b.end.compareTo(a.end));
  if (finished.isEmpty) return const FeedbackPick();
  final latest = finished.first;
  if (latest.status != SessionStatus.pending) return const FeedbackPick();
  final zone = TempZone.of(latest.forecastFeelsC);
  if (!profile.isStable(latest.sport, zone)) {
    return FeedbackPick(ask: latest);
  }
  final lastAnswer = profile.recent(latest.sport, zone).first.date;
  final skippedSince = records
      .where(
        (r) =>
            r.status == SessionStatus.skippedStable &&
            r.sport == latest.sport &&
            TempZone.of(r.forecastFeelsC) == zone &&
            r.start.isAfter(lastAnswer),
      )
      .length;
  return skippedSince >= stableSkips
      ? FeedbackPick(ask: latest)
      : FeedbackPick(skip: latest);
}

/// "a lighter top", "warmer gloves", "lighter kit".
String _kitPhrase(BodyPart? part, String direction) => switch (part) {
  BodyPart.torso => 'a $direction top',
  BodyPart.head => '$direction headwear',
  BodyPart.hands => '$direction gloves',
  BodyPart.legs => '$direction legwear',
  BodyPart.feet => '$direction footwear',
  null => '$direction kit',
};

/// Tells the user straight away what was learned (PRD decision 4),
/// comparing the profile before and after [entry].
String learnedMessage(
  ComfortProfile before,
  ComfortProfile after,
  FeedbackEntry entry,
) {
  final feels = entry.feelsC.round();
  if (entry.feeling == Feeling.justRight) {
    return 'Great — we\'ll keep suggesting similar kit when it feels '
        'about $feels°.';
  }
  final tooWarm = entry.feeling == Feeling.tooWarm;
  final ourDirection = tooWarm ? 'lighter' : 'warmer';
  if (entry.explainedByClothing) {
    return 'That makes sense — you wore something '
        '${tooWarm ? 'warmer' : 'lighter'} than we suggested. Our '
        '$ourDirection suggestion should suit you better next time.';
  }
  final parts = entry.part == null ? BodyPart.values : [entry.part!];
  final zone = entry.zone;
  final anchor = entry.part ?? BodyPart.torso;
  final was = before.learned(entry.sport, anchor, zone);
  final now = after.learned(entry.sport, anchor, zone);
  final changed = parts.any(
    (p) =>
        after.learned(entry.sport, p, zone).steps !=
        before.learned(entry.sport, p, zone).steps,
  );
  final kit = _kitPhrase(entry.part, ourDirection);
  if (changed && now.steps != 0) {
    final subject = entry.part == null ? 'You run' : runsSubject(entry.part!);
    return 'Learned: ${subject.toLowerCase()} '
        '${now.steps > 0 ? 'warm' : 'cold'} ${zone.phrase}. '
        'Next time we\'ll suggest $kit.';
  }
  if (changed) {
    return 'Noted — that balances out earlier reports, so we\'re back to '
        'our standard suggestion ${zone.phrase}.';
  }
  if (was.net.sign != 0 && was.net.sign != (tooWarm ? 1 : -1)) {
    return 'Noted — that balances out an earlier '
        '"${tooWarm ? 'too cold' : 'too warm'}" report.';
  }
  if (now.steps.abs() >= maxComfortSteps) {
    return 'Noted — we\'re already suggesting the '
        '${tooWarm ? 'lightest' : 'warmest'} kit we can for you '
        '${zone.phrase}.';
  }
  return 'Noted. One more report like this and we\'ll suggest $kit when '
      'it\'s ${zone.phrase}.';
}
