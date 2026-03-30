import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Check shop rating column', () async {
    final supabase = SupabaseClient(
      'https://bxjasdlhozceeztnxhcj.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
    );

    try {
      final shopsRes = await supabase.from('shops').select('id, name, rating').limit(5);
      debugPrint('Shops table rating check: $shopsRes');

      final reviewsRes = await supabase.from('reviews').select('shop_id, rating').limit(5);
      debugPrint('Reviews table check: $reviewsRes');
    } catch (e) {
      debugPrint('Error querying ratings: $e');
    }
  });
}
