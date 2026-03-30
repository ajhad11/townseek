import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Supabase Connection Test', () async {
    final supabase = SupabaseClient(
      'https://bxjasdlhozceeztnxhcj.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
    );

    try {
      // Attempt to access a potentially non-existent table to check connectivity.
      // If we get a response (even a 404 or API error), it means we connected.
      await supabase.from('health_check').select().limit(1);
      debugPrint('Connection Successful: Query executed cleanly.');
    } catch (e) {
      final errorString = e.toString();
      // Check for common connection errors
      if (errorString.contains('SocketException') || errorString.contains('ClientException') || errorString.contains('Connection refused')) {
         fail('Connection Failed: Could not reach Supabase. Original error: $e');
      } else {
         // If generic API error (like table not found), connection is actually successful!
         debugPrint('Connection Successful: Reached Supabase (Error was expected for missing table: $e)');
      }
    }
  });
}
