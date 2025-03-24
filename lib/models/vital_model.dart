class VitalModel {
  final String id;
  final String username;
  final int? heartRate;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? temperature;
  final int? oxygenSaturation;
  final int? glucoseLevel;
  final DateTime recordedAt;
  final String? notes;

  VitalModel({
    required this.id,
    required this.username,
    this.heartRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.temperature,
    this.oxygenSaturation,
    this.glucoseLevel,
    required this.recordedAt,
    this.notes,
  });

  factory VitalModel.fromJson(Map<String, dynamic> json) {
    return VitalModel(
      id: json['id'],
      username: json['username'],
      heartRate: json['heart_rate'],
      bloodPressureSystolic: json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      temperature: json['temperature']?.toDouble(),
      oxygenSaturation: json['oxygen_saturation'],
      glucoseLevel: json['glucose_level'],
      recordedAt: DateTime.parse(json['recorded_at']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'heart_rate': heartRate,
      'blood_pressure_systolic': bloodPressureSystolic,
      'blood_pressure_diastolic': bloodPressureDiastolic,
      'temperature': temperature,
      'oxygen_saturation': oxygenSaturation,
      'glucose_level': glucoseLevel,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }
}