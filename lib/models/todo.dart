import 'dart:convert';

enum ReminderType { none, daily, weekly, monthly }

class Todo {
  final String id;
  final String title;
  final String notes;
  final ReminderType reminderType;
  final DateTime? nextReminder;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    required this.notes,
    required this.reminderType,
    this.nextReminder,
    required this.createdAt,
    this.lastUpdated,
    this.isCompleted = false,
  });

  Todo copyWith({
    String? id,
    String? title,
    String? notes,
    ReminderType? reminderType,
    DateTime? nextReminder,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isCompleted,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      reminderType: reminderType ?? this.reminderType,
      nextReminder: nextReminder ?? this.nextReminder,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'reminderType': reminderType.index,
      'nextReminder': nextReminder?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      notes: map['notes'] ?? '',
      reminderType: ReminderType.values[map['reminderType'] ?? 0],
      nextReminder: map['nextReminder'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextReminder'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Todo.fromJson(String source) => Todo.fromMap(json.decode(source));

  DateTime? calculateNextReminder() {
    if (reminderType == ReminderType.none) return null;

    final now = DateTime.now();
    DateTime next;

    switch (reminderType) {
      case ReminderType.daily:
        next = DateTime(now.year, now.month, now.day + 1, 9, 0);
        break;
      case ReminderType.weekly:
        next = DateTime(now.year, now.month, now.day + 7, 9, 0);
        break;
      case ReminderType.monthly:
        next = DateTime(now.year, now.month + 1, now.day, 9, 0);
        break;
      case ReminderType.none:
        return null;
    }

    return next;
  }
}
