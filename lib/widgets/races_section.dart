import 'package:flutter/material.dart';

import '../logic/fingerprint_text.dart';
import '../models/race.dart';
import '../models/session.dart';
import '../screens/race_detail_page.dart';
import '../screens/race_form_page.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';

/// "My races" on the home screen: up to [maxRaces] race cards, or an
/// optional invitation to add one. The app works fully without a race.
class RacesSection extends StatefulWidget {
  const RacesSection({
    super.key,
    required this.store,
    required this.weather,
    this.onChanged,
  });

  final PrefsStore store;
  final WeatherService weather;

  /// Called after races may have been added, edited or deleted.
  final VoidCallback? onChanged;

  @override
  State<RacesSection> createState() => _RacesSectionState();
}

class _RacesSectionState extends State<RacesSection> {
  Future<void> _add() async {
    final outcome = await Navigator.of(context).push<RaceFormOutcome>(
      MaterialPageRoute(
        builder: (context) =>
            RaceFormPage(store: widget.store, weather: widget.weather),
      ),
    );
    if (!mounted) return;
    setState(() {});
    widget.onChanged?.call();
    final race = outcome?.race;
    // Straight to the race-day climate, which starts computing at once.
    if (race != null) await _open(race);
  }

  Future<void> _open(Race race) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RaceDetailPage(
          raceId: race.id,
          store: widget.store,
          weather: widget.weather,
        ),
      ),
    );
    if (mounted) setState(() {});
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final races = widget.store.races;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (races.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: ListTile(
          leading: const Icon(Icons.emoji_events_outlined),
          title: const Text('Training for a race?'),
          subtitle: const Text(
            'Optional: add it to see its typical race-day weather.',
          ),
          trailing: const Icon(Icons.add),
          onTap: _add,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('My races', style: theme.textTheme.titleMedium),
            ),
            if (races.length < maxRaces)
              TextButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Add race'),
              ),
          ],
        ),
        for (final race in races) _raceCard(race),
        if (races.length >= maxRaces)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Up to $maxRaces races – delete one to add another.',
              style: muted,
            ),
          ),
      ],
    );
  }

  Widget _raceCard(Race race) {
    final theme = Theme.of(context);
    final fingerprint = race.validFingerprint;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Icon(
          race.isMultisport
              ? Icons.emoji_events
              : sportIcon(race.legs.first.sport),
        ),
        title: Text(race.name),
        subtitle: Text(
          '${formatFullDate(race.date)} · '
          '${countdownText(race.date, DateTime.now())}\n'
          '${fingerprint == null ? 'Tap to see race-day climate' : fingerprintShortLine(fingerprint)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(race),
      ),
    );
  }
}
