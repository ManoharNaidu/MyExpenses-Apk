import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEnv {
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}

Future<void> initSupabase() async {
  if (SupabaseEnv.url.isEmpty || SupabaseEnv.anonKey.isEmpty) {
    debugPrint('Supabase configuration missing. Please provide SUPABASE_URL and SUPABASE_ANON_KEY');
    return;
  }
  await Supabase.initialize(
    url: SupabaseEnv.url,
    anonKey: SupabaseEnv.anonKey,
  );
}

SupabaseClient get supabaseClient => Supabase.instance.client;
