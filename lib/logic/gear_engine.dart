import '../models/comfort.dart';
import '../models/gear.dart';
import '../models/session.dart';
import '../models/weather.dart';

/// Temperature bands the gear rules are written against, based on the
/// session's mean "feels like" temperature.
enum TempBand { freezing, cold, cool, mild, warm, hot }

TempBand bandFor(double apparentC) {
  if (apparentC < 0) return TempBand.freezing;
  if (apparentC < 6) return TempBand.cold;
  if (apparentC < 12) return TempBand.cool;
  if (apparentC < 18) return TempBand.mild;
  if (apparentC < 24) return TempBand.warm;
  return TempBand.hot;
}

/// Zero-data comfort baseline (PRD decision 4): with no feedback yet,
/// sport defaults apply. Runners tolerate breeze on legs and torso, so
/// those parts are treated a few degrees warmer than the air says.
/// Cyclists make their own headwind, so torso, hands, head and feet are
/// treated colder. Returned value is added to the felt temperature before
/// picking a band. The F4 comfort profile will later add a learned,
/// per-user shift on top of this.
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
/// With a [comfort] profile (F4), each body part's felt temperature gets
/// the user's personal shift. Items that end up different from the
/// standard suggestion say why ("You run warm above 15°C, …").
List<GearItem> buildKit(
  Sport sport,
  SessionForecast forecast, {
  double distanceKm = 0,
  ComfortProfile? comfort,
}) {
  final standard = _build(sport, forecast, distanceKm, const {});
  if (comfort == null) return standard;
  final zone = TempZone.of(forecast.meanApparentC);
  final shifts = {
    for (final part in BodyPart.values) part: comfort.shiftC(sport, part, zone),
  };
  if (shifts.values.every((s) => s == 0)) return standard;
  final personal = _build(sport, forecast, distanceKm, shifts);
  return [
    for (final item in personal)
      if (shifts[item.part] != 0 &&
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
  Map<BodyPart, double> shifts,
) {
  final builder = _KitBuilder(sport, forecast, distanceKm, shifts);
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

/// "You run warm above 15°C, so this is lighter than usual." The learned
/// part wins; otherwise the Settings slider is quoted.
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
/// weather-independent-of-rain item), for the "Did you wear that?" check.
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
  _KitBuilder(this.sport, this.f, this.distanceKm, this.shifts);

  final Sport sport;
  final SessionForecast f;
  final double distanceKm;

  /// Personal comfort shift per body part (°C), from the F4 profile.
  final Map<BodyPart, double> shifts;
  final List<GearItem> items = [];

  /// Long enough that blister prevention deserves a mention.
  bool get distanceIsLong => sport == Sport.run && distanceKm >= 15;

  /// Felt temperature for a body part, including the sport baseline.
  double feltC(BodyPart part) =>
      f.meanApparentC + sportPartAdjustment(sport, part) + (shifts[part] ?? 0);

  TempBand band(BodyPart part) => bandFor(feltC(part));

  /// The number quoted in reasons: the real session feels-like, rounded.
  int get feels => f.meanApparentC.round();

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
      case TempBand.freezing:
        add(
          BodyPart.head,
          'Warm beanie',
          'Session feels like $feels° — you lose a lot of heat bare-headed.',
        );
      case TempBand.cold:
        add(
          BodyPart.head,
          'Thin beanie or headband',
          'Session feels like $feels° — keeps ears warm without overheating.',
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
          'Session feels like $feels° — heat builds fast on the run.$humidNote',
        );
      case TempBand.warm:
        add(
          BodyPart.torso,
          'Light short-sleeve tech tee',
          'Session feels like $feels° and runners warm up quickly.$humidNote',
        );
      case TempBand.mild:
        add(
          BodyPart.torso,
          'Short-sleeve tee',
          'Session feels like $feels° — comfortable once you are moving.',
        );
        add(
          BodyPart.torso,
          'Light long sleeve to start',
          'A touch cool for the first 10 minutes; tie it round your waist after.',
          optional: true,
        );
      case TempBand.cool:
        add(
          BodyPart.torso,
          'Long-sleeve base layer',
          'Session feels like $feels° — long sleeves, but nothing heavy: you generate heat on the move.',
        );
      case TempBand.cold:
        add(
          BodyPart.torso,
          'Base layer + light running jacket',
          'Session feels like $feels° — two thin layers beat one thick one.',
        );
      case TempBand.freezing:
        add(
          BodyPart.torso,
          'Thermal base layer + running jacket',
          'Session feels like $feels° — protect your core, vent with the zip.',
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
      case TempBand.freezing:
        add(
          BodyPart.hands,
          'Warm running gloves',
          'Session feels like $feels° — fingers lose heat fastest.',
        );
      case TempBand.cold:
        add(
          BodyPart.hands,
          'Thin gloves',
          'Session feels like $feels° — easy to stash once your hands warm up.',
        );
      case TempBand.cool:
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
      case TempBand.freezing:
        add(
          BodyPart.legs,
          'Thermal running tights',
          'Session feels like $feels° — full insulation today.',
        );
      case TempBand.cold:
        add(
          BodyPart.legs,
          'Running tights',
          'Session feels like $feels° — too cold for bare legs, even on the run.',
        );
      case TempBand.cool:
        add(
          BodyPart.legs,
          'Shorts',
          'Session feels like $feels°, but runners\' legs run warm — most prefer shorts here.',
        );
      default:
        add(
          BodyPart.legs,
          'Shorts',
          'Session feels like $feels° — an easy shorts day.',
        );
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
    final b = band(BodyPart.head);
    if (b == TempBand.freezing || b == TempBand.cold) {
      add(
        BodyPart.head,
        'Thermal skull cap under the helmet',
        'Session feels like $feels° plus riding windchill on your ears.',
      );
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
    switch (band(BodyPart.torso)) {
      case TempBand.hot:
        add(
          BodyPart.torso,
          'Lightweight summer jersey',
          'Session feels like $feels° — go as breathable as you own.',
        );
      case TempBand.warm:
        add(
          BodyPart.torso,
          'Short-sleeve jersey',
          'Session feels like $feels° — standard short-sleeve weather.',
        );
      case TempBand.mild:
        add(
          BodyPart.torso,
          'Jersey + arm warmers',
          'Session feels like $feels° but riding at 25 km/h makes its own windchill.',
        );
      case TempBand.cool:
        add(
          BodyPart.torso,
          'Long-sleeve jersey',
          'Session feels like $feels° — cool air plus riding windchill.',
        );
      case TempBand.cold:
        add(
          BodyPart.torso,
          'Long-sleeve jersey + thermal gilet',
          'Session feels like $feels° — keep the core warm, arms free.',
        );
      case TempBand.freezing:
        add(
          BodyPart.torso,
          'Winter cycling jacket',
          'Session feels like $feels° — full winter kit on the bike.',
        );
    }
    if (f.rainLikely) {
      add(
        BodyPart.torso,
        'Packable rain jacket',
        '$rainChance% rain chance — getting soaked on a bike gets cold fast.',
        trigger: GearTrigger.rain,
      );
    } else if (f.windy) {
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
      case TempBand.freezing:
        add(
          BodyPart.hands,
          'Winter gloves or lobster mitts',
          'Session feels like $feels° — braking fingers go numb first.',
        );
      case TempBand.cold:
        add(
          BodyPart.hands,
          'Insulated full-finger gloves',
          'Session feels like $feels° plus windchill on the bars.',
        );
      case TempBand.cool:
        add(
          BodyPart.hands,
          'Full-finger gloves',
          'Session feels like $feels° — windchill bites on descents.',
        );
      case TempBand.mild:
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
      case TempBand.freezing:
        add(
          BodyPart.legs,
          'Winter bib tights',
          'Session feels like $feels° — knees need full cover.',
        );
      case TempBand.cold:
        add(
          BodyPart.legs,
          'Thermal bib tights',
          'Session feels like $feels° — cold knees are slow knees.',
        );
      case TempBand.cool:
        add(
          BodyPart.legs,
          'Bib shorts + leg warmers',
          'Session feels like $feels° — warmers come off if it warms up.',
        );
      case TempBand.mild:
        add(
          BodyPart.legs,
          'Bib shorts + knee warmers',
          'Session feels like $feels° — protect the knees in cool moving air.',
        );
      default:
        add(
          BodyPart.legs,
          'Bib shorts',
          'Session feels like $feels° — standard bibs weather.',
        );
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
    } else {
      switch (band(BodyPart.feet)) {
        case TempBand.freezing:
          add(
            BodyPart.feet,
            'Insulated overshoes',
            'Session feels like $feels° — toes get no blood flow on the bike.',
          );
        case TempBand.cold:
          add(
            BodyPart.feet,
            'Toe covers',
            'Session feels like $feels° plus windchill — toes go numb first.',
          );
        case TempBand.cool:
          add(
            BodyPart.feet,
            'Mid-weight socks',
            'Session feels like $feels° — a little insulation goes a long way.',
          );
        default:
          break;
      }
    }
  }

  // --------------------------------------------------------------- swim --

  void buildSwim() {
    final airBand = band(BodyPart.torso);
    final coolOrColder = airBand.index <= TempBand.cool.index;

    // Head
    add(BodyPart.head, 'Bright silicone swim cap', 'Be visible in open water.');
    if (coolOrColder) {
      add(
        BodyPart.head,
        'Neoprene cap',
        'Air feels like $feels° over the session — expect cold water on the head.',
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
    if (coolOrColder) {
      add(
        BodyPart.torso,
        'Wetsuit',
        'Air feels like $feels° over the session — open water will feel colder still. '
            '(Water temperature data comes in a later version.)',
      );
    } else if (airBand == TempBand.mild) {
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
        'Session feels like $feels° — warm enough to skip neoprene for most.',
      );
    }
    if (coolOrColder || f.windy) {
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
    if (airBand == TempBand.freezing || airBand == TempBand.cold) {
      add(
        BodyPart.hands,
        'Neoprene gloves',
        'Air feels like $feels° over the session — fingers go numb quickly in cold water.',
      );
    }

    // Legs
    if (!coolOrColder) {
      add(
        BodyPart.legs,
        'Jammers / suit bottoms',
        'Part of your swim base layer.',
      );
    }

    // Feet
    if (coolOrColder) {
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
