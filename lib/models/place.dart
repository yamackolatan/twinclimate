import 'dart:convert';

/// A spot where a training session can happen, with exact coordinates.
class Place {
  const Place({
    required this.name,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.isPreset = false,
  });

  final String name;

  /// Admin area (province / state). May be empty.
  final String region;

  /// May be empty.
  final String country;

  final double latitude;
  final double longitude;

  /// True for the spots bundled with the app (shown as quick picks).
  final bool isPreset;

  String get subtitle =>
      [region, country].where((part) => part.isNotEmpty).join(', ');

  /// Same physical spot (coordinates within ~100 m and same name).
  bool sameSpot(Place other) =>
      name == other.name &&
      (latitude - other.latitude).abs() < 0.001 &&
      (longitude - other.longitude).abs() < 0.001;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        name: json['name'] as String,
        region: json['region'] as String? ?? '',
        country: json['country'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'region': region,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };

  static String encodeList(List<Place> places) =>
      jsonEncode([for (final p in places) p.toJson()]);

  static List<Place> decodeList(String encoded) => [
        for (final item in jsonDecode(encoded) as List)
          Place.fromJson(item as Map<String, dynamic>),
      ];
}

/// Bundled quick-pick training spots (Istanbul area, per the PRD).
const List<Place> presetPlaces = [
  Place(
    name: 'Belgrad Forest',
    region: 'Istanbul',
    country: 'Türkiye',
    latitude: 41.1839,
    longitude: 28.9869,
    isPreset: true,
  ),
  Place(
    name: 'Kilyos',
    region: 'Istanbul',
    country: 'Türkiye',
    latitude: 41.2503,
    longitude: 29.0397,
    isPreset: true,
  ),
  Place(
    name: 'Caddebostan',
    region: 'Istanbul',
    country: 'Türkiye',
    latitude: 40.9622,
    longitude: 29.0570,
    isPreset: true,
  ),
];
