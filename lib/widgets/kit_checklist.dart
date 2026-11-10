import 'package:flutter/material.dart';

import '../logic/gear_engine.dart';
import '../models/gear.dart';

/// The kit list, grouped HEAD / TORSO / HANDS / LEGS / FEET, tappable as a
/// packing checklist with an "all packed" state. Rain/wind items stand out.
class KitChecklist extends StatefulWidget {
  const KitChecklist({
    super.key,
    required this.items,
    this.initialPacked = const {},
    this.onPackedChanged,
    this.shopItems = const {},
    this.ownedShopItems = const {},
    this.onShop,
  });

  final List<GearItem> items;

  /// Names of items already ticked (e.g. when reopening a session).
  final Set<String> initialPacked;

  /// Called with the ticked item names and whether everything is packed.
  /// Ticks double as "what you wore" for the comfort profile (F4).
  final void Function(Set<String> packed, bool allPacked)? onPackedChanged;

  /// Items that get a quiet "Don't have one?" shop link (at most a few).
  final Set<GearItem> shopItems;

  /// Shop items the user already has: the link stays, worded as "other
  /// models".
  final Set<GearItem> ownedShopItems;
  final void Function(GearItem item)? onShop;

  @override
  State<KitChecklist> createState() => _KitChecklistState();
}

class _KitChecklistState extends State<KitChecklist> {
  // Tracked by name: the parent rebuilds the kit (new GearItem objects)
  // whenever it redraws, and ticks must survive that.
  late final Set<String> _packedNames = {...widget.initialPacked};

  Set<String> get _packed => {
    for (final item in widget.items)
      if (_packedNames.contains(item.name)) item.name,
  };

  void _toggle(GearItem item) {
    setState(() {
      _packedNames.contains(item.name)
          ? _packedNames.remove(item.name)
          : _packedNames.add(item.name);
    });
    final packed = _packed;
    widget.onPackedChanged?.call(packed, packed.length == widget.items.length);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupKit(widget.items);
    final total = widget.items.length;
    final packed = _packed.length;
    final allPacked = total > 0 && packed == total;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your kit', style: text.titleLarge),
            Text(
              '$packed / $total packed',
              style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : packed / total,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap items as you pack them.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
          _sectionHeader(context, part, grouped[part]!.length),
          for (final item in grouped[part]!) _itemTile(context, item),
        ],
      ],
    );
  }

  static const _partIcons = {
    BodyPart.head: Icons.face_outlined,
    BodyPart.torso: Icons.checkroom,
    BodyPart.hands: Icons.back_hand_outlined,
    BodyPart.legs: Icons.airline_seat_legroom_extra,
    BodyPart.feet: Icons.directions_walk,
  };

  /// Section header; an empty part is a single quiet line.
  Widget _sectionHeader(BuildContext context, BodyPart part, int count) {
    final scheme = Theme.of(context).colorScheme;
    final empty = count == 0;
    final color = empty ? scheme.onSurfaceVariant : scheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, empty ? 10 : 16, 0, empty ? 2 : 6),
      child: Row(
        children: [
          Icon(_partIcons[part], size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            part.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              empty ? '· nothing extra needed' : '· $count',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(BuildContext context, GearItem item) {
    final scheme = Theme.of(context).colorScheme;
    final isPacked = _packedNames.contains(item.name);
    final accent = triggerColor(item.trigger, scheme.brightness);
    final shop = widget.onShop != null && widget.shopItems.contains(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isPacked
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: accent == null
            ? BorderSide.none
            : BorderSide(color: accent.withValues(alpha: 0.7), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            checked: isPacked,
            button: true,
            label:
                '${item.name}${item.optional ? ', optional' : ''}. '
                '${item.reason}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _toggle(item),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, shop ? 4 : 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isPacked
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isPacked ? scheme.primary : scheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: isPacked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (accent != null)
                                _tag(
                                  context,
                                  item.trigger == GearTrigger.rain
                                      ? 'for the rain'
                                      : 'for the wind',
                                  item.trigger == GearTrigger.rain
                                      ? Icons.umbrella
                                      : Icons.air,
                                  accent,
                                ),
                              if (item.optional)
                                _tag(context, 'optional', null, scheme.outline),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.reason,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (shop) _shopLink(context, item),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String label, IconData? icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _shopLink(BuildContext context, GearItem item) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => widget.onShop!(item),
      child: ConstrainedBox(
        // A full-size tap target, separate from ticking the item.
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 0, 12, 4),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.ownedShopItems.contains(item)
                      ? 'You have one — see other models at Decathlon'
                      : "Don't have one? See options at Decathlon",
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accent colour for rain- and wind-driven items (null for the rest):
/// blue for rain, violet for wind — distinct from the app's other notes.
Color? triggerColor(GearTrigger trigger, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (trigger) {
    GearTrigger.rain =>
      dark ? const Color(0xFF8DB8FF) : const Color(0xFF1F5FBF),
    GearTrigger.wind =>
      dark ? const Color(0xFFC9A7FF) : const Color(0xFF6B3FB0),
    GearTrigger.none => null,
  };
}
