
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';
import 'shop_data.dart';

class ReviewService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Review>> fetchReviews(String shopId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, profiles(name, id, avatar_url)') // Fetch avatar_url
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  Future<void> addReview(String shopId, double rating, String text) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _client.from('reviews').upsert({
        'shop_id': shopId,
        'user_id': user.id,
        'rating': rating.toInt(),
        'review_text': text,
      }, onConflict: 'shop_id, user_id');

      await updateShopRating(shopId);
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId, String shopId) async {
    try {
      await _client.from('reviews').delete().eq('id', reviewId);
      await updateShopRating(shopId);
    } catch (e) {
      debugPrint('Error deleting review: $e');
      rethrow;
    }
  }

  Future<void> updateReviewResponse(String reviewId, String responseText) async {
    try {
      await _client.from('reviews').update({
        'response': responseText,
        'response_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
    } catch (e) {
      debugPrint('Error updating review response: $e');
      rethrow;
    }
  }

  Future<void> updateShopRating(String shopId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('rating')
          .eq('shop_id', shopId);
      
      final List<dynamic> ratings = response as List<dynamic>;
      
      if (ratings.isEmpty) {
        await _client.from('shops').update({'rating': 0}).eq('id', shopId);
        return;
      }

      double totalRating = 0;
      for (var r in ratings) {
        totalRating += (r['rating'] as num).toDouble();
      }
      double averageRating = totalRating / ratings.length;

      await _client.from('shops').update({'rating': averageRating}).eq('id', shopId);
      
      // Update local cache so ShopCards reflect the change immediately
      ShopData.updateLocalShopRating(shopId, averageRating);
    } catch (e) {
      debugPrint('Error updating shop rating: $e');
    }
  }
}
