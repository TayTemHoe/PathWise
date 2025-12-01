// lib/repo/notification_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notification.dart';
import '../services/firebase_service.dart';

class NotificationRepository {
  static const String collectionName = 'notifications';

  // CREATE OPERATIONS

  /// Create a new notification
  static Future<String> createNotification(Notification notification) async {
    try {
      return await FirebaseService.addDocument(collectionName, notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Create appointment status notification
  static Future<String> createAppointmentStatusNotification({
    required String userId,
    required String appointmentId,
    required String status,
    required String workshopName,
    required DateTime appointmentDate,
    required String timeSlot,
  }) async {
    try {
      final notificationData = _buildAppointmentStatusNotification(
        userId: userId,
        appointmentId: appointmentId,
        status: status,
        workshopName: workshopName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
      );

      return await FirebaseService.addDocument(collectionName, notificationData.toMap());
    } catch (e) {
      throw Exception('Failed to create appointment status notification: $e');
    }
  }

  /// Create reminder notification
  static Future<String> createReminderNotification({
    required String userId,
    required String appointmentId,
    required String workshopName,
    required DateTime appointmentDate,
    required String timeSlot,
    required int minutesUntilAppointment,
  }) async {
    try {
      final notification = Notification(
        id: '',
        userId: userId,
        title: 'Upcoming Appointment',
        message: 'Your appointment at $workshopName is in $minutesUntilAppointment minutes.',
        type: 'reminder',
        priority: 'high',
        data: {
          'appointmentId': appointmentId,
          'workshopName': workshopName,
          'appointmentDate': appointmentDate.toIso8601String(),
          'timeSlot': timeSlot,
          'minutesUntilAppointment': minutesUntilAppointment,
        },
        createdAt: DateTime.now(),
      );

      return await FirebaseService.addDocument(collectionName, notification.toMap());
    } catch (e) {
      throw Exception('Failed to create reminder notification: $e');
    }
  }

  // READ OPERATIONS

  /// Get notification by ID
  static Future<Notification?> getNotificationById(String notificationId) async {
    try {
      final doc = await FirebaseService.getDocument(collectionName, notificationId);
      if (doc.exists) {
        return Notification.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get notification: $e');
    }
  }

  /// Get notifications by user ID
  static Future<List<Notification>> getNotificationsByUserId(String userId) async {
    try {
      final snapshot = await FirebaseService.getCollectionWithQuery(
        collectionName,
            (collection) => collection
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true),
      );

      return snapshot.docs
          .map((doc) => Notification.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications by user: $e');
    }
  }

  /// Get unread notifications by user ID
  static Future<List<Notification>> getUnreadNotificationsByUserId(String userId) async {
    try {
      final snapshot = await FirebaseService.getCollectionWithQuery(
        collectionName,
            (collection) => collection
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'unread')
            .orderBy('createdAt', descending: true),
      );

      return snapshot.docs
          .map((doc) => Notification.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get unread notifications: $e');
    }
  }

  /// Get notifications by type
  static Future<List<Notification>> getNotificationsByType(String userId, String type) async {
    try {
      final snapshot = await FirebaseService.getCollectionWithQuery(
        collectionName,
            (collection) => collection
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: type)
            .orderBy('createdAt', descending: true),
      );

      return snapshot.docs
          .map((doc) => Notification.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications by type: $e');
    }
  }

  /// Get notifications with pagination
  static Future<List<Notification>> getNotificationsPaginated({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final snapshot = await FirebaseService.getCollectionWithQuery(
        collectionName,
            (collection) {
          Query query = collection
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(limit);

          if (startAfter != null) {
            query = query.startAfterDocument(startAfter);
          }

          return query;
        },
      );

      return snapshot.docs
          .map((doc) => Notification.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated notifications: $e');
    }
  }

  // UPDATE OPERATIONS

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseService.updateDocument(collectionName, notificationId, {
        'status': 'read',
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final unreadNotifications = await getUnreadNotificationsByUserId(userId);
      final batch = FirebaseService.createBatch();

      for (final notification in unreadNotifications) {
        final docRef = FirebaseService.db.collection(collectionName).doc(notification.id);
        batch.update(docRef, {
          'status': 'read',
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await FirebaseService.commitBatch(batch);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Update notification
  static Future<void> updateNotification(Notification notification) async {
    try {
      await FirebaseService.updateDocument(collectionName, notification.id, notification.toMap());
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  // DELETE OPERATIONS

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseService.deleteDocument(collectionName, notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete notifications older than specified days
  static Future<void> deleteOldNotifications(String userId, int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await FirebaseService.getCollectionWithQuery(
        collectionName,
            (collection) => collection
            .where('userId', isEqualTo: userId)
            .where('createdAt', isLessThan: cutoffDate.toIso8601String()),
      );

      final batch = FirebaseService.createBatch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await FirebaseService.commitBatch(batch);
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }

  // STREAM OPERATIONS

  /// Stream notifications by user ID
  static Stream<List<Notification>> getNotificationsStream(String userId) {
    return FirebaseService.getCollectionStreamWithQuery(
      collectionName,
          (collection) => collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    ).map((snapshot) {
      return snapshot.docs
          .map((doc) => Notification.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    });
  }

  /// Stream unread notifications count
  static Stream<int> getUnreadCountStream(String userId) {
    return FirebaseService.getCollectionStreamWithQuery(
      collectionName,
          (collection) => collection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread'),
    ).map((snapshot) => snapshot.docs.length);
  }

  // UTILITY OPERATIONS

  /// Get unread notifications count
  static Future<int> getUnreadCount(String userId) async {
    try {
      final unreadNotifications = await getUnreadNotificationsByUserId(userId);
      return unreadNotifications.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Check for duplicate appointment notifications
  static Future<bool> appointmentNotificationExists(String userId, String appointmentId, String status) async {
    try {
      final snapshot = await FirebaseService.getCollectionWithQuery(
        collectionName,
            (collection) => collection
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: 'appointment')
            .where('data.appointmentId', isEqualTo: appointmentId)
            .where('data.status', isEqualTo: status),
      );

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check appointment notification existence: $e');
    }
  }

  // PRIVATE HELPER METHODS

  /// Build appointment status notification based on status
  static Notification _buildAppointmentStatusNotification({
    required String userId,
    required String appointmentId,
    required String status,
    required String workshopName,
    required DateTime appointmentDate,
    required String timeSlot,
  }) {
    String title;
    String message;
    String priority = 'medium';

    switch (status.toLowerCase()) {
      case 'confirmed':
        title = 'Appointment Confirmed';
        message = 'Your service appointment at $workshopName has been confirmed for ${_formatDate(appointmentDate)} at $timeSlot.';
        priority = 'high';
        break;
      case 'in_progress':
      case 'inprogress':
        title = 'Service In Progress';
        message = 'Your vehicle service at $workshopName is now in progress. We\'ll notify you when it\'s ready for pickup.';
        break;
      case 'ready_for_pickup':
      case 'readyforpickup':
        title = 'Ready for Pickup';
        message = 'Great news! Your vehicle is ready for pickup at $workshopName. Please proceed to payment for the services.';
        priority = 'high';
        break;
      case 'completed':
        title = 'Service Completed';
        message = 'Your vehicle service has been completed successfully! Thank you for choosing $workshopName. Don\'t forget to leave a review!';
        priority = 'high';
        break;
      case 'cancelled':
        title = 'Appointment Cancelled';
        message = 'Your appointment at $workshopName scheduled for ${_formatDate(appointmentDate)} has been cancelled.';
        priority = 'high';
        break;
      case 'overdue':
        title = 'Missed Appointment';
        message = 'You missed your service appointment at $workshopName on ${_formatDate(appointmentDate)}. Please reschedule if needed.';
        priority = 'high';
        break;
      default:
        title = 'Appointment Pending';
        message = 'Your appointment at $workshopName is pending and awaiting confirmation.';
    }

    return Notification(
      id: '',
      userId: userId,
      title: title,
      message: message,
      type: 'appointment',
      priority: priority,
      data: {
        'appointmentId': appointmentId,
        'status': status,
        'workshopName': workshopName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'timeSlot': timeSlot,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}