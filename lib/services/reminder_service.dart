import 'package:elderly_care/config/supabase_config.dart';
import 'package:elderly_care/models/reminder_model.dart';

class ReminderService {
  final _supabase = SupabaseConfig.supabase;
  final String _currentUser = 'dazzal-david';
  static final DateTime _currentTime = DateTime.parse('2025-02-20 17:06:21');
  static const String _tableName = 'reminders';

  Stream<List<Reminder>> getRemindersStream() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('username', _currentUser)
        .map((rows) => rows.map((row) => Reminder.fromJson(row)).toList());
  }

  Stream<List<Reminder>> getTodayRemindersStream() {
    final startOfDay = DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('username', _currentUser)
        .map((rows) {
          final List<Map<String, dynamic>> filteredRows = rows.where((row) {
            final dateTime = DateTime.parse(row['date_time']);
            return dateTime.isAfter(startOfDay) && 
                   dateTime.isBefore(endOfDay);
          }).toList();
          
          // Sort by date_time
          filteredRows.sort((a, b) => 
            DateTime.parse(a['date_time']).compareTo(DateTime.parse(b['date_time']))
          );
          
          return filteredRows.map((row) => Reminder.fromJson(row)).toList();
        });
  }

  Future<Reminder> addReminder(Reminder reminder) async {
    final response = await _supabase
        .from(_tableName)
        .insert({
          ...reminder.toJson(),
          'username': _currentUser,
          'created_at': _currentTime.toIso8601String(),
        })
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    final response = await _supabase
        .from(_tableName)
        .update({
          ...reminder.toJson(),
          'updated_at': _currentTime.toIso8601String(),
        })
        .eq('id', reminder.id)
        .eq('username', _currentUser)
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('id', reminderId)
        .eq('username', _currentUser);
  }

  Future<void> toggleReminderCompletion(String reminderId, bool isCompleted) async {
    await _supabase
        .from(_tableName)
        .update({
          'is_completed': isCompleted,
          'updated_at': _currentTime.toIso8601String(),
        })
        .eq('id', reminderId)
        .eq('username', _currentUser);

    await _logReminderAction(
      reminderId: reminderId,
      action: isCompleted ? 'completed' : 'uncompleted',
    );
  }

  Future<List<Reminder>> getRemindersForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('username', _currentUser)
        .gte('date_time', startOfDay.toIso8601String())
        .lt('date_time', endOfDay.toIso8601String())
        .order('date_time');

    return response.map((row) => Reminder.fromJson(row)).toList();
  }

  Future<List<Reminder>> getUpcomingReminders({int limit = 5}) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('username', _currentUser)
        .eq('is_completed', false)
        .gte('date_time', _currentTime.toIso8601String())
        .order('date_time')
        .limit(limit);

    return response.map((row) => Reminder.fromJson(row)).toList();
  }

  Future<Map<String, int>> getReminderStats() async {
    final response = await _supabase
        .from(_tableName)
        .select('is_completed, id')
        .eq('username', _currentUser);

    final completedCount = response.where((row) => row['is_completed'] == true).length;
    final pendingCount = response.where((row) => row['is_completed'] == false).length;

    return {
      'completed': completedCount,
      'pending': pendingCount,
      'total': response.length,
    };
  }

  Future<void> _logReminderAction({
    required String reminderId,
    required String action,
  }) async {
    await _supabase
        .from('reminder_logs')
        .insert({
          'reminder_id': reminderId,
          'username': _currentUser,
          'action': action,
          'created_at': _currentTime.toIso8601String(),
        });
  }

  Stream<List<Reminder>> getRecurringRemindersStream() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('username', _currentUser)
        .map((rows) {
          final List<Map<String, dynamic>> filteredRows = rows
            .where((row) => row['is_recurring'] == true)
            .toList()
            ..sort((a, b) => 
              DateTime.parse(a['date_time']).compareTo(DateTime.parse(b['date_time']))
            );
          return filteredRows.map((row) => Reminder.fromJson(row)).toList();
        });
}

  Future<void> createRecurringReminders(
    Reminder baseReminder,
    DateTime endDate,
    String recurrencePattern,
  ) async {
    DateTime currentDate = baseReminder.dateTime;
    final reminders = <Map<String, dynamic>>[];

    while (currentDate.isBefore(endDate)) {
      reminders.add({
        ...baseReminder.toJson(),
        'date_time': currentDate.toIso8601String(),
        'username': _currentUser,
        'created_at': _currentTime.toIso8601String(),
        'is_recurring': true,
        'recurrence_pattern': recurrencePattern,
      });

      // Calculate next occurrence based on pattern
      switch (recurrencePattern) {
        case 'daily':
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + 1,
            currentDate.day,
            currentDate.hour,
            currentDate.minute,
          );
          break;
        default:
          throw Exception('Invalid recurrence pattern');
      }
    }

    if (reminders.isNotEmpty) {
      await _supabase.from(_tableName).insert(reminders);
    }
  }

  Stream<List<Reminder>> getActiveRemindersStream() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('username', _currentUser)
        .map((rows) {
          final List<Map<String, dynamic>> filteredRows = rows
            .where((row) => 
              row['is_completed'] == false && 
              DateTime.parse(row['date_time']).isAfter(_currentTime)
            )
            .toList()
            ..sort((a, b) => 
              DateTime.parse(a['date_time']).compareTo(DateTime.parse(b['date_time']))
            );
          return filteredRows.map((row) => Reminder.fromJson(row)).toList();
        });
}

}