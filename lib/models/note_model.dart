import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  const NoteModel({
    this.id = '',
    required this.title,
    required this.content,
    this.tag = 'Ideas',
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String tag;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'tag': tag,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
  };

  factory NoteModel.fromMap(String id, Map<String, dynamic> map) => NoteModel(
    id: id,
    title: map['title'] as String? ?? '',
    content: map['content'] as String? ?? '',
    tag: map['tag'] as String? ?? 'Ideas',
    createdAt: _dateFrom(map['createdAt']),
  );

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? tag,
    DateTime? createdAt,
  }) => NoteModel(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    tag: tag ?? this.tag,
    createdAt: createdAt ?? this.createdAt,
  );
}

DateTime? _dateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
