import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/prefs_store.dart';
import '../widgets/product_sheet.dart';

/// Gear the user already has (from "I already have this" or packing
/// ticks; their shop links then show other models) — plus the switch that
/// turns shop suggestions off entirely.
class MyGearPage extends StatefulWidget {
  const MyGearPage({super.key, required this.store});

  final PrefsStore store;

  @override
  State<MyGearPage> createState() => _MyGearPageState();
}

class _MyGearPageState extends State<MyGearPage> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final owned = store.ownedTypes.toList()
      ..sort(
        (a, b) =>
            (productCategories[a] ?? a).compareTo(productCategories[b] ?? b),
      );
    return Scaffold(
      appBar: AppBar(title: const Text('My gear')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Shopping suggestions'),
            subtitle: const Text(
              'Show "Don\'t have one?" links to Decathlon next to your kit '
              'and race-day picks.',
            ),
            value: store.shopSuggestionsOn,
            onChanged: (on) async {
              await store.setShopSuggestionsOn(on);
              setState(() {});
            },
          ),
          const Divider(height: 32),
          Text('Gear you have', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Added when you tap "I already have this" or tick an item while '
            'packing. Their shop links stay, showing other models.',
            style: muted,
          ),
          const SizedBox(height: 8),
          if (owned.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing yet.', style: muted),
            ),
          for (final type in owned)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(productIcon(type)),
              title: Text(_capitalised(productCategories[type] ?? type)),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await store.unmarkOwned(type);
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }
}

String _capitalised(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
