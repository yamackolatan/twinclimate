import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/weather_text.dart';
import '../models/session.dart';
import '../models/weather.dart';

/// Hour-by-hour forecast for the session window as one timeline card:
/// a column per hour with sky, temperature, a rain-chance bar and wind.
/// Up to six hours share the full width; longer sessions scroll sideways.
class HourCards extends StatelessWidget {
  const HourCards({super.key, required this.hours});

  final List<HourWeather> hours;

  static const _maxFitting = 6;
  static const _scrollColumnWidth = 76.0;

  @override
  Widget build(BuildContext context) {
    final columns = [for (final h in hours) _HourColumn(hour: h)];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: hours.length <= _maxFitting
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final c in columns) Expanded(child: c)],
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in columns)
                      SizedBox(width: _scrollColumnWidth, child: c),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HourColumn extends StatelessWidget {
  const _HourColumn({required this.hour});

  final HourWeather hour;

  static const _barHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final rain = hour.precipProbabilityPercent.clamp(0, 100) / 100;
    final rainColor = scheme.brightness == Brightness.dark
        ? const Color(0xFF8DB8FF)
        : const Color(0xFF1F5FBF);
    return Semantics(
      label:
          '${formatTime(hour.time)}: ${hour.temperatureC.round()} degrees, '
          'feels like ${hour.apparentC.round()}, '
          '${hour.precipProbabilityPercent.round()} percent chance of rain, '
          'wind ${hour.windKmh.round()} kilometres per hour',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            formatTime(hour.time),
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Icon(
            weatherIcon(hour.weatherCode, isDay: hour.isDay),
            color: scheme.primary,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            '${hour.temperatureC.round()}°',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text('feels ${hour.apparentC.round()}°', style: muted),
          const SizedBox(height: 8),
          // Rain chance as a bar.
          SizedBox(
            height: _barHeight,
            width: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: math.max(rain * _barHeight, rain > 0 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: rainColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${hour.precipProbabilityPercent.round()}%',
            style: text.labelMedium?.copyWith(color: rainColor),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              Text('${hour.windKmh.round()}', style: muted),
            ],
          ),
          Text('km/h', style: muted),
        ],
      ),
    );
  }
}
