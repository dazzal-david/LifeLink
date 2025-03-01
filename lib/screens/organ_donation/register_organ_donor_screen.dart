import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class RegisterOrganDonorScreen extends StatefulWidget {
  const RegisterOrganDonorScreen({Key? key}) : super(key: key);

  @override
  State<RegisterOrganDonorScreen> createState() => _RegisterOrganDonorScreenState();
}

class _RegisterOrganDonorScreenState extends State<RegisterOrganDonorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  
  // Add blood type selection
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  String _selectedBloodType = 'O+'; // Default value
  
  final Map<String, bool> _selectedOrgans = {
    'Lungs (Lobe)': false,
    'Liver': false,
    'Kidneys': false,
    'Pancreas': false,
    'Intestines': false,
    'Blood & Plasma': false,
    'Bone & Cartilage': false,
    'Bone marrow': false,
  };
  bool _consent = false;
  bool _isLoading = false;
  bool _isRegistered = false; // Track if the user is already registered
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIfRegistered(); // Check if the user is already registered
  }

  @override
  void dispose() {
    _locationController.dispose();
    _contactController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  // Check if the user is already registered as an organ donor
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
          .from('organ_donors')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _isRegistered = true;
          _locationController.text = response['location'];
          _contactController.text = response['contact'];
          _medicalHistoryController.text = response['medical_history'] ?? '';
          _consent = response['consent'];
          // Get blood type if exists
          _selectedBloodType = response['blood_type'] ?? 'O+';
          // Update selected organs
          final List<dynamic> organs = response['organs'];
          for (var organ in organs) {
            if (_selectedOrgans.containsKey(organ)) {
              _selectedOrgans[organ] = true;
            }
          }
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

  Future<void> _registerOrUpdateOrganDonor() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consent) {
      setState(() {
        _errorMessage = 'You must provide consent to register as an organ donor';
      });
      return;
    }

    final List<String> organsList = _selectedOrgans.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (organsList.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one organ for donation';
      });
      return;
    }

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

      if (_isRegistered) {
        // Update existing record
        await supabase
            .from('organ_donors')
            .update({
              'organs': organsList,
              'medical_history': _medicalHistoryController.text.trim(),
              'location': _locationController.text.trim(),
              'consent': _consent,
              'contact': _contactController.text.trim(),
              'blood_type': _selectedBloodType, // Add blood type
            })
            .eq('user_id', userId);
      } else {
        // Insert new record
        await supabase.from('organ_donors').insert({
          'user_id': userId,
          'organs': organsList,
          'medical_history': _medicalHistoryController.text.trim(),
          'location': _locationController.text.trim(),
          'consent': _consent,
          'contact': _contactController.text.trim(),
          'blood_type': _selectedBloodType, // Add blood type
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegistered
                ? 'Your organ donor registration has been updated!'
                : 'You are now registered as an organ donor!'),
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

  Future<void> _cancelOrganDonorRegistration() async {
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
          .from('organ_donors')
          .delete()
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your organ donor registration has been canceled.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isRegistered = false;
          _selectedOrgans.updateAll((key, value) => false);
          _locationController.clear();
          _contactController.clear();
          _medicalHistoryController.clear();
          _selectedBloodType = 'O+'; // Reset blood type
          _consent = false;
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
        title: const Text('Register as Organ Donor'),
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
                  'You are already registered as an organ donor.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _cancelOrganDonorRegistration,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Cancel Registration'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerOrUpdateOrganDonor,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Update Registration'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
              // Add Blood Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blood Type',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _bloodTypes.map((bloodType) {
                          return DropdownMenuItem<String>(
                            value: bloodType,
                            child: Text(bloodType),
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
                            return 'Please select your blood type';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Select Organs for Donation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _selectedOrgans.keys.map((organ) {
                      return CheckboxListTile(
                        title: Text(organ),
                        value: _selectedOrgans[organ],
                        onChanged: (bool? value) {
                          setState(() {
                            _selectedOrgans[organ] = value ?? false;
                          });
                        },
                        activeColor: Colors.green,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Medical History (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _medicalHistoryController,
                decoration: const InputDecoration(
                  hintText: 'Any relevant medical conditions...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text(
                  'I consent to donate my selected organs after death',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _consent,
                onChanged: (bool? value) {
                  setState(() {
                    _consent = value ?? false;
                  });
                },
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              if (!_isRegistered)
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerOrUpdateOrganDonor,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register as Organ Donor'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}