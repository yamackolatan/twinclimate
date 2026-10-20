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
///
/// Multiple answers are allowed (owner request, Oct 2026): "too warm" and
/// "too cold" together (e.g. warm torso, cold hands) and several body parts
/// for each. Each feeling + body part is stored as its own answer.
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

  /// Chosen discomforts: too cold and/or too warm.
  final Set<Feeling> _feelings = {};

  /// Body parts per chosen feeling; `null` in the set means "Everywhere".
  final Map<Feeling, Set<BodyPart?>> _parts = {
    Feeling.tooCold: {},
    Feeling.tooWarm: {},
  };
  String _message = '';

  /// Every (feeling, body part) answer, in a stable order.
  List<(Feeling, BodyPart?)> get _answers => [
    for (final f in [Feeling.tooWarm, Feeling.tooCold])
      if (_feelings.contains(f))
        for (final p in [...BodyPart.values, null])
          if (_parts[f]!.contains(p)) (f, p),
  ];

  SessionRecord get r => widget.record;

  String get _activity => switch (r.sport) {
    Sport.run => 'run',
    Sport.bike => 'ride',
    Sport.swim => 'swim',
  };

  void _toggleFeeling(Feeling feeling) => setState(() {
    _feelings.contains(feeling)
        ? _feelings.remove(feeling)
        : _feelings.add(feeling);
  });

  void _justRight() {
    _feelings
      ..clear()
      ..add(Feeling.justRight);
    _save(Worn.unknown);
  }

  /// "Everywhere" and specific parts exclude each other, and a body part
  /// can't be both too warm and too cold.
  void _togglePart(Feeling feeling, BodyPart? part) => setState(() {
    final set = _parts[feeling]!;
    if (set.contains(part)) {
      set.remove(part);
      return;
    }
    if (part == null) {
      set.clear();
    } else {
      set.remove(null);
      for (final other in _parts.entries) {
        if (other.key != feeling) other.value.remove(part);
      }
    }
    set.add(part);
  });

  bool get _whereComplete =>
      _feelings.every((f) => _parts[f]!.isNotEmpty) && _feelings.isNotEmpty;

  void _finishWhere() {
    // The packing checklist already shows the suggestions were packed.
    if (_answers.every((a) => r.packedSuggestionFor(a.$2))) {
      _save(Worn.asSuggested);
    } else {
      setState(() => _step = _Step.worn);
    }
  }

  Future<void> _save(Worn worn) async {
    setState(() => _step = _Step.saving);
    final (feelsC, measured) = await _recordedFeelsLike();
    final stamp = widget.clock().microsecondsSinceEpoch;
    final answers = _feelings.contains(Feeling.justRight)
        ? [(Feeling.justRight, null)]
        : _answers;
    final entries = [
      for (var i = 0; i < answers.length; i++)
        FeedbackEntry(
          id: '${r.id}#$stamp#$i',
          sport: r.sport,
          date: r.start,
          feelsC: feelsC,
          measured: measured,
          feeling: answers[i].$1,
          part: answers[i].$2,
          worn: worn,
        ),
    ];
    final before = widget.store.comfortProfile;
    for (final entry in entries) {
      await widget.store.addFeedback(entry);
    }
    await widget.store.updateSession(
      r.id,
      (s) => s.copyWith(status: SessionStatus.answered),
    );
    final after = widget.store.comfortProfile;
    if (!mounted) return;
    final differs = measured && (feelsC - r.forecastFeelsC).abs() >= 3;
    final learned = <String>{
      for (final entry in entries) learnedMessage(before, after, entry),
    }.join('\n');
    setState(() {
      _message =
          '${differs ? 'It actually felt like ${feelsC.round()}° '
                    '(the forecast said ${r.forecastFeelsC.round()}°).\n' : ''}'
          '$learned';
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
        _choice(Icons.thumb_up_alt_outlined, 'Just right', _justRight),
        _toggle(
          Icons.ac_unit,
          'Too cold',
          _feelings.contains(Feeling.tooCold),
          () => _toggleFeeling(Feeling.tooCold),
        ),
        _toggle(
          Icons.wb_sunny_outlined,
          'Too warm',
          _feelings.contains(Feeling.tooWarm),
          () => _toggleFeeling(Feeling.tooWarm),
        ),
      ],
    ),
    if (_feelings.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        _feelings.length == 2
            ? 'Both: some parts too cold, others too warm.'
            : 'You can pick both if some parts were too cold and others '
                  'too warm.',
        style: theme.textTheme.bodySmall,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () => setState(() => _step = _Step.where),
          child: const Text('Next'),
        ),
      ),
    ],
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
    for (final feeling in [Feeling.tooWarm, Feeling.tooCold])
      if (_feelings.contains(feeling)) ...[
        Text(
          feeling == Feeling.tooWarm
              ? 'Where did you feel too warm?'
              : 'Where did you feel too cold?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final part in [...BodyPart.values, null])
              _toggle(
                null,
                part?.label ?? 'Everywhere',
                _parts[feeling]!.contains(part),
                () => _togglePart(feeling, part),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    Text('Pick one or more.', style: theme.textTheme.bodySmall),
    Align(
      alignment: Alignment.centerRight,
      child: FilledButton(
        onPressed: _whereComplete ? _finishWhere : null,
        child: const Text('Done'),
      ),
    ),
  ];

  List<Widget> _wornStep(ThemeData theme) {
    // One specific body part: name the item. Several: ask once for all.
    final answers = _answers;
    final part = answers.length == 1 ? answers.single.$2 : null;
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

  /// A selectable answer (several can be on at once).
  Widget _toggle(
    IconData? icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: icon == null || selected ? null : Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      // Selected answers must stand out against the card's own colour.
      selectedColor: scheme.primary,
      checkmarkColor: scheme.onPrimary,
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimary : scheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
      backgroundColor: scheme.surface,
      side: BorderSide(color: selected ? scheme.primary : scheme.outline),
    );
  }

  Widget _choice(IconData? icon, String label, VoidCallback onTap) =>
      icon == null
      ? OutlinedButton(onPressed: onTap, child: Text(label))
      : OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        );
}
