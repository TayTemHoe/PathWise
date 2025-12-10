import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/user_profile.dart'; // CHANGED: Import new model
import '../repository/auth_repository.dart';
import '../services/firebase_service.dart';
import '../utils/shared_preferences_helper.dart';
import '../utils/validators.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isLoginMode = true;
  String? _errorMessage;
  bool _isFormValid = false;
  bool _rememberMe = false;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  bool get isLoginMode => _isLoginMode;
  String? get errorMessage => _errorMessage;
  bool get isFormValid => _isFormValid;
  bool get rememberMe => _rememberMe;
  UserModel? get currentUser => _currentUser;

  Future<void> init() async {
    try {
      _rememberMe = SharedPreferencesHelper.getRememberMe();
      if (_authRepository.isUserLoggedIn()) {
        _currentUser = _authRepository.getCurrentUser();

        if (_currentUser == null) {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            try {
              final userDoc = await FirebaseService.getUser(firebaseUser.uid);
              if (userDoc.exists) {
                _currentUser = UserModel.fromFirestore(
                  userDoc as DocumentSnapshot<Map<String, dynamic>>,
                );
                await SharedPreferencesHelper.saveUserData(_currentUser!);
              }
            } catch (e) {
              await logout();
            }
          }
        }
      }
    } catch (e) {
      await logout();
    }
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;

    try {
      final userDoc = await FirebaseService.getUser(_currentUser!.userId);
      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(
          userDoc as DocumentSnapshot<Map<String, dynamic>>,
        );
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
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

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void validateForm({
    required String email,
    required String password,
    String? confirmPassword,
    String? firstName,
    String? lastName,
    String? phone,
    String? dob,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? zipCode,
  }) {
    bool newFormValid = false;

    if (_isLoginMode) {
      newFormValid = email.trim().isNotEmpty && password.trim().isNotEmpty;
    } else {
      newFormValid = email.trim().isNotEmpty &&
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
          addressLine1 != null &&
          addressLine1.trim().isNotEmpty &&
          city != null &&
          city.trim().isNotEmpty &&
          state != null &&
          state.trim().isNotEmpty &&
          country != null &&
          country.trim().isNotEmpty &&
          zipCode != null &&
          zipCode.trim().isNotEmpty;
    }

    if (_isFormValid != newFormValid) {
      _isFormValid = newFormValid;
      notifyListeners();
    }
  }

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

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required DateTime dob, // CHANGED: DateTime instead of String
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String country,
    required String zipCode,
    required String userRole,
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
        dob: dob, // Pass DateTime directly
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        country: country,
        zipCode: zipCode,
        userRole: userRole,
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

  bool isUserLoggedIn() {
    return _authRepository.isUserLoggedIn();
  }

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