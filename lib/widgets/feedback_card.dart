import 'package:flutter/material.dart';

import '../logic/feedback_logic.dart';
import '../models/comfort.dart';
import '../models/gear.dart';
import '../models/place.dart';
import '../models/session.dart';
import '../services/prefs_store.dart';
import '../services/weather_service.dart';

enum _Step { feeling, where, worn, saving, done }

/// The post-session question on the home screen (F4): how did it feel →
/// optional where → (only on uncomfortable days, and only if the packing
/// checklist doesn't already tell us) did you wear what we suggested?
class FeedbackCard extends StatefulWidget {
  const FeedbackCard({
    super.key,
    required this.record,
    required this.store,
    required this.weather,
    required this.onDone,
    this.clock = DateTime.now,
  });

  final SessionRecord record;
  final PrefsStore store;
  final WeatherService weather;
  final VoidCallback onDone;
  final DateTime Function() clock;

  @override
  State<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<FeedbackCard> {
  _Step _step = _Step.feeling;
  Feeling? _feeling;
  BodyPart? _part;
  String _message = '';

  SessionRecord get r => widget.record;

  String get _activity => switch (r.sport) {
    Sport.run => 'run',
    Sport.bike => 'ride',
    Sport.swim => 'swim',
  };

  void _pickFeeling(Feeling feeling) {
    _feeling = feeling;
    if (feeling == Feeling.justRight) {
      _save(Worn.unknown);
    } else {
      setState(() => _step = _Step.where);
    }
  }

  void _pickPart(BodyPart? part) {
    _part = part;
    if (r.packedSuggestionFor(part)) {
      // The packing checklist already says they wore our suggestion.
      _save(Worn.asSuggested);
    } else {
      setState(() => _step = _Step.worn);
    }
  }

  Future<void> _save(Worn worn) async {
    setState(() => _step = _Step.saving);
    final (feelsC, measured) = await _recordedFeelsLike();
    final entry = FeedbackEntry(
      id: '${r.id}#${widget.clock().microsecondsSinceEpoch}',
      sport: r.sport,
      date: r.start,
      feelsC: feelsC,
      measured: measured,
      feeling: _feeling!,
      part: _part,
      worn: worn,
    );
    final before = widget.store.comfortProfile;
    await widget.store.addFeedback(entry);
    await widget.store.updateSession(
      r.id,
      (s) => s.copyWith(status: SessionStatus.answered),
    );
    final after = widget.store.comfortProfile;
    if (!mounted) return;
    final differs = measured && (feelsC - r.forecastFeelsC).abs() >= 3;
    setState(() {
      _message =
          '${differs ? 'It actually felt like ${feelsC.round()}° '
                    '(the forecast said ${r.forecastFeelsC.round()}°). ' : ''}'
          '${learnedMessage(before, after, entry)}';
      _step = _Step.done;
    });
  }

  /// The session's actual recorded "feels like" (owner decision 5); falls
  /// back to the forecast that was shown if it can't be fetched.
  Future<(double, bool)> _recordedFeelsLike() async {
    try {
      final hours = await widget.weather.fetchHourly(
        place: Place(
          name: r.placeName,
          region: '',
          country: '',
          latitude: r.latitude,
          longitude: r.longitude,
        ),
        firstDay: r.start,
        lastDay: r.end,
      );
      final firstSlot = DateTime(
        r.start.year,
        r.start.month,
        r.start.day,
        r.start.hour,
      );
      final during = [
        for (final h in hours)
          if (!h.time.isBefore(firstSlot) && h.time.isBefore(r.end))
            h.apparentC,
      ];
      if (during.isEmpty) return (r.forecastFeelsC, false);
      return (during.reduce((a, b) => a + b) / during.length, true);
    } catch (_) {
      return (r.forecastFeelsC, false);
    }
  }

  Future<void> _close(SessionStatus status) async {
    await widget.store.updateSession(r.id, (s) => s.copyWith(status: status));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (_step) {
              _Step.feeling => _feelingStep(theme),
              _Step.where => _whereStep(theme),
              _Step.worn => _wornStep(theme),
              _Step.saving => [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
              ],
              _Step.done => _doneStep(theme),
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _feelingStep(ThemeData theme) => [
    Text(
      'How did your $_activity at ${r.placeName} feel?',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 2),
    Text(
      '${formatDay(r.start)} · ${formatTime(r.start)}–'
      '${formatTime(r.end)} · forecast felt like '
      '${r.forecastFeelsC.round()}°',
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _choice(Icons.ac_unit, 'Too cold', () => _pickFeeling(Feeling.tooCold)),
        _choice(
          Icons.check,
          'Just right',
          () => _pickFeeling(Feeling.justRight),
        ),
        _choice(
          Icons.wb_sunny_outlined,
          'Too warm',
          () => _pickFeeling(Feeling.tooWarm),
        ),
      ],
    ),
    const SizedBox(height: 4),
    Wrap(
      children: [
        TextButton(
          onPressed: () => _close(SessionStatus.didntGo),
          child: const Text('I didn\'t go'),
        ),
        TextButton(
          onPressed: () => _close(SessionStatus.dismissed),
          child: const Text('Not now'),
        ),
      ],
    ),
  ];

  List<Widget> _whereStep(ThemeData theme) => [
    Text(
      _feeling == Feeling.tooWarm
          ? 'Where did you feel too warm?'
          : 'Where did you feel too cold?',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final part in BodyPart.values)
          _choice(null, part.label, () => _pickPart(part)),
        _choice(null, 'Everywhere', () => _pickPart(null)),
      ],
    ),
  ];

  List<Widget> _wornStep(ThemeData theme) {
    final part = _part;
    final suggested = part == null ? null : r.suggested[part];
    final question = part == null
        ? 'Did you wear the kit we suggested?'
        : suggested == null
        ? 'We suggested nothing extra for your '
              '${part.label.toLowerCase()}. Did you wear something there?'
        : 'We suggested: $suggested. Did you wear that?';
    return [
      Text(
        question,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: part != null && suggested == null
            ? [
                _choice(null, 'No, nothing', () => _save(Worn.asSuggested)),
                _choice(null, 'Yes, something', () => _save(Worn.warmer)),
              ]
            : [
                _choice(null, 'Yes', () => _save(Worn.asSuggested)),
                _choice(null, 'Something warmer', () => _save(Worn.warmer)),
                _choice(null, 'Something lighter', () => _save(Worn.lighter)),
              ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => _save(Worn.unknown),
          child: const Text('Skip'),
        ),
      ),
    ];
  }

  List<Widget> _doneStep(ThemeData theme) => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lightbulb_outline),
        const SizedBox(width: 8),
        Expanded(child: Text(_message, style: theme.textTheme.bodyLarge)),
      ],
    ),
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(onPressed: widget.onDone, child: const Text('Done')),
    ),
  ];

  Widget _choice(IconData? icon, String label, VoidCallback onTap) =>
      icon == null
      ? OutlinedButton(onPressed: onTap, child: Text(label))
      : OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        );
}
