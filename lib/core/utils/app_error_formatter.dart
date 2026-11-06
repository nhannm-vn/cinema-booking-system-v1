import 'package:supabase_flutter/supabase_flutter.dart';

/// Bộ chuyển đổi lỗi kỹ thuật (Exceptions) thành thông điệp tiếng Việt thân thiện với người dùng.
/// Tuyệt đối không hiển thị PostgrestException, AuthApiException, FunctionException hay stack trace thô cho người dùng.
abstract final class AppErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';

    // 1. Auth exceptions từ Supabase Auth
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final code = error.code?.toLowerCase() ?? '';

      if (code == 'over_email_send_rate_limit' ||
          msg.contains('after 10 seconds') ||
          msg.contains('rate limit')) {
        return 'Bạn đang thao tác quá nhanh. Vui lòng đợi 10 giây trước khi thử lại.';
      }
      if (code == 'user_already_exists' ||
          msg.contains('already registered') ||
          msg.contains('already been registered')) {
        return 'Email này đã được đăng ký trong hệ thống. Vui lòng đăng nhập hoặc dùng email khác.';
      }
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login credentials')) {
        return 'Email hoặc mật khẩu không chính xác.';
      }
      if (code == 'email_not_confirmed' ||
          msg.contains('email not confirmed')) {
        return 'Tài khoản chưa được xác thực email. Vui lòng kiểm tra hộp thư của bạn.';
      }
      if (code == 'weak_password' ||
          msg.contains('password should be at least')) {
        return 'Mật khẩu quá ngắn. Vui lòng nhập tối thiểu 6 ký tự.';
      }
      if (code == 'invalid_email' ||
          code == 'email_address_invalid' ||
          msg.contains('unable to validate email') ||
          (msg.contains('email address') && msg.contains('invalid'))) {
        return 'Địa chỉ email không hợp lệ. Vui lòng dùng email thật (ví dụ @gmail.com).';
      }
      if (code == 'unexpected_failure' || msg.contains('database error saving new user')) {
        return 'Không thể tạo hồ sơ tài khoản (số điện thoại có thể đã được dùng). Vui lòng thử lại với thông tin khác.';
      }
      if (code == 'signup_disabled' || msg.contains('signups not allowed')) {
        return 'Hệ thống đang tạm khóa đăng ký tài khoản mới.';
      }
      if (code == 'over_request_rate_limit' || msg.contains('too many requests')) {
        return 'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau ít phút.';
      }
      return 'Đăng ký / đăng nhập không thành công. Vui lòng kiểm tra lại thông tin.';
    }

    // 2. PostgREST database exceptions
    if (error is PostgrestException) {
      if (error.code == 'PGRST116' || error.message.contains('0 rows')) {
        return 'Không tìm thấy dữ liệu hồ sơ tài khoản.';
      }
      if (error.code == '23505' || error.message.contains('duplicate key')) {
        return 'Thông tin (email hoặc số điện thoại) đã tồn tại trong hệ thống.';
      }
      return 'Lỗi truy xuất cơ sở dữ liệu. Vui lòng thử lại sau.';
    }

    // 3. Supabase Edge Functions exception
    if (error is FunctionException) {
      if (error.details is Map && error.details['error'] != null) {
        return error.details['error'].toString();
      }
      if (error.reasonPhrase != null && error.reasonPhrase!.isNotEmpty) {
        return error.reasonPhrase!;
      }
      return 'Lỗi thực thi dịch vụ máy chủ.';
    }

    // 4. String hoặc Exception đã bị stringify
    final raw = error.toString().replaceFirst('Exception: ', '').trim();

    // Bắt chuỗi lỗi PostgrestException bị bọc
    if (raw.contains('PostgrestException') || raw.contains('PGRST116')) {
      return 'Không tìm thấy dữ liệu hồ sơ tài khoản.';
    }

    // Bắt chuỗi lỗi AuthApiException / AuthException bị bọc
    if (raw.contains('AuthApiException') || raw.contains('AuthException')) {
      if (raw.contains('over_email_send_rate_limit') || raw.contains('after 10 seconds')) {
        return 'Bạn đang thao tác quá nhanh. Vui lòng đợi 10 giây trước khi thử lại.';
      }
      if (raw.contains('user_already_exists') || raw.contains('already registered') || raw.contains('already been registered')) {
        return 'Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.';
      }
      if (raw.contains('Invalid login credentials')) {
        return 'Email hoặc mật khẩu không chính xác.';
      }
      if (raw.contains('Email not confirmed')) {
        return 'Tài khoản chưa được xác thực email. Vui lòng kiểm tra hộp thư của bạn.';
      }
      return 'Lỗi xác thực tài khoản. Vui lòng thử lại.';
    }

    // Lỗi mạng hoặc không gọi được server
    if (raw.contains('Failed to fetch') ||
        raw.contains('ClientException') ||
        raw.contains('SocketException') ||
        raw.contains('Connection refused') ||
        raw.contains('NetworkImage')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
    }

    if (raw.contains('Tài khoản đã bị khóa')) {
      return 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản lý.';
    }

    return raw.isNotEmpty ? raw : 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
