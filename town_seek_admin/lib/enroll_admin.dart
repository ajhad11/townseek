import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase Client (CLI context)
  await Supabase.initialize(
    url: 'https://bxjasdlhozceeztnxhcj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
  );
  
  final client = Supabase.instance.client;
  final String adminEmail = 'ajhadk453@gimail.com';
  final String adminPass = 'ajhad12345';

  print('Enrolling Super Admin: $adminEmail...');
  
  try {
     // 1. Try to register through Supabase Auth
     await client.auth.signUp(
       email: adminEmail,
       password: adminPass,
     );
     print('Signup successful or email already exists.');

     // 2. Insert as admin in profiles if possible
     // Just login check should be enough since we restricted it in code.
     print('--- ADMIM ACCESS CONFIGURED ---');
     print('Email: $adminEmail');
     print('Password: $adminPass');
     print('Only this email can désormais access the Admin Dashboard.');
  } catch (e) {
    print('Configuration error: $e');
  }
}
