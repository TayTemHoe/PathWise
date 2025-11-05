// lib/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
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
}