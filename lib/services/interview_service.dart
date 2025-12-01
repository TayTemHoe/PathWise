import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/careerroadmap_model.dart';


class InterviewService{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update interview session with evaluation results
  Future<void> updateInterviewSessionWithEvaluation({
    required String uid,
    required String sessionId,
    required Map<String, dynamic> evaluationData,
  }) async {
    try {
      final updateData = {
        ...evaluationData,
        'updatedAt': Timestamp.now(),
        'endTime': Timestamp.now(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('interview')
          .doc(sessionId)
          .update(updateData);

      debugPrint('✅ Updated interview session with evaluation: $sessionId');
    } catch (e) {
      debugPrint('❌ Error updating interview session: $e');
      throw Exception('Failed to update interview session: $e');
    }
  }

  /// Get interview session by ID
  Future<Map<String, dynamic>?> getInterviewSession(String uid, String sessionId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('interview')
          .doc(sessionId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('❌ Error fetching interview session: $e');
      throw Exception('Failed to fetch interview session: $e');
    }
  }

  /// Get all interview sessions for a user
  Future<List<Map<String, dynamic>>> getAllInterviewSessions(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('interview')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching interview sessions: $e');
      throw Exception('Failed to fetch interview sessions: $e');
    }
  }

  /// Get recent interview sessions (last N sessions)
  Future<List<Map<String, dynamic>>> getRecentInterviewSessions(String uid, {int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('interview')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching recent interview sessions: $e');
      throw Exception('Failed to fetch recent interview sessions: $e');
    }
  }

  /// Delete interview session
  Future<void> deleteInterviewSession(String uid, String sessionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('interview')
          .doc(sessionId)
          .delete();

      debugPrint('🗑️ Deleted interview session: $sessionId');
    } catch (e) {
      debugPrint('❌ Error deleting interview session: $e');
      throw Exception('Failed to delete interview session: $e');
    }
  }
}
