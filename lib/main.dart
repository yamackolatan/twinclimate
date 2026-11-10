import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      // European conventions: weeks start on Monday, 24-hour clock.
      locale: const Locale('en', 'GB'),
      supportedLocales: const [Locale('en', 'GB')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
      home: QuickSessionPage(store: store, weather: weather),
    );
  }
}
