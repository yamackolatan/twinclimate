import 'package:flutter/material.dart';

import '../models/comfort.dart';
import '../models/gear.dart';
import '../models/session.dart';
import '../services/prefs_store.dart';

/// Settings → Comfort profile (F4): optional sliders per body part, what
/// the app has learned from feedback, and recent answers.
class ComfortProfilePage extends StatefulWidget {
  const ComfortProfilePage({super.key, required this.store});

  final PrefsStore store;

  @override
  State<ComfortProfilePage> createState() => _ComfortProfilePageState();
}

class _ComfortProfilePageState extends State<ComfortProfilePage> {
  static const _sliderLabels = {
    -2: 'Runs cold',
    -1: 'Slightly cold',
    0: 'Neutral',
    1: 'Slightly warm',
    2: 'Runs warm',
  };

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your comfort profile?'),
        content: const Text(
          'All feedback, sliders and learned preferences '
          'for every sport will be cleared. Kit suggestions go back to the '
          'standard ones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.store.resetComfort();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: Sport.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comfort profile'),
          bottom: TabBar(
            tabs: [for (final sport in Sport.values) Tab(text: sport.label)],
          ),
        ),
        body: TabBarView(
          children: [for (final sport in Sport.values) _sportTab(sport)],
        ),
      ),
    );
  }

  Widget _sportTab(Sport sport) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final profile = widget.store.comfortProfile;
    final learned = [
      for (final part in BodyPart.values)
        for (final zone in TempZone.values)
          if (profile.learned(sport, part, zone).reports > 0 ||
              profile.learned(sport, part, zone).steps != 0)
            (part, zone, profile.learned(sport, part, zone)),
    ];
    final recent = [
      for (final e in profile.feedback.reversed)
        if (e.sport == sport) e,
    ].take(10).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TwinClimate learns from the short question after each '
                  'session. You can also set it yourself here — completely '
                  'optional.',
                  style: muted,
                ),
                const SizedBox(height: 16),
                Text(
                  'How warm do you run?',
                  style: theme.textTheme.titleMedium,
                ),
                for (final part in BodyPart.values)
                  _sliderRow(sport, part, profile.manual(sport, part)),
                const SizedBox(height: 16),
                Text('What we\'ve learned', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                if (learned.isEmpty)
                  Text(
                    'Nothing yet — answer the short question after a '
                    '${sport.label.toLowerCase()} and we\'ll learn.',
                    style: muted,
                  ),
                for (final (part, zone, l) in learned)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${part.label} · runs '
                      '${l.net > 0 ? 'warm' : 'cold'} ${zone.phrase}',
                    ),
                    subtitle: Text(
                      l.steps == 0
                          ? '${l.reports} report${l.reports == 1 ? '' : 's'} '
                                '· one more matching report changes your kit'
                          : '${l.reports} reports · kit is '
                                '${l.steps.abs()} step${l.steps.abs() == 1 ? '' : 's'} '
                                '${l.steps > 0 ? 'lighter' : 'warmer'}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await widget.store.forgetLearned(
                          sport,
                          part,
                          zone,
                          DateTime.now(),
                        );
                        if (mounted) setState(() {});
                      },
                      child: const Text('Forget'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Recent feedback', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                if (recent.isEmpty) Text('No answers yet.', style: muted),
                for (final e in recent)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${formatDay(e.date)} · ${_feelingText(e)}'
                      '${e.part == null ? '' : ' · ${e.part!.label}'}',
                    ),
                    subtitle: Text(
                      'Felt like ${e.feelsC.round()}° '
                      '(${e.measured ? 'recorded weather' : 'forecast'})'
                      '${_wornText(e)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete this answer',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await widget.store.deleteFeedback(e.id);
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _resetAll,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset everything'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sliderRow(Sport sport, BodyPart part, int value) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(part.label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: -2,
            max: 2,
            divisions: 4,
            label: _sliderLabels[value],
            onChanged: (v) async {
              await widget.store.setComfortManual(sport, part, v.round());
              if (mounted) setState(() {});
            },
          ),
        ),
        SizedBox(
          width: 96,
          child: Text(_sliderLabels[value]!, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  static String _feelingText(FeedbackEntry e) => switch (e.feeling) {
    Feeling.tooCold => 'Too cold',
    Feeling.justRight => 'Just right',
    Feeling.tooWarm => 'Too warm',
  };

  static String _wornText(FeedbackEntry e) => switch (e.worn) {
    Worn.warmer => ' · wore something warmer than suggested',
    Worn.lighter => ' · wore something lighter than suggested',
    _ => '',
  };
}
