import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eomyqtrudqlabmfvoksu.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvbXlxdHJ1ZHFsYWJtZnZva3N1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5MjY1NjIsImV4cCI6MjEwNzUwMjU2Mn0.ssuLf-SQcL7Qh8n4u5hJCmEUav7lU5mzbxoNjF6rv8o',
  );
  static bool _isInitialized = false;
  static bool get isConfigured => projectUrl.isNotEmpty && anonKey.isNotEmpty;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (projectUrl.isEmpty && anonKey.isEmpty) return;
    if (!isConfigured) {
      throw StateError(
        'Provide both SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.',
      );
    }

    await Supabase.initialize(
      url: projectUrl,
      publishableKey: anonKey,
    );
    _isInitialized = true;
  }
}