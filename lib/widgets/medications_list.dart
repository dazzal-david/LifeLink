import 'package:flutter/material.dart';
import 'package:elderly_care/models/medication_model.dart';
import 'package:elderly_care/services/medication_service.dart';
import 'package:intl/intl.dart';

class MedicationsList extends StatelessWidget {
  const MedicationsList({super.key});

  DateTime get _currentTime => DateTime.now().toUtc();
  DateTime get _startOfDay => DateTime(_currentTime.year, _currentTime.month, _currentTime.day);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Medication>>(
      stream: MedicationService().getTodaysMedicationsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton(
                  onPressed: () {
                    // Trigger a rebuild to retry
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final medications = snapshot.data!;
        
        if (medications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No medications scheduled for today',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            final nextDose = medication.schedule.firstWhere(
              (time) => time.isAfter(_currentTime),
              orElse: () => medication.schedule.first,
            );

            // For each medication, create a MedicationCard that checks logs
            return _MedicationCardWithLogs(
              medication: medication,
              nextDose: nextDose,
              isUpcoming: nextDose.isAfter(_currentTime),
            );
          },
        );
      },
    );
  }
}

class _MedicationCardWithLogs extends StatefulWidget {
  final Medication medication;
  final DateTime nextDose;
  final bool isUpcoming;

  const _MedicationCardWithLogs({
    required this.medication,
    required this.nextDose,
    required this.isUpcoming,
  });

  @override
  State<_MedicationCardWithLogs> createState() => _MedicationCardWithLogsState();
}

class _MedicationCardWithLogsState extends State<_MedicationCardWithLogs> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isTaken = false;
  final MedicationService _medicationService = MedicationService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkIfMedicationWasTaken();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _colorAnimation = ColorTween(
      begin: null,
      end: Colors.green.withOpacity(0.2),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  // Check medication_logs to see if this medication was already taken today
  void _checkIfMedicationWasTaken() {
    // Use a stream to continuously check for logs
    _medicationService.getMedicationLogsStream(widget.medication.id).listen((logs) {
      // Get today's start and end times
      final now = DateTime.now().toUtc();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Convert the scheduled time to today's date for comparison
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        widget.nextDose.hour,
        widget.nextDose.minute,
      );
      
      // Check if there's a log for this scheduled time today
      final wasTakenToday = logs.any((log) {
        final takenAt = DateTime.parse(log['taken_at']);
        final scheduledTime = DateTime.parse(log['scheduled_time']);
        
        // Compare the hours and minutes, not the exact date
        return takenAt.isAfter(startOfDay) && 
               takenAt.isBefore(endOfDay) && 
               scheduledTime.hour == scheduledDateTime.hour && 
               scheduledTime.minute == scheduledDateTime.minute;
      });
      
      if (wasTakenToday != _isTaken) {
        setState(() {
          _isTaken = wasTakenToday;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpcoming = widget.isUpcoming && !_isTaken;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              elevation: isUpcoming ? 2 : 1,
              color: _isTaken ? _colorAnimation.value : null,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUpcoming 
                      ? theme.primaryColor.withOpacity(0.1) 
                      : _isTaken ? Colors.green.withOpacity(0.1) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: isUpcoming 
                      ? theme.primaryColor 
                      : _isTaken ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(
                  widget.medication.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: _isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.medication.dosage),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: isUpcoming 
                            ? theme.primaryColor 
                            : _isTaken ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Next dose: ${DateFormat('hh:mm a').format(widget.nextDose)}',
                          style: TextStyle(
                            color: isUpcoming 
                              ? theme.primaryColor 
                              : _isTaken ? Colors.green : Colors.grey,
                            fontWeight: isUpcoming ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (widget.medication.instructions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.medication.instructions,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: IconButton(
                    key: ValueKey<bool>(_isTaken),
                    icon: Icon(
                      _isTaken ? Icons.check_circle : Icons.check_circle_outline,
                      color: _isTaken ? Colors.green : theme.primaryColor,
                    ),
                    onPressed: () async {
                      try {
                        // Show confirmation dialog only if not already taken
                        final bool shouldMark;
                        if (!_isTaken) {
                          shouldMark = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Mark Medication'),
                              content: Text('Mark ${widget.medication.name} as taken?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          ) ?? false;
                        } else {
                          // Show confirmation dialog for undoing
                          shouldMark = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Undo Medication'),
                              content: Text('Mark ${widget.medication.name} as not taken?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          ) ?? false;
                        }

                        if (shouldMark) {
                          // First, update the UI
                          setState(() {
                            _isTaken = !_isTaken;
                          });
                          
                          // Play the animation
                          await _animationController.forward().then((_) {
                            _animationController.reverse();
                          });
                          
                          if (_isTaken) {
                            // Add a new log entry
                            await _medicationService.markMedicationTaken(
                              widget.medication.id,
                              widget.nextDose,
                            );
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.medication.name} marked as taken'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            // TODO: Implement undo functionality by deleting the log entry
                            // We would need to add a removeLog method to the MedicationService
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.medication.name} marked as not taken'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}