// lib/services/mbti_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/mbti.dart';

class MBTIApiService {
  static final MBTIApiService instance = MBTIApiService._init();
  MBTIApiService._init();

  //Android Emulator used: http://10.0.2.2:8000
  //Physical Android Device (Wi-Fi) used: http://192.168.0.11:8000
  //Physical Android Device (ADB Reverse) used:	http://localhost:8000 (after running adb reverse tcp:8000 tcp:8000)
  static const String baseUrl = 'http://192.168.0.11:8000';

  // Cache for questions to avoid repeated API calls
  List<MBTIQuestion>? _cachedQuestions;

  /// Fetch all personality test questions
  Future<List<MBTIQuestion>> getQuestions() async {
    // Return cached questions if available
    if (_cachedQuestions != null) {
      debugPrint('✅ Returning cached MBTI questions (${_cachedQuestions!.length})');
      return _cachedQuestions!;
    }

    try {
      debugPrint('🔄 Fetching MBTI questions from API...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/personality/questions'),
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
            .map((json) => MBTIQuestion.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache the questions
        _cachedQuestions = questions;

        debugPrint('✅ Successfully fetched ${questions.length} MBTI questions');
        return questions;
      } else {
        debugPrint('❌ Failed to fetch questions: ${response.statusCode}');
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching MBTI questions: $e');
      rethrow;
    }
  }

  /// Submit personality test answers and get result
  Future<MBTIResult> submitAnswers({
    required List<MBTIAnswer> answers,
    required String gender,
  }) async {
    try {
      debugPrint('🔄 Submitting MBTI test answers (${answers.length} answers)...');

      final requestBody = {
        'answers': answers.map((a) => a.toJson()).toList(),
        'gender': gender,
      };

      debugPrint('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/personality/submit'),
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
        final Map<String, dynamic> json = jsonDecode(response.body);
        final result = MBTIResult.fromJson(json);

        debugPrint('✅ MBTI test completed: ${result.fullCode} (${result.niceName})');
        return result;
      } else {
        debugPrint('❌ Failed to submit answers: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.body}');
        throw Exception('Failed to submit answers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error submitting MBTI answers: $e');
      rethrow;
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing MBTI API connection...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/personality/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final isConnected = response.statusCode == 200;
      debugPrint(isConnected
          ? '✅ MBTI API connection successful'
          : '❌ MBTI API connection failed: ${response.statusCode}');

      return isConnected;
    } catch (e) {
      debugPrint('❌ MBTI API connection error: $e');
      return false;
    }
  }

  /// Clear cached questions (useful for testing or forcing refresh)
  void clearCache() {
    _cachedQuestions = null;
    debugPrint('🗑️ MBTI questions cache cleared');
  }
}