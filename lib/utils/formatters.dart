// lib/utils/formatters.dart
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Format large numbers with commas
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  /// Format duration in months to readable format
  static String formatDuration(String? durationMonths) {
    if (durationMonths == null || durationMonths.isEmpty) {
      return 'Duration not specified';
    }

    final months = int.tryParse(durationMonths);
    if (months == null) return durationMonths;

    if (months < 12) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    }

    final years = months / 12;
    if (years % 1 == 0) {
      return '${years.toInt()} ${years.toInt() == 1 ? 'year' : 'years'}';
    }

    final fullYears = years.floor();
    final remainingMonths = months % 12;

    if (remainingMonths == 0) {
      return '$fullYears ${fullYears == 1 ? 'year' : 'years'}';
    }

    return '$fullYears ${fullYears == 1 ? 'year' : 'years'} $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
  }

  /// Format study mode for display
  static String formatStudyMode(String? studyMode) {
    if (studyMode == null || studyMode.isEmpty) {
      return 'Not specified';
    }
    return studyMode;
  }

  /// Format intake periods as readable string
  static String formatIntakePeriods(List<String>? intakePeriods) {
    if (intakePeriods == null || intakePeriods.isEmpty) {
      return 'Contact university for intake information';
    }

    if (intakePeriods.length == 1) {
      return '${intakePeriods.first} intake';
    }

    return '${intakePeriods.join(', ')} intakes';
  }

  /// Format date to readable string
  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy hh:mm a');
    return formatter.format(dateTime);
  }

  /// Get relative time (e.g., "2 hours ago", "3 days ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Format percentage
  static String formatPercentage(double percentage, {int decimals = 1}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Format phone number
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'Not provided';
    // Basic formatting - can be enhanced based on country codes
    return phone;
  }

  /// Format email (lowercase)
  static String formatEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    return email.toLowerCase().trim();
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates CGPA value
  static String? validateCGPA(double value, double min, double max) {
    if (value < min || value > max) {
      return 'CGPA must be between ${min.toStringAsFixed(1)} and ${max.toStringAsFixed(1)}';
    }
    if (value == 0.0) {
      return 'Please enter your CGPA';
    }
    return null;
  }

  /// Validates year
  static String? validateYear(int? year) {
    if (year == null) {
      return null;
    }

    final currentYear = DateTime.now().year;
    if (year < 1950 || year > currentYear + 10) {
      return 'Please enter a valid year';
    }
    return null;
  }

  /// Validates subject name
  static String? validateSubjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Subject name is required';
    }
    if (value.trim().length < 2) {
      return 'Subject name is too short';
    }
    return null;
  }

  /// Validates grade selection
  static String? validateGrade(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a grade';
    }
    return null;
  }

  /// Validates English test score based on test type
  static String? validateEnglishScore(String? score, String? testType) {
    if (score == null || score.trim().isEmpty) {
      return 'Score is required';
    }

    if (testType == null) {
      return 'Please select a test type first';
    }

    final trimmedScore = score.trim();

    switch (testType) {
      case 'IELTS':
        final ieltsScore = double.tryParse(trimmedScore);
        if (ieltsScore == null) {
          return 'Please enter a valid number';
        }
        if (ieltsScore < 1.0 || ieltsScore > 9.0) {
          return 'IELTS score must be between 1.0 and 9.0';
        }
        break;

      case 'TOEFL':
        final toeflScore = int.tryParse(trimmedScore);
        if (toeflScore == null) {
          return 'Please enter a valid whole number';
        }
        if (toeflScore < 0 || toeflScore > 120) {
          return 'TOEFL score must be between 0 and 120';
        }
        break;

      case 'MUET':
        if (!RegExp(r'^[Bb]and\s*[1-6]$|^[1-6]$').hasMatch(trimmedScore)) {
          return 'MUET must be Band 1-6 (e.g., "Band 4" or "4")';
        }
        break;

      case 'Cambridge':
        final cambridgeScore = int.tryParse(trimmedScore);
        if (cambridgeScore == null) {
          return 'Please enter a valid number';
        }
        if (cambridgeScore < 80 || cambridgeScore > 230) {
          return 'Cambridge score must be between 80 and 230';
        }
        break;

      case 'IGCSE English':
        final validGrades = ['A*', 'A', 'B', 'C', 'D', 'E', 'F', 'G'];
        if (!validGrades.contains(trimmedScore.toUpperCase())) {
          return 'Valid grades: A*, A, B, C, D, E, F, G';
        }
        break;

      case 'Other':
        if (trimmedScore.length < 1) {
          return 'Please enter your score';
        }
        break;

      default:
        return 'Unknown test type';
    }

    return null;
  }

  /// Validates education level text for "Other" option
  static String? validateEducationLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your education level';
    }
    if (value.trim().length < 3) {
      return 'Education level name is too short';
    }
    return null;
  }

  /// Validates that at least one subject is added
  static String? validateSubjectsList(List subjects) {
    if (subjects.isEmpty) {
      return 'Please add at least one subject';
    }

    // Check if all subjects have valid data
    for (var subject in subjects) {
      if (subject.name.trim().isEmpty || subject.grade.trim().isEmpty) {
        return 'Please complete all subject details';
      }
    }

    return null;
  }

  /// Validates institution name
  static String? validateInstitution(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length < 3) {
      return 'Institution name is too short';
    }
    return null;
  }

  static List<TextInputFormatter> decimalFormatter({int decimalPlaces = 2}) {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,' + decimalPlaces.toString() + '}')),
    ];
  }

  /// Integer-only formatter
  static List<TextInputFormatter> integerFormatter() {
    return [
      FilteringTextInputFormatter.digitsOnly,
    ];
  }

  /// IELTS score formatter (1.0 - 9.0)
  static List<TextInputFormatter> ieltsFormatter() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^[1-9]\.?[0-9]?$')),
    ];
  }

  /// TOEFL score formatter (0 - 120)
  static List<TextInputFormatter> toeflFormatter() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      _NumericRangeFormatter(min: 0, max: 120),
    ];
  }

  /// Cambridge score formatter (80 - 230)
  static List<TextInputFormatter> cambridgeFormatter() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      _NumericRangeFormatter(min: 80, max: 230),
    ];
  }

  /// MUET band formatter
  static List<TextInputFormatter> muetFormatter() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^[Bb]?[Aa]?[Nn]?[Dd]?\s?[1-6]?$')),
    ];
  }

  /// Grade formatter (letters only)
  static List<TextInputFormatter> gradeFormatter() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^[A-Ga-g\*]*$')),
      TextInputFormatter.withFunction((oldValue, newValue) {
        return TextEditingValue(
          text: newValue.text.toUpperCase(),
          selection: newValue.selection,
        );
      }),
    ];
  }

  /// Format CGPA display
  static String formatCGPA(double cgpa) {
    return cgpa.toStringAsFixed(2);
  }

  /// Format year range display
  static String formatYearRange(int startYear, int endYear) {
    return '$startYear - $endYear';
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Format institution name
  static String formatInstitutionName(String name) {
    return capitalizeWords(name.trim());
  }

  static String? validateProgramName(String? value) {
    final trimmedValue = value?.trim();

    if (trimmedValue == null || trimmedValue.isEmpty) {
      return 'Program Name is required';
    }

    if (trimmedValue.length < 3) {
      return 'Must be at least 3 characters';
    }

    if (trimmedValue.length > 100) {
      return 'Must be 100 characters or less';
    }

    // Check for "Alphabet and Spaces only"
    // This RegExp allows letters (a-z, A-Z) and spaces.
    // It will fail if it sees numbers (0-9) or special chars (!@#$).
    final RegExp alphaOnly = RegExp(r'^[a-zA-Z ]+$');

    if (!alphaOnly.hasMatch(trimmedValue)) {
      return 'Only letters and spaces are allowed';
    }

    return null;
  }
}

/// Custom formatter for numeric ranges
class _NumericRangeFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumericRangeFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final intValue = int.tryParse(newValue.text);
    if (intValue == null) {
      return oldValue;
    }

    if (intValue < min || intValue > max) {
      return oldValue;
    }

    return newValue;
  }

  static bool isValidScore(double score) {
    return score >= 0.0 && score <= 1.0;
  }

  /// Validates MBTI type format (must be one of the 16 types)
  static bool isValidMBTI(String? mbti) {
    if (mbti == null || mbti.isEmpty) return false;

    const validTypes = [
      'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
      'ISTP', 'ISFP', 'INFP', 'INTP',
      'ESTP', 'ESFP', 'ENFP', 'ENTP',
      'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
    ];

    return validTypes.contains(mbti.toUpperCase());
  }

  /// Validates RIASEC key
  static bool isValidRIASECKey(String key) {
    return ['R', 'I', 'A', 'S', 'E', 'C'].contains(key.toUpperCase());
  }

  /// Validates OCEAN key
  static bool isValidOCEANKey(String key) {
    return ['O', 'C', 'E', 'A', 'N'].contains(key.toUpperCase());
  }

  /// Validates a complete RIASEC profile
  static bool isValidRIASECProfile(Map<String, double>? profile) {
    if (profile == null || profile.isEmpty) return false;

    for (final entry in profile.entries) {
      if (!isValidRIASECKey(entry.key)) return false;
      if (!isValidScore(entry.value)) return false;
    }

    return true;
  }

  /// Validates a complete OCEAN profile
  static bool isValidOCEANProfile(Map<String, double>? profile) {
    if (profile == null || profile.isEmpty) return false;

    for (final entry in profile.entries) {
      if (!isValidOCEANKey(entry.key)) return false;
      if (!isValidScore(entry.value)) return false;
    }

    return true;
  }

  /// Validates that personality profile has at least some data
  static bool hasPersonalityData({
    String? mbti,
    Map<String, double>? riasec,
    Map<String, double>? ocean,
  }) {
    final hasMBTI = mbti != null && mbti.isNotEmpty;
    final hasRIASEC = riasec != null && riasec.isNotEmpty;
    final hasOCEAN = ocean != null && ocean.isNotEmpty;

    return hasMBTI || hasRIASEC || hasOCEAN;
  }

  /// Validates score string input (for text fields)
  static String? validateScoreInput(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Please enter a valid number';
    }

    if (!isValidScore(parsed)) {
      return 'Score must be between 0.0 and 1.0';
    }

    return null;
  }

  /// Validates MBTI input (for text fields)
  static String? validateMBTIInput(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (!isValidMBTI(value)) {
      return 'Please enter a valid MBTI type (e.g., INTJ, ENFP)';
    }

    return null;
  }
}