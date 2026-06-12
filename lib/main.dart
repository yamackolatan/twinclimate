import 'package:flutter/material.dart';

import 'data.dart';
import 'models.dart';
import 'similarity.dart';
import 'widgets/city_facts.dart';
import 'widgets/rain_chart.dart';
import 'widgets/score_card.dart';
import 'widgets/temp_chart.dart';
import 'widgets/twin_list.dart';

void main() {
  runApp(const TwinClimateApp());
}

class TwinClimateApp extends StatelessWidget {
  const TwinClimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TwinClimate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00696D),
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const _colorA = Color(0xFF00696D);
  static const _colorB = Color(0xFFB3541E);

  late final TabController _tab = TabController(length: 2, vsync: this);

  City _cityA = cities.firstWhere((c) => c.name == 'London');
  City _cityB = cities.firstWhere((c) => c.name == 'Seattle');
  City _homeCity = cities.firstWhere((c) => c.name == 'Istanbul');
  bool _useFahrenheit = false;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _pickTwin(City city) {
    setState(() {
      _cityA = _homeCity;
      _cityB = city;
    });
    _tab.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, color: _colorA),
            SizedBox(width: 8),
            Text('TwinClimate',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('°C')),
                ButtonSegment(value: true, label: Text('°F')),
              ],
              selected: {_useFahrenheit},
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onSelectionChanged: (selection) =>
                  setState(() => _useFahrenheit = selection.first),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Compare cities'),
            Tab(text: 'Find my climate twin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildCompareTab(context),
          _buildFindTab(context),
        ],
      ),
    );
  }

  Widget _buildCompareTab(BuildContext context) {
    final result = twinScore(_cityA, _cityB);
    final sameCity = _cityA == _cityB;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Pick two cities and see how alike their climates are.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    _cityPicker(
                      label: 'First city',
                      value: _cityA,
                      color: _colorA,
                      onChanged: (c) => setState(() => _cityA = c),
                    ),
                    IconButton(
                      tooltip: 'Swap cities',
                      onPressed: () => setState(() {
                        final tmp = _cityA;
                        _cityA = _cityB;
                        _cityB = tmp;
                      }),
                      icon: const Icon(Icons.swap_horiz),
                    ),
                    _cityPicker(
                      label: 'Second city',
                      value: _cityB,
                      color: _colorB,
                      onChanged: (c) => setState(() => _cityB = c),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ScoreCard(result: result, sameCity: sameCity),
                const SizedBox(height: 16),
                _chartCard(
                  context,
                  title: 'Monthly temperatures',
                  explainer:
                      'Thick line = average day high · thin line = average '
                      'night low · shaded band = typical daily range',
                  chartHeight: 280,
                  chart: TempChart(
                    a: _cityA,
                    b: _cityB,
                    colorA: _colorA,
                    colorB: _colorB,
                    useFahrenheit: _useFahrenheit,
                  ),
                ),
                const SizedBox(height: 16),
                _chartCard(
                  context,
                  title: 'Monthly rainfall',
                  explainer: 'Average precipitation per month, in millimeters',
                  chartHeight: 220,
                  chart: RainChart(
                    a: _cityA,
                    b: _cityB,
                    colorA: _colorA,
                    colorB: _colorB,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final factsA = CityFactsCard(
                      city: _cityA,
                      color: _colorA,
                      useFahrenheit: _useFahrenheit,
                    );
                    final factsB = CityFactsCard(
                      city: _cityB,
                      color: _colorB,
                      useFahrenheit: _useFahrenheit,
                    );
                    if (constraints.maxWidth > 640) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: factsA),
                          const SizedBox(width: 16),
                          Expanded(child: factsB),
                        ],
                      );
                    }
                    return Column(
                      children: [factsA, const SizedBox(height: 16), factsB],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Based on approximate 1991–2020 climate normals for '
                  '${cities.length} world cities. Twin Score compares '
                  'month-by-month day highs, night lows and rainfall '
                  '(100 = identical climate).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFindTab(BuildContext context) {
    final ranked = rankTwins(_homeCity, cities);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: _cityPicker(
                label: 'Your city',
                value: _homeCity,
                color: _colorA,
                onChanged: (c) => setState(() => _homeCity = c),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Cities ranked by how closely their climate matches '
                '${_homeCity.name}. Tap one to compare in detail.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: TwinList(ranked: ranked, onPick: _pickTwin)),
          ],
        ),
      ),
    );
  }

  Widget _cityPicker({
    required String label,
    required City value,
    required Color color,
    required void Function(City) onChanged,
  }) {
    return DropdownMenu<City>(
      label: Text(label),
      initialSelection: value,
      width: 280,
      menuHeight: 360,
      leadingIcon: Icon(Icons.location_on_outlined, color: color),
      dropdownMenuEntries: [
        for (final city in cities)
          DropdownMenuEntry(
            value: city,
            label: '${city.flag} ${city.name}, ${city.country}',
          ),
      ],
      onSelected: (city) {
        if (city != null) onChanged(city);
      },
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required String explainer,
    required double chartHeight,
    required Widget chart,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                _legendDot(_colorA, _cityA.name),
                _legendDot(_colorB, _cityB.name),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              explainer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: chartHeight, width: double.infinity, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
