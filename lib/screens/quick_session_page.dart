import 'package:flutter/material.dart';

import '../logic/feedback_logic.dart';
import '../logic/match_engine.dart';
import '../models/comfort.dart';
import '../models/matching.dart';
import '../models/place.dart';
import '../models/race.dart';
import '../models/session.dart';
import '../services/place_namer.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';
import '../widgets/feedback_card.dart';
import '../widgets/place_search_sheet.dart';
import '../widgets/races_section.dart';
import '../widgets/weights_panel.dart';
import 'comfort_profile_page.dart';
import 'match_result_page.dart';
import 'session_result_page.dart';

/// The default screen: plan a training session in a few taps and get
/// conditions + kit advice (F1 in the PRD).
class QuickSessionPage extends StatefulWidget {
  const QuickSessionPage({
    super.key,
    required this.store,
    required this.weather,
    this.namer,
  });

  final PrefsStore store;
  final WeatherService weather;

  /// Names race-matching results; defaults to OpenStreetMap.
  final PlaceNamer? namer;

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

  // Race Matching (F3) settings.
  bool _matching = false;
  String? _raceId;
  double _rangeKm = 50;
  MatchMode _mode = MatchMode.specificDate;
  int _periodDays = 14;
  late TrainingWindow _window = widget.store.trainingWindow;
  final Map<Sport, MatchWeights> _weights = {
    for (final sport in Sport.values) sport: MatchWeights.forSport(sport),
  };

  List<Race> get _races => widget.store.races;

  Race? get _selectedRace {
    final races = _races;
    if (races.isEmpty) return null;
    return races.firstWhere((r) => r.id == _raceId, orElse: () => races.first);
  }

  @override
  void initState() {
    super.initState();
    final (hour, minute) = widget.store.lastStartTime;
    _time = TimeOfDay(hour: hour, minute: minute);
    final saved = widget.store.savedPlaces;
    if (saved.isNotEmpty) _place = saved.first;
    _refreshFeedback();
  }

  /// The finished session to ask "How did it feel?" about (F4), if any.
  SessionRecord? _feedbackRecord;

  Future<void> _refreshFeedback() async {
    final pick = pickSessionToAsk(
      widget.store.sessionRecords,
      widget.store.comfortProfile,
      DateTime.now(),
    );
    if (pick.skip != null) {
      // Profile is stable here: quietly skip this one ("ask less").
      await widget.store.updateSession(
        pick.skip!.id,
        (r) => r.copyWith(status: SessionStatus.skippedStable),
      );
    }
    if (mounted) setState(() => _feedbackRecord = pick.ask);
  }

  Future<void> _openComfortProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComfortProfilePage(store: widget.store),
      ),
    );
    if (mounted) setState(() {});
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionResultPage(
          plan: plan,
          weather: widget.weather,
          store: widget.store,
        ),
      ),
    );
    // Saved places may have changed order; refresh chips.
    if (mounted) setState(() {});
    _refreshFeedback();
  }

  Future<void> _findMatches() async {
    final place = _place;
    final race = _selectedRace;
    if (place == null || race == null) return;
    await widget.store.rememberPlace(place);
    await widget.store.rememberSport(_sport);
    await widget.store.rememberDistance(_sport, _distanceKm[_sport]!);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchResultPage(
          request: MatchRequest(
            race: race,
            sport: _sport,
            home: (
              name: place.name,
              latitude: place.latitude,
              longitude: place.longitude,
            ),
            distanceKm: _distanceKm[_sport]!,
            rangeKm: _rangeKm,
            mode: _mode,
            date: _date,
            periodDays: _periodDays,
            weights: _weights[_sport]!,
            window: _window,
          ),
          store: widget.store,
          weather: widget.weather,
          namer: widget.namer,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final matching = _matching && _races.isNotEmpty;
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
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
        actions: [
          IconButton(
            tooltip: 'Comfort profile',
            icon: const Icon(Icons.accessibility_new),
            onPressed: _openComfortProfile,
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
                  if (_feedbackRecord != null) ...[
                    FeedbackCard(
                      key: ValueKey(_feedbackRecord!.id),
                      record: _feedbackRecord!,
                      store: widget.store,
                      weather: widget.weather,
                      onDone: _refreshFeedback,
                    ),
                    const SizedBox(height: 16),
                  ],
                  RacesSection(
                    store: widget.store,
                    weather: widget.weather,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  if (_races.isNotEmpty) ...[
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Quick Session'),
                          icon: Icon(Icons.checkroom),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Match my race'),
                          icon: Icon(Icons.travel_explore),
                        ),
                      ],
                      selected: {matching},
                      onSelectionChanged: (selection) =>
                          setState(() => _matching = selection.first),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    matching ? 'Match my race' : 'Quick Session',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    matching
                        ? 'Where and when, near you, will training feel most '
                              'like race day?'
                        : 'Where and when are you training? We\'ll tell you '
                              'what it\'ll be like and what to wear.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (matching) ..._racePicker(),

                  // Sport
                  SegmentedButton<Sport>(
                    segments: const [
                      ButtonSegment(
                        value: Sport.run,
                        label: Text('Run'),
                        icon: Icon(Icons.directions_run),
                      ),
                      ButtonSegment(
                        value: Sport.bike,
                        label: Text('Bike'),
                        icon: Icon(Icons.directions_bike),
                      ),
                      ButtonSegment(
                        value: Sport.swim,
                        label: Text('Swim'),
                        icon: Icon(Icons.pool),
                      ),
                    ],
                    selected: {_sport},
                    onSelectionChanged: (selection) =>
                        setState(() => _sport = selection.first),
                  ),
                  const SizedBox(height: 16),

                  // Place
                  if (matching)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Starting point', style: muted),
                    ),
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
                                  selected:
                                      _place != null && _place!.sameSpot(place),
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

                  if (matching) ..._matchOptions(muted),
                  // Date & time
                  if (!matching)
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
                      Text(
                        'Distance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        formatDistance(_distanceKm[_sport]!),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Slider(
                    value: _distanceKm[_sport]!.clamp(
                      _sport.minKm,
                      _sport.maxKm,
                    ),
                    min: _sport.minKm,
                    max: _sport.maxKm,
                    divisions: _sport.sliderDivisions,
                    label: formatDistance(_distanceKm[_sport]!),
                    onChanged: (km) => setState(
                      () => _distanceKm[_sport] =
                          (km / _sport.stepKm).round() * _sport.stepKm,
                    ),
                  ),
                  if (plan != null && !matching)
                    Text(
                      'About ${plan.durationLabel} for a typical pace — '
                      'we\'ll show the weather for ${plan.windowLabel}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (matching) ...[
                    const SizedBox(height: 8),
                    WeightsPanel(
                      sport: _sport,
                      weights: _weights[_sport]!,
                      onChanged: (w) => setState(() => _weights[_sport] = w),
                    ),
                  ],
                  const SizedBox(height: 24),

                  if (matching)
                    FilledButton.icon(
                      onPressed: _place == null || !_windowFits
                          ? null
                          : _findMatches,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.travel_explore),
                      label: const Text('Find race-like conditions'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: plan == null ? null : _go,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (matching && plan != null && !_windowFits)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _window.isValid
                            ? noTimeFoundNote(_window, _matchMinutes)
                            : 'Set a finish time later than the start time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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

  List<Widget> _racePicker() {
    final races = _races;
    final race = _selectedRace!;
    return [
      if (races.length > 1)
        DropdownButtonFormField<String>(
          initialValue: race.id,
          decoration: const InputDecoration(
            labelText: 'Race to match',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final r in races)
              DropdownMenuItem(value: r.id, child: Text(r.name)),
          ],
          onChanged: (id) => setState(() => _raceId = id),
        )
      else
        Text(
          'Race to match: ${race.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _matchOptions(TextStyle? muted) => [
    const SizedBox(height: 8),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Travel range', style: Theme.of(context).textTheme.titleMedium),
        Text(
          '${_rangeKm.round()} km',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
    Slider(
      value: _rangeKm,
      min: 10,
      max: 300,
      divisions: 29,
      label: '${_rangeKm.round()} km',
      onChanged: (km) => setState(() => _rangeKm = km),
    ),
    Text('When', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    SegmentedButton<MatchMode>(
      segments: const [
        ButtonSegment(
          value: MatchMode.specificDate,
          label: Text('Specific date'),
        ),
        ButtonSegment(
          value: MatchMode.period,
          label: Text('Best day in a period'),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (selection) =>
          setState(() => _mode = selection.first),
    ),
    const SizedBox(height: 8),
    if (_mode == MatchMode.specificDate)
      _pickerTile(
        icon: Icons.calendar_today,
        label: formatDay(_date),
        onTap: _pickDate,
      )
    else
      Wrap(
        spacing: 8,
        children: [
          for (final days in const [7, 14])
            ChoiceChip(
              label: Text('Next $days days'),
              selected: _periodDays == days,
              onSelected: (_) => setState(() => _periodDays = days),
            ),
        ],
      ),
    const SizedBox(height: 4),
    Text(
      _mode == MatchMode.specificDate
          ? 'We\'ll find the best places and the best time window that '
                'day, within your training hours.'
          : 'We\'ll find the best day, place and time window, within your '
                'training hours.',
      style: muted,
    ),
    const SizedBox(height: 16),
    Text('When can you train?', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: _pickerTile(
            icon: Icons.wb_twilight,
            label: 'From ${TrainingWindow.clock(_window.fromMinutes)}',
            onTap: () => _pickWindowTime(from: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _pickerTile(
            icon: Icons.flag_outlined,
            label: 'Until ${TrainingWindow.clock(_window.untilMinutes)}',
            onTap: () => _pickWindowTime(from: false),
          ),
        ),
      ],
    ),
    Text(
      _window.isValid
          ? 'Earliest start and latest finish.'
          : 'The finish time must be later than the start time.',
      style: _window.isValid
          ? muted
          : TextStyle(color: Theme.of(context).colorScheme.error),
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Daylight only'),
      subtitle: const Text(
        'Only suggest sessions that start and finish before dark',
      ),
      value: _window.daylightOnly,
      onChanged: (value) => _setWindow(_window.copyWith(daylightOnly: value)),
    ),
    const SizedBox(height: 8),
  ];

  /// Minutes the current match session would take.
  int get _matchMinutes =>
      (_distanceKm[_sport]! * _sport.hoursPerKm * 60).round();

  bool get _windowFits => _window.isValid && _window.fits(_matchMinutes);

  void _setWindow(TrainingWindow window) {
    setState(() => _window = window);
    if (window.isValid) widget.store.rememberTrainingWindow(window);
  }

  Future<void> _pickWindowTime({required bool from}) async {
    final minutes = from ? _window.fromMinutes : _window.untilMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: from ? 'Earliest start' : 'Latest finish',
    );
    if (picked == null) return;
    final value = picked.hour * 60 + picked.minute;
    _setWindow(
      from
          ? _window.copyWith(fromMinutes: value)
          : _window.copyWith(untilMinutes: value),
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
      child: ListTile(leading: Icon(icon), title: Text(label), onTap: onTap),
    );
  }
}
