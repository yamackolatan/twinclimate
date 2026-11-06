import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/weather_text.dart';
import '../models/session.dart';
import '../models/weather.dart';

/// Horizontal strip of per-hour forecast cards for the session window.
class HourCards extends StatelessWidget {
  const HourCards({super.key, required this.hours});

  final List<HourWeather> hours;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Grows with the phone's text size setting.
      height: MediaQuery.textScalerOf(context).scale(150) + 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _HourCard(hour: hours[index]),
      ),
    );
  }
}

class _HourCard extends StatelessWidget {
  const _HourCard({required this.hour});

  final HourWeather hour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatTime(hour.time),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              weatherIcon(hour.weatherCode, isDay: hour.isDay),
              color: scheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              '${hour.temperatureC.round()}°',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'feels ${hour.apparentC.round()}°',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.umbrella, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  '${hour.precipProbabilityPercent.round()}%',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                if (hour.windDirectionDeg != null)
                  Tooltip(
                    message:
                        'Wind from the ${compassPoint(hour.windDirectionDeg!)}',
                    // The arrow points where the wind blows to.
                    child: Transform.rotate(
                      angle: (hour.windDirectionDeg! + 180) * math.pi / 180,
                      child: Icon(
                        Icons.navigation,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Icon(Icons.air, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  '${hour.windKmh.round()} km/h',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
