import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:elderly_care/config/supabase_config.dart';
import 'package:elderly_care/models/medication_model.dart';
import 'package:elderly_care/models/vital_model.dart';
import 'package:elderly_care/services/medication_service.dart';
import 'package:elderly_care/services/vitals_service.dart';

class AIDoctorService {
  final _supabase = SupabaseConfig.supabase;
  final _medicationService = MedicationService();
  final _vitalsService = VitalsService();

  // Use dynamic current time and user
  DateTime get _currentTime => DateTime.now().toUtc();
  
  String get _currentUser {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('User not authenticated');
    return email.split('@')[0].toLowerCase();
  }

  static const String _baseUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3';
  static const String _apiKey = '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';


  Future<Map<String, dynamic>?> _getUserProfile() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('username', _currentUser)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  String _formatUserProfile(Map<String, dynamic>? profile) {
    if (profile == null) return "No user profile available.";

    return '''- Name: ${profile['name'] ?? 'Not provided'}
- Age: ${profile['age'] ?? 'Not provided'} years
- Gender: ${profile['gender'] ?? 'Not provided'}
- Blood Type: ${profile['blood_group'] ?? 'Not provided'}
- Height: ${profile['height'] ?? 'Not provided'} cm
- Weight: ${profile['weight'] ?? 'Not provided'} kg
- Allergies: ${profile['allergies'] ?? 'None recorded'}
- Emergency Contact: ${profile['emergency_contact'] ?? 'Not provided'}''';
  }


  Future<String> getResponse(String message) async {
    try {
      // Get user's medications
      final medications = await _medicationService.getTodaysMedications();
      final userProfile = await _getUserProfile();
      
      // Get user's latest vitals using the stream
      VitalModel? latestVitals;
      await for (final vitals in _vitalsService.getLatestVitalsStream()) {
        latestVitals = vitals;
        break; // Just get the first (latest) value
      }
      
      // Create context strings
      String medicationContext = _formatMedicationsContext(medications);
      String vitalsContext = _formatVitalsContext(latestVitals);
      String userContext = _formatUserProfile(userProfile);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': '''<|im_start|>system
You are an AI medical assistant for Senior Citizens. You have access to the following patient information:

PATIENT PROFILE:
$userContext

CURRENT MEDICATIONS:
$medicationContext

LATEST VITAL SIGNS:
$vitalsContext

TIME OF CONSULTATION: ${_currentTime.toIso8601String()}

Please provide a single, helpful response while:
1. Consider the patient's current medications and vital signs when giving advice
2. Messages should be easy to understand and short
3. Recommending professional consultation for serious issues not every single time only very very important times only.
4. Using clear, simple language and do not over talk, say least number of words only
5. Being empathetic and helpful
6. Only respond once and do not generate follow-up conversations
7. Alert about any concerning vital signs or medication interactions
8. Remind about medication schedules when relevant
9. Act like a doctor like real professional.

<|im_start|>user
$message

<|im_start|>assistant''',
          'parameters': {
            'max_length': 500,
            'temperature': 0.7,
            'top_p': 0.9,
            'stop': ['<|im_start|>'],
            'return_full_text': false
          }
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data[0]['generated_text'] ?? 
          'I apologize, but I was unable to generate a response.';
        
        // Clean up the response
        aiResponse = aiResponse.split('\nUser:')[0].trim();
        aiResponse = aiResponse.split('\nAI Doctor:')[0].trim();
        
        // Save the conversation with current user and time
        await _saveConversation(message, aiResponse);
        return aiResponse;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getOfflineResponse();
      }
    } catch (e) {
      print('Error in getResponse: $e');
      return _getOfflineResponse();
    }
  }
  
  String _getOfflineResponse() {
    return '''I apologize, but I'm currently experiencing technical difficulties. 
    As an AI medical assistant, I recommend:
    
    1. For non-urgent matters, please try again in a few moments
    2. For medical advice, consult your healthcare provider
    3. For emergencies, call emergency services immediately
    
    Remember: I'm an AI assistant and cannot replace professional medical care.''';
  }

  String _formatMedicationsContext(List<Medication> medications) {
    if (medications.isEmpty) {
      return "No current medications.";
    }

    return medications.map((med) {
      final schedule = med.getFormattedSchedule();
      return '''- ${med.name} (${med.dosage})
    Schedule: $schedule
    Instructions: ${med.instructions}
    Start Date: ${med.startDate.toString().split(' ')[0]}
    ${med.endDate != null ? 'End Date: ${med.endDate.toString().split(' ')[0]}' : 'Ongoing'}''';
    }).join('\n');
  }

  String _formatVitalsContext(VitalModel? vitals) {
    if (vitals == null) {
      return "No recent vital signs recorded.";
    }

    return '''- Heart Rate: ${vitals.heartRate ?? 'Not recorded'} BPM
- Blood Pressure: ${vitals.bloodPressureSystolic ?? 'Not recorded'}/${vitals.bloodPressureDiastolic ?? 'Not recorded'} mmHg
- Temperature: ${vitals.temperature?.toStringAsFixed(1) ?? 'Not recorded'}°C
- Oxygen Level: ${vitals.oxygenSaturation ?? 'Not recorded'}%
- Blood Sugar: ${vitals.glucoseLevel ?? 'Not recorded'} mg/dL
- Notes: ${vitals.notes ?? 'No notes'}
Last recorded: ${vitals.recordedAt.toString().split('.')[0]}''';
  }

  Future<void> _saveConversation(String userMessage, String aiResponse) async {
    try {
      await _supabase.from('ai_conversations').insert({
        'username': _currentUser,  // Using dynamic user
        'user_message': userMessage,
        'ai_response': aiResponse,
        'created_at': _currentTime.toIso8601String(),
        'context': 'medical_assistant',
        'model': 'Mistral-7B'
      });
    } catch (e) {
      print('Error saving conversation: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    try {
      final response = await _supabase
          .from('ai_conversations')
          .select()
          .eq('username', _currentUser)  // Using dynamic user
          .order('created_at', ascending: false)
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching conversation history: $e');
      return [];
    }
  }
}