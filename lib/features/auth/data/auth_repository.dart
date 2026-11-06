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

      if (data == null) {
        return AppUser(
          id: user.id,
          fullName: (user.userMetadata?['full_name'] as String?) ?? '',
          phone: user.userMetadata?['phone'] as String?,
          role: UserRole.customer,
          email: user.email,
        );
      }
      final profile = AppUser.fromMap(data, email: user.email);
      if (profile.isLocked) {
        await signOut();
        return null;
      }
      return profile;
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

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final profile = AppUser.fromMap(data, email: user.email);
        if (profile.isLocked) {
          await signOut();
          throw Exception('Tài khoản đã bị khóa. Vui lòng liên hệ ban quản lý.');
        }
        return profile;
      }
    } catch (e) {
      if (e.toString().contains('Tài khoản đã bị khóa')) rethrow;
    }

    return AppUser(
      id: user.id,
      fullName: (user.userMetadata?['full_name'] as String?) ?? '',
      phone: user.userMetadata?['phone'] as String?,
      role: UserRole.customer,
      email: user.email,
    );
  }

  /// Sign up a new customer account.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final metadata = <String, dynamic>{
      'full_name': fullName,
    };
    if (phone != null && phone.isNotEmpty) {
      metadata['phone'] = phone;
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Đăng ký không thành công. Vui lòng kiểm tra lại thông tin.');
    }
    if (user.identities != null && user.identities!.isEmpty) {
      throw Exception('Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.');
    }

    // 1. Trường hợp có session ngay lập tức
    if (response.session != null) {
      if (phone != null && phone.isNotEmpty) {
        try {
          await _supabase
              .from('profiles')
              .update({'phone': phone})
              .eq('id', user.id);
        } catch (_) {}
      }

      try {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          return AppUser.fromMap(data, email: user.email);
        }
      } catch (_) {}

      return AppUser(
        id: user.id,
        fullName: fullName,
        phone: phone,
        role: UserRole.customer,
        email: user.email,
      );
    }

    // 2. Trường hợp session == null (do Supabase Auth bật xác nhận email hoặc chưa tự sinh session)
    try {
      final loggedIn = await signIn(email: email, password: password);
      return loggedIn;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('email not confirmed') || errStr.contains('confirm')) {
        throw Exception(
          'Đăng ký tài khoản thành công! Vui lòng kiểm tra email của bạn để xác thực tài khoản trước khi đăng nhập.',
        );
      }

      return AppUser(
        id: user.id,
        fullName: fullName,
        phone: phone,
        role: UserRole.customer,
        email: user.email,
      );
    }
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
        .maybeSingle();

    if (data != null) {
      return AppUser.fromMap(data, email: user.email);
    }

    return AppUser(
      id: user.id,
      fullName: fullName,
      phone: phone,
      role: UserRole.customer,
      email: user.email,
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
