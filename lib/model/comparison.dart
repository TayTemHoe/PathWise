// lib/model/comparison.dart

import 'package:flutter/material.dart';

enum ComparisonType {
  programs,
  universities,
}

class ComparisonItem {
  final String id;
  final String name;
  final String? logoUrl;
  final ComparisonType type;

  ComparisonItem({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ComparisonItem &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'ComparisonItem(id: $id, name: $name, logoUrl: $logoUrl, type: $type)';
  }

  ComparisonItem copyWith({
    String? id,
    String? name,
    String? logoUrl,
    ComparisonType? type,
  }) {
    return ComparisonItem(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'type': type.toString(),
    };
  }

  factory ComparisonItem.fromJson(Map<String, dynamic> json) {
    return ComparisonItem(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      type: json['type'] == 'ComparisonType.programs'
          ? ComparisonType.programs
          : ComparisonType.universities,
    );
  }

  // Convert to SQLite format
  Map<String, dynamic> toSQLite(String userId) {
    return {
      'user_id': userId,
      'item_type': type == ComparisonType.programs ? 'program' : 'university',
      'item_id': id,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create from SQLite row
  factory ComparisonItem.fromSQLite(
      Map<String, dynamic> row, {
        required String name,
        String? logoUrl,
      }) {
    return ComparisonItem(
      id: row['item_id'] as String,
      name: name,
      logoUrl: logoUrl,
      type: row['item_type'] == 'program'
          ? ComparisonType.programs
          : ComparisonType.universities,
    );
  }
}

class ComparisonAttribute {
  final String label;
  final String tooltip;
  final List<String?> values;

  ComparisonAttribute({
    required this.label,
    required this.tooltip,
    required this.values,
  });

  @override
  String toString() {
    return 'ComparisonAttribute(label: $label, values: $values)';
  }
}

class ComparisonMetric {
  final String label;
  final String? value;
  final String? category;
  final Color? color;

  ComparisonMetric({
    required this.label,
    this.value,
    this.category,
    this.color,
  });
}