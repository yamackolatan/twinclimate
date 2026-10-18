import 'package:flutter/material.dart';

import '../models/matching.dart';
import '../models/session.dart';

/// Optional, collapsed sliders for power users: how much each condition
/// counts in the match score (PRD decision 9).
class WeightsPanel extends StatelessWidget {
  const WeightsPanel({
    super.key,
    required this.sport,
    required this.weights,
    required this.onChanged,
  });

  final Sport sport;
  final MatchWeights weights;
  final ValueChanged<MatchWeights> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final share = weights.normalised;
    Widget row(String label, double value, double shareValue,
            MatchWeights Function(double) update) =>
        Row(
          children: [
            SizedBox(width: 100, child: Text(label)),
            Expanded(
              child: Slider(
                value: value.clamp(0, 1),
                onChanged: (v) => onChanged(update(v)),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text('${(shareValue * 100).round()}%',
                  textAlign: TextAlign.end),
            ),
          ],
        );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: const Text('Advanced: what matters most'),
        subtitle: Text('Defaults for ${sport.label.toLowerCase()} training'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        children: [
          row('Temperature', weights.temperature, share.temperature,
              (v) => weights.copyWith(temperature: v)),
          row('Humidity', weights.humidity, share.humidity,
              (v) => weights.copyWith(humidity: v)),
          row('Wind', weights.wind, share.wind,
              (v) => weights.copyWith(wind: v)),
          row('Rain', weights.rain, share.rain,
              (v) => weights.copyWith(rain: v)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onChanged(MatchWeights.forSport(sport)),
              child: const Text('Reset to defaults'),
            ),
          ),
        ],
      ),
    );
  }
}
