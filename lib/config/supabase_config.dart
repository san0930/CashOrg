import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://opivljzgoiknuzssdjna.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9waXZsanpnb2lrbnV6c3Nkam5hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2Njc4NjQsImV4cCI6MjEwMzI0Mzg2NH0.FGyBQJ1YR0j0vXgkZDKIRwcvlah5mXzpclBWJPDsT2g';

  /// Returns true if Supabase credentials have been configured
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  /// Initializes Supabase if configured
  static Future<void> initialize() async {
    if (isConfigured) {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
    }
  }
}
