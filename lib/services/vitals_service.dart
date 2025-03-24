import 'package:elderly_care/models/vital_model.dart';
import 'package:elderly_care/config/supabase_config.dart';

class VitalsService {
  final _supabase = SupabaseConfig.supabase;
  static const String _tableName = 'vitals';
  static final DateTime _currentTime = DateTime.parse('2025-03-10 18:53:13');

  String get _currentUser {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User not authenticated');
    return email.split('@')[0].toLowerCase();
  }

  Stream<VitalModel?> getLatestVitalsStream() {
    try {
      return _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('username', _currentUser)
          .order('recorded_at', ascending: false)
          .limit(1)
          .map((data) {
            if (data.isEmpty) return null;
            return VitalModel.fromJson(data.first);
          });
    } catch (e) {
      print('Error in getLatestVitalsStream: $e');
      return Stream.value(null);
    }
  }

  Future<List<VitalModel>> getVitalsHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from(_tableName)
          .select()
          .eq('username', _currentUser);

      // Build the filter conditions
      List<String> conditions = [];
      if (startDate != null) {
        conditions.add('recorded_at.gte.${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        conditions.add('recorded_at.lte.${endDate.toIso8601String()}');
      }

      // Apply the conditions if any
      if (conditions.isNotEmpty) {
        query = query.or(conditions.join(','));
      }

      final response = await query
          .order('recorded_at', ascending: false)
          .limit(limit);

      return response.map((data) => VitalModel.fromJson(data)).toList();
    } catch (e) {
      print('Error in getVitalsHistory: $e');
      return [];
    }
  }

  Future<void> recordVitals({
    int? heartRate,
    int? bloodPressureSystolic,
    int? bloodPressureDiastolic,
    double? temperature,
    int? oxygenSaturation,
    int? glucoseLevel,
    String? notes,
  }) async {
    try {
      await _supabase.from(_tableName).insert({
        'username': _currentUser,
        'heart_rate': heartRate,
        'blood_pressure_systolic': bloodPressureSystolic,
        'blood_pressure_diastolic': bloodPressureDiastolic,
        'temperature': temperature,
        'oxygen_saturation': oxygenSaturation,
        'glucose_level': glucoseLevel,
        'notes': notes,
        'recorded_at': _currentTime.toIso8601String(),
      });
    } catch (e) {
      print('Error in recordVitals: $e');
      rethrow;
    }
  }

  Future<void> updateVital(String vitalId, {
    int? heartRate,
    int? bloodPressureSystolic,
    int? bloodPressureDiastolic,
    double? temperature,
    int? oxygenSaturation,
    int? glucoseLevel,
    String? notes,
  }) async {
    try {
      await _supabase
          .from(_tableName)
          .update({
            'heart_rate': heartRate,
            'blood_pressure_systolic': bloodPressureSystolic,
            'blood_pressure_diastolic': bloodPressureDiastolic,
            'temperature': temperature,
            'oxygen_saturation': oxygenSaturation,
            'glucose_level': glucoseLevel,
            'notes': notes,
            'updated_at': _currentTime.toIso8601String(),
          })
          .eq('id', vitalId)
          .eq('username', _currentUser);
    } catch (e) {
      print('Error in updateVital: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getVitalAlertsStream() {
    try {
      return _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('username', _currentUser)
          .order('recorded_at', ascending: false)
          .limit(1)
          .map((data) {
            if (data.isEmpty) return [];
            
            final vital = VitalModel.fromJson(data.first);
            final alerts = <Map<String, dynamic>>[];

            if (vital.bloodPressureSystolic != null && vital.bloodPressureDiastolic != null) {
              if (vital.bloodPressureSystolic! >= 140 || vital.bloodPressureDiastolic! >= 90) {
                alerts.add({
                  'id': vital.id,
                  'vital_type': 'blood_pressure',
                  'vital_value': '${vital.bloodPressureSystolic}/${vital.bloodPressureDiastolic}',
                  'message': 'High blood pressure detected',
                  'created_at': vital.recordedAt.toIso8601String(),
                  'status': 'active',
                });
              }
            }

            _checkVitalRange(vital.heartRate, 'heart_rate', 60, 100, alerts, vital);
            _checkVitalRange(vital.oxygenSaturation, 'oxygen_saturation', 95, 100, alerts, vital);
            _checkVitalRange(vital.glucoseLevel, 'glucose_level', 70, 140, alerts, vital);

            return alerts;
          });
    } catch (e) {
      print('Error in getVitalAlertsStream: $e');
      return Stream.value([]);
    }
  }

  void _checkVitalRange(
    int? value,
    String type,
    int minValue,
    int maxValue,
    List<Map<String, dynamic>> alerts,
    VitalModel vital,
  ) {
    if (value != null) {
      if (value < minValue || value > maxValue) {
        alerts.add({
          'id': vital.id,
          'vital_type': type,
          'vital_value': value.toString(),
          'message': '${type.replaceAll('_', ' ').toUpperCase()} is out of normal range',
          'created_at': vital.recordedAt.toIso8601String(),
          'status': 'active',
        });
      }
    }
  }
}