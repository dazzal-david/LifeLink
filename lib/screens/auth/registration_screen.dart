import 'package:flutter/material.dart';
import 'package:elderly_care/services/auth_service.dart';
import 'package:elderly_care/models/user_model.dart';
import 'package:elderly_care/screens/base_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  
  String _selectedGender = 'Male';
  List<String> _selectedMedicalConditions = [];
  List<String> _selectedDisabilities = [];
  List<String> _selectedAllergies = [];
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Predefined lists for selection
  final List<String> _medicalConditionsList = [
    'Hypertension',
    'Diabetes',
    'Heart Disease',
    'Arthritis',
    'Asthma',
    'Other'
  ];

  final List<String> _disabilitiesList = [
    'None',
    'Visual Impairment',
    'Hearing Impairment',
    'Mobility Issues',
    'Other'
  ];

  final List<String> _allergiesList = [
    'None',
    'Penicillin',
    'Pollen',
    'Dust',
    'Nuts',
    'Other'
  ];

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information Section
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Personal Details Section
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final age = int.tryParse(value!);
                        if (age == null || age < 0 || age > 150) {
                          return 'Invalid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _bloodGroups[0],
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        border: OutlineInputBorder(),
                      ),
                      items: _bloodGroups.map((group) => DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      )).toList(),
                      onChanged: (value) => _bloodGroupController.text = value!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final height = double.tryParse(value!);
                        if (height == null || height <= 0) {
                          return 'Invalid height';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final weight = double.tryParse(value!);
                        if (weight == null || weight <= 0) {
                          return 'Invalid weight';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other'].map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                )).toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 24),

              // Medical Information Section
              const Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Medical Conditions MultiSelect
              ExpansionTile(
                title: const Text('Medical Conditions'),
                children: [
                  Wrap(
                    spacing: 8,
                    children: _medicalConditionsList.map((condition) {
                      return FilterChip(
                        label: Text(condition),
                        selected: _selectedMedicalConditions.contains(condition),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMedicalConditions.add(condition);
                            } else {
                              _selectedMedicalConditions.remove(condition);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Disabilities MultiSelect
              ExpansionTile(
                title: const Text('Disabilities'),
                children: [
                  Wrap(
                    spacing: 8,
                    children: _disabilitiesList.map((disability) {
                      return FilterChip(
                        label: Text(disability),
                        selected: _selectedDisabilities.contains(disability),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDisabilities.add(disability);
                            } else {
                              _selectedDisabilities.remove(disability);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Allergies MultiSelect
              ExpansionTile(
                title: const Text('Allergies'),
                children: [
                  Wrap(
                    spacing: 8,
                    children: _allergiesList.map((allergy) {
                      return FilterChip(
                        label: Text(allergy),
                        selected: _selectedAllergies.contains(allergy),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAllergies.add(allergy);
                            } else {
                              _selectedAllergies.remove(allergy);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Emergency Contact Section
              const Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name *', // Added asterisk
                  prefixIcon: Icon(Icons.contact_emergency),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Emergency contact name is required';
                  }
                  if (value!.length < 2) {
                    return 'Please enter a valid name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone *', // Added asterisk
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., +1234567890',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Emergency contact phone is required';
                  }
                  // Basic phone number validation (you can adjust the regex pattern as needed)
                  final phoneRegex = RegExp(r'^\+?[\d\s-]{8,}$');
                  if (!phoneRegex.hasMatch(value!)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),


              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final userData = UserModel(
          id: '',
          name: _nameController.text,
          age: int.parse(_ageController.text),
          bloodGroup: _bloodGroupController.text,
          height: double.parse(_heightController.text),
          weight: double.parse(_weightController.text),
          gender: _selectedGender,
          medicalConditions: _selectedMedicalConditions,
          disabilities: _selectedDisabilities,
          allergies: _selectedAllergies,
          emergencyContactName: _emergencyContactNameController.text, // Add this
          emergencyContactPhone: _emergencyContactPhoneController.text, // Add this
          createdAt: DateTime.now().toUtc(), // Use current time instead of hardcoded
        );

        await _authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          userData: userData,
        );

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const BaseScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }
}

  
