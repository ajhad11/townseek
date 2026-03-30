import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://bxjasdlhozceeztnxhcj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
  );
  
  final tables = ['doctors', 'departments', 'doctor_appointments', 'doctor_availability'];
  print('Inspecting Hospital Tables Schema');
  for (var table in tables) {
    try {
      final res = await supabase.from(table).select().limit(1);
      if (res.isNotEmpty) {
        print('Table \${table} columns: \${res[0].keys.toList()}');
      } else {
        print('Table \${table} is empty');
      }
    } catch (e) {
      print('Table \${table} error: \$e');
    }
  }
}
