import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/device_services.dart' as device;
import '../services/place_namer.dart';
import '../services/weather_service.dart';

/// Bottom sheet for picking a place: presets and saved places first,
/// live Open-Meteo geocoding results as you type. Pops with the chosen
/// [Place], or null if dismissed.
class PlaceSearchSheet extends StatefulWidget {
  const PlaceSearchSheet({
    super.key,
    required this.weather,
    required this.savedPlaces,
    this.namer,
    this.locate = device.currentPosition,
  });

  final WeatherService weather;
  final List<Place> savedPlaces;

  /// Names "my location"; defaults to OpenStreetMap.
  final PlaceNamer? namer;

  /// The device position, as (latitude, longitude) or null.
  final Future<(double, double)?> Function() locate;

  static Future<Place?> show(
    BuildContext context, {
    required WeatherService weather,
    required List<Place> savedPlaces,
    PlaceNamer? namer,
  }) {
    return showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PlaceSearchSheet(
          weather: weather,
          savedPlaces: savedPlaces,
          namer: namer,
        ),
      ),
    );
  }

  @override
  State<PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<PlaceSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<Place> _results = const [];
  bool _searching = false;
  bool _locating = false;
  String? _error;

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    final position = await widget.locate();
    if (!mounted) return;
    if (position == null) {
      setState(() {
        _locating = false;
        _error =
            'Couldn\'t get your location. Allow location access for this '
            'site in your browser, or search for the place instead.';
      });
      return;
    }
    final (lat, lon) = position;
    String? name;
    try {
      name = await (widget.namer ?? OsmPlaceNamer()).nameFor(lat, lon);
    } catch (_) {
      name = null;
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      Place(
        name: name ?? 'My location',
        region: 'Your location',
        country: '',
        latitude: lat,
        longitude: lon,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    setState(() => _query = query);
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await widget.weather.searchPlaces(query);
      if (!mounted || _query != query) return;
      setState(() {
        _results = results;
        _searching = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || _query != query) return;
      setState(() {
        _results = const [];
        _searching = false;
        _error = e is WeatherServiceException
            ? e.message
            : 'Place search failed. Try again in a moment.';
      });
    }
  }

  /// Presets and saved places that match what's typed (all of them when
  /// nothing is typed yet).
  List<Place> get _localMatches {
    final all = [...presetPlaces, ...widget.savedPlaces];
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return [
      for (final p in all)
        if (p.name.toLowerCase().contains(q)) p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final local = _localMatches;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search any town, park or beach…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          if (_searching || _locating) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                if (_query.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.my_location),
                    title: const Text('Use my location'),
                    subtitle: const Text('Weather for exactly where you are'),
                    enabled: !_locating,
                    onTap: _useMyLocation,
                  ),
                if (local.isNotEmpty) ...[
                  _sectionLabel(
                    context,
                    _query.isEmpty ? 'Your spots' : 'Your matching spots',
                  ),
                  for (final place in local)
                    _placeTile(
                      place,
                      icon: place.isPreset ? Icons.star : Icons.history,
                    ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_results.isNotEmpty) ...[
                  _sectionLabel(context, 'Search results'),
                  for (final place in _results)
                    _placeTile(place, icon: Icons.location_on_outlined),
                ],
                if (_query.length >= 2 &&
                    !_searching &&
                    _error == null &&
                    _results.isEmpty &&
                    local.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No places found — try a different spelling.'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _placeTile(Place place, {required IconData icon}) => ListTile(
    leading: Icon(icon),
    title: Text(place.name),
    subtitle: place.subtitle.isEmpty ? null : Text(place.subtitle),
    onTap: () => Navigator.of(context).pop(place),
  );
}
