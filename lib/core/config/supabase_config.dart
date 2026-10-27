/// Supabase configuration constants loaded from --dart-define.
/// References: TECH_STACK.md Section 12 & PROJECT_STRUCTURE.md
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
