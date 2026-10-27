import 'package:flutter/material.dart';
import '../../../../shared/models/app_user.dart';
import '../../data/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// Auth Provider managing login state and current user profile.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  AuthProvider([AuthRepository? repo]) : _repo = repo ?? AuthRepository() {
    _init();
  }

  AppUser? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _status == AuthStatus.loading;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _currentUser = await _repo.getCurrentProfile();
    _status = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();

    _repo.onAuthStateChange.listen((data) async {
      if (data.session == null) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        _currentUser = await _repo.getCurrentProfile();
        _status = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repo.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repo.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
