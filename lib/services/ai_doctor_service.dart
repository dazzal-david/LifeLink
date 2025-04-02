import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AIDoctorService {


  static const String _baseUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3';
  static const String _apiKey = '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';


  


  Future<String> getResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': '''<|im_start|>system
You are an AI medical assistant for Peopls. You have access to the following patient information:


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
}