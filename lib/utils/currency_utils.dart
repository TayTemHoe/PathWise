import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CurrencyUtils {
  // Cache for exchange rates
  static Map<String, double> _exchangeRates = {};
  static DateTime? _lastFetchTime;
  static const Duration _cacheValidity = Duration(hours: 12);

  // Fallback rates (used if API fails)
  static const Map<String, double> _fallbackRates = {
    'USD': 4.50,
    'EUR': 4.90,
    'GBP': 5.70,
    'AUD': 3.00,
    'SGD': 3.35,
    'MYR': 1.00,
    'CAD': 3.30,
    'NZD': 2.75,
    'CHF': 5.10,
    'JPY': 0.030,
    'CNY': 0.62,
    'INR': 0.054,
    'THB': 0.13,
    'IDR': 0.00029,
    'VND': 0.00018,
    'PHP': 0.078,
    'KRW': 0.0034,
    'HKD': 0.58,
    'TWD': 0.14,
    'RUB': 0.047,
    'BRL': 0.89,
    'ZAR': 0.24,
  };

  // Currency symbols and codes
  static const Map<String, List<String>> currencyPatterns = {
    'USD': ['\$', 'USD', 'US\$', 'dollar', 'dollars', 'US DOLLAR'],
    'EUR': ['€', 'EUR', 'euro', 'euros', 'EURO'],
    'GBP': ['£', 'GBP', 'pound', 'pounds', 'POUND STERLING'],
    'AUD': ['A\$', 'AUD', 'AU\$', 'AUSTRALIAN DOLLAR'],
    'SGD': ['S\$', 'SGD', 'SG\$', 'SINGAPORE DOLLAR'],
    'MYR': ['RM', 'MYR', 'ringgit', 'MALAYSIAN RINGGIT'],
    'CAD': ['C\$', 'CAD', 'CA\$', 'CANADIAN DOLLAR'],
    'NZD': ['NZ\$', 'NZD', 'NEW ZEALAND DOLLAR'],
    'CHF': ['CHF', 'Fr.', 'SFr.', 'SWISS FRANC'],
    'JPY': ['¥', 'JPY', 'yen', 'JAPANESE YEN'],
    'CNY': ['¥', 'CNY', 'yuan', 'RMB', 'CHINESE YUAN'],
    'INR': ['₹', 'INR', 'rupee', 'rupees', 'INDIAN RUPEE'],
    'THB': ['฿', 'THB', 'baht', 'THAI BAHT'],
    'IDR': ['Rp', 'IDR', 'INDONESIAN RUPIAH'],
    'VND': ['₫', 'VND', 'dong', 'VIETNAMESE DONG'],
    'PHP': ['₱', 'PHP', 'peso', 'PHILIPPINE PESO'],
    'KRW': ['₩', 'KRW', 'won', 'KOREAN WON'],
    'HKD': ['HK\$', 'HKD', 'HONG KONG DOLLAR'],
    'TWD': ['NT\$', 'TWD', 'TAIWAN DOLLAR'],
    'RUB': ['₽', 'RUB', 'ruble', 'RUSSIAN RUBLE'],
    'BRL': ['R\$', 'BRL', 'real', 'BRAZILIAN REAL'],
    'ZAR': ['R', 'ZAR', 'rand', 'SOUTH AFRICAN RAND'],
  };

  /// Fetch current exchange rates from API
  static Future<void> fetchExchangeRates() async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidity &&
        _exchangeRates.isNotEmpty) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/MYR'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        _exchangeRates.clear();
        rates.forEach((currency, rate) {
          if (rate is num && rate > 0) {
            _exchangeRates[currency] = 1.0 / rate.toDouble();
          }
        });

        _exchangeRates['MYR'] = 1.0;
        _lastFetchTime = DateTime.now();

        if (kDebugMode) {
          print('✅ Exchange rates updated successfully at $_lastFetchTime');
        }
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to fetch exchange rates: $e');
        print('📌 Using fallback rates');
      }

      if (_exchangeRates.isEmpty) {
        _exchangeRates = Map.from(_fallbackRates);
        _lastFetchTime = DateTime.now();
      }
    }
  }

  /// Get exchange rate for a currency
  static double getExchangeRate(String currencyCode) {
    if (_exchangeRates.isEmpty) {
      _exchangeRates = Map.from(_fallbackRates);
    }

    return _exchangeRates[currencyCode.toUpperCase()] ??
        _fallbackRates[currencyCode.toUpperCase()] ??
        _fallbackRates['USD']!;
  }

  /// Converts a fee string to MYR
  static double? convertToMYR(String? feeString) {
    if (feeString == null || feeString.isEmpty) return null;

    try {
      String cleaned = feeString.replaceAll(',', '').trim();
      RegExp numericRegex = RegExp(r'[\d.]+');
      Match? numericMatch = numericRegex.firstMatch(cleaned);

      if (numericMatch == null) return null;

      double amount = double.parse(numericMatch.group(0)!);
      String detectedCurrency = detectCurrency(cleaned);
      double rate = getExchangeRate(detectedCurrency);

      return amount * rate;
    } catch (e) {
      if (kDebugMode) {
        print('Error converting currency: $feeString - $e');
      }
      return null;
    }
  }

  /// Detects currency from a string
  static String detectCurrency(String text) {
    String upperText = text.toUpperCase();

    for (var entry in currencyPatterns.entries) {
      for (var pattern in entry.value) {
        if (upperText.contains(pattern.toUpperCase())) {
          if (pattern == '¥') {
            if (upperText.contains('JPY') || upperText.contains('JAPANESE')) {
              return 'JPY';
            } else if (upperText.contains('CNY') || upperText.contains('CHINESE') ||
                upperText.contains('RMB') || upperText.contains('YUAN')) {
              return 'CNY';
            }
            return 'CNY';
          }

          if (pattern == 'R' && entry.key == 'ZAR') {
            if (RegExp(r'\bR\s*\d').hasMatch(text)) {
              return 'ZAR';
            }
            continue;
          }

          return entry.key;
        }
      }
    }

    if (RegExp(r'\b(pound|pounds)\b', caseSensitive: false).hasMatch(text)) {
      return 'GBP';
    }
    if (RegExp(r'\b(euro|euros)\b', caseSensitive: false).hasMatch(text)) {
      return 'EUR';
    }
    if (RegExp(r'\b(dollar|dollars)\b', caseSensitive: false).hasMatch(text)) {
      if (RegExp(r'\b(australian|australia|aus)\b', caseSensitive: false).hasMatch(text)) {
        return 'AUD';
      }
      if (RegExp(r'\b(singapore|sg)\b', caseSensitive: false).hasMatch(text)) {
        return 'SGD';
      }
      if (RegExp(r'\b(canadian|canada)\b', caseSensitive: false).hasMatch(text)) {
        return 'CAD';
      }
      if (RegExp(r'\b(new zealand|nz)\b', caseSensitive: false).hasMatch(text)) {
        return 'NZD';
      }
      if (RegExp(r'\b(hong kong|hk)\b', caseSensitive: false).hasMatch(text)) {
        return 'HKD';
      }
      return 'USD';
    }

    return 'USD';
  }

  /// Format MYR amount for display
  static String formatMYR(double amount, {bool compact = true}) {
    if (compact) {
      if (amount >= 1000000) {
        return 'RM ${(amount / 1000000).toStringAsFixed(2)}M';
      } else if (amount >= 1000) {
        return 'RM ${(amount / 1000).toStringAsFixed(0)}K';
      } else {
        return 'RM ${amount.toStringAsFixed(0)}';
      }
    } else {
      String formatted = amount.toStringAsFixed(2);
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String result = formatted.replaceAllMapped(reg, (Match match) => '${match[1]},');
      return 'RM $result';
    }
  }

  static bool get hasValidCache {
    return _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidity &&
        _exchangeRates.isNotEmpty;
  }

  static Future<void> refreshRates() async {
    _lastFetchTime = null;
    await fetchExchangeRates();
  }

  static DateTime? get lastUpdateTime => _lastFetchTime;

  static List<String> get availableCurrencies {
    return _exchangeRates.keys.toList()..sort();
  }

  static void clearCache() {
    _exchangeRates.clear();
    _lastFetchTime = null;
  }
}

/// Helper class for ranking operations
class RankingParser {
  /// Format ranking for display
  /// Examples:
  /// - formatRanking(70, null) -> "#70"
  /// - formatRanking(70, 70) -> "#70"
  /// - formatRanking(1001, 2000) -> "#1001 - #2000"
  static String formatRanking(int? minRanking, int? maxRanking) {
    if (minRanking == null) return 'Unranked';

    // If both are the same or maxRanking is null, show only minRanking
    if (maxRanking == null || minRanking == maxRanking) {
      return '#$minRanking';
    }

    // Show range
    return '#$minRanking - #$maxRanking';
  }

  /// FIXED: Check if a university's ranking falls within a specified filter range
  ///
  /// LOGIC EXPLANATION:
  /// We need to check if there's ANY overlap between the university's ranking range
  /// and the filter's ranking range.
  ///
  /// Examples:
  /// - University (50-100), Filter (75-150) -> TRUE (overlap: 75-100)
  /// - University (200-300), Filter (50-100) -> FALSE (no overlap)
  /// - University (50, null), Filter (40-60) -> TRUE (50 is in 40-60)
  /// - University (50, 100), Filter (101-200) -> FALSE (no overlap)
  static bool isInRange(int? minRanking, int? maxRanking, int? minRange, int? maxRange) {
    // If university has no ranking, exclude it
    if (minRanking == null) return false;

    // If no filter range specified, include all ranked universities
    if (minRange == null && maxRange == null) return true;

    // Use maxRanking if available, otherwise use minRanking for both bounds
    final effectiveMaxRanking = maxRanking ?? minRanking;

    if (kDebugMode) {
      print('🔍 Ranking Check: Uni($minRanking-$effectiveMaxRanking) vs Filter($minRange-$maxRange)');
    }

    // For overlap to exist, BOTH of these must be true:
    // 1. University's BEST ranking (minRanking) must be ≤ filter's max (if set)
    // 2. University's WORST ranking (effectiveMaxRanking) must be ≥ filter's min (if set)

    // Check condition 1: Exclude if university's BEST ranking is worse than filter's max
    if (maxRange != null && minRanking > maxRange) {
      if (kDebugMode) print('❌ Excluded: Best rank $minRanking > filter max $maxRange');
      return false;
    }

    // Check condition 2: Exclude if university's WORST ranking is better than filter's min
    if (minRange != null && effectiveMaxRanking < minRange) {
      if (kDebugMode) print('❌ Excluded: Worst rank $effectiveMaxRanking < filter min $minRange');
      return false;
    }

    if (kDebugMode) print('✅ Included: Overlap exists');
    return true;
  }

  /// Compare rankings for sorting (lower number = better ranking)
  static int compareRankings(int? rankA, int? rankB) {
    // Handle null cases - push unranked to end
    if (rankA == null && rankB == null) return 0;
    if (rankA == null) return 1;  // A is unranked, push to end
    if (rankB == null) return -1; // B is unranked, push to end

    // Compare rankings (lower is better)
    return rankA.compareTo(rankB);
  }
}