import 'package:elderly_care/config/supabase_config.dart';

class EmergencyService {
  final _supabase = SupabaseConfig.supabase;
  
  // Get current user from AuthService
  String get _currentUser {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User not authenticated');
    return email.split('@')[0].toLowerCase();
  }
  
  // Get current time dynamically
  DateTime get _currentTime => DateTime.now().toUtc();

  Future<void> sendEmergencyAlert({String? additionalNotes}) async {
    if (_currentUser.isEmpty) {
      throw Exception('No authenticated user found');
    }

    try {
      // Get user's profile and emergency contact information
      final userProfile = await _supabase
          .from('profiles')
          .select('name, emergency_contact_name, emergency_contact_phone')
          .eq('username', _currentUser)
          .single();

      // Create emergency alert record
      final alertResponse = await _supabase
          .from('emergency_alerts')
          .insert({
            'username': _currentUser,
            'user_name': userProfile['name'],
            'status': 'active',
            'emergency_contact_name': userProfile['emergency_contact_name'],
            'emergency_contact_phone': userProfile['emergency_contact_phone'],
            'notes': additionalNotes,
            'location': null, // TODO: Implement location services
            'created_at': _currentTime.toIso8601String(),
            'updated_at': _currentTime.toIso8601String(),
          })
          .select()
          .single();

      // Log the emergency alert
      await _logEmergencyEvent(
        alertId: alertResponse['id'],
        eventType: 'alert_created',
        details: 'Emergency alert initiated by user',
      );

      // Notify caregivers
      await _notifyCaregivers(alertResponse['id']);
    } catch (e) {
      await _logEmergencyEvent(
        eventType: 'alert_failed',
        details: 'Failed to create emergency alert: $e',
      );
      rethrow;
    }
  }

  Future<void> cancelEmergencyAlert(String alertId) async {
    if (_currentUser.isEmpty) {
      throw Exception('No authenticated user found');
    }

    try {
      await _supabase
          .from('emergency_alerts')
          .update({
            'status': 'cancelled',
            'updated_at': _currentTime.toIso8601String(),
            'cancelled_at': _currentTime.toIso8601String(),
            'cancelled_by': _currentUser,
          })
          .eq('id', alertId)
          .eq('username', _currentUser);

      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'alert_cancelled',
        details: 'Emergency alert cancelled by user',
      );
    } catch (e) {
      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'cancel_failed',
        details: 'Failed to cancel emergency alert: $e',
      );
      rethrow;
    }
  }

  Future<void> updateEmergencyAlert(String alertId, {
    String? notes,
    String? status,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentUser.isEmpty) {
      throw Exception('No authenticated user found');
    }

    try {
      final updateData = {
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
        if (additionalData != null) ...additionalData,
        'updated_at': _currentTime.toIso8601String(),
      };

      await _supabase
          .from('emergency_alerts')
          .update(updateData)
          .eq('id', alertId)
          .eq('username', _currentUser);

      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'alert_updated',
        details: 'Emergency alert updated with new information',
      );
    } catch (e) {
      await _logEmergencyEvent(
        alertId: alertId,
        eventType: 'update_failed',
        details: 'Failed to update emergency alert: $e',
      );
      rethrow;
    }
  }

  // ... rest of your methods, updated to use _currentUser and _currentTime getters ...

  Future<void> _logEmergencyEvent({
    String? alertId,
    required String eventType,
    required String details,
  }) async {
    if (_currentUser.isEmpty) {
      throw Exception('No authenticated user found');
    }

    await _supabase
        .from('emergency_event_logs')
        .insert({
          'alert_id': alertId,
          'username': _currentUser,
          'event_type': eventType,
          'details': details,
          'created_at': _currentTime.toIso8601String(),
        });
  }

  Future<void> _notifyCaregivers(String alertId) async {
    if (_currentUser.isEmpty) {
      throw Exception('No authenticated user found');
    }

    // Get associated caregivers
    final caregivers = await _supabase
        .from('caregiver_associations')
        .select('caregiver_username')
        .eq('elderly_username', _currentUser)
        .eq('status', 'active');

    // Create notifications for each caregiver
    for (final caregiver in caregivers) {
      await _supabase
          .from('caregiver_notifications')
          .insert({
            'caregiver_username': caregiver['caregiver_username'],
            'alert_id': alertId,
            'type': 'emergency_alert',
            'status': 'pending',
            'created_at': _currentTime.toIso8601String(),
          });
    }
  }
}