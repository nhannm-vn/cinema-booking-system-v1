// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Checks if window.google.maps is initialized on Flutter Web.
bool isGoogleMapsAvailable() {
  try {
    return js.context.hasProperty('google') &&
        (js.context['google'] as js.JsObject).hasProperty('maps');
  } catch (_) {
    return false;
  }
}
