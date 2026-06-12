/// Month initials used as chart axis labels, January to December.
const List<String> monthLetters = [
  'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
];

/// Full month names, January to December.
const List<String> monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;

/// A city with approximate 1991-2020 monthly climate normals.
class City {
  const City({
    required this.name,
    required this.country,
    required this.flag,
    required this.climate,
    required this.latitude,
    required this.highC,
    required this.lowC,
    required this.precipMm,
  });

  final String name;
  final String country;
  final String flag;

  /// Friendly climate-type label, e.g. "Oceanic" or "Tropical".
  final String climate;

  /// Approximate latitude in degrees; negative means southern hemisphere.
  final double latitude;

  /// Average daily high per month, January to December, in degrees Celsius.
  final List<double> highC;

  /// Average daily low per month, January to December, in degrees Celsius.
  final List<double> lowC;

  /// Average precipitation per month, January to December, in millimeters.
  final List<double> precipMm;

  String get label => '$flag $name, $country';

  bool get southernHemisphere => latitude < 0;

  double get annualMeanC {
    var sum = 0.0;
    for (var m = 0; m < 12; m++) {
      sum += (highC[m] + lowC[m]) / 2;
    }
    return sum / 12;
  }

  double get annualPrecipMm => precipMm.reduce((a, b) => a + b);

  int get hottestMonth => _indexOfMax(highC);

  int get coldestMonth => _indexOfMin(lowC);

  int get wettestMonth => _indexOfMax(precipMm);
}

int _indexOfMax(List<double> values) {
  var best = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[best]) best = i;
  }
  return best;
}

int _indexOfMin(List<double> values) {
  var best = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] < values[best]) best = i;
  }
  return best;
}
