import 'appConstants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.emailRequired;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppConstants.emailInvalid;
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequired;
    }

    if (value.length < 6) {
      return AppConstants.passwordTooShort;
    }

    // Check for at least one uppercase, one lowercase, and one number
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$');
    if (!passwordRegex.hasMatch(value)) {
      return AppConstants.passwordTooWeak;
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters and spaces';
    }

    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.phoneRequired;
    }

    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return AppConstants.phoneInvalid;
    }

    return null;
  }

  // Format phone number for display
  static String formatPhoneNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length >= 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }
    return phone;
  }

  // Address Line 1 validation
  static String? validateAddressLine1(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address Line 1 is required';
    }

    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }

    return null;
  }

  // Address Line 2 validation (optional)
  static String? validateAddressLine2(String? value) {
    // Address Line 2 is optional, so only validate if provided
    if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
      return 'Address must be at least 3 characters';
    }
    return null;
  }

  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }

    if (value.trim().length < 2) {
      return 'City must be at least 2 characters';
    }

    final cityRegex = RegExp(r'^[a-zA-Z\s\-]+$');
    if (!cityRegex.hasMatch(value.trim())) {
      return 'City can only contain letters, spaces, and hyphens';
    }

    return null;
  }

  // State validation
  static String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State/Province is required';
    }

    if (value.trim().length < 2) {
      return 'State/Province must be at least 2 characters';
    }

    final stateRegex = RegExp(r'^[a-zA-Z\s\-]+$');
    if (!stateRegex.hasMatch(value.trim())) {
      return 'State/Province can only contain letters, spaces, and hyphens';
    }

    return null;
  }

  // Country validation
  static String? validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }

    if (value.trim().length < 2) {
      return 'Country must be at least 2 characters';
    }

    final countryRegex = RegExp(r'^[a-zA-Z\s\-]+$');
    if (!countryRegex.hasMatch(value.trim())) {
      return 'Country can only contain letters, spaces, and hyphens';
    }

    return null;
  }

  // Zip Code validation
  static String? validateZipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zip/Postal code is required';
    }

    // Allow alphanumeric, spaces, and hyphens (covers various postal code formats)
    final zipRegex = RegExp(r'^[a-zA-Z0-9\s\-]{3,10}$');
    if (!zipRegex.hasMatch(value.trim())) {
      return 'Invalid zip/postal code format';
    }

    return null;
  }
}