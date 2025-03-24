import 'package:flutter/material.dart';
import 'package:elderly_care/models/vital_model.dart';
import 'package:elderly_care/services/vitals_service.dart';
import 'package:intl/intl.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final VitalsService _vitalsService = VitalsService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Vitals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddVitalsDialog(context),
            tooltip: 'Add New Vitals',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<VitalModel?>(
          stream: _vitalsService.getLatestVitalsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLatestReadings(snapshot.data),
                  const SizedBox(height: 24),
                  _buildVitalsHistory(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLatestReadings(VitalModel? vital) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Readings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (vital != null)
                  Text(
                    DateFormat('MMM d, h:mm a').format(vital.recordedAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (vital != null) ...[
              _buildVitalTile(
                'Heart Rate',
                '${vital.heartRate ?? '--'} BPM',
                Icons.favorite,
                Colors.red,
                isNormal: vital.heartRate != null && vital.heartRate! >= 60 && vital.heartRate! <= 100,
              ),
              _buildVitalTile(
                'Blood Pressure',
                '${vital.bloodPressureSystolic ?? '--'}/${vital.bloodPressureDiastolic ?? '--'} mmHg',
                Icons.speed,
                Colors.blue,
                isNormal: vital.bloodPressureSystolic != null && 
                         vital.bloodPressureDiastolic != null &&
                         vital.bloodPressureSystolic! < 140 &&
                         vital.bloodPressureDiastolic! < 90,
              ),
              _buildVitalTile(
                'Temperature',
                '${vital.temperature?.toStringAsFixed(1) ?? '--'}°C',
                Icons.thermostat,
                Colors.orange,
                isNormal: vital.temperature != null && 
                         vital.temperature! >= 36.1 &&
                         vital.temperature! <= 37.2,
              ),
              _buildVitalTile(
                'Oxygen Level',
                '${vital.oxygenSaturation ?? '--'}%',
                Icons.air,
                Colors.green,
                isNormal: vital.oxygenSaturation != null && 
                         vital.oxygenSaturation! >= 95,
              ),
              _buildVitalTile(
                'Blood Sugar',
                '${vital.glucoseLevel ?? '--'} mg/dL',
                Icons.water_drop,
                Colors.purple,
                isNormal: vital.glucoseLevel != null && 
                         vital.glucoseLevel! >= 70 &&
                         vital.glucoseLevel! <= 140,
              ),
              if (vital.notes?.isNotEmpty == true) ...[
                const Divider(),
                Text(
                  'Notes:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vital.notes!,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No readings available yet.\nTap + to add your first reading.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalTile(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isNormal = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isNormal ? color : Colors.red,
                      ),
                    ),
                    if (!isNormal) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<VitalModel>>(
          future: _vitalsService.getVitalsHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No history available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            final vitals = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vitals.length,
              itemBuilder: (context, index) {
                final vital = vitals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      DateFormat('MMM d, y - h:mm a').format(vital.recordedAt),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'BP: ${vital.bloodPressureSystolic}/${vital.bloodPressureDiastolic} • HR: ${vital.heartRate} • SpO2: ${vital.oxygenSaturation}%',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditVitalsDialog(context, vital),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddVitalsDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final heartRateController = TextEditingController();
    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();
    final temperatureController = TextEditingController();
    final oxygenController = TextEditingController();
    final glucoseController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vital Signs'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: heartRateController,
                  decoration: const InputDecoration(
                    labelText: 'Heart Rate (BPM)',
                    hintText: '60-100',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final rate = int.tryParse(value);
                      if (rate == null || rate < 40 || rate > 200) {
                        return 'Enter a valid heart rate (40-200)';
                      }
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: systolicController,
                        decoration: const InputDecoration(
                          labelText: 'Systolic',
                          hintText: '90-140',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: diastolicController,
                        decoration: const InputDecoration(
                          labelText: 'Diastolic',
                          hintText: '60-90',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: temperatureController,
                  decoration: const InputDecoration(
                    labelText: 'Temperature (°C)',
                    hintText: '36.1-37.2',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: oxygenController,
                  decoration: const InputDecoration(
                    labelText: 'Oxygen Level (%)',
                    hintText: '95-100',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: glucoseController,
                  decoration: const InputDecoration(
                    labelText: 'Blood Sugar (mg/dL)',
                    hintText: '70-140',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _vitalsService.recordVitals(
                    heartRate: int.tryParse(heartRateController.text),
                    bloodPressureSystolic: int.tryParse(systolicController.text),
                    bloodPressureDiastolic: int.tryParse(diastolicController.text),
                    temperature: double.tryParse(temperatureController.text),
                    oxygenSaturation: int.tryParse(oxygenController.text),
                    glucoseLevel: int.tryParse(glucoseController.text),
                    notes: notesController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vitals recorded successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error recording vitals: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditVitalsDialog(BuildContext context, VitalModel vital) async {
    // Similar to _showAddVitalsDialog but pre-filled with vital data
    // Implement the edit functionality here
  }
}