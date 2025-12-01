// lib/utils/app_color.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFF8E87FF);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF6584);
  static const Color secondaryDark = Color(0xFFE5576F);
  static const Color secondaryLight = Color(0xFFFF8BA0);

  // Accent Colors
  static const Color accent = Color(0xFFFFB74D);
  static const Color accentDark = Color(0xFFF9A825);
  static const Color accentLight = Color(0xFFFFD54F);

  // Ranking Colors
  static const Color topRankedGold = Color(0xFFFFD700);
  static const Color topRankedSilver = Color(0xFFC0C0C0);
  static const Color topRankedBronze = Color(0xFFCD7F32);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFE8ECF1);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFF95A5A6);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFD63031);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74B9FF);

  // Border Colors
  static const Color border = Color(0xFFDFE6E9);
  static const Color borderLight = Color(0xFFF0F3F5);
  static const Color borderDark = Color(0xFFB2BEC3);

  // Shadow Colors
  static Color shadow = Colors.black.withOpacity(0.1);
  static Color shadowLight = Colors.black.withOpacity(0.05);
  static Color shadowDark = Colors.black.withOpacity(0.2);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  // Shimmer Colors (for loading states)
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Card Colors
  static const Color cardBackground = Colors.white;
  static Color cardShadow = Colors.black.withOpacity(0.08);

  // Disabled Colors
  static Color disabled = Colors.grey.withOpacity(0.5);
  static const Color disabledText = Color(0xFFBDBDBD);

  // Overlay Colors
  static Color overlay = Colors.black.withOpacity(0.5);
  static Color overlayLight = Colors.black.withOpacity(0.3);

  // Subject Area Colors (for program cards)
  static const Map<String, Color> subjectColors = {
    'Engineering': Color(0xFF6C63FF),
    'Business': Color(0xFFFF6584),
    'Computer Science': Color(0xFF00B894),
    'Medicine': Color(0xFFD63031),
    'Arts': Color(0xFFFFB74D),
    'Science': Color(0xFF74B9FF),
    'Law': Color(0xFF636E72),
    'Education': Color(0xFFFDCB6E),
    'Social Sciences': Color(0xFFE17055),
    'default': Color(0xFF95A5A6),
  };

  // Get color by subject area
  static Color getSubjectColor(String? subjectArea) {
    if (subjectArea == null || subjectArea.isEmpty) {
      return subjectColors['default']!;
    }

    // Try exact match first
    if (subjectColors.containsKey(subjectArea)) {
      return subjectColors[subjectArea]!;
    }

    // Try partial match
    for (var key in subjectColors.keys) {
      if (subjectArea.toLowerCase().contains(key.toLowerCase())) {
        return subjectColors[key]!;
      }
    }

    return subjectColors['default']!;
  }

  // Study Level Colors
  static const Map<String, Color> studyLevelColors = {
    'Diploma': Color(0xFF74B9FF),
    'Degree': Color(0xFF6C63FF),
    'Bachelor': Color(0xFF00B894),
    'Masters': Color(0xFFFF6584),
    'PhD': Color(0xFFD63031),
    'Doctorate': Color(0xFF8E44AD),
    'default': Color(0xFF95A5A6),
  };

  // Get color by study level
  static Color getStudyLevelColor(String? studyLevel) {
    if (studyLevel == null || studyLevel.isEmpty) {
      return studyLevelColors['default']!;
    }

    return studyLevelColors[studyLevel] ?? studyLevelColors['default']!;
  }
}