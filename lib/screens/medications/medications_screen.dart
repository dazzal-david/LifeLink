import 'package:elderly_care/screens/medications/medication_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:elderly_care/models/medication_model.dart';
import 'package:elderly_care/services/medication_service.dart';
import 'package:elderly_care/screens/medications/medication_logs_screen.dart';
import 'package:intl/intl.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final MedicationService _medicationService = MedicationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationLogsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMedicationDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Medication>>(
        stream: _medicationService.getMedicationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final medications = snapshot.data!;
          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              return _buildMedicationCard(medications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    medication.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditMedicationDialog(context, medication),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dosage: ${medication.dosage}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Schedule: ${medication.getFormattedSchedule()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Instructions: ${medication.instructions}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start Date: ${DateFormat('MMM dd, yyyy').format(medication.startDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (medication.endDate != null)
                  Text(
                    'End Date: ${DateFormat('MMM dd, yyyy').format(medication.endDate!)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MedicationFormDialog(),
    );
  }

  void _showEditMedicationDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => MedicationFormDialog(medication: medication),
    );
  }
}