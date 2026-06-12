import 'package:flutter/material.dart';

import '../models.dart';
import '../similarity.dart';

/// Ranked list of the cities most similar to a chosen home city.
class TwinList extends StatelessWidget {
  const TwinList({
    super.key,
    required this.ranked,
    required this.onPick,
  });

  final List<(City, TwinResult)> ranked;
  final void Function(City) onPick;

  Color _scoreColor(double s) {
    if (s >= 85) return const Color(0xFF2E7D32);
    if (s >= 70) return const Color(0xFF00796B);
    if (s >= 50) return const Color(0xFFF9A825);
    if (s >= 30) return const Color(0xFFEF6C00);
    return const Color(0xFF8D6E63);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: ranked.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final (city, result) = ranked[index];
        final color = _scoreColor(result.score);
        return ListTile(
          onTap: () => onPick(city),
          leading: SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          title: Text('${city.flag} ${city.name}, ${city.country}'),
          subtitle: Text(
            result.seasonsFlipped
                ? '${city.climate} · seasons offset by 6 months'
                : city.climate,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              '${result.score.round()}',
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        );
      },
    );
  }
}
