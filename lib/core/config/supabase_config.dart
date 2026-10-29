import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_loader.dart';

/// Supabase configuration constants loaded strictly from .env.
/// Supports both compile-time (--dart-define-from-file=.env) and runtime .env loading.
/// References: TECH_STACK.md Section 12 & PROJECT_STRUCTURE.md
abstract final class SupabaseConfig {
  static const String _compileTimeUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _compileTimeAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String _runtimeUrl = '';
  static String _runtimeAnonKey = '';

  static String get url => _compileTimeUrl.isNotEmpty ? _compileTimeUrl : _runtimeUrl;
  static String get anonKey => _compileTimeAnonKey.isNotEmpty ? _compileTimeAnonKey : _runtimeAnonKey;

  static bool get isConfigured {
    if (url.isNotEmpty && anonKey.isNotEmpty) return true;
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads configuration from .env if compile-time variables were not provided.
  static Future<void> initialize() async {
    if (isConfigured) return;
    final env = await loadLocalEnv();
    if (_compileTimeUrl.isEmpty && env.containsKey('SUPABASE_URL')) {
      _runtimeUrl = env['SUPABASE_URL'] ?? '';
    }
    if (_compileTimeAnonKey.isEmpty && env.containsKey('SUPABASE_ANON_KEY')) {
      _runtimeAnonKey = env['SUPABASE_ANON_KEY'] ?? '';
    }
  }
}
