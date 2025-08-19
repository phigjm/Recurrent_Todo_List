import 'dart:convert';

enum ReminderType { none, daily, weekly, monthly, custom }

class CompletionEntry {
  final DateTime completedAt;
  final String? note;

  CompletionEntry({required this.completedAt, this.note});

  Map<String, dynamic> toMap() {
    return {'completedAt': completedAt.millisecondsSinceEpoch, 'note': note};
  }

  factory CompletionEntry.fromMap(Map<String, dynamic> map) {
    return CompletionEntry(
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completedAt']),
      note: map['note'],
    );
  }
}

class Todo {
  final String id;
  final String title;
  final String notes;
  final ReminderType reminderType;
  final DateTime? nextReminder;
  final DateTime? customReminderDate;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isCompleted;
  final bool isHidden;
  final DateTime? snoozedUntil;
  final List<CompletionEntry> completionHistory;

  Todo({
    required this.id,
    required this.title,
    required this.notes,
    required this.reminderType,
    this.nextReminder,
    this.customReminderDate,
    required this.createdAt,
    this.lastUpdated,
    this.isCompleted = false,
    this.isHidden = false,
    this.snoozedUntil,
    this.completionHistory = const [],
  });

  Todo copyWith({
    String? id,
    String? title,
    String? notes,
    ReminderType? reminderType,
    DateTime? nextReminder,
    DateTime? customReminderDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isCompleted,
    bool? isHidden,
    DateTime? snoozedUntil,
    List<CompletionEntry>? completionHistory,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      reminderType: reminderType ?? this.reminderType,
      nextReminder: nextReminder ?? this.nextReminder,
      customReminderDate: customReminderDate ?? this.customReminderDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCompleted: isCompleted ?? this.isCompleted,
      isHidden: isHidden ?? this.isHidden,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      completionHistory: completionHistory ?? this.completionHistory,
    );
  }

  bool get shouldBeHidden {
    final now = DateTime.now();

    // Hide if explicitly hidden
    if (isHidden) return true;

    // Hide if snoozed
    if (snoozedUntil != null && snoozedUntil!.isAfter(now)) return true;

    // Hide if has future reminder
    if (nextReminder != null && nextReminder!.isAfter(now)) return true;

    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'reminderType': reminderType.index,
      'nextReminder': nextReminder?.millisecondsSinceEpoch,
      'customReminderDate': customReminderDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'isHidden': isHidden,
      'snoozedUntil': snoozedUntil?.millisecondsSinceEpoch,
      'completionHistory': completionHistory.map((e) => e.toMap()).toList(),
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
      customReminderDate: map['customReminderDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['customReminderDate'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
      isCompleted: map['isCompleted'] ?? false,
      isHidden: map['isHidden'] ?? false,
      snoozedUntil: map['snoozedUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['snoozedUntil'])
          : null,
      completionHistory:
          (map['completionHistory'] as List<dynamic>?)
              ?.map((e) => CompletionEntry.fromMap(e))
              .toList() ??
          [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Todo.fromJson(String source) => Todo.fromMap(json.decode(source));

  DateTime? calculateNextReminder() {
    if (reminderType == ReminderType.none) return null;
    if (reminderType == ReminderType.custom) return customReminderDate;

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
      case ReminderType.custom:
        return customReminderDate;
      case ReminderType.none:
        return null;
    }

    return next;
  }

  Todo markAsCompleted({String? note}) {
    final now = DateTime.now();
    final newEntry = CompletionEntry(completedAt: now, note: note);

    final newHistory = List<CompletionEntry>.from(completionHistory)
      ..add(newEntry);

    // For recurring todos, calculate next reminder
    DateTime? nextReminderTime;
    if (reminderType != ReminderType.none &&
        reminderType != ReminderType.custom) {
      nextReminderTime = calculateNextReminder();
    }

    return copyWith(
      lastUpdated: now,
      completionHistory: newHistory,
      nextReminder: nextReminderTime,
      isCompleted:
          reminderType == ReminderType.none ||
          reminderType == ReminderType.custom,
    );
  }

  Todo snooze() {
    final now = DateTime.now();
    DateTime snoozeUntil;

    switch (reminderType) {
      case ReminderType.daily:
        snoozeUntil = now.add(const Duration(days: 1));
        break;
      case ReminderType.weekly:
        snoozeUntil = now.add(const Duration(days: 7));
        break;
      case ReminderType.monthly:
        snoozeUntil = now.add(const Duration(days: 30));
        break;
      case ReminderType.custom:
        snoozeUntil = now.add(const Duration(days: 1));
        break;
      case ReminderType.none:
        snoozeUntil = now.add(const Duration(hours: 1));
        break;
    }

    return copyWith(snoozedUntil: snoozeUntil, lastUpdated: now);
  }
}
