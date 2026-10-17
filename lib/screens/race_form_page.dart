import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/race.dart';
import '../models/session.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';
import '../widgets/place_search_sheet.dart';

/// What the race form ended with.
class RaceFormOutcome {
  const RaceFormOutcome.saved(Race this.race) : deleted = false;
  const RaceFormOutcome.deleted()
      : race = null,
        deleted = true;

  final Race? race;
  final bool deleted;
}

/// Add or edit a target race (F2). Saves to the store itself and pops with
/// a [RaceFormOutcome], or null if the user backed out.
class RaceFormPage extends StatefulWidget {
  const RaceFormPage({
    super.key,
    required this.store,
    required this.weather,
    this.existing,
  });

  final PrefsStore store;
  final WeatherService weather;

  /// The race being edited; null when adding a new one.
  final Race? existing;

  @override
  State<RaceFormPage> createState() => _RaceFormPageState();
}

class _RaceFormPageState extends State<RaceFormPage> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  Place? _place;
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);

  /// Selected legs keyed by sport; shown in [legOrder].
  final Map<Sport, RaceLeg> _legs = {};
  final Map<Sport, TextEditingController> _distanceText = {};
  final Map<Sport, String?> _distanceError = {};
  String? _formError;

  @override
  void initState() {
    super.initState();
    final race = widget.existing;
    if (race != null) {
      _place = race.place;
      _date = race.date;
      _time = TimeOfDay(hour: race.startHour, minute: race.startMinute);
      for (final leg in race.legs) {
        _setLeg(leg);
      }
    } else {
      _setLeg(defaultLeg(Sport.run));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _distanceText.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  List<RaceLeg> get _orderedLegs => [
        for (final sport in legOrder)
          if (_legs.containsKey(sport)) _legs[sport]!,
      ];

  void _setLeg(RaceLeg leg) {
    _legs[leg.sport] = leg;
    final text = _trimNumber(leg.distanceKm);
    final controller = _distanceText[leg.sport];
    if (controller == null) {
      _distanceText[leg.sport] = TextEditingController(text: text);
    } else if (controller.text != text) {
      controller.text = text;
    }
    _distanceError[leg.sport] = null;
  }

  void _toggleSport(Sport sport, bool selected) {
    setState(() {
      if (selected) {
        _setLeg(defaultLeg(sport));
      } else if (_legs.length > 1) {
        _legs.remove(sport);
      }
    });
  }

  void _applyPreset(RacePreset preset) {
    setState(() {
      _legs.clear();
      for (final leg in preset.legs) {
        _setLeg(leg);
      }
    });
  }

  void _onDistanceChanged(Sport sport, String text) {
    final km = double.tryParse(text.trim().replaceAll(',', '.'));
    setState(() {
      if (km == null || km <= 0) {
        _distanceError[sport] = 'Enter a distance';
        return;
      }
      _distanceError[sport] = null;
      _legs[sport] = _legs[sport]!.copyWith(
        distanceKm: km,
        minutes: RaceLeg.estimateMinutes(sport, km).clamp(5, 16 * 60 + 55),
      );
    });
  }

  void _setMinutes(Sport sport, {int? hours, int? minutes}) {
    final current = _legs[sport]!.minutes;
    final h = hours ?? current ~/ 60;
    final m = minutes ?? current % 60;
    setState(() => _legs[sport] = _legs[sport]!.copyWith(minutes: h * 60 + m));
  }

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
    final initial = _date ?? today.add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: _date != null && _date!.isBefore(today) ? _date! : today,
      lastDate: today.add(const Duration(days: 3 * 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Race? _buildRace() {
    if (_place == null) {
      _formError = 'Pick the race location.';
      return null;
    }
    if (_date == null) {
      _formError = 'Pick the race date.';
      return null;
    }
    if (_distanceError.values.any((e) => e != null)) {
      _formError = 'Fix the distances above.';
      return null;
    }
    if (_legs.values.any((leg) => leg.minutes <= 0)) {
      _formError = 'Every leg needs an expected time.';
      return null;
    }
    _formError = null;
    final name = _name.text.trim();
    return Race(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.isEmpty ? '${_place!.name} race' : name,
      place: _place!,
      date: DateTime(_date!.year, _date!.month, _date!.day),
      startHour: _time.hour,
      startMinute: _time.minute,
      legs: _orderedLegs,
    );
  }

  Future<void> _save() async {
    var race = _buildRace();
    setState(() {});
    if (race == null) return;
    final previous = widget.existing?.fingerprint;
    if (previous != null && previous.key == race.fingerprintKey) {
      race = race.withFingerprint(previous);
    }
    final saved = await widget.store.saveRace(race);
    if (!mounted) return;
    if (!saved) {
      setState(() => _formError =
          'You can save up to $maxRaces races. Delete one to add another.');
      return;
    }
    Navigator.of(context).pop(RaceFormOutcome.saved(race));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this race?'),
        content: Text('"${widget.existing!.name}" and its race-day climate '
            'will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.store.deleteRace(widget.existing!.id);
    if (mounted) Navigator.of(context).pop(const RaceFormOutcome.deleted());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final presets = presetsFor(_legs.keys.toSet());
    final preview = Race(
      id: '',
      name: '',
      place: _place ?? presetPlaces.first,
      date: _date ?? DateTime.now(),
      startHour: _time.hour,
      startMinute: _time.minute,
      legs: _orderedLegs,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit race' : 'Add a race'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete race',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
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
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Race name',
                      hintText: 'e.g. Ironman Kalmar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _tile(
                    icon: Icons.location_on_outlined,
                    title: _place?.name ?? 'Pick the race location',
                    subtitle: _place?.subtitle,
                    trailing: Icons.search,
                    onTap: _pickPlace,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                          icon: Icons.calendar_today,
                          title: _date == null
                              ? 'Race date'
                              : formatFullDate(_date!),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _tile(
                          icon: Icons.schedule,
                          title: 'Start ${_time.hour.toString().padLeft(2, '0')}'
                              ':${_time.minute.toString().padLeft(2, '0')}',
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Sports in this race',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final sport in legOrder)
                        FilterChip(
                          label: Text(sport.label),
                          avatar: Icon(sportIcon(sport), size: 18),
                          selected: _legs.containsKey(sport),
                          onSelected: (selected) =>
                              _toggleSport(sport, selected),
                        ),
                    ],
                  ),
                  if (presets.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Quick fill', style: muted),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in presets)
                          ActionChip(
                            label: Text(preset.label),
                            onPressed: () => _applyPreset(preset),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final window in preview.legWindows)
                    _legCard(window, preview),
                  const SizedBox(height: 8),
                  Text(
                    preview.isMultisport
                        ? '${preview.legTimeline}\n'
                            'Total ${formatDuration(preview.totalMinutes / 60)}'
                            ' (changeovers between legs are not counted).'
                        : 'Race hours: ${preview.windowLabel} '
                            '(${formatDuration(preview.totalMinutes / 60)}).',
                    style: muted,
                  ),
                  const SizedBox(height: 24),
                  if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_formError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.check),
                    label: Text(_isEditing ? 'Save changes' : 'Save race'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legCard(LegWindow window, Race preview) {
    final sport = window.leg.sport;
    final leg = _legs[sport]!;
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sportIcon(sport), size: 20),
                const SizedBox(width: 8),
                Text(sport.label, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${preview.clockAt(window.startOffset)}–'
                  '${preview.clockAt(window.endOffset)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    key: ValueKey('distance-${sport.name}'),
                    controller: _distanceText[sport],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (text) => _onDistanceChanged(sport, text),
                    decoration: InputDecoration(
                      labelText: 'Distance',
                      suffixText: 'km',
                      errorText: _distanceError[sport],
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text('Expected time', style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  key: ValueKey('hours-${sport.name}'),
                  value: (leg.minutes ~/ 60).clamp(0, 16),
                  items: [
                    for (var h = 0; h <= 16; h++)
                      DropdownMenuItem(value: h, child: Text('$h h')),
                  ],
                  onChanged: (h) => _setMinutes(sport, hours: h),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  key: ValueKey('minutes-${sport.name}'),
                  value: (leg.minutes % 60) ~/ 5 * 5,
                  items: [
                    for (var m = 0; m < 60; m += 5)
                      DropdownMenuItem(
                          value: m,
                          child: Text('${m.toString().padLeft(2, '0')} min')),
                  ],
                  onChanged: (m) => _setMinutes(sport, minutes: m),
                ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    IconData? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle:
            subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
        trailing: trailing == null ? null : Icon(trailing),
        onTap: onTap,
      ),
    );
  }
}

IconData sportIcon(Sport sport) => switch (sport) {
      Sport.run => Icons.directions_run,
      Sport.bike => Icons.directions_bike,
      Sport.swim => Icons.pool,
    };

String _trimNumber(double value) => value
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'0+$'), '')
    .replaceFirst(RegExp(r'\.$'), '');
