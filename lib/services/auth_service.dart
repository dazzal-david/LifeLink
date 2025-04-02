import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  SupabaseClient? _supabase;
  User? _user;
  
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  
  AuthService() {
    _init();
  }
  
  Future<void> _init() async {
    try {
      _supabase = Supabase.instance.client;
      _user = _supabase?.auth.currentUser;

      _supabase?.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn && session?.user != null) {
          _user = session!.user;
        } else if (event == AuthChangeEvent.signedOut) {
          _user = null;
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }
  

  Future<void> signUp({required String email, required String password}) async {
    if (_supabase == null) throw Exception('Supabase client not initialized');
    
    try {
      await _supabase!.auth.signUp(email: email, password: password);
    } catch (e) {
      debugPrint('SignUp Error: $e');
      throw Exception('Failed to sign up. Please try again.');
    }
  }
  
  Future<void> signIn({required String email, required String password}) async {
    if (_supabase == null) throw Exception('Supabase client not initialized');
    
    try {
      await _supabase!.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint('SignIn Error: $e');
      throw Exception('Failed to sign in. Please check your credentials.');
    }
  }

  Future<void> signOut() async {
    if (_supabase == null) throw Exception('Supabase client not initialized');
    
    try {
      await _supabase!.auth.signOut();
    } catch (e) {
      debugPrint('SignOut Error: $e');
      throw Exception('Failed to sign out. Please try again.');
    }
  }
  
  Future<void> resetPassword(String email) async {
    if (_supabase == null) throw Exception('Supabase client not initialized');
    
    try {
      await _supabase!.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      throw Exception('Failed to send password reset email.');
    }
  }
} 
