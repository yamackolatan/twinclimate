import 'package:flutter/material.dart';

import 'screens/quick_session_page.dart';
import 'services/prefs_store.dart';
import 'services/weather_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await PrefsStore.load();
  runApp(TwinClimateApp(store: store, weather: OpenMeteoWeatherService()));
}

class TwinClimateApp extends StatelessWidget {
  const TwinClimateApp({super.key, required this.store, required this.weather});

  final PrefsStore store;
  final WeatherService weather;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TwinClimate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: QuickSessionPage(store: store, weather: weather),
    );
  }
}
