import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _mfaChallengeId;
  String? _authenticatorUri;
  String? _qrCodeDataUri;
  String? _manualEntryKey;
  bool _requiresAuthenticatorSetup = false;
  List<String> _recoveryCodes = const [];

  User? get currentUser => _currentUser;
  String? get mfaChallengeId => _mfaChallengeId;
  String? get authenticatorUri => _authenticatorUri;
  String? get qrCodeDataUri => _qrCodeDataUri;
  String? get manualEntryKey => _manualEntryKey;
  bool get requiresAuthenticatorSetup => _requiresAuthenticatorSetup;
  List<String> get recoveryCodes => List.unmodifiable(_recoveryCodes);
  bool get requiresMfa => _mfaChallengeId != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Password step: keep the returned challenge in memory and do not authenticate yet.
  Future<void> login(String username, String password) async {
    _setLoading(true);
    _error = null;
    _currentUser = null;
    _mfaChallengeId = null;
    _recoveryCodes = const [];
    try {
      final result = await DatabaseService.login(username, password);
      if (result['error'] != null) {
        _error = result['error'].toString();
      } else {
        final flow = result['flow'] as Map<String, dynamic>? ?? {};
        _mfaChallengeId = flow['challengeId']?.toString();
        _authenticatorUri = flow['authenticatorUri']?.toString();
        _qrCodeDataUri = flow['qrCodeDataUri']?.toString();
        _manualEntryKey = flow['manualEntryKey']?.toString();
        _requiresAuthenticatorSetup = flow['nextStep'] == 'setupAuthenticator';
        if (_mfaChallengeId == null) _error = 'The server did not return an MFA challenge.';
      }
    } catch (_) {
      _error = 'Login failed. Please try again.';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> verifyAuthenticator(String code) async {
    final challenge = _mfaChallengeId;
    if (challenge == null) { _error = 'Sign in again to get a new verification request.'; notifyListeners(); return; }
    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.verifyAuthenticator(challengeId: challenge, code: code);
      if (result['user'] is User) {
        _currentUser = result['user'] as User;
        _recoveryCodes = ((result['recoveryCodes'] as List?) ?? const []).map((value) => value.toString()).toList();
        await _saveSession(_currentUser!);
        _mfaChallengeId = null;
      } else {
        _error = result['error']?.toString() ?? 'Authenticator verification failed.';
      }
    } catch (_) {
      _error = 'Authenticator verification failed. Please try again.';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void clearMfaState() {
    _mfaChallengeId = null;
    _authenticatorUri = null;
    _qrCodeDataUri = null;
    _manualEntryKey = null;
    _requiresAuthenticatorSetup = false;
    _error = null;
    notifyListeners();
  }

  void clearRecoveryCodes() {
    _recoveryCodes = const [];
    notifyListeners();
  }

  // REGISTER
  Future<void> register({
    required String username,
    required String password,
    required String name,
    required UserRole role,
    String? email,
    String? address,
    String? contactNumber,
    String? studentNo,
    String? gender,
    String? dateOfBirth,
    String? course,
    String? year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await DatabaseService.register(
        username: username,
        password: password,
        name: name,
        role: role,
        email: email,
        address: address,
        contactNumber: contactNumber,
        studentNo: studentNo,
        gender: gender,
        dateOfBirth: dateOfBirth,
        course: course,
        year: year,
      );

      if (result['success'] == true) {
        _currentUser = result['user'] as User;
        _error = null;
      } else {
        _currentUser = null;
        _error = result['message'];
      }
    } catch (e) {
      _currentUser = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    _currentUser = null;
    clearMfaState();
    _recoveryCodes = const [];
    await DatabaseService.clearToken();
    await _clearSession();
    notifyListeners();
  }

  //CHECK AUTH STATUS
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');
      final userName = prefs.getString('user_name');

      if (userId != null && userRole != null) {
        _currentUser = User(
          id: userId,
          username: '',
          password: '',
          name: userName ?? '',
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

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_role', user.role.name);
    await prefs.setString('user_name', user.name);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('jwt_token');
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
