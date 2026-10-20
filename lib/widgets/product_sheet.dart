import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/decathlon_catalogue.dart';
import '../models/product.dart';
import '../services/prefs_store.dart';

/// Shown wherever products appear (owner: honest, not pushy).
const String shopDisclosure =
    'Shop links go to decathlon.nl. Demo — not affiliated with Decathlon.';

/// A bottom sheet with 1–3 decathlon.nl products for one need, plus
/// "I already have this" (saved in My gear; the link then offers other
/// models instead of disappearing).
class ProductSheet extends StatelessWidget {
  const ProductSheet({
    super.key,
    required this.title,
    required this.why,
    required this.products,
    required this.types,
    this.store,
    this.owned = false,
  });

  /// e.g. "Light water-resistant jacket".
  final String title;

  /// Why this is suggested (the kit item's reason).
  final String why;
  final List<Product> products;

  /// Product types this need covers; marked owned by "I already have this".
  final List<String> types;
  final PrefsStore? store;

  /// The user already has this (shown as "other models").
  final bool owned;

  /// Opens the sheet; returns true when the user said they have it.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String why,
    required List<Product> products,
    required List<String> types,
    PrefsStore? store,
    bool owned = false,
  }) async {
    for (final type in types) {
      store?.countShop('opened', type);
    }
    final saidOwned = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProductSheet(
        title: title,
        why: why,
        products: products.take(3).toList(),
        types: types,
        store: store,
        owned: owned,
      ),
    );
    return saidOwned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(why, style: muted),
              const SizedBox(height: 12),
              Text(
                owned ? 'Other models at Decathlon' : 'Options at Decathlon',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              for (final product in products)
                ProductTile(product: product, store: store),
              const SizedBox(height: 4),
              if (owned)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'You have one — saved in My gear',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    await store?.markOwned(types);
                    for (final type in types) {
                      await store?.countShop('owned', type);
                    }
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('I already have this'),
                ),
              const SizedBox(height: 12),
              Text(
                'Prices and ratings as listed on decathlon.nl in '
                '$catalogueDate — check the shop for today\'s price. '
                '$shopDisclosure',
                style: muted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One product: icon, name, brand · price, rating, what it's good for, and
/// a button to its decathlon.nl page.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, this.store, this.why});

  final Product product;
  final PrefsStore? store;

  /// Optional line above the product's own description.
  final String? why;

  Future<void> _open() async {
    await store?.countShop('clicked', product.id);
    await launchUrl(Uri.parse(product.url), webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final meta = [?product.brand, ?product.priceLabel].join(' · ');
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                  child: Icon(productIcon(product.category)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (meta.isNotEmpty) Text(meta, style: muted),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (product.ratingLabel != null) ...[
                            Icon(Icons.star, size: 16, color: scheme.primary),
                            const SizedBox(width: 2),
                            Text(
                              product.ratingLabel!.replaceFirst('★', ''),
                              style: theme.textTheme.labelLarge,
                            ),
                          ] else
                            Text('Reviews on decathlon.nl', style: muted),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (why != null) Text(why!),
                      Text(product.fit, style: muted),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View at decathlon.nl'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple icon per product type (no product photos in the demo).
IconData productIcon(String category) {
  if (category.contains('glasses') || category.contains('sunglasses')) {
    return Icons.visibility;
  }
  if (category.contains('goggles')) return Icons.visibility;
  if (category.contains('helmet')) return Icons.sports_motorsports;
  if (category.contains('cap') ||
      category.contains('beanie') ||
      category.contains('headband') ||
      category.contains('gaiter')) {
    return Icons.face;
  }
  if (category.contains('glove') || category.contains('mitts')) {
    return Icons.back_hand;
  }
  if (category.contains('jacket') ||
      category.contains('gilet') ||
      category.contains('vest') ||
      category.contains('parka')) {
    return Icons.dry_cleaning;
  }
  if (category.contains('sock') ||
      category.contains('shoe') ||
      category.contains('toe')) {
    return Icons.ice_skating;
  }
  if (category.contains('wetsuit') ||
      category.contains('trisuit') ||
      category.startsWith('swim')) {
    return Icons.pool;
  }
  if (category.contains('gel') || category.contains('electrolytes')) {
    return Icons.bolt;
  }
  if (category.contains('bottle') || category.contains('softflask')) {
    return Icons.water_drop;
  }
  if (category.contains('sunscreen')) return Icons.wb_sunny;
  if (category.contains('belt')) return Icons.confirmation_number;
  return Icons.checkroom;
}
