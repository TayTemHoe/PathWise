// lib/model/notification.dart
class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'appointment', 'reminder', 'system'
  final String status; // 'unread', 'read'
  final String priority; // 'low', 'medium', 'high'
  final Map<String, dynamic>? data; // Additional data like appointmentId
  final DateTime createdAt;
  final DateTime? readAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.status = 'unread',
    this.priority = 'medium',
    this.data,
    required this.createdAt,
    this.readAt,
  });

  factory Notification.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Notification(
      id: docId ?? (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'system',
      status: (map['status'] as String?) ?? 'unread',
      priority: (map['priority'] as String?) ?? 'medium',
      data: map['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse((map['createdAt'] as String?) ?? DateTime.now().toIso8601String()),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'status': status,
    'priority': priority,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
  };

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? status,
    String? priority,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  bool get isRead => status == 'read';
  bool get isUnread => status == 'unread';
  bool get isHighPriority => priority == 'high';

  @override
  String toString() =>
      'Notification(id: $id, title: $title, type: $type, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Notification && other.id == id;

  @override
  int get hashCode => id.hashCode;
}