import '../models/comfort.dart';
import '../models/gear.dart';
import '../models/session.dart';
import '../models/weather.dart';

/// Felt-temperature ranges the kit rules are written against, coldest
/// first. Narrow (about 3 °C) where athletes' clothing choices change
/// often — between roughly 7 and 20 °C cycling guides change kit every
/// 2–3 °C — and in the cold, where every degree counts (owner request,
/// Oct 2026).
enum TempBand {
  severe, // below −5
  freezing, // −5 to 0
  veryCold, // 0 to 4
  cold, // 4 to 7
  chilly, // 7 to 10
  cool, // 10 to 13
  mild, // 13 to 16
  mildWarm, // 16 to 20
  warm, // 20 to 24
  hot, // 24 and above
}

const List<double> _bandUpperC = [-5, 0, 4, 7, 10, 13, 16, 20, 24];

TempBand bandFor(double feltC) {
  for (var i = 0; i < _bandUpperC.length; i++) {
    if (feltC < _bandUpperC[i]) return TempBand.values[i];
  }
  return TempBand.hot;
}

/// Zero-data comfort baseline (PRD decision 4): with no feedback yet,
/// sport defaults apply. Runners tolerate breeze on legs and torso, so
/// those parts are treated a few degrees warmer than the air says.
/// Cyclists make their own headwind, so torso, hands, head and feet are
/// treated colder. Returned value is added to the felt temperature before
/// picking a range.
double sportPartAdjustment(Sport sport, BodyPart part) {
  switch (sport) {
    case Sport.run:
      return (part == BodyPart.torso || part == BodyPart.legs) ? 3 : 0;
    case Sport.bike:
      switch (part) {
        case BodyPart.torso:
        case BodyPart.hands:
          return -3;
        case BodyPart.head:
        case BodyPart.feet:
          return -2;
        case BodyPart.legs:
          return 0;
      }
    case Sport.swim:
      return 0;
  }
}

/// Builds the kit list for a session. Pure logic: same inputs, same list.
///
/// With a [comfort] profile (F4), each body part moves up to two kit
/// ranges lighter or warmer. Items that end up different from the
/// standard suggestion say why ("You run warm between 13 and 16°C, …").
List<GearItem> buildKit(
  Sport sport,
  SessionForecast forecast, {
  double distanceKm = 0,
  ComfortProfile? comfort,
}) {
  final standard = _build(sport, forecast, distanceKm, const {});
  if (comfort == null) return standard;
  final zone = TempZone.of(forecast.meanApparentC);
  final steps = {
    for (final part in BodyPart.values) part: comfort.steps(sport, part, zone),
  };
  if (steps.values.every((s) => s == 0)) return standard;
  final personal = _build(sport, forecast, distanceKm, steps);
  return [
    for (final item in personal)
      if (steps[item.part] != 0 &&
          !standard.any((s) => s.part == item.part && s.name == item.name))
        GearItem(
          part: item.part,
          name: item.name,
          reason:
              '${comfortNote(comfort, sport, item.part, zone)} '
              '${item.reason}',
          trigger: item.trigger,
          optional: item.optional,
        )
      else
        item,
  ];
}

List<GearItem> _build(
  Sport sport,
  SessionForecast forecast,
  double distanceKm,
  Map<BodyPart, int> steps,
) {
  final builder = _KitBuilder(sport, forecast, distanceKm, steps);
  switch (sport) {
    case Sport.run:
      builder.buildRun();
    case Sport.bike:
      builder.buildBike();
    case Sport.swim:
      builder.buildSwim();
  }
  return builder.items;
}

/// Convenience wrapper taking a whole session plan.
List<GearItem> buildKitForPlan(
  SessionPlan plan,
  SessionForecast forecast, {
  ComfortProfile? comfort,
}) => buildKit(
  plan.sport,
  forecast,
  distanceKm: plan.distanceKm,
  comfort: comfort,
);

/// "You run warm between 13 and 16°C, so this is lighter than usual." The
/// learned part wins; otherwise the Settings slider is quoted.
String comfortNote(
  ComfortProfile comfort,
  Sport sport,
  BodyPart part,
  TempZone zone,
) {
  final learned = comfort.learned(sport, part, zone).steps;
  final total = comfort.steps(sport, part, zone);
  final warmOrCold = total > 0 ? 'warm' : 'cold';
  final direction = total > 0 ? 'lighter' : 'warmer';
  if (learned != 0) {
    return '${runsSubject(part)} $warmOrCold ${zone.phrase}, so this is '
        '$direction than usual.';
  }
  return 'Your comfort profile says your ${_partNoun(part)} '
      '${part == BodyPart.head ? 'runs' : 'run'} $warmOrCold, so this is '
      '$direction than usual.';
}

/// "You run" for the torso (the brief's wording), "Your hands run" etc.
String runsSubject(BodyPart part) => switch (part) {
  BodyPart.torso => 'You run',
  BodyPart.head => 'Your head runs',
  _ => 'Your ${_partNoun(part)} run',
};

String _partNoun(BodyPart part) => switch (part) {
  BodyPart.torso => 'body',
  _ => part.label.toLowerCase(),
};

/// Items that are always on the list whatever the weather; not useful as
/// "what we suggested" when asking what the user wore.
const _fixedItems = {'Helmet', 'Bright silicone swim cap', 'Towel'};

/// The main clothing suggestion per body part (first essential,
/// non-rain/wind item), for the "Did you wear that?" check.
Map<BodyPart, String> mainSuggestions(List<GearItem> kit) {
  final result = <BodyPart, String>{};
  for (final item in kit) {
    if (result.containsKey(item.part) ||
        item.optional ||
        item.trigger != GearTrigger.none ||
        _fixedItems.contains(item.name)) {
      continue;
    }
    result[item.part] = item.name;
  }
  return result;
}

class _KitBuilder {
  _KitBuilder(this.sport, this.f, this.distanceKm, this.steps);

  final Sport sport;
  final SessionForecast f;
  final double distanceKm;

  /// Personal comfort steps per body part (F4): +1 = one range lighter.
  final Map<BodyPart, int> steps;
  final List<GearItem> items = [];

  /// Long enough that blister prevention deserves a mention.
  bool get distanceIsLong => sport == Sport.run && distanceKm >= 15;

  /// Kit range for a body part: felt temperature (with sun and wet), the
  /// sport baseline, then the personal comfort steps.
  TempBand band(BodyPart part) {
    final base = bandFor(f.kitFeelsC + sportPartAdjustment(sport, part));
    final index = (base.index + (steps[part] ?? 0)).clamp(
      0,
      TempBand.values.length - 1,
    );
    return TempBand.values[index];
  }

  bool atMost(BodyPart part, TempBand b) => band(part).index <= b.index;

  /// The number quoted in reasons: the real session feels-like, rounded.
  int get feels => f.meanApparentC.round();

  /// "Session feels like 12°" plus, when sun or rain changed the picture,
  /// ", more like 15° in the sun".
  String get feelsLike {
    final adjusted = f.kitFeelsC.round();
    if (adjusted == feels) return 'Session feels like $feels°';
    final why = f.sunBonusC > 0 && f.wetPenaltyC > 0
        ? 'with the sun and rain'
        : f.sunBonusC > 0
        ? 'in the sun'
        : 'when wet';
    return 'Session feels like $feels°, more like $adjusted° $why';
  }

  int get rainChance => f.maxPrecipProbabilityPercent.round();

  int get gusts => f.maxGustKmh.round();

  void add(
    BodyPart part,
    String name,
    String reason, {
    GearTrigger trigger = GearTrigger.none,
    bool optional = false,
  }) {
    items.add(
      GearItem(
        part: part,
        name: name,
        reason: reason,
        trigger: trigger,
        optional: optional,
      ),
    );
  }

  // ---------------------------------------------------------------- run --

  void buildRun() {
    _runHead();
    _runTorso();
    _runHands();
    _runLegs();
    _runFeet();
  }

  void _runHead() {
    switch (band(BodyPart.head)) {
      case TempBand.severe:
        add(
          BodyPart.head,
          'Warm beanie + neck gaiter',
          '$feelsLike — cover ears and neck; pull the gaiter over your face into the wind.',
        );
      case TempBand.freezing:
        add(
          BodyPart.head,
          'Warm beanie',
          '$feelsLike — you lose a lot of heat bare-headed.',
        );
      case TempBand.veryCold:
      case TempBand.cold:
        add(
          BodyPart.head,
          'Thin beanie or headband',
          '$feelsLike — keeps ears warm without overheating.',
        );
      case TempBand.chilly:
        add(
          BodyPart.head,
          'Ear-covering headband',
          '$feelsLike — ears feel it first; easy to pocket once warm.',
          optional: true,
        );
      default:
        break;
    }
    if (f.rainLikely) {
      add(
        BodyPart.head,
        'Cap with a brim',
        '$rainChance% rain chance — keeps rain out of your eyes.',
        trigger: GearTrigger.rain,
      );
    } else if (f.mostlyClear && f.mostlyDaylight) {
      add(BodyPart.head, 'Cap or visor', 'Clear skies during your session.');
      add(
        BodyPart.head,
        'Sunglasses',
        'Sun in your eyes on open stretches.',
        optional: true,
      );
    }
  }

  void _runTorso() {
    final humidNote = f.humid
        ? ' ${f.meanHumidityPercent.round()}% humidity will make it feel stickier.'
        : '';
    switch (band(BodyPart.torso)) {
      case TempBand.hot:
        add(
          BodyPart.torso,
          'Singlet or your lightest tee',
          '$feelsLike — heat builds fast on the run.$humidNote',
        );
      case TempBand.warm:
        add(
          BodyPart.torso,
          'Light short-sleeve tech tee',
          '$feelsLike and runners warm up quickly.$humidNote',
        );
      case TempBand.mildWarm:
        add(
          BodyPart.torso,
          'Short-sleeve tee',
          '$feelsLike — comfortable once you are moving.',
        );
      case TempBand.mild:
        add(
          BodyPart.torso,
          'Short-sleeve tee',
          '$feelsLike — fine on the move, a touch cool at the start.',
        );
        add(
          BodyPart.torso,
          'Light long sleeve to start',
          'Cool for the first 10 minutes; tie it round your waist after.',
          optional: true,
        );
      case TempBand.cool:
        add(
          BodyPart.torso,
          'Light long-sleeve top',
          '$feelsLike — sleeves for the start, thin enough not to overheat.',
        );
      case TempBand.chilly:
        add(
          BodyPart.torso,
          'Long-sleeve base layer',
          '$feelsLike — long sleeves, nothing heavy: you generate heat on the move.',
        );
      case TempBand.cold:
        add(
          BodyPart.torso,
          'Long-sleeve base layer + light vest or jacket',
          '$feelsLike — a wind-blocking layer over the base keeps the core warm.',
        );
      case TempBand.veryCold:
        add(
          BodyPart.torso,
          'Base layer + light running jacket',
          '$feelsLike — two thin layers beat one thick one.',
        );
      case TempBand.freezing:
        add(
          BodyPart.torso,
          'Thermal base layer + running jacket',
          '$feelsLike — protect your core, vent with the zip.',
        );
      case TempBand.severe:
        add(
          BodyPart.torso,
          'Thermal base + mid layer + windproof jacket',
          '$feelsLike — three layers; open the zip if you start sweating.',
        );
    }
    if (f.rainLikely) {
      add(
        BodyPart.torso,
        f.heavyRain
            ? 'Waterproof jacket with hood'
            : 'Light water-resistant jacket',
        '$rainChance% rain chance during your session.',
        trigger: GearTrigger.rain,
      );
    } else if (f.windy) {
      add(
        BodyPart.torso,
        'Packable windbreaker',
        'Wind up to ${f.maxWindKmh.round()} km/h (gusts $gusts) will chill you on exposed stretches.',
        trigger: GearTrigger.wind,
      );
    }
  }

  void _runHands() {
    switch (band(BodyPart.hands)) {
      case TempBand.severe:
        add(
          BodyPart.hands,
          'Insulated mittens',
          '$feelsLike — mittens keep fingers together and warm.',
        );
      case TempBand.freezing:
        add(
          BodyPart.hands,
          'Warm running gloves',
          '$feelsLike — fingers lose heat fastest.',
        );
      case TempBand.veryCold:
        add(
          BodyPart.hands,
          'Running gloves',
          '$feelsLike — your hands won\'t warm up on their own.',
        );
      case TempBand.cold:
        add(
          BodyPart.hands,
          'Thin gloves',
          '$feelsLike — easy to stash once your hands warm up.',
        );
      case TempBand.chilly:
        add(
          BodyPart.hands,
          'Thin gloves',
          'Borderline at $feels° — take them, pocket them if unneeded.',
          optional: true,
        );
      default:
        break;
    }
  }

  void _runLegs() {
    switch (band(BodyPart.legs)) {
      case TempBand.severe:
        add(
          BodyPart.legs,
          'Wind-blocking thermal tights',
          '$feelsLike — full insulation with a windproof front.',
        );
      case TempBand.freezing:
        add(
          BodyPart.legs,
          'Thermal running tights',
          '$feelsLike — full insulation today.',
        );
      case TempBand.veryCold:
        add(
          BodyPart.legs,
          'Running tights',
          '$feelsLike — too cold for bare legs, even on the run.',
        );
      case TempBand.cold:
        add(
          BodyPart.legs,
          'Tights or 3/4 tights',
          '$feelsLike — bare knees get stiff at this temperature.',
        );
      case TempBand.chilly:
        add(
          BodyPart.legs,
          'Shorts or 3/4 tights',
          '$feelsLike — runners\' legs run warm; tights if you run easy.',
        );
      case TempBand.cool:
        add(
          BodyPart.legs,
          'Shorts',
          '$feelsLike, but runners\' legs run warm — most prefer shorts here.',
        );
      default:
        add(BodyPart.legs, 'Shorts', '$feelsLike — an easy shorts day.');
    }
  }

  void _runFeet() {
    if (f.heavyRain) {
      add(
        BodyPart.feet,
        'Shoes with good grip',
        'Real rain expected — paths and paint lines get slick.',
        trigger: GearTrigger.rain,
      );
    } else {
      add(
        BodyPart.feet,
        'Your usual running shoes',
        'Nothing in the forecast asks for anything special.',
      );
    }
    if (f.rainLikely) {
      add(
        BodyPart.feet,
        'Synthetic (not cotton) socks',
        'Wet cotton socks cause blisters — synthetic dries on the move.',
        trigger: GearTrigger.rain,
      );
    } else if (atMost(BodyPart.feet, TempBand.freezing)) {
      add(
        BodyPart.feet,
        'Warm wool-blend socks',
        '$feelsLike — toes get cold before anything else.',
      );
    } else if (distanceIsLong) {
      add(
        BodyPart.feet,
        'Socks you\'ve done long runs in',
        '${formatDistance(distanceKm)} — blisters love new socks on long distances.',
      );
    } else {
      add(BodyPart.feet, 'Running socks', 'Standard kit for the distance.');
    }
  }

  // --------------------------------------------------------------- bike --

  void buildBike() {
    _bikeHead();
    _bikeTorso();
    _bikeHands();
    _bikeLegs();
    _bikeFeet();
  }

  void _bikeHead() {
    add(BodyPart.head, 'Helmet', 'Every ride, no exceptions.');
    switch (band(BodyPart.head)) {
      case TempBand.severe:
      case TempBand.freezing:
        add(
          BodyPart.head,
          'Thermal skull cap + neck warmer',
          '$feelsLike plus riding windchill on ears and neck.',
        );
      case TempBand.veryCold:
      case TempBand.cold:
        add(
          BodyPart.head,
          'Thermal skull cap under the helmet',
          '$feelsLike plus riding windchill on your ears.',
        );
      case TempBand.chilly:
        add(
          BodyPart.head,
          'Ear band or cycling cap',
          '$feelsLike — keeps the wind off your ears on descents.',
          optional: true,
        );
      default:
        break;
    }
    if (f.rainLikely) {
      add(
        BodyPart.head,
        'Clear-lens glasses',
        'Road spray in the eyes ends rides — $rainChance% rain chance.',
        trigger: GearTrigger.rain,
      );
    } else if (f.mostlyClear && f.mostlyDaylight) {
      add(
        BodyPart.head,
        'Cycling sunglasses',
        'Clear skies — sun and road glare.',
      );
    } else {
      add(
        BodyPart.head,
        'Clear or light-tint glasses',
        'Keeps wind and grit out of your eyes.',
        optional: true,
      );
    }
  }

  void _bikeTorso() {
    // Cycling guides are written for riding (windchill included), so with
    // the cyclist torso baseline of −3 °C these ranges line up with them:
    // e.g. arm warmers at 16–19 °C air, a gilet at 13–16 °C air.
    switch (band(BodyPart.torso)) {
      case TempBand.hot:
        add(
          BodyPart.torso,
          'Lightweight summer jersey',
          '$feelsLike — go as breathable as you own.',
        );
      case TempBand.warm:
      case TempBand.mildWarm:
        add(
          BodyPart.torso,
          'Short-sleeve jersey',
          '$feelsLike — standard short-sleeve weather.',
        );
      case TempBand.mild:
        add(
          BodyPart.torso,
          'Short-sleeve jersey + arm warmers',
          '$feelsLike — arm warmers for the start and descents; roll them down once warm.',
        );
      case TempBand.cool:
        add(
          BodyPart.torso,
          'Jersey + arm warmers + wind gilet',
          '$feelsLike but riding makes its own windchill — the gilet blocks it on descents.',
        );
      case TempBand.chilly:
        add(
          BodyPart.torso,
          'Long-sleeve thermal jersey + wind gilet',
          '$feelsLike — sleeves all ride, a gilet for the chest.',
        );
      case TempBand.cold:
        add(
          BodyPart.torso,
          'Base layer + long-sleeve thermal jersey + wind jacket',
          '$feelsLike — thermal fabric plus a wind-blocking layer.',
        );
      case TempBand.veryCold:
        add(
          BodyPart.torso,
          'Base layer + thermal jersey + windproof softshell',
          '$feelsLike — block the wind; the cold gets in through the front.',
        );
      case TempBand.freezing:
        add(
          BodyPart.torso,
          'Thermal base layer + winter cycling jacket',
          '$feelsLike — full winter kit on the bike.',
        );
      case TempBand.severe:
        add(
          BodyPart.torso,
          'Thermal layers + insulated winter jacket',
          '$feelsLike — the warmest you own; windchill is brutal at speed.',
        );
    }
    if (f.rainLikely) {
      add(
        BodyPart.torso,
        'Packable rain jacket',
        '$rainChance% rain chance — getting soaked on a bike gets cold fast.',
        trigger: GearTrigger.rain,
      );
    } else if (f.windy && band(BodyPart.torso).index > TempBand.cool.index) {
      add(
        BodyPart.torso,
        'Wind gilet',
        'Wind up to ${f.maxWindKmh.round()} km/h (gusts $gusts) — blocks the chill on descents.',
        trigger: GearTrigger.wind,
      );
    }
  }

  void _bikeHands() {
    switch (band(BodyPart.hands)) {
      case TempBand.severe:
        add(
          BodyPart.hands,
          'Lobster mitts + liner gloves',
          '$feelsLike — braking fingers go numb first.',
        );
      case TempBand.freezing:
        add(
          BodyPart.hands,
          'Winter gloves or lobster mitts',
          '$feelsLike — braking fingers go numb first.',
        );
      case TempBand.veryCold:
        add(
          BodyPart.hands,
          'Winter cycling gloves',
          '$feelsLike plus windchill on the bars.',
        );
      case TempBand.cold:
        add(
          BodyPart.hands,
          'Insulated full-finger gloves',
          '$feelsLike plus windchill on the bars.',
        );
      case TempBand.chilly:
        add(
          BodyPart.hands,
          'Full-finger gloves',
          '$feelsLike — windchill bites on descents.',
        );
      case TempBand.cool:
        add(
          BodyPart.hands,
          'Light full-finger gloves',
          '$feelsLike — thin gloves take the edge off the wind.',
        );
      case TempBand.mild:
      case TempBand.mildWarm:
        add(
          BodyPart.hands,
          'Fingerless mitts',
          'Padding for the bars, cool air for the fingers.',
        );
      default:
        add(
          BodyPart.hands,
          'Fingerless mitts',
          'Padding and grip when your hands sweat.',
          optional: true,
        );
    }
  }

  void _bikeLegs() {
    switch (band(BodyPart.legs)) {
      case TempBand.severe:
      case TempBand.freezing:
        add(
          BodyPart.legs,
          'Windproof winter bib tights',
          '$feelsLike — knees need full, wind-blocking cover.',
        );
      case TempBand.veryCold:
      case TempBand.cold:
        add(
          BodyPart.legs,
          'Thermal bib tights',
          '$feelsLike — cold knees are slow knees.',
        );
      case TempBand.chilly:
        add(
          BodyPart.legs,
          'Bib shorts + thermal leg warmers (or 3/4 tights)',
          '$feelsLike — cover the knees; warmers come off if it warms up.',
        );
      case TempBand.cool:
        add(
          BodyPart.legs,
          'Bib shorts + leg warmers',
          '$feelsLike — leg warmers rather than knee warmers at this temperature.',
        );
      case TempBand.mild:
        add(
          BodyPart.legs,
          'Bib shorts + knee warmers',
          '$feelsLike — protect the knees in cool moving air.',
        );
      default:
        add(BodyPart.legs, 'Bib shorts', '$feelsLike — standard bibs weather.');
    }
  }

  void _bikeFeet() {
    add(BodyPart.feet, 'Cycling shoes + socks', 'Your standard setup.');
    if (f.rainLikely) {
      add(
        BodyPart.feet,
        'Waterproof overshoes',
        '$rainChance% rain chance — road spray soaks shoes from below.',
        trigger: GearTrigger.rain,
      );
      return;
    }
    switch (band(BodyPart.feet)) {
      case TempBand.severe:
      case TempBand.freezing:
        add(
          BodyPart.feet,
          'Insulated overshoes + winter socks',
          '$feelsLike — toes get almost no blood flow on the bike.',
        );
      case TempBand.veryCold:
        add(
          BodyPart.feet,
          'Insulated overshoes',
          '$feelsLike — toes go numb first on the bike.',
        );
      case TempBand.cold:
        add(
          BodyPart.feet,
          'Overshoes',
          '$feelsLike plus windchill — keep the wind out of your shoes.',
        );
      case TempBand.chilly:
        add(
          BodyPart.feet,
          'Toe covers',
          '$feelsLike — wind through shoe vents chills toes.',
        );
      case TempBand.cool:
        add(
          BodyPart.feet,
          'Mid-weight or wool socks',
          '$feelsLike — a little insulation goes a long way.',
        );
      default:
        break;
    }
  }

  // --------------------------------------------------------------- swim --

  void buildSwim() {
    final airBand = band(BodyPart.torso);
    bool airAtMost(TempBand b) => airBand.index <= b.index;
    final wetsuitNeeded = airAtMost(TempBand.cool);

    // Head
    add(BodyPart.head, 'Bright silicone swim cap', 'Be visible in open water.');
    if (airAtMost(TempBand.cool)) {
      add(
        BodyPart.head,
        'Neoprene cap',
        'Air $feelsLike over the session — expect cold water on the head.',
        optional: airBand == TempBand.cool,
      );
    }
    if (f.mostlyClear && f.mostlyDaylight) {
      add(BodyPart.head, 'Tinted goggles', 'Glare off the water.');
    } else {
      add(
        BodyPart.head,
        'Clear or light-tint goggles',
        'Flat light — clear lenses sight better.',
      );
    }

    // Torso
    if (wetsuitNeeded) {
      add(
        BodyPart.torso,
        'Wetsuit',
        'Air $feelsLike over the session — open water will feel colder still. '
            '(Water temperature data comes in a later version.)',
      );
    } else if (airAtMost(TempBand.mildWarm)) {
      add(
        BodyPart.torso,
        'Wetsuit',
        'Mild air at $feels° — most swimmers still want neoprene in open water.',
        optional: true,
      );
      add(
        BodyPart.torso,
        'Swimsuit / trisuit',
        'Your base layer in the water.',
      );
    } else {
      add(
        BodyPart.torso,
        'Swimsuit / trisuit',
        '$feelsLike — warm enough to skip neoprene for most.',
      );
    }
    if (wetsuitNeeded || f.windy) {
      add(
        BodyPart.torso,
        'Dry robe or warm layer for after',
        f.windy
            ? 'Wind up to ${f.maxWindKmh.round()} km/h chills you the second you\'re out.'
            : 'At $feels° you\'ll cool down fast once you\'re out.',
        trigger: f.windy ? GearTrigger.wind : GearTrigger.none,
      );
    }
    add(BodyPart.torso, 'Towel', 'Always in the swim bag.');

    // Hands
    if (airAtMost(TempBand.cold)) {
      add(
        BodyPart.hands,
        'Neoprene gloves',
        'Air $feelsLike over the session — fingers go numb quickly in cold water.',
      );
    }

    // Legs
    if (!wetsuitNeeded) {
      add(
        BodyPart.legs,
        'Jammers / suit bottoms',
        'Part of your swim base layer.',
      );
    }

    // Feet
    if (airAtMost(TempBand.chilly)) {
      add(
        BodyPart.feet,
        'Neoprene booties',
        'Cold-water session — feet lose heat fast.',
      );
    }
    add(
      BodyPart.feet,
      'Sandals for the shore',
      'Rocky or cold beach entries.',
      optional: true,
    );
  }
}

/// Groups a kit flat list by body part, preserving the part order.
Map<BodyPart, List<GearItem>> groupKit(List<GearItem> items) => {
  for (final part in BodyPart.values)
    part: [
      for (final item in items)
        if (item.part == part) item,
    ],
};
