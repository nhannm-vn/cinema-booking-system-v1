// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Loads .env via HTTP request from dev server on Flutter Web.
Future<Map<String, String>> loadEnvImpl() async {
  try {
    final response = await html.HttpRequest.getString('/.env');
    return _parseEnv(response);
  } catch (_) {
    return const {};
  }
}

Map<String, String> _parseEnv(String content) {
  final map = <String, String>{};
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx != -1) {
      final key = trimmed.substring(0, idx).trim();
      final value = trimmed.substring(idx + 1).trim();
      map[key] = value;
    }
  }
  return map;
}
