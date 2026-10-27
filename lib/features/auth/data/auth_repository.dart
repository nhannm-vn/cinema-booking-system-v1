import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/app_user.dart';

/// Repository handling authentication and profile loading with Supabase.
/// References: TECH_STACK.md Section 7 & PROJECT_STRUCTURE.md Section 3
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  User? get currentAuthUser => _supabase.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Load current user profile from `profiles` table.
  Future<AppUser?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return AppUser.fromMap(data, email: user.email);
    } catch (_) {
      return null;
    }
  }

  /// Sign in with email and password.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Đăng nhập thất bại.');
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    final profile = AppUser.fromMap(data, email: user.email);

    if (profile.isLocked) {
      await signOut();
      throw Exception('Tài khoản đã bị khóa.');
    }

    return profile;
  }

  /// Sign up a new customer account.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Đăng ký thất bại.');
    }

    // Update phone if provided
    if (phone != null && phone.isNotEmpty) {
      await _supabase
          .from('profiles')
          .update({'phone': phone})
          .eq('id', user.id);
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return AppUser.fromMap(data, email: user.email);
  }

  /// Update customer profile (full_name, phone).
  Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');

    final data = await _supabase
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
        })
        .eq('id', user.id)
        .select()
        .single();

    return AppUser.fromMap(data, email: user.email);
  }

  /// Sign out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
