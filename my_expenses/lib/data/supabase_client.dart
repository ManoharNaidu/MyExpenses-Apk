import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://egqlppxwewqfjzidtbky.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVncWxwcHh3ZXdxZmp6aWR0Ymt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzNTA4NzQsImV4cCI6MjA4MzkyNjg3NH0._Az8bLuuS0VTR91mQAt-s-2A6cAFLd_IWwtvuAMlRpw',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
