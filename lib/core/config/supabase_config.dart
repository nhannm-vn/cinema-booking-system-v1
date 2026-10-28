/// Supabase configuration constants loaded from --dart-define or directly configured.
/// References: TECH_STACK.md Section 12 & PROJECT_STRUCTURE.md
abstract final class SupabaseConfig {
  // 1. Đọc từ biến môi trường --dart-define (Khuyên dùng khi build Production/CI)
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // 2. Điền trực tiếp URL & Anon Key của bạn vào 2 biến dưới đây để bấm Run/F5 chạy ngay:
  static const String _directUrl = ''; // Ví dụ: 'https://xyzcompany.supabase.co'
  static const String _directAnonKey = ''; // Ví dụ: 'eyJhbGciOiJIUzI1Ni...'

  static String get url => _envUrl.isNotEmpty ? _envUrl : _directUrl;
  static String get anonKey => _envAnonKey.isNotEmpty ? _envAnonKey : _directAnonKey;

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
