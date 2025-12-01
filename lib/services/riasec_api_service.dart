// lib/services/riasec_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/riasec_model.dart';

class RiasecApiService {
  static final RiasecApiService instance = RiasecApiService._init();
  RiasecApiService._init();

  static const String baseUrl = 'http://10.0.2.2:8000';

  // Cache for questions to avoid repeated API calls
  List<RiasecQuestion>? _cachedQuestions;
  List<RiasecAnswerOption>? _cachedAnswerOptions;

  /// Fetch all 60 RIASEC test questions
  Future<Map<String, dynamic>> getQuestions() async {
    // Return cached data if available
    if (_cachedQuestions != null && _cachedAnswerOptions != null) {
      debugPrint('✅ Returning cached RIASEC questions (${_cachedQuestions!.length})');
      return {
        'questions': _cachedQuestions!,
        'answerOptions': _cachedAnswerOptions!,
      };
    }

    try {
      debugPrint('🔄 Fetching RIASEC questions from API...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/riasec/questions/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        final questions = (json['question'] as List<dynamic>)
            .map((q) => RiasecQuestion.fromJson(q as Map<String, dynamic>))
            .toList();

        final answerOptions = (json['answer_option'] as List<dynamic>)
            .map((a) => RiasecAnswerOption.fromJson(a as Map<String, dynamic>))
            .toList();

        // Cache the data
        _cachedQuestions = questions;
        _cachedAnswerOptions = answerOptions;

        debugPrint('✅ Successfully fetched ${questions.length} RIASEC questions');
        return {
          'questions': questions,
          'answerOptions': answerOptions,
        };
      } else {
        debugPrint('❌ Failed to fetch questions: ${response.statusCode}');
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching RIASEC questions: $e');
      rethrow;
    }
  }

  /// Submit RIASEC test answers and get results
  Future<RiasecResult> submitAnswers({
    required List<RiasecAnswer> answers,
  }) async {
    try {
      debugPrint('🔄 Submitting RIASEC test answers (${answers.length} answers)...');

      // Build answer string (60 digits, 1-5)
      final sortedAnswers = List<RiasecAnswer>.from(answers)
        ..sort((a, b) => a.questionIndex.compareTo(b.questionIndex));

      final answerString = sortedAnswers.map((a) => a.value.toString()).join('');

      debugPrint('📤 Answer string: $answerString (length: ${answerString.length})');

      // Get results from API
      final resultsResponse = await http.post(
        Uri.parse('$baseUrl/api/riasec/results'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'answers': answerString}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      debugPrint('📥 Results response status: ${resultsResponse.statusCode}');

      if (resultsResponse.statusCode == 200) {
        final resultsJson = jsonDecode(resultsResponse.body);

        final interests = (resultsJson['result'] as List<dynamic>)
            .map((i) => RiasecInterestResult.fromJson(i as Map<String, dynamic>))
            .toList();

        debugPrint('✅ Got ${interests.length} interest results');

        // Get matching careers
        final careersResponse = await http.get(
          Uri.parse('$baseUrl/api/riasec/careers')
              .replace(queryParameters: {
            'answers': answerString,
            'start': '1',
            'end': '20',
          }),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        List<RiasecCareer> careers = [];
        if (careersResponse.statusCode == 200) {
          final careersJson = jsonDecode(careersResponse.body);
          careers = (careersJson['career'] as List<dynamic>)
              .map((c) => RiasecCareer.fromJson(c as Map<String, dynamic>))
              .toList();
          debugPrint('✅ Got ${careers.length} career matches');
        }

        final result = RiasecResult(
          interests: interests,
          careers: careers,
          completedAt: DateTime.now(),
        );

        debugPrint('✅ RIASEC test completed successfully');
        return result;
      } else {
        debugPrint('❌ Failed to submit answers: ${resultsResponse.statusCode}');
        debugPrint('📥 Response body: ${resultsResponse.body}');
        throw Exception('Failed to submit answers: ${resultsResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error submitting RIASEC answers: $e');
      rethrow;
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing RIASEC API connection...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/riasec/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final isConnected = response.statusCode == 200;
      debugPrint(isConnected
          ? '✅ RIASEC API connection successful'
          : '❌ RIASEC API connection failed: ${response.statusCode}');

      return isConnected;
    } catch (e) {
      debugPrint('❌ RIASEC API connection error: $e');
      return false;
    }
  }

  /// Clear cached questions (useful for testing or forcing refresh)
  void clearCache() {
    _cachedQuestions = null;
    _cachedAnswerOptions = null;
    debugPrint('🗑️ RIASEC questions cache cleared');
  }
}