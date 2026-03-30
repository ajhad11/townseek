import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class OSMService {
  /// Search for places using Nominatim API
  Future<List<OSMPlace>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=in',
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'TownSeek/1.0', 
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => OSMPlace.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('OSM Search Error: $e');
    }
    return [];
  }

  /// Get Route using OSRM API (Driving)
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        final coordinates = geometry['coordinates'] as List;

        return coordinates.map((coord) {
          return LatLng(coord[1], coord[0]); // GeoJSON is [long, lat]
        }).toList();
      }
    } catch (e) {
      debugPrint('OSM Route Error: $e');
    }
    return [];
  }

  /// Get Optimized Trip using OSRM API (Driving)
  Future<Map<String, dynamic>?> getOptimizedTrip(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    final coordinatesString = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = Uri.parse(
      'http://router.project-osrm.org/trip/v1/driving/$coordinatesString?source=first&destination=last&roundtrip=false&overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final trip = data['trips'][0];
        final geometry = trip['geometry'];
        final coordinates = geometry['coordinates'] as List;
        final waypointsResult = data['waypoints'] as List;
        
        final routeCoordinates = coordinates.map((coord) {
          return LatLng(coord[1], coord[0]); // GeoJSON is [long, lat]
        }).toList();

        // Sort waypoints by their optimized index
        waypointsResult.sort((a, b) => (a['waypoint_index'] as int).compareTo(b['waypoint_index'] as int));
        
        // Ensure distance and duration are returned
        final distance = trip['distance']; // in meters
        final duration = trip['duration']; // in seconds

        return {
          'coordinates': routeCoordinates,
          'distance': distance,
          'duration': duration,
          'optimized_waypoints': waypointsResult,
        };
      }
    } catch (e) {
      debugPrint('OSM Trip Optimization Error: $e');
    }
    return null;
  }
  /// Get Place details from LatLng (Reverse Geocoding)
  Future<OSMPlace?> getPlaceAt(LatLng point) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&addressdetails=1',
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'TownSeek/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OSMPlace.fromJson(data);
      }
    } catch (e) {
      debugPrint('OSM Reverse Geocode Error: $e');
    }
    return null;
  }
}

class OSMPlace {
  final String displayName;
  final double lat;
  final double lon;
  final Map<String, dynamic> address;

  OSMPlace({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.address,
  });

  factory OSMPlace.fromJson(Map<String, dynamic> json) {
    return OSMPlace(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      address: json['address'] ?? {},
    );
  }

  String get cityCountry {
    final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? '';
    final country = address['country'] ?? '';
    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return displayName.split(',').first; // Fallback
  }
}
