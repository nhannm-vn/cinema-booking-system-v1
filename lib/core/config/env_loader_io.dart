import 'dart:io';

/// Loads .env from local file system on Dart VM (tests, mobile, desktop).
Future<Map<String, String>> loadEnvImpl() async {
  try {
    final file = File('.env');
    if (await file.exists()) {
      final content = await file.readAsString();
      return _parseEnv(content);
    }
  } catch (_) {}
  return const {};
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
