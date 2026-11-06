import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Current position as (latitude, longitude), or null when unavailable or
/// refused.
Future<(double, double)?> currentPosition() {
  final done = Completer<(double, double)?>();
  try {
    web.window.navigator.geolocation.getCurrentPosition(
      ((web.GeolocationPosition p) {
        if (!done.isCompleted) {
          done.complete((p.coords.latitude, p.coords.longitude));
        }
      }).toJS,
      ((web.GeolocationPositionError _) {
        if (!done.isCompleted) done.complete(null);
      }).toJS,
      web.PositionOptions(timeout: 15000, maximumAge: 300000),
    );
  } catch (_) {
    if (!done.isCompleted) done.complete(null);
  }
  return done.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => null,
  );
}

/// Opens the system share sheet with [text]. Returns false when sharing
/// isn't available (callers then copy to the clipboard instead).
Future<bool> shareText(String text) async {
  final data = web.ShareData(text: text);
  try {
    if (!web.window.navigator.canShare(data)) return false;
  } catch (_) {
    return false;
  }
  try {
    await web.window.navigator.share(data).toDart;
  } catch (_) {
    // Closing the share sheet also lands here; that's not a failure.
  }
  return true;
}
