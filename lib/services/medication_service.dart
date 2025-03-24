import 'package:elderly_care/config/supabase_config.dart';
import 'package:elderly_care/models/medication_model.dart';

class MedicationService {
  final _supabase = SupabaseConfig.supabase;
  static const String _tableName = 'medications';
   static const String _logsTable = 'medication_logs';
  DateTime get _currentTime => DateTime.now().toUtc();


  // Get current user's username dynamically
  String get _currentUser {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User not authenticated');
    return email.split('@')[0].toLowerCase();
  }

  Stream<List<Medication>> getMedicationsStream() {
    try {
      return _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('username', _currentUser)
          .map((rows) => rows.map((row) => Medication.fromJson(row)).toList());
    } catch (e) {
      print('Error in getMedicationsStream: $e');
      return Stream.value([]);
    }
  }

  Future<List<Medication>> getTodaysMedications() async {
    try {
      final startOfDay = DateTime(_currentTime.year, _currentTime.month, _currentTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('username', _currentUser)
          .lte('start_date', _currentTime.toIso8601String())
          .or('end_date.is.null,end_date.gte.${_currentTime.toIso8601String()}')
          .eq('is_active', true);

      final medications = response.map((row) => Medication.fromJson(row)).toList();
      
      return medications.where((medication) {
        return medication.schedule.any((scheduleTime) {
          final scheduleDateTime = DateTime(
            _currentTime.year,
            _currentTime.month,
            _currentTime.day,
            scheduleTime.hour,
            scheduleTime.minute,
          );
          return scheduleDateTime.isAfter(startOfDay) && 
                 scheduleDateTime.isBefore(endOfDay);
        });
      }).toList();
    } catch (e) {
      print('Error in getTodaysMedications: $e');
      return [];
    }
  }

  // Update all other methods to use the getter instead of the hardcoded value
  Future<Medication> addMedication(Medication medication) async {
    try {
      final medicationData = {
        'username': _currentUser,
        'name': medication.name,
        'dosage': medication.dosage,
        'schedule': medication.schedule.map((time) => time.toIso8601String()).toList(),
        'instructions': medication.instructions,
        'start_date': medication.startDate.toIso8601String(),
        'end_date': medication.endDate?.toIso8601String(),
        'is_active': true,
        'prescribed_by': _currentUser,
        'created_at': _currentTime.toIso8601String(),
        'updated_at': _currentTime.toIso8601String(),
      };

      final response = await _supabase
          .from(_tableName)
          .insert(medicationData)
          .select()
          .single();
      
      return Medication.fromJson(response);
    } catch (e) {
      print('Error in addMedication: $e');
      throw Exception('Failed to add medication: $e');
    }
  }

  // Update other methods similarly...
  // (Keep all other methods the same but replace the hardcoded _currentUser with the getter)
    Future<Medication> updateMedication(Medication medication) async {
    final response = await _supabase
        .from(_tableName)
        .update({
          ...medication.toJson(),
          'updated_at': _currentTime.toIso8601String(),
        })
        .eq('id', medication.id)
        .eq('username', _currentUser)
        .select()
        .single();
    
    return Medication.fromJson(response);
  }

  Future<Map<String, int>> getMedicationStats() async {
    final response = await _supabase
        .from(_tableName)
        .select('is_active, id')
        .eq('username', _currentUser);

    final activeCount = response.where((row) => row['is_active'] == true).length;
    final inactiveCount = response.where((row) => row['is_active'] == false).length;

    return {
      'active': activeCount,
      'inactive': inactiveCount,
      'total': response.length,
    };
  }


  Future<void> markMedicationTaken(String medicationId, DateTime scheduleTime) async {
    try {
      await _supabase.from(_logsTable).insert({
        'medication_id': medicationId,
        'username': _currentUser,
        'taken_at': _currentTime.toIso8601String(),
        'scheduled_time': scheduleTime.toIso8601String(),
      });
    } catch (e) {
      print('Error in markMedicationTaken: $e');
      rethrow;
    }
  }

  // Add a new method to undo marking a medication as taken
  Future<void> undoMedicationTaken(String medicationId, DateTime scheduleTime) async {
    try {
      // Get today's start and end times
      final now = _currentTime;
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Create a datetime with today's date but with scheduled time's hour and minute
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduleTime.hour,
        scheduleTime.minute,
      );
      
      // Find and delete the matching log
      final logs = await _supabase
          .from(_logsTable)
          .select()
          .eq('medication_id', medicationId)
          .eq('username', _currentUser)
          .gte('taken_at', startOfDay.toIso8601String())
          .lt('taken_at', endOfDay.toIso8601String());
      
      // Find logs where the hour and minute of scheduled_time match
      final matchingLogs = logs.where((log) {
        final logScheduleTime = DateTime.parse(log['scheduled_time']);
        return logScheduleTime.hour == scheduledDateTime.hour && 
               logScheduleTime.minute == scheduledDateTime.minute;
      }).toList();
      
      if (matchingLogs.isNotEmpty) {
        // Delete the most recent log that matches
        await _supabase
            .from(_logsTable)
            .delete()
            .eq('id', matchingLogs.last['id']);
      }
    } catch (e) {
      print('Error in undoMedicationTaken: $e');
      rethrow;
    }
  }

  // This method helps check if a medication was taken at a specific time today
  Future<bool> wasMedicationTakenToday(String medicationId, DateTime scheduleTime) async {
    try {
      // Get today's start and end times
      final now = _currentTime;
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Create a datetime with today's date but with scheduled time's hour and minute
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduleTime.hour,
        scheduleTime.minute,
      );
      
      final logs = await _supabase
          .from(_logsTable)
          .select()
          .eq('medication_id', medicationId)
          .eq('username', _currentUser)
          .gte('taken_at', startOfDay.toIso8601String())
          .lt('taken_at', endOfDay.toIso8601String());
      
      // Check if any log matches the scheduled time (hour and minute)
      return logs.any((log) {
        final logScheduleTime = DateTime.parse(log['scheduled_time']);
        return logScheduleTime.hour == scheduledDateTime.hour && 
               logScheduleTime.minute == scheduledDateTime.minute;
      });
    } catch (e) {
      print('Error in wasMedicationTakenToday: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getMedicationLogsStream(String medicationId) {
    try {
      return _supabase
          .from('medication_logs')
          .stream(primaryKey: ['id'])
          .eq('username', _currentUser)
          .map((rows) {
            final List<Map<String, dynamic>> filteredRows = rows
              .where((row) => row['medication_id'] == medicationId)
              .toList()
              ..sort((a, b) => 
                DateTime.parse(a['taken_at']).compareTo(DateTime.parse(b['taken_at']))
              );
            return filteredRows;
          });
    } catch (e) {
      print('Error in getMedicationLogsStream: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> getAllMedicationLogsStream() {
  try {
    // First, get the base stream from the logs table
    final logsStream = _supabase
        .from(_logsTable)
        .stream(primaryKey: ['id'])
        .eq('username', _currentUser);

    // Transform the stream with medication names
    return logsStream.asyncMap((rows) async {
      if (rows.isEmpty) return [];

      // Fetch related medication data
      final medicationIds = rows.map((row) => row['medication_id']).toSet().toList();
      
      // If there are no medication IDs, return the rows as is
      if (medicationIds.isEmpty) return rows;

      final medications = await _supabase
          .from(_tableName)
          .select('id, name')
          .filter('id', 'in', medicationIds);
      
      // Create a map for quick medication name lookup
      final medicationNames = Map.fromEntries(
        medications.map((med) => MapEntry(med['id'], med['name']))
      );
      
      // Add medication names to the logs
      final logsWithNames = rows.map((row) => {
        ...row,
        'medication_name': medicationNames[row['medication_id']] ?? 'Unknown Medication'
      }).toList();
      
      // Sort by taken_at in descending order
      logsWithNames.sort((a, b) => 
        DateTime.parse(b['taken_at']).compareTo(DateTime.parse(a['taken_at']))
      );
      
      return logsWithNames;
    });
  } catch (e) {
    print('Error in getAllMedicationLogsStream: $e');
    return Stream.value([]);
  }
}

  Stream<List<Medication>> getTodaysMedicationsStream() {
    return getMedicationsStream().map((medications) {
      final startOfDay = DateTime(_currentTime.year, _currentTime.month, _currentTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return medications.where((medication) {
        return medication.schedule.any((scheduleTime) {
          final scheduleDateTime = DateTime(
            _currentTime.year,
            _currentTime.month,
            _currentTime.day,
            scheduleTime.hour,
            scheduleTime.minute,
          );
          return scheduleDateTime.isAfter(startOfDay) && 
                 scheduleDateTime.isBefore(endOfDay);
        });
      }).toList();
    });
  }


  // Add error handling for authentication errors
  void _checkAuthentication() {
    if (_supabase.auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
  }
}