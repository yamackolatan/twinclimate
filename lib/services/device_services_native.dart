import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

/// Phone app (iOS) versions, using the system location and share sheet.

/// Current position as (latitude, longitude), or null when unavailable or
/// refused.
Future<(double, double)?> currentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (p.latitude, p.longitude);
  } catch (_) {
    return null;
  }
}

/// Opens the system share sheet with [text]. Returns false when sharing
/// isn't available (callers then copy to the clipboard instead).
Future<bool> shareText(String text) async {
  try {
    await SharePlus.instance.share(ShareParams(text: text));
    return true;
  } catch (_) {
    return false;
  }
}
