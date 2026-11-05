import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/refund_request_model.dart';
import '../../data/repositories/refund_repository.dart';

/// Provider cho màn Admin duyệt yêu cầu hoàn vé (realtime theo webhook SePay).
class RefundRequestsProvider extends ChangeNotifier {
  final RefundRepository _repo;
  RealtimeChannel? _channel;

  bool _isLoading = false;
  String? _errorMessage;
  String _statusFilter = 'pending';
  List<RefundRequestModel> _requests = [];

  final Map<String, RefundRequestModel> _details = {};

  RefundRequestsProvider([RefundRepository? repo]) : _repo = repo ?? RefundRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;
  List<RefundRequestModel> get requests => _requests;

  Future<void> load({String? status, bool silent = false}) async {
    if (status != null) _statusFilter = status;
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      _requests = await _repo.getRefundRequests(status: _statusFilter);
      for (final r in _requests) {
        _details[r.id] = r;
      }
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Không thể tải danh sách yêu cầu hoàn vé.';
    }
    _isLoading = false;
    notifyListeners();
  }

  void startRealtime() {
    _channel ??= _repo.subscribe(() => load(silent: true));
  }

  RefundRequestModel? findById(String id) {
    if (_details.containsKey(id)) return _details[id];
    for (final r in _requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<RefundRequestModel?> refreshRequest(String id) async {
    try {
      final req = await _repo.getRefundRequestById(id);
      if (req != null) {
        final prev = _details[id];
        _details[id] = req;

        // If status changed, refresh the filtered list in background
        if (prev != null && prev.status != req.status) {
          load(silent: true);
        } else {
          notifyListeners();
        }
        return req;
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
