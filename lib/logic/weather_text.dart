import 'package:flutter/material.dart';

/// Plain-English sky description for a WMO weather code.
String weatherDescription(int code) {
  switch (code) {
    case 0:
      return 'Clear sky';
    case 1:
      return 'Mainly clear';
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Overcast';
    case 45:
    case 48:
      return 'Foggy';
    case 51:
    case 53:
    case 55:
      return 'Drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
      return 'Light rain';
    case 63:
      return 'Rain';
    case 65:
      return 'Heavy rain';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
      return 'Light snow';
    case 73:
      return 'Snow';
    case 75:
      return 'Heavy snow';
    case 77:
      return 'Snow grains';
    case 80:
      return 'Light showers';
    case 81:
      return 'Showers';
    case 82:
      return 'Heavy showers';
    case 85:
    case 86:
      return 'Snow showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Thunderstorm with hail';
    default:
      return 'Mixed conditions';
  }
}

IconData weatherIcon(int code, {required bool isDay}) {
  if (code <= 1) return isDay ? Icons.wb_sunny : Icons.nights_stay;
  if (code == 2) return Icons.wb_cloudy;
  if (code == 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 51 && code <= 57) return Icons.water_drop;
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
    return Icons.umbrella;
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return Icons.ac_unit;
  }
  if (code >= 95) return Icons.thunderstorm;
  return Icons.cloud;
}

/// Short wind note for the summary line, e.g. "breezy 22 km/h".
String windPhrase(double windKmh, double gustKmh) {
  final wind = windKmh.round();
  final String word;
  if (windKmh < 12) {
    word = 'calm';
  } else if (windKmh < 20) {
    word = 'light breeze';
  } else if (windKmh < 29) {
    word = 'breezy';
  } else if (windKmh < 39) {
    word = 'windy';
  } else {
    word = 'very windy';
  }
  final gustNote =
      gustKmh >= 45 ? ', gusts to ${gustKmh.round()} km/h' : '';
  return '$word $wind km/h$gustNote';
}
