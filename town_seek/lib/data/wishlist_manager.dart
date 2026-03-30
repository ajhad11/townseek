import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shop_data.dart';
import '../widgets/shop_card.dart';

class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  
  factory WishlistManager() {
    return _instance;
  }

  WishlistManager._internal() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        loadWishlist();
      } else {
        _wishlistShopIds.clear();
        notifyListeners();
      }
    });

    if (Supabase.instance.client.auth.currentUser != null) {
      loadWishlist();
    }
  }

  final Set<String> _wishlistShopIds = {};

  Future<void> loadWishlist() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('user_favorites')
          .select('shop_id')
          .eq('user_id', userId);
      
      _wishlistShopIds.clear();
      for (var row in response as List) {
        if (row['shop_id'] != null) {
          _wishlistShopIds.add(row['shop_id'].toString());
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  bool isWishlisted(String? shopId) {
    if (shopId == null) return false;
    return _wishlistShopIds.contains(shopId);
  }

  Future<void> toggleWishlist(Shop shop) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final shopId = shop.id;
    if (userId == null || shopId == null) {
       debugPrint("Cannot favorite: User or shop ID is null.");
       return;
    }

    if (_wishlistShopIds.contains(shopId)) {
      _wishlistShopIds.remove(shopId);
      notifyListeners(); 
      try {
        await Supabase.instance.client
            .from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('shop_id', shopId);
      } catch (e) {
        _wishlistShopIds.add(shopId); 
        notifyListeners();
        debugPrint('Error removing from wishlist: $e');
      }
    } else {
      _wishlistShopIds.add(shopId);
      notifyListeners(); 
      try {
        await Supabase.instance.client
            .from('user_favorites')
            .insert({
              'user_id': userId,
              'shop_id': shopId,
            });
      } catch (e) {
        _wishlistShopIds.remove(shopId); 
        notifyListeners();
        debugPrint('Error adding to wishlist: $e');
      }
    }
  }

  Future<void> addToWishlist(Shop shop) async {
    if (shop.id == null || _wishlistShopIds.contains(shop.id)) return;
    await toggleWishlist(shop);
  }

  Future<void> removeFromWishlist(Shop shop) async {
    if (shop.id == null || !_wishlistShopIds.contains(shop.id)) return;
    await toggleWishlist(shop);
  }

  List<Shop> get wishlistShops {
    return ShopData.allShops.where((shop) => shop.id != null && _wishlistShopIds.contains(shop.id)).toList();
  }
}
