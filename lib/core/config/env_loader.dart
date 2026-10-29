import 'env_loader_stub.dart'
    if (dart.library.html) 'env_loader_web.dart'
    if (dart.library.io) 'env_loader_io.dart';

/// Loads key-value pairs from .env dynamically at runtime.
Future<Map<String, String>> loadLocalEnv() => loadEnvImpl();
