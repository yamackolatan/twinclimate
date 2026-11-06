/// Current position as (latitude, longitude), or null when unavailable or
/// refused.
Future<(double, double)?> currentPosition() async => null;

/// Opens the system share sheet with [text]. Returns false when sharing
/// isn't available (callers then copy to the clipboard instead).
Future<bool> shareText(String text) async => false;
