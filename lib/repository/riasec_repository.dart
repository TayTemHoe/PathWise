// lib/repository/riasec_repository.dart

import 'package:flutter/foundation.dart';
import '../model/riasec_model.dart';
import '../services/riasec_api_service.dart';
import '../services/riasec_storage_service.dart';

class RiasecRepository {
  static final RiasecRepository instance = RiasecRepository._init();
  RiasecRepository._init();

  final RiasecApiService _apiService = RiasecApiService.instance;
  final RiasecStorageService _storageService = RiasecStorageService.instance;

  /// Fetch all test questions and answer options (Shared data)
  Future<Map<String, dynamic>> getQuestions() async {
    try {
      return await _apiService.getQuestions();
    } catch (e) {
      debugPrint('❌ Repository error fetching questions: $e');
      rethrow;
    }
  }

  /// Submit test answers and save result
  Future<RiasecResult> submitTest({
    required String userId, // ADDED
    required List<RiasecAnswer> answers,
  }) async {
    try {
      debugPrint('📤 Submitting RIASEC test (${answers.length} answers) for user: $userId...');

      // Submit to API
      final result = await _apiService.submitAnswers(answers: answers);

      // Save result locally with userId
      await _storageService.saveResult(userId, result);

      // Clear progress after successful submission
      await _storageService.clearProgress(userId);

      debugPrint('✅ RIASEC test submitted and saved');
      return result;
    } catch (e) {
      debugPrint('❌ Repository error submitting test: $e');
      rethrow;
    }
  }

  /// Save test progress (auto-save)
  Future<void> saveProgress(String userId, RiasecTestProgress progress) async {
    try {
      await _storageService.saveProgress(userId, progress);
    } catch (e) {
      debugPrint('❌ Repository error saving progress: $e');
      // Don't rethrow - auto-save failure shouldn't break the app
    }
  }

  /// Load saved test progress
  Future<RiasecTestProgress?> loadProgress(String userId) async {
    try {
      return await _storageService.loadProgress(userId);
    } catch (e) {
      debugPrint('❌ Repository error loading progress: $e');
      return null;
    }
  }

  /// Check if there's saved progress
  Future<bool> hasProgress(String userId) async {
    try {
      return await _storageService.hasProgress(userId);
    } catch (e) {
      debugPrint('❌ Repository error checking progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress(String userId) async {
    try {
      await _storageService.clearProgress(userId);
    } catch (e) {
      debugPrint('❌ Repository error clearing progress: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<RiasecResult?> loadResult(String userId) async {
    try {
      return await _storageService.loadResult(userId);
    } catch (e) {
      debugPrint('❌ Repository error loading result: $e');
      return null;
    }
  }

  /// Clear test result
  Future<void> clearResult(String userId) async {
    try {
      await _storageService.clearResult(userId);
    } catch (e) {
      debugPrint('❌ Repository error clearing result: $e');
      rethrow;
    }
  }

  /// Restart test (clear all data)
  Future<void> restartTest(String userId) async {
    try {
      debugPrint('🔄 Restarting RIASEC test for user: $userId...');
      await _storageService.clearAll(userId);
      debugPrint('✅ RIASEC test restarted');
    } catch (e) {
      debugPrint('❌ Repository error restarting test: $e');
      rethrow;
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      return await _apiService.testConnection();
    } catch (e) {
      debugPrint('❌ Repository error testing connection: $e');
      return false;
    }
  }

  /// Clear API cache
  void clearCache() {
    _apiService.clearCache();
  }
}