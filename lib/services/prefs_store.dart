import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/comfort.dart';
import '../models/gear.dart';

import '../models/matching.dart';
import '../models/place.dart';
import '../models/race.dart';
import '../models/session.dart';

/// Local, on-device storage (works on Flutter web via browser storage).
/// MVP persistence per the PRD: favourite places, last-used session
/// defaults and races. Comfort profile and feedback history will join
/// later.
class PrefsStore {
  PrefsStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kPlaces = 'favouritePlaces';
  static const _kSport = 'lastSport';
  static const _kDistancePrefix = 'lastDistanceKm.';
  static const _kStartHour = 'lastStartHour';
  static const _kStartMinute = 'lastStartMinute';
  static const _kRaces = 'races';
  static const _kTrainFrom = 'trainFromMinutes';
  static const _kTrainUntil = 'trainUntilMinutes';
  static const _kDaylightOnly = 'daylightOnly';
  static const _kSessions = 'sessionRecords';
  static const _kFeedback = 'comfortFeedback';
  static const _kManual = 'comfortManual';
  static const _kForgotten = 'comfortForgotten';

  /// Sessions kept for the feedback card (most recent first).
  static const _maxSessions = 20;

  static Future<PrefsStore> load() async =>
      PrefsStore._(await SharedPreferences.getInstance());

  /// Places the user has searched and used, most recent first. Presets are
  /// not stored — they're always available from [presetPlaces].
  List<Place> get savedPlaces {
    try {
      final encoded = _prefs.getString(_kPlaces);
      if (encoded == null) return const [];
      return Place.decodeList(encoded);
    } catch (_) {
      return const [];
    }
  }

  /// Remembers a place the user actually used ("ask once" principle).
  /// Keeps the six most recent; presets are skipped.
  Future<void> rememberPlace(Place place) async {
    if (place.isPreset) return;
    final places = [
      place,
      ...savedPlaces.where((p) => !p.sameSpot(place)),
    ].take(6).toList();
    await _prefs.setString(_kPlaces, Place.encodeList(places));
  }

  Sport get lastSport {
    final name = _prefs.getString(_kSport);
    return Sport.values.firstWhere(
      (s) => s.name == name,
      orElse: () => Sport.run,
    );
  }

  Future<void> rememberSport(Sport sport) =>
      _prefs.setString(_kSport, sport.name);

  double distanceFor(Sport sport) =>
      _prefs.getDouble('$_kDistancePrefix${sport.name}') ?? sport.defaultKm;

  Future<void> rememberDistance(Sport sport, double km) =>
      _prefs.setDouble('$_kDistancePrefix${sport.name}', km);

  /// Last used start time as (hour, minute); defaults to 08:00.
  (int, int) get lastStartTime =>
      (_prefs.getInt(_kStartHour) ?? 8, _prefs.getInt(_kStartMinute) ?? 0);

  Future<void> rememberStartTime(int hour, int minute) async {
    await _prefs.setInt(_kStartHour, hour);
    await _prefs.setInt(_kStartMinute, minute);
  }

  /// When the user can train, for Race Matching ("ask once").
  TrainingWindow get trainingWindow {
    const defaults = TrainingWindow();
    try {
      final window = TrainingWindow(
        fromMinutes: _prefs.getInt(_kTrainFrom) ?? defaults.fromMinutes,
        untilMinutes: _prefs.getInt(_kTrainUntil) ?? defaults.untilMinutes,
        daylightOnly: _prefs.getBool(_kDaylightOnly) ?? defaults.daylightOnly,
      );
      return window.isValid ? window : defaults;
    } catch (_) {
      return defaults;
    }
  }

  Future<void> rememberTrainingWindow(TrainingWindow window) async {
    await _prefs.setInt(_kTrainFrom, window.fromMinutes);
    await _prefs.setInt(_kTrainUntil, window.untilMinutes);
    await _prefs.setBool(_kDaylightOnly, window.daylightOnly);
  }

  /// Saved races (at most [maxRaces]), soonest first. Each carries its
  /// cached fingerprint, so reopening the app never recomputes it.
  List<Race> get races {
    try {
      final encoded = _prefs.getString(_kRaces);
      if (encoded == null) return const [];
      return Race.decodeList(encoded)..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      // Damaged storage must never blank the app; it then acts as if no
      // race were saved.
      return const [];
    }
  }

  Race? raceById(String id) {
    for (final race in races) {
      if (race.id == id) return race;
    }
    return null;
  }

  /// Adds [race], or replaces the saved race with the same id. Adding a
  /// race beyond [maxRaces] is refused (returns false).
  Future<bool> saveRace(Race race) async {
    final others = races.where((r) => r.id != race.id).toList();
    if (others.length >= maxRaces) return false;
    await _prefs.setString(_kRaces, Race.encodeList([...others, race]));
    return true;
  }

  Future<void> deleteRace(String id) => _prefs.setString(
    _kRaces,
    Race.encodeList(races.where((r) => r.id != id).toList()),
  );

  // ---------------------------------------------------- comfort (F4) --

  /// Sessions whose kit list was opened, newest start first.
  List<SessionRecord> get sessionRecords {
    try {
      final encoded = _prefs.getString(_kSessions);
      if (encoded == null) return const [];
      return [
        for (final item in jsonDecode(encoded) as List)
          SessionRecord.fromJson(item as Map<String, dynamic>),
      ]..sort((a, b) => b.start.compareTo(a.start));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveSessions(List<SessionRecord> records) {
    final sorted = [...records]..sort((a, b) => b.start.compareTo(a.start));
    return _prefs.setString(
      _kSessions,
      jsonEncode([for (final r in sorted.take(_maxSessions)) r.toJson()]),
    );
  }

  /// Remembers a session the user opened. Reopening the same session keeps
  /// its packing ticks and answer.
  Future<void> recordSession(SessionRecord record) {
    final others = <SessionRecord>[];
    SessionRecord? existing;
    for (final r in sessionRecords) {
      if (r.id == record.id) {
        existing = r;
      } else {
        others.add(r);
      }
    }
    final merged = existing == null
        ? record
        : record.copyWith(
            packed: existing.packed,
            allPacked: existing.allPacked,
            status: existing.status,
          );
    return _saveSessions([merged, ...others]);
  }

  Future<void> updateSession(
    String id,
    SessionRecord Function(SessionRecord) change,
  ) {
    return _saveSessions([
      for (final r in sessionRecords) r.id == id ? change(r) : r,
    ]);
  }

  /// All feedback answers, oldest first.
  List<FeedbackEntry> get feedback {
    try {
      final encoded = _prefs.getString(_kFeedback);
      return encoded == null ? const [] : FeedbackEntry.decodeList(encoded);
    } catch (_) {
      return const [];
    }
  }

  Future<void> addFeedback(FeedbackEntry entry) => _prefs.setString(
    _kFeedback,
    FeedbackEntry.encodeList([...feedback, entry]),
  );

  Future<void> deleteFeedback(String id) => _prefs.setString(
    _kFeedback,
    FeedbackEntry.encodeList(feedback.where((e) => e.id != id).toList()),
  );

  /// Settings sliders: sport → body part → −2 … +2.
  Map<Sport, Map<BodyPart, int>> get comfortManual {
    try {
      final encoded = _prefs.getString(_kManual);
      if (encoded == null) return const {};
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return {
        for (final e in json.entries)
          Sport.values.byName(e.key): {
            for (final p in (e.value as Map<String, dynamic>).entries)
              BodyPart.values.byName(p.key): p.value as int,
          },
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> setComfortManual(Sport sport, BodyPart part, int value) {
    final all = {
      for (final e in comfortManual.entries) e.key: {...e.value},
    };
    (all[sport] ??= {})[part] = value;
    return _prefs.setString(
      _kManual,
      jsonEncode({
        for (final e in all.entries)
          e.key.name: {for (final p in e.value.entries) p.key.name: p.value},
      }),
    );
  }

  /// "Forget" choices: profile key → answers up to then are ignored.
  Map<String, DateTime> get comfortForgotten {
    try {
      final encoded = _prefs.getString(_kForgotten);
      if (encoded == null) return const {};
      return {
        for (final e in (jsonDecode(encoded) as Map<String, dynamic>).entries)
          e.key: DateTime.parse(e.value as String),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> forgetLearned(
    Sport sport,
    BodyPart part,
    TempZone zone,
    DateTime now,
  ) {
    final all = {...comfortForgotten};
    all[ComfortProfile.key(sport, part, zone)] = now;
    return _prefs.setString(
      _kForgotten,
      jsonEncode({
        for (final e in all.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  ComfortProfile get comfortProfile => ComfortProfile(
    feedback: feedback,
    manualSettings: comfortManual,
    forgotten: comfortForgotten,
  );

  /// Clears feedback, sliders and "forget" choices.
  Future<void> resetComfort() async {
    await _prefs.remove(_kFeedback);
    await _prefs.remove(_kManual);
    await _prefs.remove(_kForgotten);
  }
}
