import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user.dart';
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
    required String dob,
    required String address,
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

      // 3. Create the user model with Firebase UID and custom ID
      final UserModel user = UserModel(
        userId: firebaseUser.uid, // Use Firebase UID for the main userId
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: phone.trim(),
        email: email.trim().toLowerCase(),
        dob: dob.trim(),
        address: address.trim(),
        userRole: userRole,
      );

      // 4. Create user data map and add custom ID
      final userMap = user.toMap();
      userMap['createdAt'] = FieldValue.serverTimestamp();

      // 5. Save user data to Firestore using the Firebase UID as the document key
      await FirebaseService.setDocument(
        AppConstants.usersCollection,
        firebaseUser.uid,
        userMap,
      );

      // 9. Update Firebase user's display name
      await firebaseUser.updateDisplayName('${user.firstName} ${user.lastName}');

      // 10. Save to SharedPreferences
      await SharedPreferencesHelper.saveUserId(firebaseUser.uid);
      await SharedPreferencesHelper.saveUserData(user);
      await SharedPreferencesHelper.setLoggedIn(true);

      return user;
    } on FirebaseAuthException catch (e) {
      // If Firebase Auth fails, we need to clean up
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
      // If anything else fails, clean up
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
      // Sign in with email and password
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      // Get user data from Firestore
      final DocumentSnapshot userDoc = await FirebaseService.getUser(firebaseUser.uid);

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final UserModel user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userId: firebaseUser.uid,
      );

      // Save to SharedPreferences
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

  // Check if user is logged in
  bool isUserLoggedIn() {
    final isLoggedIn = SharedPreferencesHelper.isLoggedIn();
    final rememberMe = SharedPreferencesHelper.getRememberMe();
    return isLoggedIn && rememberMe && _auth.currentUser != null;
  }

  // Logout user
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

      // ✅ Check if email exists in Firebase Auth
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where("email", isEqualTo: formattedEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No user found for this email');
      }

      // ✅ Email exists, proceed to send reset link
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

      if (firstName != null) updateData['first_name'] = firstName.trim();
      if (lastName != null) updateData['last_name'] = lastName.trim();
      if (phone != null) updateData['phone'] = phone.trim();

      // Add update timestamp
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Update Firestore
      await FirebaseService.updateUser(userId, updateData);

      // Get updated user data
      final DocumentSnapshot userDoc = await FirebaseService.getUser(userId);

      final UserModel updatedUser = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userId: userId,
      );

      // Update SharedPreferences
      await SharedPreferencesHelper.saveUserData(updatedUser);

      // Update Firebase Auth display name if names changed
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