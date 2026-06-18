import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDarkMode = false;
  bool _isDemoMode = true;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDarkMode => _isDarkMode;
  bool get isDemoMode => _isDemoMode;

  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    loadSession();
  }

  /// Initial load of the user session and global preferences
  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _isDemoMode = prefs.getBool('is_demo_mode') ?? true;

      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signup
  Future<bool> signup(String email, String password, String displayName, {String? phoneNumber}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google Login
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithGoogle();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends password recovery OTP (simulated/real)
  Future<String?> sendRecoveryOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final otp = await _authService.sendPasswordResetOtp(email);
      return otp;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Completes password reset
  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPasswordAfterOtp(email, newPassword);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle Dark/Light Mode
  Future<void> toggleTheme(bool dark) async {
    _isDarkMode = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', dark);
    notifyListeners();
  }

  /// Toggle Firebase Sync Mode vs. Offline Demo Mode
  Future<void> toggleDemoMode(bool isDemo) async {
    if (!AuthService.firebaseInitialized && !isDemo) {
      throw Exception('Firebase is not configured! Please configure Firebase before disabling Demo Mode.');
    }
    
    _isDemoMode = isDemo;
    await _authService.setDemoMode(isDemo);
    
    // Refresh session for current provider
    await loadSession();
  }

  /// Change Password
  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.changePassword(_currentUser!.uid, newPassword);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// Update Profile
  Future<bool> updateProfile({String? name, String? phoneNumber, String? photoBase64}) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateProfile(
        uid: _currentUser!.uid,
        name: name,
        phoneNumber: phoneNumber,
        photoBase64: photoBase64,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
