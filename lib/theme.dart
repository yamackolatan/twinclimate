import 'package:flutter/material.dart';

/// The app's look in one place: rounded flat cards, pill buttons and
/// chips, and a calm teal palette that works in light and dark mode.
abstract final class AppTheme {
  static const seed = Color(0xFF00696D);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme;
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Colours for the result headline, from cold blue to hot red, chosen by
/// the session's felt temperature. Text on top is white.
List<Color> feelGradient(double feelsC, Brightness brightness) {
  final List<Color> colors;
  if (feelsC < 0) {
    colors = const [Color(0xFF3557A8), Color(0xFF5B7FD6)];
  } else if (feelsC < 7) {
    colors = const [Color(0xFF1F6FA3), Color(0xFF3F97C9)];
  } else if (feelsC < 13) {
    colors = const [Color(0xFF00696D), Color(0xFF2E9A8F)];
  } else if (feelsC < 20) {
    colors = const [Color(0xFF3C8A3E), Color(0xFF77AE45)];
  } else if (feelsC < 25) {
    colors = const [Color(0xFFC77700), Color(0xFFE6A23C)];
  } else {
    colors = const [Color(0xFFB3261E), Color(0xFFE2603A)];
  }
  if (brightness == Brightness.light) return colors;
  // Slightly deeper in dark mode so the card doesn't glare.
  return [for (final c in colors) Color.lerp(c, Colors.black, 0.25)!];
}

/// Padding for a scrolling page: 16 all round, plus room at the bottom for
/// the iPhone home indicator so the last button is never underneath it.
EdgeInsets pagePadding(BuildContext context) =>
    EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom);
