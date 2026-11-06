/// Stub for non-web platforms.
/// Returns true only if GOOGLE_MAPS_API_KEY is configured.
/// Without an API key, Google Maps SDK for iOS raises a fatal NSInvalidArgumentException
/// which immediately crashes the app on iPhone.
bool isGoogleMapsAvailable() {
  const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  return apiKey.isNotEmpty;
}
