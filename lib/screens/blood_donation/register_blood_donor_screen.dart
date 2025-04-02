import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class RegisterBloodDonorScreen extends StatefulWidget {
  const RegisterBloodDonorScreen({Key? key}) : super(key: key);

  @override
  State<RegisterBloodDonorScreen> createState() => _RegisterBloodDonorScreenState();
}

class _RegisterBloodDonorScreenState extends State<RegisterBloodDonorScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedBloodType = 'A+';
  String _selectedGender = 'Male';
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  DateTime? _lastDonationDate;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isRegistered = false; // Track if the user is already registered
  String? _errorMessage;

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'HH'
  ];

  final List<String> _genders = [
    'Male', 'Female'
  ];

  @override
  void initState() {
    super.initState();
    _checkIfRegistered(); // Check if the user is already registered
  }

  @override
  void dispose() {
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // Check if the user is already registered as a blood donor
  Future<void> _checkIfRegistered() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = provider_pkg.Provider.of<AuthService>(context, listen: false).user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('blood_donors')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _isRegistered = true;
          _selectedBloodType = response['blood_type'];
          _selectedGender = response['gender'];
          _locationController.text = response['location'];
          _contactController.text = response['contact'];
          _isAvailable = response['availability'];
          _lastDonationDate = response['last_donation_date'] != null
              ? DateTime.parse(response['last_donation_date'])
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectLastDonationDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastDonationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _lastDonationDate = picked;
      });
    }
  }

  Future<void> _registerAsBloodDonor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = provider_pkg.Provider.of<AuthService>(context, listen: false).user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (_lastDonationDate != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastDonationDate!);
        if (_selectedGender == 'Male' && difference.inDays < 90) {
          throw Exception('Male donors must wait at least 3 months between donations.');
        } else if (_selectedGender == 'Female' && difference.inDays < 180) {
          throw Exception('Female donors must wait at least 6 months between donations.');
        }
      }

      await supabase.from('blood_donors').insert({
        'user_id': userId,
        'blood_type': _selectedBloodType,
        'location': _locationController.text.trim(),
        'availability': _isAvailable,
        'last_donation_date': _lastDonationDate?.toIso8601String(),
        'contact': _contactController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are now registered as a blood donor!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isRegistered = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deregisterAsBloodDonor() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = provider_pkg.Provider.of<AuthService>(context, listen: false).user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await supabase
          .from('blood_donors')
          .delete()
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have been deregistered as a blood donor.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isRegistered = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Blood Donor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              if (_isRegistered) ...[
                const Text(
                  'You are already registered as a blood donor.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _deregisterAsBloodDonor,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Deregister as Blood Donor'),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Text(
                  'Blood Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _bloodTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedBloodType = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a blood type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gender',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _genders.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., City, State',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contact Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., +1 123-456-7890',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Last Donation Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _selectLastDonationDate(context),
                      child: Text(
                        _lastDonationDate == null
                            ? 'Select Date'
                            : '${_lastDonationDate!.day}/${_lastDonationDate!.month}/${_lastDonationDate!.year}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Available for Donation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                      activeColor: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerAsBloodDonor,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register as Blood Donor'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}