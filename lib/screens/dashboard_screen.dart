import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildDashboardOption(
              context,
              title: 'Blood Donation',
              icon: Icons.bloodtype,
              color: Colors.red,
              onTap: () => context.push('/blood-donation'),
            ),
            const SizedBox(height: 20),
            _buildDashboardOption(
              context,
              title: 'Organ Donation',
              icon: Icons.volunteer_activism,
              color: Colors.green,
              onTap: () => context.push('/organ-donation'),
            ),
            const SizedBox(height: 20),
            _buildDashboardOption(
              context,
              title: 'Hospital Search',
              icon: Icons.local_hospital,
              color: Colors.blue,
              onTap: () => context.push('/hospital-search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 60,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}