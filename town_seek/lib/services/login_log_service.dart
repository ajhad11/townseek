import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/platform_utils.dart';

class LoginLogService {
  static final supabase = Supabase.instance.client;

  // Simple in-memory cache to avoid redundant lookups in the same session
  static String? _cachedIp;
  static String? _cachedLocation;

  /// Logs a login event for a user if they are a 'user'.
  static Future<void> logLogin(User user, {String? role}) async {
    // Run this in the background to avoid blocking the main UI/login flow
    _performLogging(user, role);
  }

  static Future<void> _performLogging(User user, String? providedRole) async {
    try {
      // 1. Check User Role (Use providedRole if available, otherwise fetch)
      String? role = providedRole;
      if (role == null) {
        final profileResponse = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        role = profileResponse['role'] as String?;
      }

      if (role != 'user') {
        debugPrint('LoginLogService: Skipping log for role: $role');
        return;
      }

      // 2. Collect Login Information in parallel with timeouts
      String? ipAddress = _cachedIp;
      String? location = _cachedLocation;

      if (ipAddress == null) {
        // Fetch IP and Location concurrently
        final results = await Future.wait([
          _getIPAddress(),
          // Location depends on IP, but we can try to fetch them separately if the API supports it
          // However, ip-api.com works without IP (it uses the request IP). 
          // So let's fetch both in parallel for speed.
          _getLocation(null), 
        ]);
        
        ipAddress = results[0];
        location = results[1];

        // Update cache
        _cachedIp = ipAddress;
        _cachedLocation = location;
      }

      final userAgent = _getUserAgent();
      final device = _getDeviceType(userAgent);

      // 3. Insert Login Log
      await supabase.from('profile_login_logs').insert({
        'user_id': user.id,
        'login_time': DateTime.now().toIso8601String(),
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'device': device,
        'location': location,
        'is_active': true,
      });

      debugPrint('LoginLogService: Login recorded for user ${user.id}');
    } catch (e) {
      debugPrint('LoginLogService Error during logLogin: $e');
      // Do not interrupt login flow as per requirements
    }
  }

  /// Marks the user's active session as inactive.
  static Future<void> logLogout(String userId) async {
    try {
      await supabase
          .from('profile_login_logs')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true);
      
      debugPrint('LoginLogService: Logout recorded for user $userId');
    } catch (e) {
      debugPrint('LoginLogService Error during logLogout: $e');
    }
  }

  static Future<String?> _getIPAddress() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'];
      }
    } catch (e) {
      debugPrint('LoginLogService: Failed to fetch IP: $e');
    }
    return 'Unknown';
  }

  static String _getUserAgent() {
    return PlatformUtils.getUserAgent();
  }

  static String _getDeviceType(String userAgent) {
    return PlatformUtils.getDeviceType();
  }

  static Future<String?> _getLocation(String? ip) async {
    // If ip is null, ip-api.com will use the requester's IP
    final url = ip == null || ip == 'Unknown' 
        ? 'http://ip-api.com/json/' 
        : 'http://ip-api.com/json/$ip';
        
    try {
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return '${data['city']}, ${data['country']}';
        }
      }
    } catch (e) {
      debugPrint('LoginLogService: Failed to fetch location: $e');
    }
    return 'Unknown';
  }
}
