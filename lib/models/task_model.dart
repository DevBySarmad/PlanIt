import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  const TaskModel({
    this.id = '',
    required this.title,
    this.description = '',
    this.tag = 'Personal',
    this.priority = 'Medium',
    this.dueAt,
    this.subtasks = const [],
    this.isCompleted = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String tag;
  final String priority;
  final DateTime? dueAt;
  final List<String> subtasks;
  final bool isCompleted;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'tag': tag,
    'priority': priority,
    'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt!),
    'subtasks': subtasks,
    'isCompleted': isCompleted,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
  };

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) => TaskModel(
    id: id,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    tag: map['tag'] as String? ?? 'Personal',
    priority: map['priority'] as String? ?? 'Medium',
    dueAt: _dateFrom(map['dueAt']),
    subtasks: (map['subtasks'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    isCompleted: map['isCompleted'] as bool? ?? false,
    createdAt: _dateFrom(map['createdAt']),
  );

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? tag,
    String? priority,
    DateTime? dueAt,
    List<String>? subtasks,
    bool? isCompleted,
    DateTime? createdAt,
  }) => TaskModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    tag: tag ?? this.tag,
    priority: priority ?? this.priority,
    dueAt: dueAt ?? this.dueAt,
    subtasks: subtasks ?? this.subtasks,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
  );
}

DateTime? _dateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
