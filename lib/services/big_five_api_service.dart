// lib/services/big_five_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_wise/config/api_config.dart';

import '../model/big_five_model.dart';

class BigFiveApiService {
  static final BigFiveApiService instance = BigFiveApiService._init();
  BigFiveApiService._init();

  //Android Emulator used: http://10.0.2.2:8000
  //Physical Android Device (Wi-Fi) used: http://192.168.0.11:8000
  //Physical Android Device (ADB Reverse) used:	http://localhost:8000 (after running adb reverse tcp:8000 tcp:8000)
  static const String baseUrl = ApiConfig.baseUrl;

  // Cache for questions to avoid repeated API calls
  List<BigFiveQuestion>? _cachedQuestions;

  /// Fetch all 120 personality test questions
  Future<List<BigFiveQuestion>> getQuestions({String lang = 'en'}) async {
    // Return cached questions if available
    if (_cachedQuestions != null) {
      debugPrint('✅ Returning cached Big Five questions (${_cachedQuestions!.length})');
      return _cachedQuestions!;
    }

    try {
      debugPrint('🔄 Fetching Big Five questions from API...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/bigfive/questions').replace(
          queryParameters: {'lang': lang},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final questions = jsonList
            .map((json) => BigFiveQuestion.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache the questions
        _cachedQuestions = questions;

        debugPrint('✅ Successfully fetched ${questions.length} Big Five questions');
        return questions;
      } else {
        debugPrint('❌ Failed to fetch questions: ${response.statusCode}');
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching Big Five questions: $e');
      rethrow;
    }
  }

  /// Submit personality test answers and get result
  Future<BigFiveResult> submitAnswers({
    required List<BigFiveAnswer> answers,
    String lang = 'en',
  }) async {
    try {
      debugPrint('🔄 Submitting Big Five test answers (${answers.length} answers)...');

      // Convert answers to the format expected by the API
      final answersMap = <String, int>{};
      for (var answer in answers) {
        answersMap[answer.questionId] = answer.score;
      }

      final requestBody = {
        'answers': answersMap,
        'lang': lang,
      };

      debugPrint('📤 Request body structure: ${answersMap.length} answers');

      final response = await http.post(
        Uri.parse('$baseUrl/api/bigfive/result'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        final domains = jsonList
            .map((json) => BigFiveDomainResult.fromJson(json as Map<String, dynamic>))
            .toList();

        final result = BigFiveResult(
          domains: domains,
          completedAt: DateTime.now(),
        );

        debugPrint('✅ Big Five test completed successfully');
        return result;
      } else {
        debugPrint('❌ Failed to submit answers: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.body}');
        throw Exception('Failed to submit answers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error submitting Big Five answers: $e');
      rethrow;
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing Big Five API connection...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/bigfive/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final isConnected = response.statusCode == 200;
      debugPrint(isConnected
          ? '✅ Big Five API connection successful'
          : '❌ Big Five API connection failed: ${response.statusCode}');

      return isConnected;
    } catch (e) {
      debugPrint('❌ Big Five API connection error: $e');
      return false;
    }
  }

  /// Clear cached questions (useful for testing or forcing refresh)
  void clearCache() {
    _cachedQuestions = null;
    debugPrint('🗑️ Big Five questions cache cleared');
  }
}