import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../repository/auth_repository.dart';
import '../services/firebase_service.dart';
import '../utils/shared_preferences_helper.dart';
import '../utils/validators.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Loading states
  bool _isLoading = false;
  bool _isLoginMode = true;

  // Error handling
  String? _errorMessage;

  // Form validation
  bool _isFormValid = false;

  // Remember me
  bool _rememberMe = false;

  // Current user
  UserModel? _currentUser;

  // Getters
  bool get isLoading => _isLoading;

  bool get isLoginMode => _isLoginMode;

  String? get errorMessage => _errorMessage;

  bool get isFormValid => _isFormValid;

  bool get rememberMe => _rememberMe;

  UserModel? get currentUser => _currentUser;

  // Initialize
  Future<void> init() async {
    try {
      _rememberMe = SharedPreferencesHelper.getRememberMe();
      // Check if user is logged in and get current user data
      if (_authRepository.isUserLoggedIn()) {
        _currentUser = _authRepository.getCurrentUser();

        // If we have a stored user but no current user data, try to refresh from repository
        if (_currentUser == null) {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // Try to get fresh user data from Firestore
            try {
              final userDoc = await FirebaseService.getUser(firebaseUser.uid);
              if (userDoc.exists) {
                _currentUser = UserModel.fromMap(
                  userDoc.data() as Map<String, dynamic>,
                  userId: firebaseUser.uid,
                );
                // Update SharedPreferences
                await SharedPreferencesHelper.saveUserData(_currentUser!);
              }
            } catch (e) {
              // If we can't get user data, logout
              await logout();
            }
          }
        }
      }
    } catch (e) {
      // If there's any error during initialization, clear the session
      await logout();
    }
  }

  void setAuthMode(int index) {
    final newModeIsLogin = index == 0;
    if (_isLoginMode != newModeIsLogin) {
      _isLoginMode = newModeIsLogin;
      _isFormValid = false;
      clearError();
      notifyListeners();
    }
  }

  // Set remember me
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  // Validate form
  void validateForm({
    required String email,
    required String password,
    String? confirmPassword,
    String? firstName,
    String? lastName,
    String? phone,
    String? dob,
    String? address,
  }) {
    bool newFormValid = false;

    // Check which form is active
    if (_isLoginMode) {
      // For Login: Enable button if email and password are not empty
      newFormValid = email.trim().isNotEmpty && password.trim().isNotEmpty;
    } else {
      // For Register: Enable button if all fields have some value
      newFormValid =
          email.trim().isNotEmpty &&
          password.trim().isNotEmpty &&
          confirmPassword != null &&
          confirmPassword.trim().isNotEmpty &&
          firstName != null &&
          firstName.trim().isNotEmpty &&
          lastName != null &&
          lastName.trim().isNotEmpty &&
          phone != null &&
          phone.trim().isNotEmpty &&
          dob != null &&
          dob.trim().isNotEmpty &&
          address != null &&
          address.trim().isNotEmpty;
    }

    // Only notify if the state actually changed
    if (_isFormValid != newFormValid) {
      _isFormValid = newFormValid;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      clearError();

      final user = await _authRepository.loginUser(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );

      _currentUser = user;

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String dob,
    required String address,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final newUser = await _authRepository.registerUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        dob: dob,
        address: address,
      );

      _currentUser = newUser;

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      final shouldRemember = _rememberMe;
      await _authRepository.logoutUser();
      _currentUser = null;
      _isFormValid = false;
      if (shouldRemember) {
        await SharedPreferencesHelper.setRememberMe(true);
      }
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    final validationError = Validators.validateEmail(email);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    try {
      _setLoading(true);
      clearError();

      await _authRepository.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _authRepository.isUserLoggedIn();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
