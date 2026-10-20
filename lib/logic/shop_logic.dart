import '../data/decathlon_catalogue.dart';
import '../models/fingerprint.dart';
import '../models/gear.dart';
import '../models/product.dart';
import '../models/race.dart';
import '../models/session.dart';

/// Kit item (as named by the gear engine) → Decathlon product types.
/// Items not listed here never get a shop link (e.g. "Your usual running
/// shoes", "Towel" kit the user certainly has, or advice-only items).
const Map<String, List<String>> itemProductTypes = {
  // Run — head
  'Warm beanie + neck gaiter': ['run_beanie', 'run_neck_gaiter'],
  'Warm beanie': ['run_beanie'],
  'Thin beanie or headband': ['run_headband', 'run_beanie'],
  'Ear-covering headband': ['run_headband'],
  'Cap with a brim': ['run_cap'],
  'Cap or visor': ['run_cap'],
  'Sunglasses': ['run_sunglasses'],
  // Run — torso
  'Singlet or your lightest tee': ['run_tee_light'],
  'Light short-sleeve tech tee': ['run_tee_light'],
  'Short-sleeve tee': ['run_tee_light'],
  'Light long sleeve to start': ['run_longsleeve'],
  'Light long-sleeve top': ['run_longsleeve'],
  'Long-sleeve base layer': ['run_longsleeve', 'run_thermal_base'],
  'Long-sleeve base layer + light vest or jacket': [
    'run_vest_wind',
    'run_longsleeve',
  ],
  'Base layer + light running jacket': ['run_jacket_warm', 'run_thermal_base'],
  'Thermal base layer + running jacket': [
    'run_thermal_base',
    'run_jacket_warm',
  ],
  'Thermal base + mid layer + windproof jacket': [
    'run_jacket_warm',
    'run_thermal_base',
  ],
  'Waterproof jacket with hood': ['run_jacket_rain'],
  'Light water-resistant jacket': ['run_jacket_rain'],
  'Packable windbreaker': ['run_vest_wind'],
  // Run — hands
  'Insulated mittens': ['run_gloves_warm'],
  'Warm running gloves': ['run_gloves_warm'],
  'Running gloves': ['run_gloves_thin', 'run_gloves_warm'],
  'Thin gloves': ['run_gloves_thin'],
  // Run — legs
  'Wind-blocking thermal tights': ['run_tights'],
  'Thermal running tights': ['run_tights'],
  'Running tights': ['run_tights'],
  'Tights or 3/4 tights': ['run_tights'],
  'Shorts or 3/4 tights': ['run_tights', 'run_shorts'],
  'Shorts': ['run_shorts'],
  // Run — feet
  'Shoes with good grip': ['run_shoes_grip'],
  'Synthetic (not cotton) socks': ['run_socks'],
  'Warm wool-blend socks': ['run_socks_warm'],
  'Socks you\'ve done long runs in': ['run_socks'],
  'Running socks': ['run_socks'],
  // Bike — head
  'Helmet': ['bike_helmet'],
  'Thermal skull cap + neck warmer': ['bike_skullcap', 'run_neck_gaiter'],
  'Thermal skull cap under the helmet': ['bike_skullcap'],
  'Ear band or cycling cap': ['bike_skullcap'],
  'Clear-lens glasses': ['bike_glasses'],
  'Cycling sunglasses': ['bike_glasses'],
  'Clear or light-tint glasses': ['bike_glasses'],
  // Bike — torso
  'Lightweight summer jersey': ['bike_jersey_ss'],
  'Short-sleeve jersey': ['bike_jersey_ss'],
  'Short-sleeve jersey + arm warmers': ['bike_arm_warmers', 'bike_jersey_ss'],
  'Jersey + arm warmers + wind gilet': ['bike_gilet', 'bike_arm_warmers'],
  'Long-sleeve thermal jersey + wind gilet': [
    'bike_jersey_ls_thermal',
    'bike_gilet',
  ],
  'Base layer + long-sleeve thermal jersey + wind jacket': [
    'bike_jersey_ls_thermal',
    'bike_jacket_winter',
  ],
  'Base layer + thermal jersey + windproof softshell': [
    'bike_jacket_winter',
    'bike_jersey_ls_thermal',
  ],
  'Thermal base layer + winter cycling jacket': ['bike_jacket_winter'],
  'Thermal layers + insulated winter jacket': ['bike_jacket_winter'],
  'Packable rain jacket': ['bike_jacket_rain'],
  'Wind gilet': ['bike_gilet'],
  // Bike — hands
  'Lobster mitts + liner gloves': ['bike_gloves_winter'],
  'Winter gloves or lobster mitts': ['bike_gloves_winter'],
  'Winter cycling gloves': ['bike_gloves_winter'],
  'Insulated full-finger gloves': ['bike_gloves_winter', 'bike_gloves_full'],
  'Full-finger gloves': ['bike_gloves_full'],
  'Light full-finger gloves': ['bike_gloves_full'],
  'Fingerless mitts': ['bike_mitts'],
  // Bike — legs
  'Windproof winter bib tights': ['bike_bib_tights'],
  'Thermal bib tights': ['bike_bib_tights'],
  'Bib shorts + thermal leg warmers (or 3/4 tights)': ['bike_knee_leg_warmers'],
  'Bib shorts + leg warmers': ['bike_knee_leg_warmers'],
  'Bib shorts + knee warmers': ['bike_knee_leg_warmers'],
  'Bib shorts': ['bike_bib_shorts'],
  // Bike — feet
  'Waterproof overshoes': ['bike_overshoes'],
  'Insulated overshoes + winter socks': ['bike_overshoes'],
  'Insulated overshoes': ['bike_overshoes'],
  'Overshoes': ['bike_overshoes'],
  'Toe covers': ['bike_toe_covers'],
  'Mid-weight or wool socks': ['run_socks_warm'],
  // Swim
  'Bright silicone swim cap': ['swim_cap'],
  'Neoprene cap': ['swim_neoprene_cap'],
  'Tinted goggles': ['swim_goggles'],
  'Clear or light-tint goggles': ['swim_goggles'],
  'Wetsuit': ['swim_wetsuit'],
  'Swimsuit / trisuit': ['swim_trisuit'],
  'Dry robe or warm layer for after': ['swim_parka'],
  'Neoprene gloves': ['swim_neoprene_gloves'],
  'Neoprene booties': ['swim_neoprene_socks'],
};

/// Kit items that intentionally never get a shop link.
const Set<String> noShopItems = {
  'Your usual running shoes',
  'Cycling shoes + socks',
  'Towel',
  'Jammers / suit bottoms',
  'Sandals for the shore',
};

/// At most this many shop links per kit screen (owner: not pushy).
const int maxShopLinks = 3;

/// Products of [category], best (popular and well rated) first.
List<Product> productsFor(String category, {List<Product>? catalogue}) {
  final list = [
    for (final p in catalogue ?? decathlonCatalogue)
      if (p.category == category) p,
  ]..sort((a, b) => b.score.compareTo(a.score));
  return list;
}

/// Products for one kit item, best first, without duplicates.
List<Product> productsForItem(GearItem item, {List<Product>? catalogue}) {
  final seen = <String>{};
  return [
    for (final type in itemProductTypes[item.name] ?? const <String>[])
      for (final p in productsFor(type, catalogue: catalogue))
        if (seen.add(p.id)) p,
  ];
}

/// Which kit items get a shop link: up to [maxShopLinks], rain/wind items
/// first, then the main garments; never items without products. Owning
/// an item does not remove its link (owner, Oct 2026: people may still
/// want to look at other models) — see [ownsItem] for the wording.
Set<GearItem> itemsToOffer(List<GearItem> kit, {List<Product>? catalogue}) {
  int priority(GearItem item) {
    if (item.trigger != GearTrigger.none) return 0;
    return switch (item.part) {
          BodyPart.torso => 1,
          BodyPart.hands => 2,
          BodyPart.head => 3,
          BodyPart.legs => 4,
          BodyPart.feet => 5,
        } +
        (item.optional ? 5 : 0);
  }

  final candidates = [
    for (final item in kit)
      if ((itemProductTypes[item.name] ?? const <String>[]).isNotEmpty &&
          productsForItem(item, catalogue: catalogue).isNotEmpty)
        item,
  ]..sort((a, b) => priority(a).compareTo(priority(b)));
  return candidates.take(maxShopLinks).toSet();
}

/// Whether the user said they have this kit item (all its product types
/// are in "My gear").
bool ownsItem(GearItem item, Set<String> ownedTypes) {
  final types = itemProductTypes[item.name] ?? const <String>[];
  return types.isNotEmpty && types.every(ownedTypes.contains);
}

/// A race-kit suggestion: a top-rated product and why it suits the race.
class RaceKitPick {
  const RaceKitPick(this.product, this.why, {this.owned = false});
  final Product product;
  final String why;

  /// The user already has this type of product (still shown, as another
  /// model to consider).
  final bool owned;
}

/// Up to [count] top-rated Decathlon best sellers suited to the race's
/// typical conditions (owner feature 2). One product per type; types the
/// user owns are still shown, marked [RaceKitPick.owned].
List<RaceKitPick> raceKit({
  required Race race,
  required ConditionStats conditions,
  required Sport sport,
  Set<String> ownedTypes = const {},
  int count = 5,
  List<Product>? catalogue,
}) {
  final t = conditions.temperature.mean;
  final humid = conditions.humidity.mean >= 70;
  final wet = conditions.rainChance >= 0.3;
  final windy = conditions.wind.mean >= 15;
  final sports = {for (final leg in race.legs) leg.sport, sport};
  final long = race.totalMinutes >= 90;
  final wants = <(String, String)>[
    if (sports.contains(Sport.swim))
      t < 20
          ? ('swim_wetsuit', 'Cool race morning — a wetsuit for the swim')
          : ('swim_goggles', 'Clear sighting on race morning'),
    if (sports.contains(Sport.swim) && race.isMultisport)
      ('swim_trisuit', 'One suit from swim to finish'),
    if (long) ('race_gel', 'Energy for a race of ${_hours(race.totalMinutes)}'),
    if (t >= 18 || humid)
      (
        'race_electrolytes',
        '${humid ? 'Humid' : 'Warm'} race day — replace the salts you sweat',
      ),
    if (wet && sports.contains(Sport.bike))
      (
        'bike_jacket_rain',
        '${(conditions.rainChance * 100).round()}% of race days are wet',
      ),
    if (wet && !sports.contains(Sport.bike))
      (
        'run_jacket_rain',
        '${(conditions.rainChance * 100).round()}% of race days are wet',
      ),
    if (windy && sports.contains(Sport.bike))
      (
        'bike_gilet',
        'Typically ${conditions.wind.mean.round()} km/h wind on the bike',
      ),
    if (sports.contains(Sport.run) && t >= 15) ('run_cap', 'Shade for the run'),
    if (sports.contains(Sport.run))
      (t >= 16 ? 'run_tee_light' : 'run_longsleeve', _topWhy(t)),
    if (sports.contains(Sport.bike)) ('race_bottle', 'Drink on the bike'),
    if (sports.contains(Sport.run) && long)
      ('race_softflask', 'Carry water on the run'),
    if (race.isMultisport) ('race_belt', 'Quick number changes in transition'),
    if (t <= 10 && sports.contains(Sport.run))
      ('run_gloves_thin', 'Cold start — thin gloves'),
    if (t >= 18 && conditions.rainChance < 0.3)
      ('race_sunscreen', 'Hours outside in mostly dry weather'),
  ];
  final picks = <RaceKitPick>[];
  final used = <String>{};
  for (final (type, why) in wants) {
    if (picks.length >= count) break;
    if (!used.add(type)) continue;
    final best = productsFor(type, catalogue: catalogue);
    // Rated best sellers come first; an unrated product is only picked
    // when its type has no rated one.
    if (best.isEmpty) continue;
    picks.add(RaceKitPick(best.first, why, owned: ownedTypes.contains(type)));
  }
  return picks;
}

String _topWhy(double t) => t >= 16
    ? 'Typically ${t.round()}°C — a light, breathable top'
    : 'Typically ${t.round()}°C — light long sleeves';

String _hours(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}
