import 'package:flutter/material.dart';

import 'screens/quick_session_page.dart';
import 'services/prefs_store.dart';
import 'services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await PrefsStore.load();
  runApp(TwinClimateApp(store: store, weather: OpenMeteoWeatherService()));
}

class TwinClimateApp extends StatelessWidget {
  const TwinClimateApp({super.key, required this.store, required this.weather});

  final PrefsStore store;
  final WeatherService weather;

  static const _seedColor = Color(0xFF00696D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TwinClimate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _seedColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: QuickSessionPage(store: store, weather: weather),
    );
  }
}
