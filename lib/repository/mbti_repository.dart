// lib/repository/mbti_repository.dart

import 'package:flutter/foundation.dart';
import '../model/mbti.dart';
import '../services/mbti_api_service.dart';
import '../services/mbti_storage_service.dart';

class MBTIRepository {
  static final MBTIRepository instance = MBTIRepository._init();
  MBTIRepository._init();

  final MBTIApiService _apiService = MBTIApiService.instance;
  final MBTIStorageService _storageService = MBTIStorageService.instance;

  /// Fetch all test questions
  Future<List<MBTIQuestion>> getQuestions() async {
    try {
      return await _apiService.getQuestions();
    } catch (e) {
      debugPrint('❌ Repository error fetching questions: $e');
      rethrow;
    }
  }

  /// Submit test answers and save result
  Future<MBTIResult> submitTest({
    required List<MBTIAnswer> answers,
    required String gender,
  }) async {
    try {
      debugPrint('📤 Submitting MBTI test (${answers.length} answers)...');

      // Submit to API
      final result = await _apiService.submitAnswers(
        answers: answers,
        gender: gender,
      );

      // Save result locally
      await _storageService.saveResult(result);

      // Clear progress after successful submission
      await _storageService.clearProgress();

      debugPrint('✅ MBTI test submitted and saved: ${result.fullCode}');
      return result;
    } catch (e) {
      debugPrint('❌ Repository error submitting test: $e');
      rethrow;
    }
  }

  /// Save test progress (auto-save)
  Future<void> saveProgress(MBTITestProgress progress) async {
    try {
      await _storageService.saveProgress(progress);
    } catch (e) {
      debugPrint('❌ Repository error saving progress: $e');
      // Don't rethrow - auto-save failure shouldn't break the app
    }
  }

  /// Load saved test progress
  Future<MBTITestProgress?> loadProgress() async {
    try {
      return await _storageService.loadProgress();
    } catch (e) {
      debugPrint('❌ Repository error loading progress: $e');
      return null;
    }
  }

  /// Check if there's saved progress
  Future<bool> hasProgress() async {
    try {
      return await _storageService.hasProgress();
    } catch (e) {
      debugPrint('❌ Repository error checking progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress() async {
    try {
      await _storageService.clearProgress();
    } catch (e) {
      debugPrint('❌ Repository error clearing progress: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<MBTIResult?> loadResult() async {
    try {
      return await _storageService.loadResult();
    } catch (e) {
      debugPrint('❌ Repository error loading result: $e');
      return null;
    }
  }

  /// Clear test result
  Future<void> clearResult() async {
    try {
      await _storageService.clearResult();
    } catch (e) {
      debugPrint('❌ Repository error clearing result: $e');
      rethrow;
    }
  }

  /// Save selected gender
  Future<void> saveGender(String gender) async {
    try {
      await _storageService.saveGender(gender);
    } catch (e) {
      debugPrint('❌ Repository error saving gender: $e');
      // Don't rethrow - gender save failure shouldn't break the app
    }
  }

  /// Load saved gender
  Future<String?> loadGender() async {
    try {
      return await _storageService.loadGender();
    } catch (e) {
      debugPrint('❌ Repository error loading gender: $e');
      return null;
    }
  }

  /// Restart test (clear all data)
  Future<void> restartTest() async {
    try {
      debugPrint('🔄 Restarting MBTI test...');
      await _storageService.clearAll();
      debugPrint('✅ MBTI test restarted');
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