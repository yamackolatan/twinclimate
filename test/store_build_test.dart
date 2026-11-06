import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twinclimate/app_config.dart';
import 'package:twinclimate/screens/about_page.dart';
import 'package:twinclimate/screens/quick_session_page.dart';
import 'package:twinclimate/services/prefs_store.dart';

import 'app_flow_test.dart' show FakeWeatherService;

/// Run with `flutter test --dart-define=STORE_BUILD=true` (as Codemagic's
/// App Store build does) to check the shopping demo is fully hidden.
void main() {
  testWidgets('App Store build: no shopping demo anywhere in the flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsStore.load();
    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionPage(store: store, weather: FakeWeatherService()),
      ),
    );
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('About & privacy'), findsOneWidget);
    expect(
      find.text('My gear & shopping'),
      storeBuild ? findsNothing : findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('What should I wear?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Decathlon'),
      storeBuild ? findsNothing : findsWidgets,
    );
  });

  testWidgets('About & privacy shows the credits and privacy link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    expect(find.text('Version $appVersion'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Weather data by Open-Meteo.com'), findsOneWidget);
    expect(
      find.text('Place names © OpenStreetMap contributors'),
      findsOneWidget,
    );
  });
}
