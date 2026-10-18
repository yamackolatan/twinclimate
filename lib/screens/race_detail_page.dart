import 'package:flutter/material.dart';

import '../logic/fingerprint_text.dart';
import '../models/fingerprint.dart';
import '../models/race.dart';
import '../models/session.dart';
import '../services/fingerprint_service.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';
import 'race_form_page.dart';

/// A saved race and its typical race-day climate (F2). Computes and caches
/// the fingerprint the first time it is opened.
class RaceDetailPage extends StatefulWidget {
  const RaceDetailPage({
    super.key,
    required this.raceId,
    required this.store,
    required this.weather,
    this.fingerprints,
  });

  final String raceId;
  final PrefsStore store;
  final WeatherService weather;

  /// Injectable for tests; defaults to one built on [weather].
  final FingerprintService? fingerprints;

  @override
  State<RaceDetailPage> createState() => _RaceDetailPageState();
}

class _RaceDetailPageState extends State<RaceDetailPage> {
  late final FingerprintService _service =
      widget.fingerprints ?? FingerprintService(widget.weather);

  Race? _race;
  bool _loading = false;
  int _done = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _race = widget.store.raceById(widget.raceId);
    if (_race != null && _race!.validFingerprint == null) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _compute();
      });
    }
  }

  Future<void> _compute() async {
    final race = _race!;
    setState(() {
      _loading = true;
      _error = null;
      _done = 0;
    });
    try {
      final fingerprint = await _service.compute(
        race,
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _done = done;
              _total = total;
            });
          }
        },
      );
      // Cache it even if the user has left the page, unless the race was
      // edited or deleted in the meantime.
      final latest = widget.store.raceById(race.id);
      if (latest != null && latest.fingerprintKey == fingerprint.key) {
        await widget.store.saveRace(latest.withFingerprint(fingerprint));
      }
      if (!mounted) return;
      setState(() {
        _race = widget.store.raceById(race.id);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is WeatherServiceException
            ? e.message
            : 'Something went wrong while looking up past weather: $e';
      });
    }
  }

  Future<void> _edit() async {
    final outcome = await Navigator.of(context).push<RaceFormOutcome>(
      MaterialPageRoute(
        builder: (context) => RaceFormPage(
          store: widget.store,
          weather: widget.weather,
          existing: _race,
        ),
      ),
    );
    if (!mounted || outcome == null) return;
    if (outcome.deleted) {
      Navigator.of(context).pop();
      return;
    }
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final race = _race;
    if (race == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This race no longer exists.')),
      );
    }
    final fingerprint = race.validFingerprint;
    return Scaffold(
      appBar: AppBar(
        title: Text(race.name),
        actions: [
          IconButton(
            tooltip: 'Edit race',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _loading ? null : _edit,
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
                  _RaceHeader(race: race),
                  const SizedBox(height: 16),
                  if (_loading) _progress(race),
                  if (_error != null) _errorBox(),
                  if (fingerprint != null)
                    _FingerprintView(race: race, fingerprint: fingerprint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progress(Race race) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Looking at 10 years of weather in ${race.place.name}…',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _total == 0 ? null : _done / _total),
            const SizedBox(height: 8),
            Text(
              _total == 0 ? 'Starting…' : '$_done of $_total years done',
              style: theme.textTheme.bodySmall,
            ),
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
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _compute,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "in 316 days" / "today" / "3 days ago"
String countdownText(DateTime raceDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(raceDate.year, raceDate.month, raceDate.day);
  final days = day.difference(today).inDays;
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days > 0) return 'in $days days';
  if (days == -1) return 'yesterday';
  return '${-days} days ago';
}

class _RaceHeader extends StatelessWidget {
  const _RaceHeader({required this.race});

  final Race race;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                [
                  race.place.name,
                  race.place.subtitle,
                ].where((s) => s.isNotEmpty).join(', '),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatFullDate(race.date)} · '
          '${countdownText(race.date, DateTime.now())}',
          style: muted,
        ),
        const SizedBox(height: 4),
        Text(
          race.isMultisport
              ? race.legTimeline
              : '${race.legs.first.sport.label} · ${race.windowLabel}',
          style: muted,
        ),
        Text(
          [
            for (final leg in race.legs)
              '${formatDistance(leg.distanceKm)} ${leg.sport.label.toLowerCase()}',
          ].join(' · '),
          style: muted,
        ),
      ],
    );
  }
}

class _FingerprintView extends StatelessWidget {
  const _FingerprintView({required this.race, required this.fingerprint});

  final Race race;
  final RaceFingerprint fingerprint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final profile = profileLine(race, fingerprint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Race-day climate', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              fingerprintHeadline(race, fingerprint),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (profile.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.show_chart, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(profile)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _ConditionTable(stats: fingerprint.overall),
        if (race.isMultisport) ...[
          const SizedBox(height: 24),
          Text('By leg', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final leg in fingerprint.legs)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Icon(sportIcon(leg.sport)),
                title: Text(
                  '${leg.sport.label} '
                  '${race.clockAt(leg.startOffset)}–'
                  '${race.clockAt(leg.endOffset)}',
                ),
                subtitle: Text(legLine(leg)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _ConditionTable(stats: leg.stats),
                  if (leg.sport == Sport.swim)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Water temperature isn\'t included yet — it\'s '
                        'planned for a later version.',
                        style: muted,
                      ),
                    ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(sourceNote(race, fingerprint), style: muted),
      ],
    );
  }
}

class _ConditionTable extends StatelessWidget {
  const _ConditionTable({required this.stats});

  final ConditionStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (label, value) in conditionRows(stats))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
