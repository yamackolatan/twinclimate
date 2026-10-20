import 'package:flutter/material.dart';

import '../data/decathlon_catalogue.dart';
import '../models/product.dart';
import '../services/prefs_store.dart';

/// What a retail partner would see: how often suggestions were shown,
/// opened and clicked through to the shop. Counted on this device only —
/// a demo for conversations with brands and investors.
class PartnerDemoPage extends StatefulWidget {
  const PartnerDemoPage({super.key, required this.store});

  final PrefsStore store;

  @override
  State<PartnerDemoPage> createState() => _PartnerDemoPageState();
}

class _PartnerDemoPageState extends State<PartnerDemoPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final stats = widget.store.shopStats;
    int total(String event) => stats.entries
        .where((e) => e.key.startsWith('$event:'))
        .fold(0, (sum, e) => sum + e.value);
    List<MapEntry<String, int>> top(String event) =>
        stats.entries
            .where((e) => e.key.startsWith('$event:'))
            .map((e) => MapEntry(e.key.substring(event.length + 1), e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final shown = total('shown');
    final opened = total('opened');
    final clicked = total('clicked');
    final owned = total('owned');
    final categories = {for (final p in decathlonCatalogue) p.category};
    final products = {for (final p in decathlonCatalogue) p.id: p};

    return Scaffold(
      appBar: AppBar(title: const Text('Partner demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'How shopping suggestions perform',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Counted on this device only, no personal data. In a partner '
            'version these numbers would come from all users.',
            style: muted,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tile('Suggestions shown', '$shown'),
              _Tile('Opened', '$opened'),
              _Tile('Clicks to shop', '$clicked'),
              _Tile('"Already have it"', '$owned'),
              _Tile(
                'Shown → shop',
                shown == 0 ? '–' : '${(100 * clicked / shown).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Most opened needs', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          ..._rows(
            top('opened'),
            (key) => key == 'race_kit'
                ? 'Race-day kit'
                : _capitalised(productCategories[key] ?? key),
            muted,
          ),
          const SizedBox(height: 16),
          Text('Most clicked products', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          ..._rows(top('clicked'), (id) => products[id]?.name ?? id, muted),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How it works', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    '• Products are matched to the kit the weather calls for '
                    '(type and function), with the reason shown.\n'
                    '• At most 3 links per kit list, rain/wind gear first; '
                    'never for gear the user already has.\n'
                    '• Race-day picks are the best-rated sellers for the '
                    'race\'s typical weather.\n'
                    '• Demo catalogue: ${decathlonCatalogue.length} '
                    'decathlon.nl products in ${categories.length} types, '
                    'prices and ratings as listed in $catalogueDate.\n'
                    '• Links are plain shop links today; a partner '
                    'version would add affiliate tracking.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.store.resetShopStats();
              setState(() {});
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset counters'),
          ),
        ],
      ),
    );
  }

  List<Widget> _rows(
    List<MapEntry<String, int>> entries,
    String Function(String key) label,
    TextStyle? muted,
  ) {
    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Nothing yet.', style: muted),
        ),
      ];
    }
    return [
      for (final e in entries.take(5))
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(label(e.key)),
          trailing: Text('${e.value}'),
        ),
    ];
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

String _capitalised(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
