import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'osm_service.dart';
import '../data/shop_data.dart';

class SmartRouteResult {
  final List<Map<String, dynamic>> options;
  final List<String> missingItems;

  SmartRouteResult({required this.options, required this.missingItems});
}

class SmartRouteService {
  final OSMService _osmService = OSMService();

  /// Fetches ranked shop options for each product, returning up to 5 options per item.
  Future<SmartRouteResult> getAllShopOptionsForProducts({
    required List<String> products,
    required Position userLocation,
    required String preference,
  }) async {
    List<Map<String, dynamic>> results = [];
    List<String> missingItems = [];
    Set<String> processedProducts = {};

    for (String item in products) {
      String trimmedItem = item.trim();
      if (trimmedItem.isEmpty || processedProducts.contains(trimmedItem.toLowerCase())) continue;

      // Parse "category â†’ department" format (e.g., "hospital â†’ Emergency")
      String searchCategory = trimmedItem;
      String? searchDepartment;
      if (trimmedItem.contains('â†’')) {
        final parts = trimmedItem.split('â†’');
        searchCategory = parts[0].trim();
        searchDepartment = parts.length > 1 ? parts[1].trim() : null;
        debugPrint('[SmartRoute] Category: "$searchCategory" | Department: "$searchDepartment"');
      }
      
      // Use category for product lookup, but the full label for display
      final queryTerm = searchCategory;

      debugPrint('[SmartRoute] === Searching for: "$trimmedItem" (query: "$queryTerm") ===');

      try {
        // Step 1: Search Products by name
        List<dynamic> productsFound = [];
        try {
          final productResponse = await Supabase.instance.client
              .from('products')
              .select('*')
              .ilike('name', '%$queryTerm%');
          productsFound = productResponse as List<dynamic>;
          debugPrint('[SmartRoute] Products found: ${productsFound.length}');
        } catch (e) {
          debugPrint('[SmartRoute] Product query error: $e');
        }

        List<dynamic> shopsFound = [];
        Set<String> seenShopIds = {};
        
        // Add shopIds from products to avoid duplicate direct shops
        for (var p in productsFound) {
          final id = p['shop_id']?.toString() ?? '';
          if (id.isNotEmpty) seenShopIds.add(id);
        }

        // Step 2: Search shops by name OR category OR doctors OR product_categories
        debugPrint('[SmartRoute] Searching shops by name/category/doctors/product_cats...');
        
        // Query 1: Match by shop name
        try {
          final byName = await Supabase.instance.client
              .from('shops')
              .select('*')
              .eq('is_verified', true)
              .ilike('name', '%$queryTerm%');
          for (var s in byName as List<dynamic>) {
            final id = s['id']?.toString() ?? '';
            if (id.isNotEmpty && seenShopIds.add(id)) shopsFound.add(s);
          }
        } catch (e) {
          debugPrint('[SmartRoute] Error matching by shop name: $e');
        }

        // Query 2: Match by category
        try {
          final byCategory = await Supabase.instance.client
              .from('shops')
              .select('*')
              .eq('is_verified', true)
              .ilike('category', '%$queryTerm%');
          for (var s in byCategory as List<dynamic>) {
            final id = s['id']?.toString() ?? '';
            if (id.isNotEmpty && seenShopIds.add(id)) shopsFound.add(s);
          }
        } catch (e) {
          debugPrint('[SmartRoute] Error matching by category: $e');
        }

        // Query 3: Match from doctors
        try {
           final doctorResponse = await Supabase.instance.client
               .from('doctors')
               .select('shop_id, name, department')
               .or('name.ilike.%$queryTerm%,department.ilike.%$queryTerm%');
           for (var d in doctorResponse as List<dynamic>) {
               final shopId = d['shop_id']?.toString() ?? '';
               if (shopId.isNotEmpty && seenShopIds.add(shopId)) {
                   final shopRes = await Supabase.instance.client.from('shops').select('*').eq('is_verified', true).eq('id', shopId).maybeSingle();
                   if (shopRes != null) shopsFound.add(shopRes);
               }
           }
        } catch(e) {
          debugPrint('[SmartRoute] Error matching from doctors: $e');
        }

        // Query 4: Match from product categories
        try {
           final categoryResponse = await Supabase.instance.client
               .from('product_categories')
               .select('shop_id, name')
               .ilike('name', '%$queryTerm%');
           for (var c in categoryResponse as List<dynamic>) {
               final shopId = c['shop_id']?.toString() ?? '';
               if (shopId.isNotEmpty && seenShopIds.add(shopId)) {
                   final shopRes = await Supabase.instance.client.from('shops').select('*').eq('is_verified', true).eq('id', shopId).maybeSingle();
                   if (shopRes != null) shopsFound.add(shopRes);
               }
           }
        } catch(e) {
          debugPrint('[SmartRoute] Error matching from product categories: $e');
        }

        // If a department was specified, filter shopsFound to those whose tags contain it
        if (searchDepartment != null && shopsFound.isNotEmpty) {
          final dept = searchDepartment.toLowerCase();
          shopsFound = shopsFound.where((shop) {
            final tags = shop['tags'];
            bool tagMatch = false;
            if (tags != null) {
              List<String> tagList = [];
              if (tags is List) {
                tagList = tags.map((t) => t.toString().toLowerCase()).toList();
              } else {
                tagList = tags.toString()
                    .replaceAll('[', '').replaceAll(']', '').replaceAll('{', '').replaceAll('}', '').replaceAll('"', '')
                    .split(',').map((t) => t.trim().toLowerCase()).toList();
              }
              tagMatch = tagList.any((t) => t.contains(dept));
            }
            if (tagMatch) return true;
            
            // Allow if department string matches shop category/name
            if (shop['category']?.toString().toLowerCase().contains(dept) == true) return true;
            if (shop['name']?.toString().toLowerCase().contains(dept) == true) return true;
            
            return false;
          }).toList();
        }

        // Step 2b: Try tags unconditionally to catch categories or matching terms
        try {
          final tagResponse = await Supabase.instance.client
              .from('shops')
              .select('*')
              .eq('is_verified', true)
              .contains('tags', [queryTerm]);
          for (var s in tagResponse as List<dynamic>) {
             final id = s['id']?.toString() ?? '';
             if (id.isNotEmpty && seenShopIds.add(id)) shopsFound.add(s);
          }
        } catch (e) {
          try {
            final tagStrResponse = await Supabase.instance.client
                .from('shops')
                .select('*')
                .eq('is_verified', true)
                .ilike('tags', '%$trimmedItem%');
            for (var s in tagStrResponse as List<dynamic>) {
               final id = s['id']?.toString() ?? '';
               if (id.isNotEmpty && seenShopIds.add(id)) shopsFound.add(s);
            }
          } catch (e2) {
            debugPrint('[SmartRoute] Error matching tags by string: $e2');
          }
        }

        // Step 3: Rank shops
        List<Map<String, dynamic>> rankedShops = [];

        // Rank product-matched shops (fetch shop separately by shop_id)
        for (var p in productsFound) {
          final shopId = p['shop_id'];
          if (shopId == null) {
            debugPrint('[SmartRoute] Product has no shop_id, skipping.');
            continue;
          }
          try {
            final shopRes = await Supabase.instance.client
                .from('shops')
                .select('*')
                .eq('is_verified', true)
                .eq('id', shopId)
                .maybeSingle();
            if (shopRes == null) {
              debugPrint('[SmartRoute] Shop $shopId not found.');
              continue;
            }
            final lat = double.tryParse(shopRes['latitude'].toString()) ?? 0.0;
            final lng = double.tryParse(shopRes['longitude'].toString()) ?? 0.0;
            debugPrint('[SmartRoute] Product shop: ${shopRes['name']} lat=$lat lng=$lng');
            if (lat == 0.0 || lng == 0.0) {
              debugPrint('[SmartRoute] Skipping â€” coordinates invalid');
              continue;
            }
            _rankShop(shopRes, userLocation, preference, rankedShops, product: p);
          } catch (e) {
            debugPrint('[SmartRoute] Error fetching shop for product: $e');
          }
        }

        // Rank directly-matched shops
        for (var shop in shopsFound) {
          final lat = double.tryParse(shop['latitude']?.toString() ?? '') ?? 0.0;
          final lng = double.tryParse(shop['longitude']?.toString() ?? '') ?? 0.0;
          debugPrint('[SmartRoute] Direct shop: ${shop['name']} lat=$lat lng=$lng');
          if (lat == 0.0 || lng == 0.0) {
            debugPrint('[SmartRoute] Skipping â€” coordinates invalid (lat=$lat lng=$lng)');
            continue;
          }
          _rankShop(shop, userLocation, preference, rankedShops, isDirectShop: true, searchItem: trimmedItem);
        }

        debugPrint('[SmartRoute] Ranked shops count: ${rankedShops.length}');

        // Step 3.5: Fallback to local ShopData if nothing was found or ranked
        if (rankedShops.isEmpty) {
          debugPrint('[SmartRoute] Supabase queries yielded no ranked shops. Falling back to ShopData search for "$queryTerm".');
          for (var localShop in ShopData.allShops) {
            bool matches = localShop.searchKeywords.any((kw) => kw.contains(queryTerm.toLowerCase()));
            if (!matches && localShop.category?.toLowerCase() == queryTerm.toLowerCase()) {
               matches = true;
            }
            if (!matches && localShop.tags.any((t) => t.toLowerCase() == queryTerm.toLowerCase())) {
               matches = true;
            }
            if (matches) {
              final lat = localShop.latitude ?? 0.0;
              final lng = localShop.longitude ?? 0.0;
              if (lat != 0.0 && lng != 0.0) {
                // Ensure we don't add duplicate shops
                if (!rankedShops.any((rs) => rs['shop']['id'].toString() == localShop.id)) {
                  final mockShop = {
                     'id': localShop.id,
                     'name': localShop.title,
                     'latitude': lat,
                     'longitude': lng,
                     'reviews': [{'rating': double.tryParse(localShop.rating) ?? 0.0}],
                     'facilities': localShop.facilities ?? [],
                     'tags': localShop.tags,
                     'category': localShop.category,
                  };
                  _rankShop(mockShop, userLocation, preference, rankedShops, isDirectShop: true, searchItem: trimmedItem);
                }
              }
            }
          }
          debugPrint('[SmartRoute] Fallback ranked shops count: ${rankedShops.length}');
        }

        if (rankedShops.isNotEmpty) {
          rankedShops.sort((a, b) => (a['score'] as double).compareTo(b['score'] as double));
          results.add({
            'itemName': trimmedItem,
            'options': rankedShops.take(5).toList(),
          });
          processedProducts.add(trimmedItem.toLowerCase());
        } else {
          debugPrint('[SmartRoute] No ranked shops for "$trimmedItem" â€” adding to missing.');
          missingItems.add(trimmedItem);
        }
      } catch (e) {
        debugPrint('[SmartRoute] Outer error for "$trimmedItem": $e');
        missingItems.add(trimmedItem);
      }
    }

    return SmartRouteResult(options: results, missingItems: missingItems);
  }

  /// Fetches unique product names, shop categories, and shop tags for search recommendations.
  Future<List<String>> getSearchRecommendations() async {
    try {
      // 1. Fetch products
      final productData = await Supabase.instance.client
          .from('products')
          .select('name');
      
      // 2. Fetch shop categories and tags
      final shopData = await Supabase.instance.client
          .from('shops')
          .select('category, tags')
          .eq('is_verified', true);
          
      // 3. Fetch doctors
      final doctorData = await Supabase.instance.client
          .from('doctors')
          .select('name, department');
          
      // 4. Fetch product categories
      final productCategoryData = await Supabase.instance.client
          .from('product_categories')
          .select('name');

      Set<String> recommendations = {};

      for (var p in productData as List) {
        if (p['name'] != null && p['name'].toString().trim().isNotEmpty) recommendations.add(p['name'].toString().trim());
      }
      
      for (var c in productCategoryData as List) {
        if (c['name'] != null && c['name'].toString().trim().isNotEmpty) recommendations.add(c['name'].toString().trim());
      }
      
      for (var d in doctorData as List) {
        if (d['name'] != null && d['name'].toString().trim().isNotEmpty) recommendations.add(d['name'].toString().trim());
        if (d['department'] != null && d['department'].toString().trim().isNotEmpty) recommendations.add(d['department'].toString().trim());
      }
      
      for (var cat in categoryTypes) {
        recommendations.add(cat);
      }

      for (var s in shopData as List) {
        if (s['category'] != null && s['category'].toString().trim().isNotEmpty) {
           recommendations.add(s['category'].toString().trim());
        }
        if (s['tags'] != null) {
          if (s['tags'] is List) {
            for (var tag in s['tags']) {
              if (tag.toString().trim().isNotEmpty) {
                 recommendations.add(tag.toString().trim());
              }
            }
          } else if (s['tags'] is String) {
            String tagsStr = s['tags'].toString();
            // Clean up Postgres array/JSON notation characters
            tagsStr = tagsStr.replaceAll('[', '')
                             .replaceAll(']', '')
                             .replaceAll('{', '')
                             .replaceAll('}', '')
                             .replaceAll('"', '')
                             .replaceAll("'", "");
            List<String> tagsList = tagsStr.split(',');
            for (var tag in tagsList) {
              if (tag.trim().isNotEmpty) recommendations.add(tag.trim());
            }
          }
        }
      }

      return recommendations.toList()..sort();
    } catch (e) {
      debugPrint("Error fetching search recommendations: $e");
      return [];
    }
  }

  /// Returns the list of known shop categories so the UI can detect
  /// when a user has typed a category vs a product name.
  static const List<String> categoryTypes = [
    'hospital', 'groceries', 'food', 'fashion', 'health', 'services',
    'finance', 'animals', 'education', 'religious', 'entertainment',
    'publicservices', 'commercial', 'bank', 'pharmacy', 'clinic',
  ];

  /// Fetches unique tags (departments/specialties) for shops in a given category.
  /// Example: for 'hospital', might return ['Emergency', 'Cardiology', 'Pediatrics']
  Future<List<String>> getDepartmentsForCategory(String category) async {
    try {
      final shopData = await Supabase.instance.client
          .from('shops')
          .select('tags')
          .eq('is_verified', true)
          .ilike('category', '%$category%');

      Set<String> departments = {};
      for (var s in shopData as List) {
        if (s['tags'] == null) continue;
        if (s['tags'] is List) {
          for (var tag in s['tags']) {
            final t = tag.toString().trim();
            if (t.isNotEmpty) departments.add(t);
          }
        } else if (s['tags'] is String) {
          String tagsStr = s['tags'].toString()
              .replaceAll('[', '').replaceAll(']', '')
              .replaceAll('{', '').replaceAll('}', '')
              .replaceAll('"', '').replaceAll("'", '');
          for (var tag in tagsStr.split(',')) {
            final t = tag.trim();
            if (t.isNotEmpty) departments.add(t);
          }
        }
      }
      return departments.toList()..sort();
    } catch (e) {
      debugPrint('Error fetching departments for $category: $e');
      return [];
    }
  }

  /// Groups a list of selected individual options into the shop-based format expected by generateRoute.
  List<Map<String, dynamic>> groupSelectedOptionsIntoShops(List<Map<String, dynamic>> selectedOptions) {
      List<Map<String, dynamic>> selectedShops = [];
      
      for (var option in selectedOptions) {
          final shopDetails = option['shop'];
          final productDetails = option['product'];
          
          int existingIndex = selectedShops.indexWhere((s) => s['id'] == shopDetails['id']);
          if (existingIndex != -1) {
            selectedShops[existingIndex]['itemsToBuy'].add(productDetails);
            selectedShops[existingIndex]['totalCost'] += double.tryParse(productDetails['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          } else {
            selectedShops.add({
              'id': shopDetails['id'],
              'name': shopDetails['name'],
              'latitude': shopDetails['latitude'],
              'longitude': shopDetails['longitude'],
              'rating': option['rating'],
              'hasParking': option['hasParking'],
              'itemsToBuy': [productDetails],
              'distanceFromUser': option['distance'],
              'totalCost': double.tryParse(productDetails['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
            });
          }
      }
      return selectedShops;
  }

  /// Helper to automatically select the best shops if manual selection is bypassed.
  Future<List<Map<String, dynamic>>> getBestShopsForProducts({
    required List<String> products,
    required Position userLocation,
    required String preference, // 'Cheapest', 'Fastest', 'Balanced'
  }) async {
      final result = await getAllShopOptionsForProducts(
          products: products, 
          userLocation: userLocation, 
          preference: preference
      );
      
      List<Map<String, dynamic>> bestSelections = [];
      for (var itemGroup in result.options) {
          final options = itemGroup['options'] as List<Map<String, dynamic>>;
          if (options.isNotEmpty) {
              bestSelections.add(options.first);
          }
      }
      
      return groupSelectedOptionsIntoShops(bestSelections);
  }

  void _rankShop(dynamic shop, Position userLocation, String preference, List<Map<String, dynamic>> rankedShops, {dynamic product, bool isDirectShop = false, String? searchItem}) {
          // Calculate distance from user to shop
          double shopLat = double.tryParse(shop['latitude'].toString()) ?? 0.0;
          double shopLng = double.tryParse(shop['longitude'].toString()) ?? 0.0;
          
          if (shopLat == 0.0 || shopLng == 0.0) return; // Skip invalid coordinates

          double distance = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
             shopLat,
             shopLng,
          );

          // Calculate rating
          double rating = 0.0;
          if (shop['reviews'] != null) {
            final List<dynamic> revs = shop['reviews'] as List<dynamic>;
            if (revs.isNotEmpty) {
              double total = 0.0;
              for (var r in revs) {
                 total += (r['rating'] as num).toDouble();
              }
              rating = total / revs.length;
            }
          }

          // Price (0 if direct shop search)
          double price = 0.0;
          if (product != null && product['price'] != null) {
             price = double.tryParse(product['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          }

          // Parking (Check if facilities contains 'Parking')
          bool hasParking = false;
          if (shop['facilities'] != null) {
             List<String> facilities = [];
             if (shop['facilities'] is List) {
               facilities = List<String>.from(shop['facilities']);
             } else if (shop['facilities'] is String) {
               facilities = shop['facilities'].toString().toLowerCase().split(',');
             }
             hasParking = facilities.any((f) => f.trim().toLowerCase() == 'parking');
          }

          // Calculate Score (Lower is better)
          double score = 0.0;

          // Normalize values approximately for scoring
          // Max distance assumed 50km (50000m), max rating 5, max price assumed relative
          
          double distScore = distance / 1000.0; // km
          double ratingScore = (5.0 - rating) * 2; // Invert rating, multiply to give it weight
          double priceScore = price / 100.0; 
          double parkingScore = hasParking ? -5.0 : 0.0; // Bonus for parking

          if (preference == 'Fastest') {
             score = (distScore * 10) + ratingScore + parkingScore;
          } else if (preference == 'Cheapest') {
             // Price score needs to be very high weight to beat distance
             // If price is 500, priceScore is 5. If dist is 5km, distScore is 5.
             // We want 500 to be much worse than 400 even if 5km away.
             score = distScore + (priceScore * 50) + (ratingScore * 0.5) + parkingScore;
          } else { // Balanced
             score = (distScore * 2) + (priceScore * 5) + ratingScore + (parkingScore * 2);
          }

          rankedShops.add({
            'shop': shop,
            'product': isDirectShop ? {'name': searchItem, 'price': '0'} : product,
            'distance': distance,
            'rating': rating,
            'hasParking': hasParking,
            'score': score,
          });
  }

  /// Generates the optimized route for the selected shops from the user's location.
  Future<Map<String, dynamic>?> generateRoute({
    required Position userLocation,
    required List<Map<String, dynamic>> shops,
  }) async {
    if (shops.isEmpty) return null;

    List<LatLng> waypoints = [
      LatLng(userLocation.latitude, userLocation.longitude)
    ];

    // Add all shops as coordinates
    for (var shop in shops) {
       double shopLat = double.tryParse(shop['latitude'].toString()) ?? 0.0;
       double shopLng = double.tryParse(shop['longitude'].toString()) ?? 0.0;
       
       if (shopLat != 0.0 && shopLng != 0.0) {
          waypoints.add(LatLng(shopLat, shopLng));
       }
    }

    // Call OSM to get optimized trip
    final tripData = await _osmService.getOptimizedTrip(waypoints);

    if (tripData != null) {
      // Re-order shops based on destination order
      List<Map<String, dynamic>> orderedShops = [];
      final optimizedWaypoints = tripData['optimized_waypoints'] as List;
      
      // Index 0 is the start point (user location)
      for (int i = 1; i < optimizedWaypoints.length; i++) {
         // OSRM returns waypoints in the order they were provided, but assigns them a `waypoint_index` denoting their position in the trip
         // So we need to match the waypoint_index to figure out the visit order
         final originalIndex = optimizedWaypoints[i]['waypoint_index'] as int;
         
         // originalIndex 0 is user, so originalIndex 1 is shops[0], etc.
         if (originalIndex > 0 && originalIndex <= shops.length) {
            orderedShops.add(shops[originalIndex - 1]);
         }
      }

      // If reordering failed or OSRM didn't return expected waypoint indices, fallback to original order
      if (orderedShops.length != shops.length) {
         orderedShops = List.from(shops);
      }

      return {
        'coordinates': tripData['coordinates'],
        'distance': tripData['distance'],
        'duration': tripData['duration'],
        'orderedShops': orderedShops,
      };
    }

    return null;
  }
}
