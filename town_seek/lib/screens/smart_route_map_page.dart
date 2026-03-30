import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SmartRouteMapPage extends StatefulWidget {
  final Map<String, dynamic> routeData;
  final Position userLocation;

  const SmartRouteMapPage({
    super.key,
    required this.routeData,
    required this.userLocation,
  });

  @override
  State<SmartRouteMapPage> createState() => _SmartRouteMapPageState();
}

class _SmartRouteMapPageState extends State<SmartRouteMapPage> {
  final MapController _mapController = MapController();
  List<LatLng> _routeCoordinates = [];
  List<Map<String, dynamic>> _orderedShops = [];
  double _totalDistance = 0.0;
  double _totalDuration = 0.0; // In seconds
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _parseRouteData();
  }

  void _parseRouteData() {
    setState(() {
      _routeCoordinates = List<LatLng>.from(widget.routeData['coordinates']);
      _totalDistance = (widget.routeData['distance'] as num).toDouble();
      _totalDuration = (widget.routeData['duration'] as num).toDouble();
      _orderedShops = List<Map<String, dynamic>>.from(widget.routeData['orderedShops']);

      // Calculate total cost
      _totalCost = _orderedShops.fold(0.0, (sum, shop) => sum + (shop['totalCost'] as double));
    });
  }

  Future<void> _openGoogleMaps() async {
    // Generate waypoints link
    if (_orderedShops.isEmpty) return;

    final origin = '${widget.userLocation.latitude},${widget.userLocation.longitude}';
    final destination = '${_orderedShops.last['latitude']},${_orderedShops.last['longitude']}';
    
    // Middle waypoints
    final waypoints = _orderedShops
        .take(_orderedShops.length - 1)
        .map((shop) => '${shop['latitude']},${shop['longitude']}')
        .join('|');

    final urlStr = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&waypoints=$waypoints&travelmode=driving';
    final url = Uri.parse(urlStr);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open Google Maps')),
           );
        }
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Route Map', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.town_seek',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routeCoordinates,
                    color: const Color(0xFF2962FF),
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker
                  Marker(
                    point: LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                  ),
                  // Shop Markers
                  ..._orderedShops.asMap().entries.map((entry) {
                    final index = entry.key;
                    final shop = entry.value;
                    return Marker(
                      point: LatLng((shop['latitude'] as num).toDouble(), (shop['longitude'] as num).toDouble()),
                      width: 40,
                      height: 40,
                      child: Stack(
                         alignment: Alignment.center,
                         children: [
                            const Icon(Icons.location_on, color: Colors.red, size: 40),
                            Positioned(
                               top: 6,
                               child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                               ),
                            ),
                         ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Bottom Summary Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildSummarySheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.1),
             blurRadius: 10,
             offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle for sliding (purely visual for now)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Expanded(child: Text('Smart Shopping Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                   const SizedBox(width: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                        '${(_totalDistance / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.bold),
                     ),
                  )
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                 'Est. Time: ${(_totalDuration / 60).toStringAsFixed(0)} mins • Cost: ₹${_totalCost.toStringAsFixed(0)}',
                 style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Stops List
            Flexible(
               child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.separated(
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     shrinkWrap: true,
                     itemCount: _orderedShops.length,
                     separatorBuilder: (context, index) => const Divider(),
                     itemBuilder: (context, index) {
                        final shop = _orderedShops[index];
                        final items = shop['itemsToBuy'] as List;
                        final itemNames = items.map((i) => i['name']).join(' + ');
                        
                        return Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Container(
                                 width: 28,
                                 height: 28,
                                 decoration: const BoxDecoration(
                                    color: Color(0xFF2962FF),
                                    shape: BoxShape.circle,
                                 ),
                                 child: Center(
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                 ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                 child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       Text(
                                          shop['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                       ),
                                       const SizedBox(height: 2),
                                       Text(
                                          itemNames,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                       ),
                                    ],
                                 ),
                              ),
                           ],
                        );
                     },
                  ),
               ),
            ),
            
            const SizedBox(height: 16),
            
            // Navigation Button
            Padding(
               padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
               child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                     onPressed: _openGoogleMaps,
                     icon: const Icon(Icons.navigation, color: Colors.white),
                     label: const Text('Navigate with Google Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                     style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                  ),
               ),
            ),
          ],
        ),
      ),
    );
  }
}
