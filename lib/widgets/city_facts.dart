import 'package:flutter/material.dart';

import '../models.dart';

/// Small card with the headline numbers for one city.
class CityFactsCard extends StatelessWidget {
  const CityFactsCard({
    super.key,
    required this.city,
    required this.color,
    required this.useFahrenheit,
  });

  final City city;
  final Color color;
  final bool useFahrenheit;

  String _temp(double c) {
    final v = useFahrenheit ? celsiusToFahrenheit(c) : c;
    return '${v.toStringAsFixed(0)}°${useFahrenheit ? 'F' : 'C'}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${city.flag} ${city.name}',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${city.climate} · ${city.country}',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _fact(context, Icons.thermostat,
                'Year-round average: ${_temp(city.annualMeanC)}'),
            _fact(
                context,
                Icons.wb_sunny_outlined,
                'Warmest: ${monthNames[city.hottestMonth]} '
                '(${_temp(city.highC[city.hottestMonth])} days)'),
            _fact(
                context,
                Icons.ac_unit,
                'Coolest: ${monthNames[city.coldestMonth]} '
                '(${_temp(city.lowC[city.coldestMonth])} nights)'),
            _fact(
                context,
                Icons.water_drop_outlined,
                'Rain: ${city.annualPrecipMm.round()} mm/year, '
                'peaks in ${monthNames[city.wettestMonth]}'),
          ],
        ),
      ),
    );
  }

  Widget _fact(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
