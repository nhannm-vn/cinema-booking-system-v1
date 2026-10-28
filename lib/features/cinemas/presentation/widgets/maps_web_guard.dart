import 'maps_web_guard_stub.dart'
    if (dart.library.html) 'maps_web_guard_web.dart';

/// Returns true if Google Maps SDK is loaded and ready for rendering.
bool isGoogleMapsReady() => isGoogleMapsAvailable();
