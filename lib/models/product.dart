import 'dart:math' as math;

/// A real product from the decathlon.nl online store, used for shopping
/// suggestions in this demo (owner decision, Oct 2026: EU / decathlon.nl
/// only; no partnership yet, so links simply open the product page).
class Product {
  const Product({
    required this.id,
    required this.category,
    required this.name,
    required this.url,
    required this.fit,
    this.brand,
    this.priceEur,
    this.rating,
    this.reviewCount,
  });

  final String id;

  /// Product type key, e.g. `run_jacket_rain` (see [productCategories]).
  final String category;

  final String name;
  final String? brand;

  /// decathlon.nl product page.
  final String url;

  /// Snapshot values from the decathlon.nl listing (see [catalogueDate]).
  final double? priceEur;
  final double? rating;
  final int? reviewCount;

  /// What it's good for, in a few words.
  final String fit;

  /// Popularity-weighted rating: a 4.7★ product with 1,000 reviews beats a
  /// 5★ product with 3. Unrated products sort last.
  double get score {
    final r = rating;
    if (r == null) return 0;
    final n = reviewCount ?? 0;
    // Shrink towards an average 4.0★ until there are enough reviews.
    const prior = 4.0;
    const weight = 20;
    final shrunk = (r * n + prior * weight) / (n + weight);
    return shrunk + 0.05 * math.log(1 + n);
  }

  /// "4.7★ (1,187)"
  String? get ratingLabel {
    if (rating == null) return null;
    final count = reviewCount == null ? '' : ' (${_thousands(reviewCount!)})';
    return '${rating!.toStringAsFixed(1)}★$count';
  }

  /// "€14.99"
  String? get priceLabel =>
      priceEur == null ? null : '€${priceEur!.toStringAsFixed(2)}';
}

String _thousands(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// Human labels for product types, used in "See running rain jackets".
const Map<String, String> productCategories = {
  'run_headband': 'running headbands',
  'run_beanie': 'running beanies',
  'run_cap': 'running caps',
  'run_sunglasses': 'running sunglasses',
  'run_neck_gaiter': 'neck warmers',
  'run_tee_light': 'running T-shirts',
  'run_longsleeve': 'long-sleeve running tops',
  'run_thermal_base': 'thermal base layers',
  'run_vest_wind': 'windproof running layers',
  'run_jacket_rain': 'running rain jackets',
  'run_jacket_warm': 'winter running jackets',
  'run_gloves_thin': 'thin running gloves',
  'run_gloves_warm': 'warm running gloves',
  'run_shorts': 'running shorts',
  'run_tights': 'running tights',
  'run_socks': 'running socks',
  'run_socks_warm': 'warm running socks',
  'run_shoes_grip': 'trail running shoes',
  'bike_helmet': 'cycling helmets',
  'bike_glasses': 'cycling glasses',
  'bike_skullcap': 'cycling caps',
  'bike_jersey_ss': 'short-sleeve jerseys',
  'bike_arm_warmers': 'arm warmers',
  'bike_gilet': 'cycling gilets',
  'bike_jersey_ls_thermal': 'thermal cycling jerseys',
  'bike_jacket_winter': 'winter cycling jackets',
  'bike_jacket_rain': 'cycling rain jackets',
  'bike_bib_shorts': 'bib shorts',
  'bike_knee_leg_warmers': 'knee and leg warmers',
  'bike_bib_tights': 'winter bib tights',
  'bike_mitts': 'cycling mitts',
  'bike_gloves_full': 'full-finger cycling gloves',
  'bike_gloves_winter': 'winter cycling gloves',
  'bike_overshoes': 'overshoes',
  'bike_toe_covers': 'toe covers',
  'swim_cap': 'swim caps',
  'swim_goggles': 'swim goggles',
  'swim_neoprene_cap': 'neoprene swim caps',
  'swim_wetsuit': 'triathlon wetsuits',
  'swim_trisuit': 'trisuits',
  'swim_neoprene_gloves': 'neoprene swim gloves',
  'swim_neoprene_socks': 'neoprene swim socks',
  'swim_towel': 'microfibre towels',
  'swim_parka': 'swim parkas',
  'race_gel': 'energy gels',
  'race_electrolytes': 'electrolyte drinks',
  'race_softflask': 'soft flasks',
  'race_bottle': 'cycling bottles',
  'race_belt': 'race number belts',
  'race_sunscreen': 'sport sunscreen',
};
