import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BloodDonationScreen extends StatelessWidget {
  const BloodDonationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Donation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildBloodDonationOption(
              context,
              title: 'Register as Blood Donor',
              description: 'Provide your blood type and information to help others in need',
              icon: Icons.volunteer_activism,
              onTap: () => context.push('/blood-donation/register'),
            ),
            const SizedBox(height: 20),
            _buildBloodDonationOption(
              context,
              title: 'Seek Blood',
              description: 'Find blood donors based on blood type and location',
              icon: Icons.search,
              onTap: () => context.push('/blood-donation/seek'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodDonationOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
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
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.red,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}