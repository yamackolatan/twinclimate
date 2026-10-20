import 'dart:convert';

import 'package:http/http.dart' as http;

/// Turns coordinates into a human place name ("Ouderkerk aan de Amstel"). Returns null when
/// no name is available; callers fall back to "38 km north".
abstract class PlaceNamer {
  Future<String?> nameFor(double latitude, double longitude);
}

/// OpenStreetMap's free reverse geocoder (Nominatim). Its usage policy
/// allows at most one request per second, so requests are spaced out; the
/// app only names its few final results.
class OsmPlaceNamer implements PlaceNamer {
  OsmPlaceNamer({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  static const _spacing = Duration(milliseconds: 1100);

  /// Most specific useful label first.
  static const _addressKeys = [
    'village',
    'town',
    'suburb',
    'hamlet',
    'neighbourhood',
    'quarter',
    'city_district',
    'city',
    'municipality',
    'county',
    'state',
  ];

  @override
  Future<String?> nameFor(double latitude, double longitude) async {
    final wait = _lastRequest.add(_spacing).difference(DateTime.now());
    if (!wait.isNegative) await Future<void>.delayed(wait);
    _lastRequest = DateTime.now();
    try {
      final response = await _client
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'format': 'jsonv2',
              'lat': latitude.toStringAsFixed(5),
              'lon': longitude.toStringAsFixed(5),
              'zoom': '14',
              'accept-language': 'en',
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>? ?? const {};
      for (final key in _addressKeys) {
        final value = address[key];
        if (value is String && value.isNotEmpty) return value;
      }
      final name = json['name'];
      return name is String && name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }
}
