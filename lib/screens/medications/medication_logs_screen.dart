import 'package:flutter/material.dart';
import 'package:elderly_care/services/medication_service.dart';
import 'package:intl/intl.dart';

class MedicationLogsScreen extends StatelessWidget {
  const MedicationLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MedicationService _medicationService = MedicationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Logs'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _medicationService.getAllMedicationLogsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!;
          
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No medication logs found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final groupedLogs = _groupLogsByDate(logs);

          return ListView.builder(
            itemCount: groupedLogs.length,
            itemBuilder: (context, index) {
              final date = groupedLogs.keys.elementAt(index);
              final dailyLogs = groupedLogs[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      DateFormat('EEEE, MMMM d, y').format(date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...dailyLogs.map((log) => _buildLogItem(log)).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupLogsByDate(List<Map<String, dynamic>> logs) {
    final groupedLogs = <DateTime, List<Map<String, dynamic>>>{};
    
    for (final log in logs) {
      final takenAt = DateTime.parse(log['taken_at']);
      final date = DateTime(takenAt.year, takenAt.month, takenAt.day);
      
      if (!groupedLogs.containsKey(date)) {
        groupedLogs[date] = [];
      }
      groupedLogs[date]!.add(log);
    }

    return Map.fromEntries(
      groupedLogs.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key))
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final takenAt = DateTime.parse(log['taken_at']);
    final scheduledTime = DateTime.parse(log['scheduled_time']);
    final status = log['status'] ?? 'taken';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(log['medication_name'] ?? 'Unknown Medication'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled: ${DateFormat('HH:mm').format(scheduledTime)}'),
            Text('Taken: ${DateFormat('HH:mm').format(takenAt)}'),
            if (log['notes'] != null && log['notes'].isNotEmpty)
              Text('Notes: ${log['notes']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getStatusBadge(status),
            const SizedBox(width: 8),
            _getTimingIndicator(takenAt, scheduledTime),
          ],
        ),
      ),
    );
  }

  Widget _getTimingIndicator(DateTime takenAt, DateTime scheduledTime) {
    final difference = takenAt.difference(scheduledTime);
    final absMinutes = difference.inMinutes.abs();
    
    if (absMinutes <= 15) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (absMinutes <= 30) {
      return const Icon(Icons.info, color: Colors.orange);
    } else {
      return const Icon(Icons.warning, color: Colors.red);
    }
  }

  Widget _getStatusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'taken':
        color = Colors.green;
        icon = Icons.check;
        break;
      case 'skipped':
        color = Colors.red;
        icon = Icons.close;
        break;
      case 'delayed':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}