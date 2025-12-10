import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_profile.dart';
import '../services/firebase_service.dart';
import '../utils/appConstants.dart';
import '../utils/shared_preferences_helper.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register user
  Future<UserModel> registerUser({
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
      // 1. Create user in Firebase Authentication first
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user account');
      }

      // 3. Create the user model with Firebase UID
      final UserModel user = UserModel(
        userId: firebaseUser.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: phone.trim(),
        email: email.trim().toLowerCase(),
        dob: Timestamp.fromDate(dob), // CHANGED: Convert DateTime to Timestamp
        addressLine1: addressLine1.trim(),
        addressLine2: addressLine2?.trim(),
        city: city.trim(),
        state: state.trim(),
        country: country.trim(),
        zipCode: zipCode.trim(),
        userRole: userRole,
        createdAt: Timestamp.now(), // CHANGED: Use Timestamp
        lastUpdated: Timestamp.now(), // CHANGED: Use Timestamp
      );

      // 4. Save user data to Firestore
      await FirebaseService.setDocument(
        AppConstants.usersCollection,
        firebaseUser.uid,
        user.toMap(),
      );

      // 9. Update Firebase user's display name
      await firebaseUser.updateDisplayName('${user.firstName} ${user.lastName}');

      // 10. Save to SharedPreferences
      await SharedPreferencesHelper.saveUserId(firebaseUser.uid);
      await SharedPreferencesHelper.saveUserData(user);
      await SharedPreferencesHelper.setLoggedIn(true);

      return user;
    } on FirebaseAuthException catch (e) {
      await _cleanupFailedRegistration();

      String errorMessage = AppConstants.registerFailed;

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        default:
          errorMessage = e.message ?? AppConstants.registerFailed;
      }

      throw Exception(errorMessage);
    } catch (e) {
      await _cleanupFailedRegistration();
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Helper method to clean up failed registration
  Future<void> _cleanupFailedRegistration() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  // Login user
  Future<UserModel> loginUser({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      final DocumentSnapshot userDoc = await FirebaseService.getUser(firebaseUser.uid);

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final UserModel user = UserModel.fromFirestore(
        userDoc as DocumentSnapshot<Map<String, dynamic>>,
      );

      await SharedPreferencesHelper.saveUserId(firebaseUser.uid);
      await SharedPreferencesHelper.saveUserData(user);
      await SharedPreferencesHelper.setLoggedIn(true);
      await SharedPreferencesHelper.setRememberMe(rememberMe);

      return user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = AppConstants.loginFailed;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for this email';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = e.message ?? AppConstants.loginFailed;
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Get current user
  UserModel? getCurrentUser() {
    return SharedPreferencesHelper.getUserData();
  }

  bool isUserLoggedIn() {
    final isLoggedIn = SharedPreferencesHelper.isLoggedIn();
    final rememberMe = SharedPreferencesHelper.getRememberMe();
    return isLoggedIn && rememberMe && _auth.currentUser != null;
  }

  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
      await SharedPreferencesHelper.clearUserData();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      final formattedEmail = email.trim().toLowerCase();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where("email", isEqualTo: formattedEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No user found for this email');
      }

      await _auth.sendPasswordResetEmail(email: formattedEmail);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send password reset email';

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (firstName != null) updateData['firstName'] = firstName.trim();
      if (lastName != null) updateData['lastName'] = lastName.trim();
      if (phone != null) updateData['phone'] = phone.trim();

      updateData['lastUpdated'] = FieldValue.serverTimestamp();

      await FirebaseService.updateUser(userId, updateData);

      final DocumentSnapshot userDoc = await FirebaseService.getUser(userId);

      final UserModel updatedUser = UserModel.fromFirestore(
        userDoc as DocumentSnapshot<Map<String, dynamic>>,
      );

      await SharedPreferencesHelper.saveUserData(updatedUser);

      if (firstName != null || lastName != null) {
        final User? firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.updateDisplayName('${updatedUser.firstName} ${updatedUser.lastName}');
        }
      }

      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final querySnapshot = await FirebaseService.getUserByEmail(email.trim().toLowerCase());
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}