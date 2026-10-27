import 'package:flutter/material.dart';
import '../../data/movie_model.dart';
import '../../data/movie_repository.dart';

/// Provider managing movie discovery, categorisation, and search.
class MovieProvider extends ChangeNotifier {
  final MovieRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  List<MovieModel> _allMovies = [];
  String _searchQuery = '';

  MovieProvider([MovieRepository? repo]) : _repo = repo ?? MovieRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<MovieModel> get nowShowing =>
      _allMovies.where((m) => m.isNowShowing).toList();

  List<MovieModel> get upcoming =>
      _allMovies.where((m) => m.isUpcoming).toList();

  List<MovieModel> get searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _allMovies.where((m) => m.title.toLowerCase().contains(q)).toList();
  }

  Future<void> loadMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allMovies = await _repo.getActiveMovies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách phim. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}
