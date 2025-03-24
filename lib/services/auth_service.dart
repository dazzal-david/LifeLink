import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:elderly_care/config/supabase_config.dart';
import 'package:elderly_care/models/user_model.dart';

class AuthService {
  final _supabase = SupabaseConfig.supabase;
  DateTime get _currentTime => DateTime.now().toUtc();

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      final username = email.split('@')[0].toLowerCase();

      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (profileData == null) {
        await _supabase.from('profiles').insert({
          'username': username,
          'name': email.split('@')[0],
          'age': 0,
          'blood_group': '',
          'height': 0,
          'weight': 0,
          'gender': 'Not Specified',
          'medical_conditions': [],
          'disabilities': [],
          'allergies': [],
          'created_at': _currentTime.toIso8601String(),
          'updated_at': _currentTime.toIso8601String(),
        });
      }
    } catch (e) {
      if (e is AuthException) {
        throw Exception('Invalid email or password');
      } else if (e is PostgrestException) {
        print('PostgrestException: ${e.message}');
      } else {
        print('Other error: $e');
        throw Exception('An error occurred while signing in');
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required UserModel userData,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      final username = email.split('@')[0].toLowerCase();

      // Wait a brief moment for auth to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      // Create the profile in the profiles table
      await _supabase.from('profiles').insert({
        'username': username,
        'name': userData.name,
        'age': userData.age,
        'blood_group': userData.bloodGroup,
        'height': userData.height,
        'weight': userData.weight,
        'gender': userData.gender,
        'medical_conditions': userData.medicalConditions,
        'disabilities': userData.disabilities,
        'allergies': userData.allergies,
        'emergency_contact_name': userData.emergencyContactName,
        'emergency_contact_phone': userData.emergencyContactPhone,
        'created_at': _currentTime.toIso8601String(),
        'updated_at': _currentTime.toIso8601String(),
      }).select();

      // After successful registration, sign in the user automatically
      await signIn(email: email, password: password);
    } catch (e) {
      print('SignUp error: $e');
      if (e is AuthException) {
        throw Exception('Registration failed: ${e.message}');
      } else if (e is PostgrestException) {
        print('PostgrestException: ${e.message}');
        throw Exception('Failed to create profile. Please try again.');
      } else {
        throw Exception('An unexpected error occurred');
      }
    }
  }

  Future<UserModel?> getCurrentUser() async {
  try {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('No authenticated user found');

    final username = email.split('@')[0].toLowerCase();
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('username', username)
        .single();

    if (response == null) throw Exception('Profile not found');
    
    return UserModel.fromJson(response);
  } catch (e) {
    print('GetCurrentUser error: $e');
    throw Exception('Failed to load user profile: $e');
  }
}

  Future<void> updateProfile(UserModel userData) async {
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) throw Exception('User not authenticated');

      final username = email.split('@')[0].toLowerCase();

      await _supabase
          .from('profiles')
          .update({
            'name': userData.name,
            'age': userData.age,
            'blood_group': userData.bloodGroup,
            'height': userData.height,
            'weight': userData.weight,
            'gender': userData.gender,
            'medical_conditions': userData.medicalConditions,
            'disabilities': userData.disabilities,
            'allergies': userData.allergies,
            'emergency_contact_name': userData.emergencyContactName,
            'emergency_contact_phone': userData.emergencyContactPhone,
            'updated_at': _currentTime.toIso8601String(),
          })
          .eq('username', username)
          .select();
    } catch (e) {
      print('UpdateProfile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('SignOut error: $e');
      throw Exception('Failed to sign out');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      final username = session.user.email?.split('@')[0].toLowerCase();
      if (username == null) return false;

      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (profileData == null) {
        await _supabase.from('profiles').insert({
          'username': username,
          'name': username,
          'age': 0,
          'blood_group': '',
          'height': 0,
          'weight': 0,
          'gender': 'Not Specified',
          'medical_conditions': [],
          'disabilities': [],
          'allergies': [],
          'created_at': _currentTime.toIso8601String(),
          'updated_at': _currentTime.toIso8601String(),
        }).select();
      }

      return true;
    } catch (e) {
      print('IsAuthenticated error: $e');
      return false;
    }
  }
}