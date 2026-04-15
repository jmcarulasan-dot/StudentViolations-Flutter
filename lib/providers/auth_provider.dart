import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<void> login(String username, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await DatabaseService.login(username, password);

      if (user != null) {
        _currentUser = user;
        await _saveSession(user);
        notifyListeners();
      } else {
        _error = 'Invalid username or password';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────
  Future<void> register({
    required String username,
    required String password,
    required String name,
    required UserRole role,
    String? contactNumber,
    String? studentNo,
    String? course,
    String? year,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? address,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await DatabaseService.register(
        username: username,
        password: password,
        name: name,
        role: role,
        contactNumber: contactNumber,
        studentNo: studentNo,
        course: course,
        year: year,
        email: email,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
      );

      if (user != null) {
        _currentUser = user;
        await _saveSession(user);
        notifyListeners();
      } else {
        _error = 'Registration failed. Username or email may already exist.';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    await DatabaseService.clearToken();
    await _clearSession();
    notifyListeners();
  }

  // ── CHECK AUTH STATUS ─────────────────────────────────────────────────────
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');
      final userName = prefs.getString('user_name'); // ADD THIS

      if (userId != null && userRole != null) {
        _currentUser = User(
          id: userId,
          username: '',
          password: '',
          name: userName ?? '', // ADD THIS
          role: UserRole.values.firstWhere(
            (r) => r.name == userRole,
            orElse: () => UserRole.student,
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    }
  }

  // ── Save session to SharedPreferences ─────────────────────────────────────
  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_role', user.role.name);
    await prefs.setString('user_name', user.name);  
  }

  // ── Clear session from SharedPreferences ──────────────────────────────────
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}