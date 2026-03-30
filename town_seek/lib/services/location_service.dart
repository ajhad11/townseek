import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check and request location permissions.
  /// On web, we skip the native permission check entirely because
  /// Geolocator's native APIs (isLocationServiceEnabled, etc.) are not
  /// implemented on web — the browser handles geolocation natively.
  Future<bool> checkPermission() async {
    if (kIsWeb) return true; // Let browser handle its own prompt

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    try {
      if (!kIsWeb) {
        // First try last known position for near-instant loading (mobile only)
        Position? position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          return position;
        }
      }

      // Fetch current position (works on both web and mobile)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get live position stream
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
