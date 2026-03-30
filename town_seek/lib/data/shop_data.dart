import 'dart:convert'; // Add this import
import '../utils/time_helper.dart';
import '../widgets/shop_card.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ShopData {
  static List<Shop> _allShops = [];

  static List<Shop> get allShops => _allShops;
  
  static set allShops(List<Shop> value) {
    debugPrint('Setting ShopData.allShops with ${value.length} shops');
    _allShops = value;
  }

  static Future<void> fetchShops() async {
    try {
      final response = await Supabase.instance.client
          .from('shops')
          .select('*, working_days(day_of_week), reviews(rating), doctors(*, doctor_qualifications(qualification), doctor_availability(*)), products(name), product_categories(name)')
          .eq('is_verified', true);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('Fetched ${data.length} shops from Supabase');

      if (data.isNotEmpty) {
        final List<Shop> loadedShops = [];
        
        for (var i = 0; i < data.length; i++) {
          final json = data[i];
          try {
            // Parse Working Days
            List<int> workingDays = [];
            if (json['working_days'] != null) {
              final wdList = json['working_days'] as List;
              workingDays = wdList.map<int>((e) => e['day_of_week'] as int).toList();
              workingDays.sort(); // Ensure sorted 0..6
            }
            
            // Safe parsing for tags
            List<String> parsedTags = [];
            if (json['tags'] != null) {
              if (json['tags'] is List) {
                parsedTags = List<String>.from(json['tags']);
              } else if (json['tags'] is String) {
                final str = json['tags'] as String;
                // Try to parse as JSON list first (e.g. ["Tag1", "Tag2"])
                try {
                   if (str.trim().startsWith('[')) {
                      final decoded = jsonDecode(str);
                      if (decoded is List) {
                        parsedTags = List<String>.from(decoded);
                      }
                   } else {
                      // Handle Postgres array format {tag1,tag2} or simple string
                      parsedTags = str.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                   }
                } catch (e) {
                   // Fallback: simple strip of all common array characters
                   parsedTags = str.replaceAll('[', '')
                                   .replaceAll(']', '')
                                   .replaceAll('{', '')
                                   .replaceAll('}', '')
                                   .replaceAll('"', '')
                                   .replaceAll("'", "")
                                   .split(',')
                                   .map((e) => e.trim())
                                   .where((e) => e.isNotEmpty)
                                   .toList();
                }
              }
            }

            double effectiveRating = 0.0;
            if (json['reviews'] != null) {
              final List<dynamic> revs = json['reviews'] as List<dynamic>;
              if (revs.isNotEmpty) {
                double total = 0.0;
                for (var r in revs) {
                  total += (r['rating'] as num).toDouble();
                }
                effectiveRating = total / revs.length;
              }
            }

            // Parse Doctors
            List<Doctor> shopDoctors = [];
            if (json['doctors'] != null) {
               final List<dynamic> docsData = json['doctors'] as List<dynamic>;
               for (var doc in docsData) {
                  // Qualifications
                  List<String> quals = [];
                  if (doc['doctor_qualifications'] != null) {
                     final List<dynamic> qualData = doc['doctor_qualifications'] as List<dynamic>;
                     quals = qualData.map((q) => q['qualification'].toString()).toList();
                  }

                  // Availability string building (Simplified for display purposes: "Mon-Sat 10:00 AM - 02:00 PM")
                  // Grouping or showing exact days is better, but here we will try to format it nicely.
                  String availString = "Check App for timings";
                  if (doc['doctor_availability'] != null) {
                     final List<dynamic> availData = doc['doctor_availability'] as List<dynamic>;
                     if (availData.isNotEmpty) {
                         try {
                           int parseDay(dynamic d) {
                             if (d is int) return d;
                             if (d is String) {
                               const map = {'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6};
                               return map[d] ?? 0;
                             }
                             return 0;
                           }
                           
                           // Sort by day index 0-6
                           availData.sort((a, b) => parseDay(a['day_of_week']).compareTo(parseDay(b['day_of_week'])));
                           
                           final firstDay = parseDay(availData.first['day_of_week']);
                           final lastDay = parseDay(availData.last['day_of_week']);
                           
                           final daysMap = {0: 'Sun', 1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat'};
                           
                           String dayRange = "";
                           if (firstDay == lastDay) {
                               dayRange = daysMap[firstDay] ?? "";
                           } else {
                               dayRange = "${daysMap[firstDay]} - ${daysMap[lastDay]}";
                           }

                           final sTime = availData.first['start_time']; // E.g., "10:00:00"
                           final eTime = availData.first['end_time'];   // E.g., "14:00:00"

                           // Simple HH:MM slicing (Assuming HH:MM:SS format returned by postgres)
                           String formatTime(String t) {
                              try {
                                 final parts = t.split(':');
                                 if (parts.length >= 2) {
                                    int hour = int.parse(parts[0]);
                                    int min = int.parse(parts[1]);
                                    String period = hour >= 12 ? 'PM' : 'AM';
                                    hour = hour % 12;
                                    if (hour == 0) hour = 12;
                                    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
                                 }
                              } catch(e) {/* ignore */}
                              return t;
                           }

                           availString = "$dayRange ${formatTime(sTime)} - ${formatTime(eTime)}";
                        } catch (e) {
                           debugPrint("Error formatting availability for doctor ${doc['name']}: $e");
                        }
                     }
                  }

                  shopDoctors.add(Doctor(
                     id: doc['id']?.toString(), // Ensure Doctor model supports an optional ID later if needed for editing
                     name: doc['name'] ?? 'Unknown Doctor',
                     speciality: doc['department'] ?? 'General',
                     qualification: quals.isNotEmpty ? quals.join(', ') : 'Not Specified',
                     availability: availString,
                     imageUrl: doc['image_url'] ?? '', 
                     availableDays: doc['available_days'] != null
                         ? (doc['available_days'] as List).map((e) => e.toString()).toList()
                         : null,
                     bookingLimit: doc['booking_limit'],
                  ));
               }
            }

            // Aggregate search keywords
            final Set<String> keywordSet = {};
            final shopName = json['name']?.toString() ?? '';
            final shopCat = json['category']?.toString() ?? '';
            final shopSub = json['address']?.toString() ?? '';
            
            if (shopName.isNotEmpty) keywordSet.add(shopName.toLowerCase());
            if (shopCat.isNotEmpty) keywordSet.add(shopCat.toLowerCase());
            if (shopSub.isNotEmpty) keywordSet.add(shopSub.toLowerCase());

            for (var tag in parsedTags) {
              keywordSet.add(tag.toLowerCase());
            }

            for (var doc in shopDoctors) {
              if (doc.name.isNotEmpty) keywordSet.add(doc.name.toLowerCase());
              if (doc.speciality.isNotEmpty) keywordSet.add(doc.speciality.toLowerCase());
            }

            if (json['products'] != null) {
              final List<dynamic> productsData = json['products'] as List<dynamic>;
              for (var p in productsData) {
                if (p['name'] != null) keywordSet.add(p['name'].toString().toLowerCase());
              }
            }

            if (json['product_categories'] != null) {
              final List<dynamic> categoriesData = json['product_categories'] as List<dynamic>;
              for (var c in categoriesData) {
                if (c['name'] != null) keywordSet.add(c['name'].toString().toLowerCase());
              }
            }

            final shop = Shop(
              imageUrl: json['image_url'] ?? 'https://via.placeholder.com/150',
              title: shopName.isNotEmpty ? shopName : 'Unknown Shop',
              subtitle: shopSub.isNotEmpty ? shopSub : 'No address',
              rating: effectiveRating.toStringAsFixed(1),
              tags: parsedTags,
              isOpen: _isOpen(json['opening_time'], json['closing_time']),
              openingTime: json['opening_time'],
              closingTime: json['closing_time'],
              googleMapsLink: json['google_map_link'],
              latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
              longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
              category: json['category'],
              description: json['description'],
              location: json['location'],
              phone: json['mobile'] ?? json['phone'],
              email: json['email'],
              workingDays: workingDays,
              doctors: shopDoctors,
              id: json['id']?.toString(),
              ownerId: json['owner_id']?.toString(),
              profileClicks: json['profile_clicks'] != null ? (json['profile_clicks'] as num).toInt() : 0,
              searchKeywords: keywordSet.toList(),
              openNowOverride: json['open_now'],
            );
            loadedShops.add(shop);
          } catch (e) {
            debugPrint('Error parsing shop at index $i: $e');
            debugPrint('Problematic JSON: $json');
          }
        }
        
        // Set all parsed shops, even if empty
        allShops = loadedShops;
      } else {
        // Empty the list if nothing was returned
        allShops = [];
      }
      
    } catch (e) {
      debugPrint('Error fetching shops: $e.');
      allShops = [];
    }
  }

  static void updateLocalShopRating(String id, double newRating) {
    debugPrint('Updating local shop rating for id: $id to $newRating');
    final index = _allShops.indexWhere((s) => s.id == id);
    if (index != -1) {
      final oldShop = _allShops[index];
      // Create copy with new rating
      final newShop = Shop(
        imageUrl: oldShop.imageUrl,
        title: oldShop.title,
        subtitle: oldShop.subtitle,
        rating: newRating.toStringAsFixed(1),
        tags: oldShop.tags,
        isOpen: oldShop.isOpen,
        facilities: oldShop.facilities,
        doctors: oldShop.doctors,
        services: oldShop.services,
        googleMapsLink: oldShop.googleMapsLink,
        openingTime: oldShop.openingTime,
        closingTime: oldShop.closingTime,
        latitude: oldShop.latitude,
        longitude: oldShop.longitude,
        category: oldShop.category,
        description: oldShop.description,
        location: oldShop.location,
        phone: oldShop.phone,
        email: oldShop.email,
        workingDays: oldShop.workingDays,
        id: oldShop.id,
        ownerId: oldShop.ownerId,
        profileClicks: oldShop.profileClicks,
        searchKeywords: oldShop.searchKeywords,
        openNowOverride: oldShop.openNowOverride,
      );
      _allShops[index] = newShop;
    }
  }

  static bool _isOpen(String? openTime, String? closeTime, {bool? openNowOverride}) {
    if (openNowOverride != null) return openNowOverride;
    return TimeHelper.isShopOpen(openTime, closeTime, defaultStatus: false);
  }

  static Future<void> updateShopOpenStatus(String shopId, bool? status) async {
    try {
      await Supabase.instance.client
          .from('shops')
          .update({'open_now': status})
          .eq('id', shopId);
      
      // Update local state if needed (though dashboard usually re-fetches)
      final index = _allShops.indexWhere((s) => s.id == shopId);
      if (index != -1) {
        final oldShop = _allShops[index];
        _allShops[index] = Shop(
          imageUrl: oldShop.imageUrl,
          title: oldShop.title,
          subtitle: oldShop.subtitle,
          rating: oldShop.rating,
          tags: oldShop.tags,
          isOpen: _isOpen(oldShop.openingTime, oldShop.closingTime, openNowOverride: status),
          facilities: oldShop.facilities,
          doctors: oldShop.doctors,
          services: oldShop.services,
          googleMapsLink: oldShop.googleMapsLink,
          openingTime: oldShop.openingTime,
          closingTime: oldShop.closingTime,
          latitude: oldShop.latitude,
          longitude: oldShop.longitude,
          category: oldShop.category,
          description: oldShop.description,
          location: oldShop.location,
          phone: oldShop.phone,
          email: oldShop.email,
          workingDays: oldShop.workingDays,
          id: oldShop.id,
          ownerId: oldShop.ownerId,
          profileClicks: oldShop.profileClicks,
          searchKeywords: oldShop.searchKeywords,
          openNowOverride: status,
        );
      }
    } catch (e) {
      debugPrint('Error updating shop open status: $e');
      rethrow;
    }
  }

  static Future<void> incrementClicks(String shopId, String? ownerId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    // Skip if owner is clicking their own shop
    if (userId != null && ownerId != null && userId == ownerId) {
      debugPrint('Click skipped: User is the shop owner.');
      return;
    }

    try {
      // Call Supabase RPC to securely increment without triggering RLS update restrictions
      // NOTE: Create this in SQL Editor: CREATE OR REPLACE FUNCTION increment_shop_click(shop_uuid UUID) RETURNS void LANGUAGE sql SECURITY DEFINER AS $$ UPDATE shops SET profile_clicks = COALESCE(profile_clicks, 0) + 1 WHERE id = shop_uuid; $$;
      await Supabase.instance.client.rpc('increment_shop_click', params: {'shop_uuid': shopId});
    } catch (e) {
      debugPrint('Error incrementing clicks (Ensure RPC exists): $e');
      Fluttertoast.showToast(
          msg: "Click Error: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0
      );
    }
  }

  static Future<List<ShopProductCategory>> fetchProductCategories(dynamic shopId) async {
    try {
      final parsedShopId = int.tryParse(shopId.toString()) ?? shopId;
      final response = await Supabase.instance.client
          .from('product_categories')
          .select('id, name, shop_id, image_url')
          .eq('shop_id', parsedShopId);
          
      debugPrint('Fetched \${(response as List).length} categories for shop \$shopId');
      if (response.isNotEmpty) {
        debugPrint('First category JSON: \${response.first}');
      }
      
      return (response as List).map((json) => ShopProductCategory(
        id: json['id'].toString(),
        shopId: json['shop_id'].toString(),
        name: json['name'] as String,
        imageUrl: json['image_url'] as String?,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching product categories: $e');
      return [];
    }
  }

  static Future<List<ShopProduct>> fetchProducts(dynamic shopId) async {
    try {
      final parsedShopId = int.tryParse(shopId.toString()) ?? shopId;
      final response = await Supabase.instance.client
          .from('products')
          .select('id, name, price, image_url, category_id, shop_id, stock')
          .eq('shop_id', parsedShopId);

      return (response as List).map((json) => ShopProduct(
        id: json['id'].toString(),
        shopId: json['shop_id'].toString(),
        categoryId: json['category_id'].toString(),
        name: json['name'] as String,
        price: json['price']?.toString() ?? '',
        imageUrl: json['image_url'] as String?,
        isAvailable: json['stock'] == true,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  static Future<List<ShopOffering>> fetchOfferings(dynamic shopId) async {
    try {
      final parsedShopId = int.tryParse(shopId.toString()) ?? shopId;
      final response = await Supabase.instance.client
          .from('shop_offerings')
          .select('id, shop_id, category_id, title, description, image_url, price')
          .eq('shop_id', parsedShopId);

      return (response as List).map((json) => ShopOffering(
        id: json['id'].toString(),
        shopId: json['shop_id'].toString(),
        categoryId: json['category_id']?.toString(),
        title: json['title'] as String,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        price: json['price']?.toString(),
      )).toList();
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
      return [];
    }
  }

  static Future<void> addOffering(Map<String, dynamic> data) async {
    await Supabase.instance.client.from('shop_offerings').insert(data);
  }

  static Future<void> updateOffering(String id, Map<String, dynamic> data) async {
    await Supabase.instance.client.from('shop_offerings').update(data).eq('id', id);
  }

  static Future<void> deleteOffering(String id) async {
    await Supabase.instance.client.from('shop_offerings').delete().eq('id', id);
  }
}
