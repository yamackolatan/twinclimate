import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';
import '../models/session.dart';

/// Local, on-device storage (works on Flutter web via browser storage).
/// MVP persistence per the PRD: favourite places and last-used session
/// defaults. Race, comfort profile and feedback history will join later.
class PrefsStore {
  PrefsStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kPlaces = 'favouritePlaces';
  static const _kSport = 'lastSport';
  static const _kDistancePrefix = 'lastDistanceKm.';
  static const _kStartHour = 'lastStartHour';
  static const _kStartMinute = 'lastStartMinute';

  static Future<PrefsStore> load() async =>
      PrefsStore._(await SharedPreferences.getInstance());

  /// Places the user has searched and used, most recent first. Presets are
  /// not stored — they're always available from [presetPlaces].
  List<Place> get savedPlaces {
    final encoded = _prefs.getString(_kPlaces);
    if (encoded == null) return const [];
    try {
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
}
