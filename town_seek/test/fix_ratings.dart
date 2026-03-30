import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Fix all shop ratings', () async {
    final supabase = SupabaseClient(
      'https://bxjasdlhozceeztnxhcj.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
    );

    try {
      // 1. Fetch all shops
      final shopsRes = await supabase.from('shops').select('id, name, rating');
      final List<dynamic> shops = shopsRes as List<dynamic>;

      for (var shop in shops) {
        final shopId = shop['id'];

        // 2. Fetch reviews for this shop
        final reviewsRes = await supabase.from('reviews').select('rating').eq('shop_id', shopId);
        final List<dynamic> reviews = reviewsRes as List<dynamic>;

        if (reviews.isEmpty) {
          // No reviews, so it should be 0.0
          if (shop['rating'] != 0.0) {
            debugPrint('Fixing shop ${shop['name']} with 0 reviews to rating 0.0');
            await supabase.from('shops').update({'rating': 0.0}).eq('id', shopId);
          }
        } else {
          // Recalculate average
          double totalRating = 0;
          for (var r in reviews) {
            totalRating += (r['rating'] as num).toDouble();
          }
          double averageRating = totalRating / reviews.length;
          
          if (shop['rating'] != averageRating) {
             debugPrint('Fixing shop ${shop['name']} with ${reviews.length} reviews to rating $averageRating');
             await supabase.from('shops').update({'rating': averageRating}).eq('id', shopId);
          }
        }
      }
      debugPrint('Done fixing ratings!');
    } catch (e) {
      debugPrint('Error: $e');
    }
  });
}
