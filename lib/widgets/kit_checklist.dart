import 'package:flutter/material.dart';

import '../logic/gear_engine.dart';
import '../models/gear.dart';

/// The kit list, grouped HEAD / TORSO / HANDS / LEGS / FEET, tappable as a
/// packing checklist with an "all packed" state. Rain/wind items stand out.
class KitChecklist extends StatefulWidget {
  const KitChecklist({super.key, required this.items});

  final List<GearItem> items;

  @override
  State<KitChecklist> createState() => _KitChecklistState();
}

class _KitChecklistState extends State<KitChecklist> {
  final Set<GearItem> _packed = {};

  @override
  Widget build(BuildContext context) {
    final grouped = groupKit(widget.items);
    final total = widget.items.length;
    final packed = _packed.length;
    final allPacked = total > 0 && packed == total;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your kit', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '$packed / $total packed',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap items as you pack them.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (allPacked)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All packed — have a great session!',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (final part in BodyPart.values) ...[
          _sectionHeader(context, part),
          if (grouped[part]!.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                'Nothing extra needed here.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else
            for (final item in grouped[part]!) _itemTile(context, item),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, BodyPart part) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
        child: Text(
          part.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );

  Widget _itemTile(BuildContext context, GearItem item) {
    final scheme = Theme.of(context).colorScheme;
    final isPacked = _packed.contains(item);
    final highlighted = item.trigger != GearTrigger.none;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: highlighted
          ? scheme.tertiaryContainer
          : scheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          isPacked ? _packed.remove(item) : _packed.add(item);
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isPacked ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isPacked ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: isPacked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (item.trigger == GearTrigger.rain) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.umbrella, size: 16),
                        ],
                        if (item.trigger == GearTrigger.wind) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.air, size: 16),
                        ],
                        if (item.optional) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('optional',
                                style: Theme.of(context).textTheme.labelSmall),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.reason,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
