import 'package:intl/intl.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<DateTime> schedule;
  final String instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String prescribedBy;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.schedule,
    required this.instructions,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.prescribedBy,
    required this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      schedule: (json['schedule'] as List)
          .map((time) => DateTime.parse(time))
          .toList(),
      instructions: json['instructions'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : null,
      isActive: json['is_active'],
      prescribedBy: json['prescribed_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'schedule': schedule.map((time) => time.toIso8601String()).toList(),
      'instructions': instructions,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'prescribed_by': prescribedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getFormattedSchedule() {
    return schedule
        .map((time) => DateFormat('hh:mm a').format(time))
        .join(', ');
  }
}
