import 'package:flutter/material.dart';
import '../../data/cinema_model.dart';
import '../../data/cinema_repository.dart';
import '../../data/location_service.dart';

/// Provider for Cinemas and GPS distance.
class CinemaProvider extends ChangeNotifier {
  final CinemaRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  List<CinemaModel> _cinemas = [];
  CinemaModel? _selectedCinema;

  CinemaProvider([CinemaRepository? repo]) : _repo = repo ?? CinemaRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CinemaModel> get cinemas => _cinemas;
  CinemaModel? get selectedCinema => _selectedCinema;

  Future<void> loadCinemas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();
      _cinemas = await _repo.getActiveCinemas(userPosition: position);
      if (_cinemas.isNotEmpty && _selectedCinema == null) {
        _selectedCinema = _cinemas.first;
      }
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Không thể tải danh sách rạp.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCinema(CinemaModel cinema) {
    _selectedCinema = cinema;
    notifyListeners();
  }
}
