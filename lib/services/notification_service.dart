// lib/services/notification_service.dart
import 'package:flutter/material.dart' hide Notification;
import '../model/notification.dart';
import '../repository/notification_repository.dart';
import '../services/firebase_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  /// Create 30-minute reminder notification
  static Future<void> createAppointmentReminder({
    required String userId,
    required String appointmentId,
    required String workshopName,
    required DateTime appointmentDate,
    required String timeSlot,
    required int minutesUntilAppointment,
  }) async {
    try {
      await NotificationRepository.createReminderNotification(
        userId: userId,
        appointmentId: appointmentId,
        workshopName: workshopName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        minutesUntilAppointment: minutesUntilAppointment,
      );

      debugPrint('✓ Created reminder notification for appointment: $appointmentId');
    } catch (e) {
      debugPrint('✗ Failed to create reminder notification: $e');
    }
  }

  /// Create appointment day reminder (morning of appointment)
  static Future<void> createDayOfAppointmentReminder({
    required String userId,
    required String appointmentId,
    required String workshopName,
    required DateTime appointmentDate,
    required String timeSlot,
  }) async {
    try {
      final notification = Notification(
        id: '',
        userId: userId,
        title: 'Appointment Today',
        message: 'Don\'t forget about your appointment at $workshopName today at $timeSlot. Make sure to bring your car and arrive on time.',
        type: 'reminder',
        priority: 'high',
        data: {
          'appointmentId': appointmentId,
          'workshopName': workshopName,
          'appointmentDate': appointmentDate.toIso8601String(),
          'timeSlot': timeSlot,
          'reminderType': 'day_of',
        },
        createdAt: DateTime.now(),
      );

      await NotificationRepository.createNotification(notification);
      debugPrint('✓ Created day-of reminder for appointment: $appointmentId');
    } catch (e) {
      debugPrint('✗ Failed to create day-of reminder: $e');
    }
  }

  // System and promotional notifications

  /// Create welcome notification for new users
  static Future<void> createWelcomeNotification({
    required String userId,
    required String userName,
  }) async {
    try {
      final notification = Notification(
        id: '',
        userId: userId,
        title: 'Welcome to PathWise!',
        message: 'Hi $userName! Welcome to PathWise.',
        type: 'system',
        priority: 'medium',
        data: {
          'notificationType': 'welcome',
          'userName': userName,
        },
        createdAt: DateTime.now(),
      );

      await NotificationRepository.createNotification(notification);
      debugPrint('✓ Created welcome notification for user: $userId');
    } catch (e) {
      debugPrint('✗ Failed to create welcome notification: $e');
    }
  }

  /// Create service due reminder based on car maintenance schedule
  static Future<void> createServiceDueReminder({
    required String userId,
    required String carBrand,
    required String carModel,
    required String plateNumber,
    required String serviceType,
    int daysUntilDue = 7,
  }) async {
    try {
      final notification = Notification(
        id: '',
        userId: userId,
        title: 'Service Due Soon',
        message: 'Your $carBrand $carModel ($plateNumber) is due for $serviceType in $daysUntilDue days. Book your appointment now to keep your car running smoothly.',
        type: 'reminder',
        priority: 'medium',
        data: {
          'notificationType': 'service_due',
          'carBrand': carBrand,
          'carModel': carModel,
          'plateNumber': plateNumber,
          'serviceType': serviceType,
          'daysUntilDue': daysUntilDue,
        },
        createdAt: DateTime.now(),
      );

      await NotificationRepository.createNotification(notification);
      debugPrint('✓ Created service due reminder for user: $userId');
    } catch (e) {
      debugPrint('✗ Failed to create service due reminder: $e');
    }
  }

  /// Create promotional notification
  static Future<void> createPromotionalNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? promotionData,
  }) async {
    try {
      final notification = Notification(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: 'system',
        priority: 'low',
        data: {
          'notificationType': 'promotion',
          ...?promotionData,
        },
        createdAt: DateTime.now(),
      );

      await NotificationRepository.createNotification(notification);
      debugPrint('✓ Created promotional notification for user: $userId');
    } catch (e) {
      debugPrint('✗ Failed to create promotional notification: $e');
    }
  }

  // Private helper methods

  /// Create review reminder notification after service completion
  static Future<void> _createReviewReminderNotification({
    required String userId,
    required String workshopName,
    required String appointmentId,
  }) async {
    try {
      // Schedule review reminder for 1 day after completion
      final notification = Notification(
        id: '',
        userId: userId,
        title: 'How was your service?',
        message: 'We hope you had a great experience at $workshopName! Please take a moment to leave a review and help other car owners.',
        type: 'system',
        priority: 'low',
        data: {
          'notificationType': 'review_reminder',
          'workshopName': workshopName,
          'appointmentId': appointmentId,
        },
        createdAt: DateTime.now(),
      );

      await NotificationRepository.createNotification(notification);
      debugPrint('✓ Created review reminder for appointment: $appointmentId');
    } catch (e) {
      debugPrint('✗ Failed to create review reminder: $e');
    }
  }

  // Batch operations for admin/system use

  /// Send notification to all users (admin only)
  static Future<void> broadcastNotification({
    required String title,
    required String message,
    String type = 'system',
    String priority = 'medium',
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all users
      final allUsers = await FirebaseService.getAllUsers();

      final batch = FirebaseService.createBatch();
      const maxBatchSize = 500; // Firestore batch limit

      for (int i = 0; i < allUsers.docs.length; i += maxBatchSize) {
        final batchUsers = allUsers.docs.skip(i).take(maxBatchSize);

        for (final userDoc in batchUsers) {
          final notification = Notification(
            id: '',
            userId: userDoc.id,
            title: title,
            message: message,
            type: type,
            priority: priority,
            data: data,
            createdAt: DateTime.now(),
          );

          final docRef = FirebaseService.db
              .collection('notifications')
              .doc();

          batch.set(docRef, notification.toMap());
        }

        await FirebaseService.commitBatch(batch);
        debugPrint('✓ Broadcasted notifications to batch ${i ~/ maxBatchSize + 1}');
      }

      debugPrint('✓ Successfully broadcasted notification to all users');
    } catch (e) {
      debugPrint('✗ Failed to broadcast notification: $e');
      rethrow;
    }
  }

  /// Clean up old notifications (run periodically)
  static Future<void> cleanupOldNotifications({int daysOld = 90}) async {
    try {
      // This would typically be run as a cloud function or scheduled task
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final oldNotifications = await FirebaseService.getCollectionWithQuery(
        'notifications',
            (collection) => collection
            .where('createdAt', isLessThan: cutoffDate.toIso8601String())
            .where('status', isEqualTo: 'read'),
      );

      final batch = FirebaseService.createBatch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await FirebaseService.commitBatch(batch);
      debugPrint('✓ Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      debugPrint('✗ Failed to cleanup old notifications: $e');
    }
  }
}