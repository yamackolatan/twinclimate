import 'package:flutter/material.dart';

import '../similarity.dart';

/// Big "Twin Score" badge shown between the two selected cities.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.result,
    required this.sameCity,
  });

  final TwinResult result;
  final bool sameCity;

  Color _scoreColor(double s) {
    if (s >= 85) return const Color(0xFF2E7D32);
    if (s >= 70) return const Color(0xFF00796B);
    if (s >= 50) return const Color(0xFFF9A825);
    if (s >= 30) return const Color(0xFFEF6C00);
    return const Color(0xFF8D6E63);
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result.score);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TWIN SCORE',
              style: textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${result.score.round()}',
              style: textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              sameCity ? "That's the same city!" : scoreLabel(result.score),
              style: textTheme.titleMedium?.copyWith(color: color),
            ),
            if (result.seasonsFlipped && !sameCity)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(
                      'seasons offset by 6 months',
                      style: textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
