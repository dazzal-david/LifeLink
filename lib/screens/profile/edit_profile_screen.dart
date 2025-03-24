import 'package:flutter/material.dart';
import 'package:elderly_care/services/auth_service.dart';
import 'package:elderly_care/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? initialData;

  const EditProfileScreen({
    super.key,
    this.initialData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  static final DateTime _currentTime = DateTime.parse('2025-02-21 16:10:32');

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedBloodGroup = 'A+';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'Male';
  final List<String> _medicalConditions = [];
  final List<String> _disabilities = [];
  final List<String> _allergies = [];
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!.name;
      _ageController.text = widget.initialData!.age.toString();
      _selectedBloodGroup = widget.initialData!.bloodGroup.isNotEmpty 
          ? widget.initialData!.bloodGroup 
          : _bloodGroups[0];
      _heightController.text = widget.initialData!.height.toString();
      _weightController.text = widget.initialData!.weight.toString();
      _selectedGender = widget.initialData!.gender;
      _medicalConditions.addAll(widget.initialData!.medicalConditions);
      _disabilities.addAll(widget.initialData!.disabilities);
      _allergies.addAll(widget.initialData!.allergies);
      _emergencyContactNameController.text = widget.initialData!.emergencyContactName;
      _emergencyContactPhoneController.text = widget.initialData!.emergencyContactPhone;
    }
  }

  Future<void> _addItem(String title, List<String> items) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                Navigator.pop(context, textController.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        items.add(result);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = UserModel(
        id: widget.initialData?.id ?? '',
        name: _nameController.text,
        age: int.parse(_ageController.text),
        bloodGroup: _selectedBloodGroup,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        gender: _selectedGender,
        medicalConditions: _medicalConditions,
        disabilities: _disabilities,
        allergies: _allergies,
        emergencyContactName: _emergencyContactNameController.text,
        emergencyContactPhone: _emergencyContactPhoneController.text,
        createdAt: widget.initialData?.createdAt ?? _currentTime,
      );

      await _authService.updateProfile(userData);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildChipList(String title, List<String> items, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (items.isEmpty)
          Text(
            'None added',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Chip(
              label: Text(item),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  items.remove(item);
                });
              },
            )).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.blue),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your name';
                }
                return null;
              },
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
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
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
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(),
                    ),
                    items: _bloodGroups
                        .map((group) => DropdownMenuItem(
                              value: group,
                              child: Text(group),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodGroup = value!;
                      });
                    },
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
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
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
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
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
                border: OutlineInputBorder(),
              ),
              items: _genders
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildChipList(
              'Medical Conditions',
              _medicalConditions,
              () => _addItem('Medical Condition', _medicalConditions),
            ),
            const SizedBox(height: 16),
            _buildChipList(
              'Disabilities',
              _disabilities,
              () => _addItem('Disability', _disabilities),
            ),
            const SizedBox(height: 16),
            _buildChipList(
              'Allergies',
              _allergies,
              () => _addItem('Allergy', _allergies),
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 24),
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
                labelText: 'Emergency Contact Name *',
                prefixIcon: Icon(Icons.contact_emergency),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
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
                labelText: 'Emergency Contact Phone *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: 'e.g., +1234567890',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Emergency contact phone is required';
                }
                // Basic phone number validation
                final phoneRegex = RegExp(r'^\+?[\d\s-]{8,}$');
                if (!phoneRegex.hasMatch(value!)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }
}