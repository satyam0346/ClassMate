import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data model for a task (personal or class-wide).
class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String subject;
  final String priority; // "high" | "medium" | "low"
  final String status;   // "pending" | "in_progress" | "done"
  final String createdBy;
  final bool   isClassTask;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.subject,
    required this.priority,
    required this.status,
    required this.createdBy,
    required this.isClassTask,
    required this.createdAt,
  });

  bool get isOverdue =>
      status != 'done' && dueDate.isBefore(DateTime.now());

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id:          doc.id,
      title:       d['title']       as String? ?? '',
      description: d['description'] as String? ?? '',
      dueDate:     (d['dueDate']    as Timestamp?)?.toDate() ?? DateTime.now(),
      subject:     d['subject']     as String? ?? '',
      priority:    d['priority']    as String? ?? 'medium',
      status:      d['status']      as String? ?? 'pending',
      createdBy:   d['createdBy']   as String? ?? '',
      isClassTask: d['isClassTask'] as bool?   ?? false,
      createdAt:   (d['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':       title,
    'description': description,
    'dueDate':     Timestamp.fromDate(dueDate),
    'subject':     subject,
    'priority':    priority,
    'status':      status,
    'createdBy':   createdBy,
    'isClassTask': isClassTask,
    'createdAt':   Timestamp.fromDate(createdAt),
  };

  TaskModel copyWith({
    String?   title,
    String?   description,
    DateTime? dueDate,
    String?   subject,
    String?   priority,
    String?   status,
  }) => TaskModel(
    id:          id,
    title:       title       ?? this.title,
    description: description ?? this.description,
    dueDate:     dueDate     ?? this.dueDate,
    subject:     subject     ?? this.subject,
    priority:    priority    ?? this.priority,
    status:      status      ?? this.status,
    createdBy:   createdBy,
    isClassTask: isClassTask,
    createdAt:   createdAt,
  );
}
