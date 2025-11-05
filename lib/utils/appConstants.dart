class AppConstants {
  static const String appName = 'PathWise';
  static const int pageSize = 10;
  static const int maxCompareUniversities = 3;

  static const List<String> studyLevels = [
    'Diploma',
    'Degree',
    'Masters',
    'PhD',
  ];

  static const List<String> institutionTypes = [
    'Public',
    'Private',
    'Research',
  ];
  
  // Firebase Collections
  static const String usersCollection = 'users';

  // SharedPreferences Keys
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String rememberMeKey = 'remember_me';

  // Validation Messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordTooWeak = 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
  static const String firstNameRequired = 'First name is required';
  static const String lastNameRequired = 'Last name is required';
  static const String phoneRequired = 'Phone number is required';
  static const String phoneInvalid = 'Please enter a valid phone number';

  // Error Messages
  static const String loginFailed = 'Login failed. Please check your credentials.';
  static const String registerFailed = 'Registration failed. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'An unexpected error occurred.';
}