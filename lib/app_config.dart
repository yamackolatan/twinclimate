/// Build switches.
///
/// The App Store version is built with `--dart-define=STORE_BUILD=true`
/// (see codemagic.yaml). It leaves out the Decathlon shopping demo: Apple
/// rejects apps labelled as demos (guideline 2.2) and apps that use another
/// company's brand without permission (5.2). The website keeps the demo for
/// investor and partner pitches.
const bool storeBuild = bool.fromEnvironment('STORE_BUILD');

/// Shop links, race-day product picks, "My gear & shopping" and the
/// Partner demo screen.
const bool shoppingDemo = !storeBuild;

/// Shown on the About screen; keep in step with `version:` in pubspec.yaml.
const String appVersion = '1.0.0';
