import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/fingerprint_text.dart';
import '../logic/match_engine.dart';
import '../logic/match_text.dart';
import '../models/matching.dart';
import '../models/place.dart';
import '../models/session.dart';
import '../services/fingerprint_service.dart';
import '../services/match_service.dart';
import '../services/place_namer.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';
import 'session_result_page.dart';

/// Race Matching results (F3): the best places and time windows to train
/// in race-like conditions.
class MatchResultPage extends StatefulWidget {
  const MatchResultPage({
    super.key,
    required this.request,
    required this.store,
    required this.weather,
    this.namer,
    this.matchService,
    this.fingerprints,
  });

  final MatchRequest request;
  final PrefsStore store;
  final WeatherService weather;

  /// Injectable for tests; default is OpenStreetMap.
  final PlaceNamer? namer;
  final MatchService? matchService;
  final FingerprintService? fingerprints;

  @override
  State<MatchResultPage> createState() => _MatchResultPageState();
}

class _MatchResultPageState extends State<MatchResultPage> {
  late final MatchService _matcher =
      widget.matchService ?? MatchService(widget.weather);
  late final PlaceNamer _namer = widget.namer ?? OsmPlaceNamer();
  late MatchRequest _request = widget.request;

  String _status = 'Starting…';
  MatchResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _result = null;
      _status = 'Starting…';
    });
    try {
      await _ensureFingerprint();
      final result = await _matcher.run(_request, onProgress: (status) {
        if (mounted) setState(() => _status = status);
      });
      if (!mounted) return;
      setState(() => _result = result);
      await _nameResults(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is WeatherServiceException
          ? e.message
          : 'Something went wrong while searching: $e');
    }
  }

  /// A race saved while offline may not have its race-day climate yet.
  Future<void> _ensureFingerprint() async {
    final race = _request.race;
    if (race.validFingerprint != null) return;
    setState(() =>
        _status = 'First looking at 10 years of weather in ${race.place.name}…');
    final fingerprint =
        await (widget.fingerprints ?? FingerprintService(widget.weather))
            .compute(race);
    final updated = race.withFingerprint(fingerprint);
    await widget.store.saveRace(updated);
    _request = MatchRequest(
      race: updated,
      sport: _request.sport,
      home: _request.home,
      distanceKm: _request.distanceKm,
      rangeKm: _request.rangeKm,
      mode: _request.mode,
      date: _request.date,
      periodDays: _request.periodDays,
      weights: _request.weights,
      window: _request.window,
    );
  }

  /// Fills in place names one by one; results show "38 km north" until then.
  Future<void> _nameResults(MatchResult result) async {
    for (var i = 0; i < result.results.length; i++) {
      final spot = result.results[i].spot;
      final name = spot.isHome
          ? _request.home.name
          : await _namer.nameFor(spot.latitude, spot.longitude);
      if (!mounted) return;
      if (name == null) continue;
      setState(() {
        final current = _result!.results[i];
        final renamed = PlaceResult(
          spot: current.spot.copyWith(name: name),
          best: current.best,
          windowFirstStart: current.windowFirstStart,
          windowLastStart: current.windowLastStart,
          durationMinutes: current.durationMinutes,
          dayScores: current.dayScores,
        );
        _result = MatchResult(
          target: _result!.target,
          results: [..._result!.results]..[i] = renamed,
          spotsChecked: _result!.spotsChecked,
          notes: _result!.notes,
        );
      });
    }
  }

  void _openSession(PlaceResult r) {
    final place = Place(
      name: spotTitle(r.spot),
      region: r.spot.name == null ? '' : spotDirection(r.spot),
      country: '',
      latitude: r.spot.latitude,
      longitude: r.spot.longitude,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SessionResultPage(
        plan: SessionPlan(
          sport: _request.sport,
          place: place,
          start: r.best.start,
          distanceKm: _request.distanceKm,
        ),
        weather: widget.weather,
      ),
    ));
  }

  Future<void> _openMap(Spot spot) async {
    final lat = spot.latitude.toStringAsFixed(5);
    final lon = spot.longitude.toStringAsFixed(5);
    await launchUrl(
      Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lon'
          '#map=13/$lat/$lon'),
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Race-like conditions')),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _searchSummary(),
                  const SizedBox(height: 16),
                  if (_error != null)
                    _errorBox()
                  else if (result == null)
                    _progress()
                  else
                    ..._results(result),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchSummary() {
    final theme = Theme.of(context);
    final r = _request;
    final target = _result?.target ?? MatchTarget.forRace(r.race, r.sport);
    final when = r.mode == MatchMode.specificDate
        ? formatDay(r.date)
        : 'best day in the next ${r.periodDays} days';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Matching ${r.race.name}', style: theme.textTheme.titleLarge),
        if (target != null) ...[
          const SizedBox(height: 4),
          Text('${_capitalised(target.label)}: typically '
              '${conditionsLine(target.stats)}'),
        ],
        const SizedBox(height: 4),
        Text(
          '${formatDistance(r.distanceKm)} ${r.sport.label.toLowerCase()} '
          '(about ${formatDuration(r.durationHours)}) · within '
          '${r.rangeKm.round()} km of ${r.home.name} · $when · '
          'training ${r.window.label}'
          '${r.window.daylightOnly ? ' (daylight only)' : ''}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _progress() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _errorBox() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: _run, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(MatchResult result) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (result.results.isEmpty) {
      return [
        Text('No suitable time found', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final note in result.notes) Text(note),
      ];
    }
    final weak = result.bestScore < goodMatchScore;
    return [
      if (weak)
        Card(
          elevation: 0,
          color: theme.colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best available: ${scoreText(result.bestScore)} — no close '
                  'match within ${_request.rangeKm.round()} km',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer),
                ),
                const SizedBox(height: 8),
                for (final note in result.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $note',
                        style: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer)),
                  ),
              ],
            ),
          ),
        ),
      for (var i = 0; i < result.results.length; i++)
        _ResultCard(
          rank: i + 1,
          result: result.results[i],
          target: result.target,
          onSession: () => _openSession(result.results[i]),
          onMap: () => _openMap(result.results[i].spot),
        ),
      const SizedBox(height: 12),
      if (_request.sport == Sport.swim)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Spots are not checked for safe open-water access — check '
            'before you go. Water temperature is not included yet.',
            style: muted,
          ),
        ),
      Text(
        'Checked ${result.spotsChecked} spots on land and every hourly start '
        'time in your training window (${_request.window.label}'
        '${_request.window.daylightOnly ? ', daylight only' : ''}). '
        '100% means race-typical conditions; 70% or '
        'more is within the normal range of race days. The bars show the '
        'score for each start time; the highlighted ones are the good '
        'window.',
        style: muted,
      ),
    ];
  }
}

String _capitalised(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.rank,
    required this.result,
    required this.target,
    required this.onSession,
    required this.onMap,
  });

  final int rank;
  final PlaceResult result;
  final MatchTarget target;
  final VoidCallback onSession;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final details = spotDetails(result.spot);
    final good = result.best.score >= goodMatchScore;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('$rank. ${spotTitle(result.spot)}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: good
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('${scoreText(result.best.score)} match',
                      style: theme.textTheme.labelLarge),
                ),
              ],
            ),
            if (details.isNotEmpty) Text(details, style: muted),
            const SizedBox(height: 8),
            Text(bestStartText(result), style: theme.textTheme.bodyMedium),
            Text(windowText(result),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ScoreBars(result: result),
            const SizedBox(height: 8),
            Text(comparisonParts(result.best.conditions, target.stats)
                .join(' · ')),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onSession,
                  icon: const Icon(Icons.checkroom, size: 18),
                  label: const Text('See forecast & kit'),
                ),
                TextButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Open in map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Score for each start time on the best day; the good window is
/// highlighted.
class _ScoreBars extends StatelessWidget {
  const _ScoreBars({required this.result});

  final PlaceResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final option in result.dayScores)
            Expanded(
              child: Tooltip(
                message: '${formatTime(option.start)}: '
                    '${scoreText(option.score)}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 4 + 32 * option.score / 100,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: _inWindow(option.start)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _showLabel(option)
                          ? option.start.hour.toString().padLeft(2, '0')
                          : '',
                      style: small,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _showLabel(MatchOption option) {
    final scores = result.dayScores;
    if (scores.length <= 6) return true;
    final i = scores.indexOf(option);
    return i == 0 || i == scores.length - 1 || i % 3 == 0;
  }

  bool _inWindow(DateTime start) =>
      !start.isBefore(result.windowFirstStart) &&
      !start.isAfter(result.windowLastStart);
}
