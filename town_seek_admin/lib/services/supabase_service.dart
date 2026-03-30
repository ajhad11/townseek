import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/platform_utils.dart';

class SupabaseService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }

  /// Admin Check Utility
  Future<bool> verifyIsAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      
      return response != null && response['role'] == 'admin';
    } catch (e) {
      debugPrint('Admin check error: $e');
      return false;
    }
  }


  Future<Map<String, int>> getDashboardStats() async {
    _setLoading(true);
    try {
      // Explicitly forcing Future type using .then() to avoid compilation issues
      final futures = [
        _supabase.from('profiles').select('id').then((v) => v),
        _supabase.from('shops').select('id').then((v) => v),
        _supabase.from('shops').select('id').eq('is_verified', false).then((v) => v),
      ];
      final responses = await Future.wait(futures);

      return {
        'users': (responses[0] as List).length,
        'shops': (responses[1] as List).length,
        'pending': (responses[2] as List).length,
      };
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// User Management (Table: profiles)
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase.from('profiles').select('*, admins(id)').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching users: $e');
      // If requested column is missing, try a simpler select
      if (e.toString().contains('PGRST204')) {
        try {
          final backupResponse = await _supabase.from('profiles').select('id, name, email, created_at');
          return List<Map<String, dynamic>>.from(backupResponse);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> blockUser(String userId) async {
    if (!await verifyIsAdmin()) throw Exception('Access Denied: You do not have administrative permissions.');

    try {
      final response = await _supabase.from('profiles').update({'is_disabled': true}).eq('id', userId).select();
      if ((response as List).isEmpty) {
        throw Exception('Update failed. Ensure that the database "profiles" table has the "is_disabled" column and RLS policies are applied.');
      }
    } catch (e) {
      debugPrint('Block User Error: $e');
      rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    if (!await verifyIsAdmin()) throw Exception('Access Denied: Administrative permissions required.');

    try {
      final response = await _supabase.from('profiles').update({'is_disabled': false}).eq('id', userId).select();
      if ((response as List).isEmpty) {
        throw Exception('Update failed. Ensure that the is_disabled column exists and RLS is configured.');
      }
    } catch (e) {
      debugPrint('Unblock User Error: $e');
      rethrow;
    }
  }


  /// Update Profile Safety
  Future<void> updateMyProfile(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User must be logged in to update profile.');
    
    try {
      _setLoading(true);
      // Using upsert for profile safety as requested
      await _supabase.from('profiles').upsert({
        'id': user.id,
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile Update Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }


  Future<void> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      await _supabase.from('products').delete().eq('id', productId);
    } catch (e) {
      debugPrint('Delete Product Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleProductStatus(String productId, bool isDisabled) async {
    try {
      _setLoading(true);
      await _supabase.from('products').update({'is_disabled': isDisabled}).eq('id', productId);
    } catch (e) {
      debugPrint('Toggle Product Status Error: $e');
      if (e.toString().contains('is_disabled')) {
        throw Exception('Server configuration error: The "is_disabled" feature is not active in the database yet. Please run the SQL migration.');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }


  Future<void> deleteOffer(String offerId) async {
    try {
      _setLoading(true);
      await _supabase.from('offers').delete().eq('id', offerId);
    } catch (e) {
      debugPrint('Delete Offer Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      _setLoading(true);
      await _supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      debugPrint('Delete Review Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      _setLoading(true);
      
      // 1. Identify all owned shops
      final ownedShops = await _supabase.from('shops').select('id').eq('owner_id', userId);
      final shopList = List<Map<String, dynamic>>.from(ownedShops as List);

      // 2. Wipe each shop's deep data first
      for (final shop in shopList) {
        final shopId = shop['id'];
        await _deepWipeShopData(shopId);
      }

      // 3. Delete the shops themselves
      await _supabase.from('shops').delete().eq('owner_id', userId);

      // 4. Cleanup other user-linked tables (Broad Sweep)
      final profileLinkedTables = ['reviews', 'doctors', 'admins', 'products', 'doctor_appointments', 'offers', 'user_favorites'];
      final List<Future> cleanupFutures = [];
      for (final table in profileLinkedTables) {
        final columns = ['profile_id', 'user_id', 'owner_id', 'id'];
        for (final col in columns) {
          cleanupFutures.add(
            _supabase.from(table).delete().eq(col, userId)
              .then((_) => null)
              .catchError((_) => null)
          );
        }
      }
      await Future.wait(cleanupFutures);

      // 5. Atomic Profile Wipe
      await _supabase.from('profiles').delete().eq('id', userId);

      // 6. Hard verification with multiple attempts
      bool isDeleted = false;
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        final check = await _supabase.from('profiles').select('id').eq('id', userId).maybeSingle();
        if (check == null) {
          isDeleted = true;
          break;
        }
      }

      if (!isDeleted) {
        throw Exception('User record deletion blocked. This usually happens when other tables still reference this ID. Ensure all linked tables (like active orders) are cleared.');
      }
    } catch (e) {
      debugPrint('Global Wipe Failure: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _deepWipeShopData(String shopId) async {
    // 1. Fetch all doctors for this shop to wipe their nested data
    try {
      final doctors = await _supabase.from('doctors').select('id').eq('shop_id', shopId);
      final docList = List<Map<String, dynamic>>.from(doctors as List);
      for (final doc in docList) {
        final docId = doc['id'];
        try { await _supabase.from('doctor_qualifications').delete().eq('doctor_id', docId); } catch (_) {}
        try { await _supabase.from('doctor_availability').delete().eq('doctor_id', docId); } catch (_) {}
      }
    } catch (_) {} // Ignore if fails

    // 2. Wipe standard shop-linked data
    final tables = [
      'doctors', 'working_days', 'departments',
      'reviews', 'products', 'offers', 'doctor_appointments',
      'product_categories', 'gallery_images'
    ];
    
    for (final table in tables) {
      try {
        await _supabase.from(table).delete().eq('shop_id', shopId);
      } catch (_) {
        try {
          await _supabase.from(table).delete().eq('id', shopId);
        } catch (_) {}
      }
    }
  }

  /// Shop Management (Table: shops)
  Future<List<Map<String, dynamic>>> getAllShops() async {
    try {
      final response = await _supabase.from('shops').select('*, profiles!owner_id(name)');
      final list = List<Map<String, dynamic>>.from(response as List? ?? []);
      return list.map((s) {
        final profiles = s['profiles'];
        if (profiles is List && profiles.isNotEmpty) {
          s['profiles'] = profiles.first;
        } else if (profiles is Map) {
           // If Supabase returns a map directly (sometimes happens depending on join notation)
           s['profiles'] = profiles;
        }
        return s;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching shops with hint: $e');
      try {
        final response = await _supabase.from('shops').select('*, profiles(name)');
        final list = List<Map<String, dynamic>>.from(response as List? ?? []);
        return list.map((s) {
          final profiles = s['profiles'];
          if (profiles is List && profiles.isNotEmpty) {
            s['profiles'] = profiles.first;
          }
          return s;
        }).toList();
      } catch (e) {
         debugPrint('Final shop fetch failure: $e');
         rethrow;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getPendingShops() async {
    try {
      final response = await _supabase
          .from('shops')
          .select('*, profiles!owner_id(name)')
          .eq('is_verified', false);
      
      final list = List<Map<String, dynamic>>.from(response as List? ?? []);
      return list.map((s) {
        final profiles = s['profiles'];
        if (profiles is List && profiles.isNotEmpty) {
          s['profiles'] = profiles.first;
        } else if (profiles is Map) {
           s['profiles'] = profiles;
        }
        return s;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching pending shops: $e');
      rethrow;
    }
  }

  Future<void> blockShop(String shopId) async {
    final response = await _supabase.from('shops').update({'is_blocked': true}).eq('id', shopId).select();
    if ((response as List).isEmpty) throw Exception('Establishment not found or update failed.');
  }

  Future<void> unblockShop(String shopId) async {
    final response = await _supabase.from('shops').update({'is_blocked': false}).eq('id', shopId).select();
    if ((response as List).isEmpty) throw Exception('Establishment not found or update failed.');
  }

  Future<void> toggleShopVerification(String shopId, bool isVerified) async {
    try {
      _setLoading(true);
      
      // Confirm the establishment exists first
      final check = await _supabase.from('shops').select('id, name').eq('id', shopId).maybeSingle();
      if (check == null) {
        throw Exception('Establishment with ID "$shopId" no longer exists in the database.');
      }

      final response = await _supabase
          .from('shops')
          .update({'is_verified': isVerified})
          .eq('id', shopId)
          .select();
      
      if ((response as List).isEmpty) {
        throw Exception('Access Denied or Update Blocked: The database rejected the update for "${check['name']}". This usually happens due to Row Level Security (RLS) policies. Ensure your account has "admin" permissions in the profiles table.');
      }
    } catch (e) {
      debugPrint('Toggle Shop Verification Error: $e');
      if (e.toString().contains('is_verified')) {
        throw Exception('The "is_verified" column does not exist in the "shops" table. Please add it via SQL: ALTER TABLE shops ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteShop(String shopId) async {
    try {
      _setLoading(true);
      await _deepWipeShopData(shopId);
      await _supabase.from('shops').delete().eq('id', shopId);
      
      // Verification
      await Future.delayed(const Duration(milliseconds: 600));
      final check = await _supabase.from('shops').select('id').eq('id', shopId).maybeSingle();
      if (check != null) {
        throw Exception('Establishment data removal was blocked by a server constraint.');
      }
    } catch (e) {
       debugPrint('Delete Shop Failure: $e');
       rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Product Management (Table: products)
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final response = await _supabase.from('products').select('*, shops(name, profiles(name))');
      final list = List<Map<String, dynamic>>.from(response as List? ?? []);
      return list.map((p) {
        final shops = p['shops'];
        if (shops != null && shops is Map && shops['profiles'] is List && (shops['profiles'] as List).isNotEmpty) {
          p['shops']['profiles'] = (shops['profiles'] as List).first;
        }
        return p;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      // Fallback if specific columns like is_disabled are missing
      if (e.toString().contains('is_disabled') || e.toString().contains('PGRST204')) {
         try {
           final response = await _supabase.from('products').select('id, name, price, shop_id');
           return List<Map<String, dynamic>>.from(response);
         } catch (_) {}
      }
      rethrow;
    }
  }


  /// Hospital Management
  Future<Map<String, dynamic>> getHospitalDetails(String shopId) async {
    try {
      final futures = [
        _supabase.from('shops').select('*, profiles!owner_id(*)').eq('id', shopId).maybeSingle().then((v) => v),
        _supabase.from('doctors').select('*, doctor_availability(*), doctor_qualifications(*)').eq('shop_id', shopId).then((v) => v),
        _supabase.from('doctor_appointments').select('*, doctors(name)').eq('shop_id', shopId).order('appointment_date', ascending: false).limit(50).then((v) => v),
        _supabase.from('departments').select('*').eq('shop_id', shopId).then((v) => v),
        _supabase.from('reviews').select('*, profiles(name, avatar_url)').eq('shop_id', shopId).order('created_at', ascending: false).then((v) => v),
        _supabase.from('media').select('*').eq('shop_id', shopId).maybeSingle().then((v) => v),
      ];

      final responses = await Future.wait(futures);
      
      var shop = responses[0] as Map<String, dynamic>?;
      if (shop != null && shop['profiles'] is List && (shop['profiles'] as List).isNotEmpty) {
        shop['profiles'] = (shop['profiles'] as List).first;
      }

      final reviews = List<Map<String, dynamic>>.from(responses[4] as List? ?? []);
      for (var r in reviews) {
        final profiles = r['profiles'];
        if (profiles is List && profiles.isNotEmpty) {
          r['profiles'] = profiles.first;
        }
      }

      return {
        'shop': shop,
        'doctors': responses[1] as List? ?? [],
        'appointments': responses[2] as List? ?? [],
        'departments': responses[3] as List? ?? [],
        'reviews': reviews,
        'media': responses[5] as Map<String, dynamic>? ?? {},
      };
    } catch (e) {
      debugPrint('Error fetching hospital details: $e');
      rethrow;
    }
  }

  Future<void> deleteDoctor(String doctorId) async {
    try {
      _setLoading(true);
      await _supabase.from('doctor_availability').delete().eq('doctor_id', doctorId);
      await _supabase.from('doctor_qualifications').delete().eq('doctor_id', doctorId);
      await _supabase.from('doctors').delete().eq('id', doctorId);
    } catch (e) {
      debugPrint('Delete Doctor Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleDoctorStatus(String doctorId, bool isDisabled) async {
    try {
      _setLoading(true);
      await _supabase.from('doctors').update({'is_disabled': isDisabled}).eq('id', doctorId);
    } catch (e) {
      debugPrint('Toggle Doctor Status Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }


  Future<Map<String, dynamic>> getShopDetails(String shopId) async {
    try {
      final futures = [
        _supabase.from('shops').select('*, profiles!owner_id(*)').eq('id', shopId).maybeSingle().then((v) => v),
        _supabase.from('products').select('*').eq('shop_id', shopId).then((v) => v),
        _supabase.from('offers').select('*').eq('shop_id', shopId).then((v) => v),
        _supabase.from('reviews').select('*, profiles(name, avatar_url)').eq('shop_id', shopId).then((v) => v),
        _supabase.from('working_days').select('*').eq('shop_id', shopId).then((v) => v),
        _supabase.from('media').select('*').eq('shop_id', shopId).maybeSingle().then((v) => v),
      ];

      final responses = await Future.wait(futures);
      var shop = responses[0] as Map<String, dynamic>?;
      if (shop != null && shop['profiles'] is List && (shop['profiles'] as List).isNotEmpty) {
        shop['profiles'] = (shop['profiles'] as List).first;
      }

      final reviews = List<Map<String, dynamic>>.from(responses[3] as List);
      for (var r in reviews) {
        if (r['profiles'] is List && (r['profiles'] as List).isNotEmpty) {
          r['profiles'] = (r['profiles'] as List).first;
        }
      }

      return {
        'shop': shop,
        'products': responses[1],
        'offers': responses[2],
        'reviews': reviews,
        'working_days': responses[4],
        'media': responses[5],
      };
    } catch (e) {
      debugPrint('Error fetching shop details: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFullUserDetails(String userId) async {
    try {
      final futures = [
        _supabase.from('profiles').select('*').eq('id', userId).maybeSingle().then((v) => v),
        _supabase.from('shops').select('*, profiles!owner_id(name)').eq('owner_id', userId).then((v) => v),
        _supabase.from('reviews').select('*, shops(name)').eq('user_id', userId).then((v) => v),
      ];

      final responses = await Future.wait(futures);
      
      return {
        'profile': responses[0] as Map<String, dynamic>?,
        'shops': responses[1] as List? ?? [],
        'reviews': responses[2] as List? ?? [],
      };
    } catch (e) {
      debugPrint('Error fetching user full details: $e');
      rethrow;
    }
  }

  /// Security Monitoring
  Future<List<Map<String, dynamic>>> getAdminSecurityLogs() async {
    try {
      final response = await _supabase
          .from('admin_security_log')
          .select('*')
          .order('login_time', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching admin security logs: $e');
      // If table doesn't exist yet, return empty list instead of crashing
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProfileLoginLogs() async {
    try {
      final response = await _supabase
          .from('profile_login_logs')
          .select('*')
          .order('login_time', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching profile login logs: $e');
      return [];
    }
  }

  /// Log Admin Login Activity
  /// Requirement: Record login activity only for admin accounts in "admin_security_log"
  Future<void> logAdminLogin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Check If User Is Admin (Requirement 2)
      final profileResponse = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      
      final role = profileResponse['role'];
      if (role != 'admin') return;

      // 2. Collect Login Metadata (Requirement 3)
      String? ipAddress;
      String location = 'Unknown';
      String userAgent = 'Unknown';
      String deviceType = 'Desktop';

      // Determine User Agent and Device (Requirement 3)
      userAgent = getUserAgent();
      
      if (userAgent.toLowerCase().contains('mobile') || 
          userAgent.toLowerCase().contains('android') || 
          userAgent.toLowerCase().contains('iphone') || 
          userAgent.toLowerCase().contains('ipad')) {
        deviceType = 'Mobile';
      } else {
        deviceType = 'Desktop';
      }

      // Fetch IP (Requirement 3)
      try {
        final ipResponse = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 5));
        if (ipResponse.statusCode == 200) {
          final data = jsonDecode(ipResponse.body);
          ipAddress = data['ip'];
        }
      } catch (e) {
        debugPrint('IP lookup failed: $e');
        // If IP lookup fails, store NULL (Requirement 5)
      }

      // Fetch Location (Requirement 3)
      if (ipAddress != null) {
        try {
          final locResponse = await http.get(Uri.parse('http://ip-api.com/json/$ipAddress')).timeout(const Duration(seconds: 5));
          if (locResponse.statusCode == 200) {
            final locData = jsonDecode(locResponse.body);
            if (locData['status'] == 'success') {
              location = "${locData['city']}, ${locData['country']}";
            }
          }
        } catch (e) {
          debugPrint('Location lookup failed: $e');
          // If location lookup fails, store "Unknown" (Requirement 5)
        }
      }

      // 3. Insert Login Record (Requirement 4)
      await _supabase.from('admin_security_log').insert({
        'admin_id': user.id,
        'login_time': DateTime.now().toIso8601String(),
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'device': deviceType,
        'location': location,
      });

      debugPrint('Admin login logged successfully for ${user.id}');
    } catch (e) {
      // Requirement 5: Logging failure must not block the login process
      debugPrint('Security logging failed: $e');
    }
  }
}
