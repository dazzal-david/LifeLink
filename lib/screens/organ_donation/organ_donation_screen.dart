import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrganDonationScreen extends StatelessWidget {
  const OrganDonationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organ Donation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildOrganDonationOption(
              context,
              title: 'Register as Organ Donor',
              description: 'Pledge to donate your organs to save lives',
              icon: Icons.favorite,
              onTap: () => context.push('/organ-donation/register'),
            ),
            const SizedBox(height: 20),
            _buildOrganDonationOption(
              context,
              title: 'Seek Organ Donor',
              description: 'Find a matching organ donor for yourself or someone else',
              icon: Icons.search,
              onTap: () => context.push('/organ-donation/seek'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganDonationOption(
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
                color: Colors.green,
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