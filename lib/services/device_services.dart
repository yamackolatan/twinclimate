/// Browser features the app uses where available: the device's location
/// and the system share sheet. Off the web (tests) they report "not
/// available" and callers fall back gracefully.
library;

export 'device_services_stub.dart'
    if (dart.library.js_interop) 'device_services_web.dart';
