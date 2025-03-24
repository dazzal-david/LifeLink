import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseConfig {
  static const String supabaseUrl = 'https://oxklsjiprxeijrpeztxf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94a2xzamlwcnhlaWpycGV6dHhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNjc5NTYsImV4cCI6MjA1NTY0Mzk1Nn0.VVfMs182VjUjNY8odYEwxbSm27iODkziS-DLba6RNdc';
  
  static final supabase = Supabase.instance.client;
}