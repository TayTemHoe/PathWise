import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import 'appConstants.dart';

class SharedPreferencesHelper {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // User authentication state
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await _preferences?.setBool(AppConstants.isLoggedInKey, isLoggedIn);
  }

  static bool isLoggedIn() {
    return _preferences?.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  // Remember me functionality
  static Future<void> setRememberMe(bool remember) async {
    await _preferences?.setBool(AppConstants.rememberMeKey, remember);
  }

  static bool getRememberMe() {
    return _preferences?.getBool(AppConstants.rememberMeKey) ?? false;
  }

  // User data
  static Future<void> saveUserId(String userId) async {
    await _preferences?.setString(AppConstants.userIdKey, userId);
  }

  static String? getUserId() {
    return _preferences?.getString(AppConstants.userIdKey);
  }

  static Future<void> saveUserData(UserModel user) async {
    final userJson = jsonEncode(user.toMap());
    await _preferences?.setString(AppConstants.userDataKey, userJson);
  }

  static UserModel? getUserData() {
    final userJson = _preferences?.getString(AppConstants.userDataKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromMap(userMap);
    }
    return null;
  }

  // Clear all data on logout
  static Future<void> clearUserData() async {
    await _preferences?.remove(AppConstants.userIdKey);
    await _preferences?.remove(AppConstants.userDataKey);
    await _preferences?.remove(AppConstants.isLoggedInKey);
  }

  // Clear all preferences
  static Future<void> clearAll() async {
    await _preferences?.clear();
  }
}