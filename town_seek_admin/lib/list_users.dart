import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://bxjasdlhozceeztnxhcj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
  );
  
  try {
    final response = await Supabase.instance.client.from('profiles').select('id, email, name, role');
    print('Users in database:');
    for (var user in response) {
      print('${user['email']} | Role: ${user['role']} | Name: ${user['name']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
