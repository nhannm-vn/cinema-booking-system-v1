import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository handling VNPay payment initiation through Supabase Edge Function.
/// References: TECH_STACK.md Section 8 & BUSINESS_RULES.md Section 6.2
class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Invoke Edge Function `create-vnpay-url` to get secure payment URL.
  Future<String> createVNPayUrl({
    required String bookingCode,
    required String txnRef,
    String? returnUrl,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-vnpay-url',
      body: {
        'booking_code': bookingCode,
        'txn_ref': txnRef,
        'return_url': returnUrl ?? 'cinemaapp://vnpay-return',
        'ip': '127.0.0.1',
      },
    );

    if (response.status != 200) {
      throw Exception('Không thể tạo liên kết thanh toán VNPay.');
    }

    final data = response.data as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('URL thanh toán không hợp lệ.');
    }

    return url;
  }
}
