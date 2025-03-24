class UserModel {
  final String id;
  final String name;
  final int age;
  final String bloodGroup;
  final double height;
  final double weight;
  final String gender;
  final List<String> medicalConditions;
  final List<String> disabilities;
  final List<String> allergies;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodGroup,
    required this.height,
    required this.weight,
    required this.gender,
    required this.medicalConditions,
    required this.disabilities,
    required this.allergies,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      bloodGroup: json['blood_group'] ?? '',
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      gender: json['gender'] ?? 'Not Specified',
      medicalConditions: List<String>.from(json['medical_conditions'] ?? []),
      disabilities: List<String>.from(json['disabilities'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      emergencyContactName: json['emergency_contact_name'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? '2025-03-11 06:35:52'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'blood_group': bloodGroup,
      'height': height,
      'weight': weight,
      'gender': gender,
      'medical_conditions': medicalConditions,
      'disabilities': disabilities,
      'allergies': allergies,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    int? age,
    String? bloodGroup,
    double? height,
    double? weight,
    String? gender,
    List<String>? medicalConditions,
    List<String>? disabilities,
    List<String>? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      disabilities: disabilities ?? this.disabilities,
      allergies: allergies ?? this.allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      createdAt: createdAt,
    );
  }

  // Add a method to validate emergency contact information
  bool hasValidEmergencyContact() {
    return emergencyContactName.isNotEmpty && 
           emergencyContactPhone.isNotEmpty &&
           emergencyContactPhone.length >= 8;
  }

  // Add a method to format emergency contact information
  Map<String, String> getEmergencyContactInfo() {
    return {
      'name': emergencyContactName,
      'phone': emergencyContactPhone,
    };
  }

  // Add a method to check if emergency contact needs to be updated
  bool needsEmergencyContactUpdate() {
    return emergencyContactName.isEmpty || emergencyContactPhone.isEmpty;
  }

  @override
  String toString() {
    return 'UserModel('
        'id: $id, '
        'name: $name, '
        'age: $age, '
        'bloodGroup: $bloodGroup, '
        'height: $height, '
        'weight: $weight, '
        'gender: $gender, '
        'medicalConditions: $medicalConditions, '
        'disabilities: $disabilities, '
        'allergies: $allergies, '
        'emergencyContactName: $emergencyContactName, '
        'emergencyContactPhone: $emergencyContactPhone, '
        'createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.age == age &&
        other.bloodGroup == bloodGroup &&
        other.height == height &&
        other.weight == weight &&
        other.gender == gender &&
        listEquals(other.medicalConditions, medicalConditions) &&
        listEquals(other.disabilities, disabilities) &&
        listEquals(other.allergies, allergies) &&
        other.emergencyContactName == emergencyContactName &&
        other.emergencyContactPhone == emergencyContactPhone &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      age,
      bloodGroup,
      height,
      weight,
      gender,
      Object.hashAll(medicalConditions),
      Object.hashAll(disabilities),
      Object.hashAll(allergies),
      emergencyContactName,
      emergencyContactPhone,
      createdAt,
    );
  }
}

// Add this at the top of the file
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}