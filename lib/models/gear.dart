/// The five body parts every kit list covers, in display order.
enum BodyPart {
  head('Head'),
  torso('Torso'),
  hands('Hands'),
  legs('Legs'),
  feet('Feet');

  const BodyPart(this.label);
  final String label;
}

/// What put an item on the list. Rain- and wind-triggered items are
/// visually highlighted (per the PRD).
enum GearTrigger { none, rain, wind }

/// A single kit suggestion. Every item carries the reason it was suggested
/// — that is a hard product rule, never emit an item without one.
class GearItem {
  const GearItem({
    required this.part,
    required this.name,
    required this.reason,
    this.trigger = GearTrigger.none,
    this.optional = false,
  });

  final BodyPart part;
  final String name;
  final String reason;
  final GearTrigger trigger;

  /// "Nice to have" rather than "you'll regret skipping it".
  final bool optional;
}
