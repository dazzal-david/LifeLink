import 'package:flutter/material.dart';
import 'package:elderly_care/models/medication_model.dart';
import 'package:elderly_care/services/medication_service.dart';
import 'package:elderly_care/config/supabase_config.dart';

class MedicationFormDialog extends StatefulWidget {
  final Medication? medication;

  const MedicationFormDialog({
    super.key,
    this.medication,
  });

  @override
  State<MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final List<TimeOfDay> _scheduleTime = [];
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool _isLoading = false;

  // Get current user's username
  String get _currentUser {
    final email = SupabaseConfig.supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User not authenticated');
    return email.split('@')[0].toLowerCase();
  }

  // Current timestamp
  static final DateTime _currentTime = DateTime.parse('2025-03-11 06:56:40');

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _instructionsController.text = widget.medication!.instructions;
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
      _scheduleTime.addAll(
        widget.medication!.schedule.map(
          (dateTime) => TimeOfDay.fromDateTime(dateTime),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medication == null ? 'Add Medication' : 'Edit Medication'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 500mg',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Take with food',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Schedule Times *'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addScheduleTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time'),
                  ),
                ],
              ),
              if (_scheduleTime.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scheduleTime
                        .map((time) => Chip(
                              label: Text(time.format(context)),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _scheduleTime.remove(time);
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? _currentTime,
                          firstDate: _currentTime,
                          lastDate: _currentTime.add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            // Ensure end date is not before start date
                            if (_endDate != null && _endDate!.isBefore(date)) {
                              _endDate = date;
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate == null
                            ? 'Start Date *'
                            : 'Start: ${_startDate.toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _startDate == null
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? _startDate!,
                                firstDate: _startDate!,
                                lastDate:
                                    _currentTime.add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _endDate = date;
                                });
                              }
                            },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _endDate == null
                            ? 'End Date'
                            : 'End: ${_endDate.toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.medication == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _addScheduleTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (!_scheduleTime.contains(time)) {
          _scheduleTime.add(time);
          _scheduleTime.sort((a, b) {
            final aMinutes = a.hour * 60 + a.minute;
            final bMinutes = b.hour * 60 + b.minute;
            return aMinutes.compareTo(bMinutes);
          });
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_scheduleTime.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one schedule time')),
        );
        return;
      }

      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set a start date')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final schedule = _scheduleTime.map((time) {
          return DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            time.hour,
            time.minute,
          );
        }).toList();

        final medication = Medication(
          id: widget.medication?.id ?? '',
          name: _nameController.text,
          dosage: _dosageController.text,
          schedule: schedule,
          instructions: _instructionsController.text,
          startDate: _startDate!,
          endDate: _endDate,
          prescribedBy: _currentUser,
          isActive: true,
          createdAt: widget.medication?.createdAt ?? _currentTime,
        );

        final service = MedicationService();
        if (widget.medication == null) {
          await service.addMedication(medication);
        } else {
          await service.updateMedication(medication);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}