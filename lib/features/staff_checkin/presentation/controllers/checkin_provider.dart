import 'package:flutter/material.dart';
import '../../data/checkin_repository.dart';

/// Presentation Controller for S18 Ticket Check-in.
/// References: ROLE_FLOWS.md Section 3.1 & BUSINESS_RULES.md Section 8
class CheckinProvider extends ChangeNotifier {
  final CheckinRepository _repo;

  CheckinProvider([CheckinRepository? repo])
      : _repo = repo ?? CheckinRepository();

  bool _isLoading = false;
  String? _errorMessage;
  CheckinResult? _lastResult;
  bool _isIdVerified = false;
  String? _currentScannedCode;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CheckinResult? get lastResult => _lastResult;
  bool get isIdVerified => _isIdVerified;
  String? get currentScannedCode => _currentScannedCode;

  /// Thực hiện kiểm tra mã vé qua RPC check_in.
  Future<CheckinResult> checkIn(String code) async {
    final normalized = code.trim().toUpperCase();
    _currentScannedCode = normalized;
    _isIdVerified = false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repo.checkIn(normalized);
      _lastResult = result;
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      final result = CheckinResult(
        isSuccess: false,
        message: 'Lỗi kiểm tra vé: ${e.toString()}',
      );
      _lastResult = result;
      _errorMessage = result.message;
      _isLoading = false;
      notifyListeners();
      return result;
    }
  }

  /// Cập nhật xác nhận giấy tờ tùy thân cho phim T16/T18.
  void setIdVerified(bool verified) {
    _isIdVerified = verified;
    notifyListeners();
  }

  /// Khởi tạo lại trạng thái quét để tiếp tục lượt soát vé mới.
  void resetScan() {
    _lastResult = null;
    _currentScannedCode = null;
    _isIdVerified = false;
    _errorMessage = null;
    notifyListeners();
  }
}
