import 'package:shared_preferences/shared_preferences.dart';

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
    return Sport.values
        .firstWhere((s) => s.name == name, orElse: () => Sport.run);
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
      _kRaces, Race.encodeList(races.where((r) => r.id != id).toList()));
}
