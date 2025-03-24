import 'package:flutter/material.dart';
import 'package:elderly_care/models/reminder_model.dart';
import 'package:elderly_care/services/reminder_service.dart';
import 'package:intl/intl.dart';

class RemindersList extends StatelessWidget {
  const RemindersList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reminder>>(
      stream: ReminderService().getTodayRemindersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading reminders'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final reminders = snapshot.data!;

        if (reminders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('No reminders for today'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return _ReminderCard(reminder: reminders[index]);
          },
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.parse('2025-02-20 16:34:30');
    final isUpcoming = reminder.dateTime.isAfter(currentTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUpcoming ? Colors.green[50] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            reminder.isRecurring ? Icons.repeat : Icons.event,
            color: isUpcoming ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          reminder.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description != null)
              Text(reminder.description!),
            Text(
              DateFormat('hh:mm a').format(reminder.dateTime),
              style: TextStyle(
                color: isUpcoming ? Colors.green : Colors.grey,
                fontWeight: isUpcoming ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Checkbox(
          value: reminder.isCompleted,
          onChanged: (value) async {
            try {
              await ReminderService().toggleReminderCompletion(
                reminder.id,
                value ?? false,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}