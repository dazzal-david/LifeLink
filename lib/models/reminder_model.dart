class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isRecurring;
  final String? recurrencePattern;
  final bool isCompleted;
  final String createdBy;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.isRecurring = false,
    this.recurrencePattern,
    this.isCompleted = false,
    required this.createdBy,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['date_time']),
      isRecurring: json['is_recurring'],
      recurrencePattern: json['recurrence_pattern'],
      isCompleted: json['is_completed'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'is_completed': isCompleted,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}