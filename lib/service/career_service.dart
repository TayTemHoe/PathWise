// lib/service/career_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/career_suggestion.dart';

/// Service for retrieving and managing career suggestions from Firestore
class CareerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch the latest career suggestion for a user
  /// Returns null if no career suggestion is found
  Future<CareerSuggestion?> getLatestCareerSuggestion(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .where('isLatest', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return CareerSuggestion.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, doc.id);
      }

      return null; // No latest career suggestion found
    } catch (e) {
      debugPrint('Error fetching latest career suggestion: $e');
      throw Exception('Failed to fetch latest career suggestion: $e');
    }
  }

  /// Fetch all career suggestions for a user (history)
  /// Returns list ordered by creation date (newest first)
  Future<List<CareerSuggestion>> getCareerSuggestionsHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CareerSuggestion.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching career suggestions history: $e');
      throw Exception('Failed to fetch career suggestions history: $e');
    }
  }

  /// Fetch a specific career suggestion by ID
  Future<CareerSuggestion?> getCareerSuggestionById(
      String uid, String careerSuggestionId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .doc(careerSuggestionId)
          .get();

      if (doc.exists && doc.data() != null) {
        return CareerSuggestion.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, doc.id);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching career suggestion by ID: $e');
      throw Exception('Failed to fetch career suggestion: $e');
    }
  }

  /// Get count of total career suggestions for a user
  Future<int> getCareerSuggestionsCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting career suggestions count: $e');
      return 0;
    }
  }

  /// Fetch paginated career suggestions history
  /// Useful for lazy loading in UI
  Future<List<CareerSuggestion>> getCareerSuggestionsPaginated({
    required String uid,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => CareerSuggestion.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching paginated career suggestions: $e');
      throw Exception('Failed to fetch paginated career suggestions: $e');
    }
  }

  /// Delete a specific career suggestion
  Future<void> deleteCareerSuggestion(String uid, String careerSuggestionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .doc(careerSuggestionId)
          .delete();

      debugPrint('Career suggestion $careerSuggestionId deleted successfully');
    } catch (e) {
      debugPrint('Error deleting career suggestion: $e');
      throw Exception('Failed to delete career suggestion: $e');
    }
  }

  /// Delete all career suggestions for a user
  Future<void> deleteAllCareerSuggestions(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('All career suggestions deleted for user $uid');
    } catch (e) {
      debugPrint('Error deleting all career suggestions: $e');
      throw Exception('Failed to delete all career suggestions: $e');
    }
  }

  /// Stream the latest career suggestion (real-time updates)
  Stream<CareerSuggestion?> streamLatestCareerSuggestion(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('careersuggestion')
        .where('isLatest', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return CareerSuggestion.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, doc.id);
      }
      return null;
    });
  }

  /// Stream all career suggestions history (real-time updates)
  Stream<List<CareerSuggestion>> streamCareerSuggestionsHistory(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('careersuggestion')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CareerSuggestion.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, doc.id))
          .toList();
    });
  }
}