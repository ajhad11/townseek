import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bxjasdlhozceeztnxhcj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
  );
  
  try {
    print('Fetching user roles...');
    final res = await client.from('profiles').select('id, role, name');
    for (var u in res) {
      print('ID: ${u['id']} | Role: ${u['role']} | Name: ${u['name']}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
