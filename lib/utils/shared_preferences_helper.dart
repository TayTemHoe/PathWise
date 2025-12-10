import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_profile.dart'; // CHANGED: Import new model
import 'appConstants.dart';

class SharedPreferencesHelper {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await _preferences?.setBool(AppConstants.isLoggedInKey, isLoggedIn);
  }

  static bool isLoggedIn() {
    return _preferences?.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  static Future<void> setRememberMe(bool remember) async {
    await _preferences?.setBool(AppConstants.rememberMeKey, remember);
  }

  static bool getRememberMe() {
    return _preferences?.getBool(AppConstants.rememberMeKey) ?? false;
  }

  static Future<void> saveUserId(String userId) async {
    await _preferences?.setString(AppConstants.userIdKey, userId);
  }

  static String? getUserId() {
    return _preferences?.getString(AppConstants.userIdKey);
  }

  static Future<void> saveUserData(UserModel user) async {
    // We use toEncodable to handle Firestore Timestamp objects which aren't natively supported by jsonEncode
    final userJson = jsonEncode(user.toMap(), toEncodable: (Object? value) {
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      }
      // If we encounter another non-encodable type, we throw the error
      throw JsonUnsupportedObjectError(value);
    });

    await _preferences?.setString(AppConstants.userDataKey, userJson);
  }

  static UserModel? getUserData() {
    final userJson = _preferences?.getString(AppConstants.userDataKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromMap(userMap);
      } catch (e) {
        // If parsing fails, clear corrupted data
        _preferences?.remove(AppConstants.userDataKey);
        return null;
      }
    }
    return null;
  }

  static Future<void> clearUserData() async {
    await _preferences?.remove(AppConstants.userIdKey);
    await _preferences?.remove(AppConstants.userDataKey);
    await _preferences?.remove(AppConstants.isLoggedInKey);
  }

  static Future<void> clearAll() async {
    await _preferences?.clear();
  }
}