/// Device features the app uses: the current location and the system share
/// sheet. The website uses the browser's versions; the phone app the
/// system's. Both report "not available" gracefully (null / false).
library;

export 'device_services_native.dart'
    if (dart.library.js_interop) 'device_services_web.dart';
