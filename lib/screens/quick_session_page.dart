import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/session.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';
import '../widgets/place_search_sheet.dart';
import 'session_result_page.dart';

/// The default screen: plan a training session in a few taps and get
/// conditions + kit advice (F1 in the PRD).
class QuickSessionPage extends StatefulWidget {
  const QuickSessionPage({super.key, required this.store, required this.weather});

  final PrefsStore store;
  final WeatherService weather;

  @override
  State<QuickSessionPage> createState() => _QuickSessionPageState();
}

class _QuickSessionPageState extends State<QuickSessionPage> {
  late Sport _sport = widget.store.lastSport;
  Place? _place;
  late DateTime _date = DateTime.now().add(const Duration(days: 1));
  late TimeOfDay _time;
  late final Map<Sport, double> _distanceKm = {
    for (final sport in Sport.values) sport: widget.store.distanceFor(sport),
  };

  @override
  void initState() {
    super.initState();
    final (hour, minute) = widget.store.lastStartTime;
    _time = TimeOfDay(hour: hour, minute: minute);
    final saved = widget.store.savedPlaces;
    if (saved.isNotEmpty) _place = saved.first;
  }

  DateTime get _start =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  SessionPlan? get _plan => _place == null
      ? null
      : SessionPlan(
          sport: _sport,
          place: _place!,
          start: _start,
          distanceKm: _distanceKm[_sport]!,
        );

  Future<void> _pickPlace() async {
    final place = await PlaceSearchSheet.show(
      context,
      weather: widget.weather,
      savedPlaces: widget.store.savedPlaces,
    );
    if (place != null) setState(() => _place = place);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      // Open-Meteo forecasts reach 16 days out.
      lastDate: today.add(const Duration(days: 15)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _go() async {
    final plan = _plan;
    if (plan == null) return;
    await widget.store.rememberPlace(plan.place);
    await widget.store.rememberSport(plan.sport);
    await widget.store.rememberDistance(plan.sport, plan.distanceKm);
    await widget.store.rememberStartTime(_time.hour, _time.minute);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          SessionResultPage(plan: plan, weather: widget.weather),
    ));
    // Saved places may have changed order; refresh chips.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final quickPicks = [...presetPlaces, ...widget.store.savedPlaces];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terrain),
            SizedBox(width: 8),
            Text('TwinClimate', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Quick Session',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Where and when are you training? We\'ll tell you what '
                    'it\'ll be like and what to wear.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // Sport
                  SegmentedButton<Sport>(
                    segments: const [
                      ButtonSegment(
                          value: Sport.run,
                          label: Text('Run'),
                          icon: Icon(Icons.directions_run)),
                      ButtonSegment(
                          value: Sport.bike,
                          label: Text('Bike'),
                          icon: Icon(Icons.directions_bike)),
                      ButtonSegment(
                          value: Sport.swim,
                          label: Text('Swim'),
                          icon: Icon(Icons.pool)),
                    ],
                    selected: {_sport},
                    onSelectionChanged: (selection) =>
                        setState(() => _sport = selection.first),
                  ),
                  const SizedBox(height: 16),

                  // Place
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(_place?.name ?? 'Pick a place'),
                          subtitle: _place == null
                              ? const Text('Search or tap a quick pick below')
                              : (_place!.subtitle.isEmpty
                                  ? null
                                  : Text(_place!.subtitle)),
                          trailing: const Icon(Icons.search),
                          onTap: _pickPlace,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final place in quickPicks)
                                ChoiceChip(
                                  label: Text(place.name),
                                  avatar: place.isPreset
                                      ? const Icon(Icons.star, size: 18)
                                      : const Icon(Icons.history, size: 18),
                                  selected: _place != null &&
                                      _place!.sameSpot(place),
                                  onSelected: (_) =>
                                      setState(() => _place = place),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date & time
                  Row(
                    children: [
                      Expanded(
                        child: _pickerTile(
                          icon: Icons.calendar_today,
                          label: formatDay(_date),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _pickerTile(
                          icon: Icons.schedule,
                          label:
                              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Distance',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        formatDistance(_distanceKm[_sport]!),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Slider(
                    value: _distanceKm[_sport]!
                        .clamp(_sport.minKm, _sport.maxKm),
                    min: _sport.minKm,
                    max: _sport.maxKm,
                    divisions: _sport.sliderDivisions,
                    label: formatDistance(_distanceKm[_sport]!),
                    onChanged: (km) =>
                        setState(() => _distanceKm[_sport] = km),
                  ),
                  if (plan != null)
                    Text(
                      'About ${plan.durationLabel} for a typical pace — '
                      'we\'ll show the weather for ${plan.windowLabel}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: plan == null ? null : _go,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.checkroom),
                    label: const Text('What should I wear?'),
                  ),
                  if (plan == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Pick a place first.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}
