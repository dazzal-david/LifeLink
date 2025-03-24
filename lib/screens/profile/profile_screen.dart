import 'package:flutter/material.dart';
import 'package:elderly_care/services/auth_service.dart';
import 'package:elderly_care/models/user_model.dart';
import 'package:elderly_care/services/medication_service.dart';
import 'package:elderly_care/screens/profile/edit_profile_screen.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _medicationService = MedicationService();
  bool _isLoading = true;
  Map<String, int> _medicationStats = {};
  UserModel? _userData;
  static final DateTime _currentTime = DateTime.parse('2025-02-21 16:07:24');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    print('Loading user data...'); // Debug print
    final userData = await _authService.getCurrentUser();
    print('User data loaded: ${userData?.name}'); // Debug print
    
    final stats = await _medicationService.getMedicationStats();
    print('Medication stats loaded: $stats'); // Debug print
    
    if (mounted) {
      setState(() {
        _userData = userData;
        _medicationStats = stats;
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error in _loadData: $e'); // More detailed error logging
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Widget _buildProfileHeader(ThemeData theme) {
    if (_userData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            const Text('No profile data available'),
            TextButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Text(
                _userData!.name.substring(0, min(2, _userData!.name.length)).toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userData!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                Chip(
                  label: Text('Age: ${_userData!.age}'),
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                ),
                if (_userData!.bloodGroup.isNotEmpty)
                  Chip(
                    label: Text('Blood: ${_userData!.bloodGroup}'),
                    backgroundColor: Colors.red[100],
                  ),
                Chip(
                  label: Text(_userData!.gender),
                  backgroundColor: Colors.purple[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Height: ${_userData!.height.toStringAsFixed(1)}cm',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Text(' • '),
                Text(
                  'Weight: ${_userData!.weight.toStringAsFixed(1)}kg',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Member since ${_currentTime.toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfo() {
    if (_userData == null) return const SizedBox();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMedicalSection(
              'Medical Conditions',
              _userData!.medicalConditions,
              Icons.medical_information,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMedicalSection(
              'Disabilities',
              _userData!.disabilities,
              Icons.accessible,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildMedicalSection(
              'Allergies',
              _userData!.allergies,
              Icons.warning_amber,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Text(
              'None specified',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => Chip(
                        label: Text(item),
                        backgroundColor: color.withOpacity(0.1),
                        labelStyle: TextStyle(color: color),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_userData != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(initialData: _userData!),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(theme),
                    const SizedBox(height: 16),
                    _buildMedicalInfo(),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medication Statistics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.medication,
                                    value: _medicationStats['total'] ?? 0,
                                    label: 'Total',
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.check_circle,
                                    value: _medicationStats['active'] ?? 0,
                                    label: 'Active',
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: const Text('Notifications'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Implement notifications settings
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.security_outlined),
                            title: const Text('Privacy & Security'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Implement privacy settings
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.help_outline),
                            title: const Text('Help & Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Implement help section
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}