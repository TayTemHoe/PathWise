// lib/view_model/notification_view_model.dart
import 'package:flutter/material.dart' hide Notification;
import 'dart:async';
import '../model/notification.dart';
import '../repository/notification_repository.dart';
import '../services/firebase_service.dart';

class NotificationViewModel extends ChangeNotifier {
  // State variables
  List<Notification> _notifications = [];
  List<Notification> _unreadNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription<List<Notification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  Timer? _schedulerTimer;
  Set<String> _processedReminders = {}; // Track sent reminders
  Set<String> _processedOverdueChecks = {}; // Track overdue checks

  // Getters
  List<Notification> get notifications => _notifications;
  List<Notification> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper getters
  List<Notification> get reminderNotifications =>
      _notifications.where((n) => n.type == 'reminder').toList();

  List<Notification> get systemNotifications =>
      _notifications.where((n) => n.type == 'system').toList();

  List<Notification> get highPriorityNotifications =>
      _notifications.where((n) => n.priority == 'high').toList();

  List<Notification> get todaysNotifications {
    final today = DateTime.now();
    return _notifications.where((notification) {
      return notification.createdAt.year == today.year &&
          notification.createdAt.month == today.month &&
          notification.createdAt.day == today.day;
    }).toList();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // INITIALIZATION AND CLEANUP

  /// Initialize notification system for a user
  Future<void> initializeForUser(String userId) async {
    try {
      _clearError();

      // Validate userId
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Load initial data with error handling
      await loadNotifications(userId);

      // Only set up streams if loading was successful
      if (_error == null) {
        _setupNotificationStreams(userId);
      }
    } catch (e) {
      _setError('Failed to initialize notifications: ${e.toString()}');
    }
  }

  /// Clean up resources
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _schedulerTimer?.cancel();
    super.dispose();
  }

  /// Set up real-time streams
  void _setupNotificationStreams(String userId) {
    // Listen to notifications
    _notificationsSubscription =
        NotificationRepository.getNotificationsStream(userId).listen(
              (notifications) {
            _notifications = notifications;
            _unreadNotifications =
                notifications.where((n) => n.isUnread).toList();
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to listen to notifications: ${error.toString()}');
          },
        );

    // Listen to unread count
    _unreadCountSubscription =
        NotificationRepository.getUnreadCountStream(userId).listen(
              (count) {
            _unreadCount = count;
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to listen to unread count: ${error.toString()}');
          },
        );
  }

  /// Clear processed reminders (call this periodically to prevent memory buildup)
  void clearProcessedReminders() {
    _processedReminders.clear();
    _processedOverdueChecks.clear();
    debugPrint('Cleared processed reminders cache');
  }

  /// Create custom notification
  Future<bool> createCustomNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    String priority = 'medium',
    Map<String, dynamic>? data,
  }) async {
    try {
      _clearError();

      final notification = Notification(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        data: data,
        createdAt: DateTime.now(),
      );

      await NotificationRepository.createNotification(notification);
      return true;
    } catch (e) {
      _setError('Failed to create notification: ${e.toString()}');
      return false;
    }
  }

  // READ OPERATIONS

  /// Load notifications for a user
  Future<void> loadNotifications(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate userId before making the query
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Check if user exists in Firestore first
      final userExists = await _checkUserExists(userId);
      if (!userExists) {
        throw Exception('User not found. Please log in again.');
      }

      _notifications = await NotificationRepository.getNotificationsByUserId(userId);
      _unreadNotifications = _notifications.where((n) => n.isUnread).toList();
      _unreadCount = _unreadNotifications.length;

      notifyListeners();
    } catch (e) {
      // Handle specific Firestore errors
      String errorMessage = 'Failed to load notifications';

      if (e.toString().contains('failed-precondition')) {
        errorMessage = 'Database index is being created. Please wait a moment and try again.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please log in again.';
      } else if (e.toString().contains('unavailable')) {
        errorMessage = 'Service temporarily unavailable. Please check your connection.';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      _setError(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user exists in Firestore
  Future<bool> _checkUserExists(String userId) async {
    try {
      final userDoc = await FirebaseService.getUser(userId);
      return userDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Load notifications by type
  Future<void> loadNotificationsByType(String userId, String type) async {
    try {
      _setLoading(true);
      _clearError();

      final typeNotifications = await NotificationRepository
          .getNotificationsByType(userId, type);
      // Update only the notifications of this type
      _notifications.removeWhere((n) => n.type == type);
      _notifications.addAll(typeNotifications);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _unreadNotifications = _notifications.where((n) => n.isUnread).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notifications by type: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications(String userId) async {
    try {
      _clearError();

      if (_notifications.isEmpty) return;

      // Get last notification for pagination
      final lastDoc = await NotificationRepository.getNotificationById(
          _notifications.last.id);

      final moreNotifications = await NotificationRepository
          .getNotificationsPaginated(
        userId: userId,
        limit: 20,
      );

      if (moreNotifications.isNotEmpty) {
        _notifications.addAll(moreNotifications);
        _unreadNotifications = _notifications.where((n) => n.isUnread).toList();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load more notifications: ${e.toString()}');
    }
  }

  // UPDATE OPERATIONS

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      _clearError();

      await NotificationRepository.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          status: 'read',
          readAt: DateTime.now(),
        );
        _unreadNotifications = _notifications.where((n) => n.isUnread).toList();
        _unreadCount = _unreadNotifications.length;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to mark notification as read: ${e.toString()}');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      _clearError();

      await NotificationRepository.markAllAsRead(userId);

      // Update local state
      _notifications = _notifications.map((n) =>
          n.copyWith(
            status: 'read',
            readAt: DateTime.now(),
          )).toList();
      _unreadNotifications.clear();
      _unreadCount = 0;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to mark all notifications as read: ${e.toString()}');
      return false;
    }
  }

  // DELETE OPERATIONS

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      _clearError();

      await NotificationRepository.deleteNotification(notificationId);

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications = _notifications.where((n) => n.isUnread).toList();
      _unreadCount = _unreadNotifications.length;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete notification: ${e.toString()}');
      return false;
    }
  }

  /// Clear old notifications (older than specified days)
  Future<bool> clearOldNotifications(String userId, {int daysOld = 30}) async {
    try {
      _clearError();

      await NotificationRepository.deleteOldNotifications(userId, daysOld);
      await loadNotifications(userId); // Refresh the list

      return true;
    } catch (e) {
      _setError('Failed to clear old notifications: ${e.toString()}');
      return false;
    }
  }

  // UTILITY METHODS
  /// Clear all data
  void clearData() {
    _notifications.clear();
    _unreadNotifications.clear();
    _unreadCount = 0;
    _error = null;
    _isLoading = false;
    _processedReminders.clear();
    _processedOverdueChecks.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  /// Refresh notifications
  Future<void> refreshNotifications(String userId) async {
    await loadNotifications(userId);
  }

  /// Get notifications count by type
  int getNotificationCountByType(String type) {
    return _notifications
        .where((n) => n.type == type)
        .length;
  }

  /// Check if there are any high priority unread notifications
  bool hasHighPriorityUnread() {
    return _unreadNotifications.any((n) => n.priority == 'high');
  }

  /// Get notification by appointment ID
  Notification? getNotificationByAppointmentId(String appointmentId) {
    try {
      return _notifications.firstWhere(
            (n) => n.data?['appointmentId'] == appointmentId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Format notification time for display
  String formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1
          ? ''
          : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1
          ? ''
          : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get appropriate color for notification priority
  Color getNotificationColor(Notification notification) {
    switch (notification.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}