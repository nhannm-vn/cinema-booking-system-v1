import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/refund_request_model.dart';

/// Repository đọc yêu cầu hoàn vé cho Admin.
/// Ghi (tạo / hoàn tất) chỉ đi qua RPC request_refund và webhook SePay (complete_refund).
class RefundRepository {
  final SupabaseClient _supabase;

  RefundRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<RefundRequestModel>> getRefundRequests({String? status}) async {
    var query = _supabase.from('refund_requests').select();
    if (status != null && status != 'ALL') {
      query = query.eq('status', status);
    }
    final response = await query.order('created_at', ascending: false).limit(200);
    return (response as List)
        .map((e) => RefundRequestModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<RefundRequestModel?> getRefundRequestById(String id) async {
    final response = await _supabase
        .from('refund_requests')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return RefundRequestModel.fromMap(response);
  }

  RealtimeChannel subscribe(void Function() onChange) {
    return _supabase
        .channel('public:refund_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'refund_requests',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
