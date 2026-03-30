import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/osm_service.dart';
import 'dart:async';
import '../data/shop_data.dart';
import '../widgets/shop_card.dart';
import '../utils/icon_helper.dart';
import '../screens/shop_page.dart';
import "package:url_launcher/url_launcher.dart";
import "package:cached_network_image/cached_network_image.dart";
import '../main.dart';

/// Location Page - OpenStreetMap Integration
class LocationPage extends StatefulWidget {
  final bool isSelecting;
  final String? initialQuery;
  final double? destLat;
  final double? destLng;
  final String? destName;
  final bool isVisible; // New property

  const LocationPage({
    super.key,
    this.isSelecting = false,
    this.initialQuery,
    this.destLat,
    this.destLng,
    this.destName,
    this.isVisible = true, // Default to true for standalone navigation
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> with SingleTickerProviderStateMixin, RouteAware {
  // ... (existing state) ...
  final LocationService _locationService = LocationService();
  final OSMService _osmService = OSMService();
  final MapController _mapController = MapController();

  // State
  Position? _currentPosition;
  List<OSMPlace> _searchResults = [];
  OSMPlace? _selectedDestination;
  List<LatLng> _routePoints = [];
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<Position>? _positionStream;
  LatLng _center = const LatLng(11.2588, 75.7804); // Default Calicut
  bool _isTracking = true;

  // Nearby Shops
  List<Shop> _nearbyShops = [];
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentShopIndex = 0;
  LatLng? _lastShopLoadCenter;
  bool _showSearchAreaButton = false;
  bool _hasNoResults = false;
  late AnimationController _directionsController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _initLocation();

    _directionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Increased from 600
    );

    _expandAnimation = CurvedAnimation(
      parent: _directionsController,
      curve: Curves.easeInOut,
    );

    // Initial animation trigger is now handled by didPush/didPopNext
  }

  @override
  void didUpdateWidget(LocationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startDirectionsHintAnimation();
    }
  }

  void _startDirectionsHintAnimation() {
    if (!mounted || widget.isSelecting) return;

    // Reset if already running or at end
    _directionsController.reset();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _directionsController.forward().then((_) {
          Future.delayed(const Duration(seconds: 5), () { // Increased from 3s
            if (mounted) {
              _directionsController.reverse();
            }
          });
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() {
    // Called when the route was pushed onto the navigator and is now the topmost route.
    _startDirectionsHintAnimation();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and the current route shows up.
    _startDirectionsHintAnimation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    _pageController.dispose();
    _directionsController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _initLocation() async {
    // 0. Check for initial query or destination
    if (widget.destLat != null && widget.destLng != null) {
      // We have a direct destination
      final dest = LatLng(widget.destLat!, widget.destLng!);
      _selectedDestination = OSMPlace(
        displayName: widget.destName ?? "Destination",
        lat: widget.destLat!,
        lon: widget.destLng!,
        address: {},
      );
      _searchController.text = widget.destName ?? "Destination";
      _isTracking = false;
      _center = dest;

      // Calculate route/load shops will happen after we get user position or via separate init
      // Let's set the map center to destination for now
    } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _onSearchChanged(widget.initialQuery!);
    }

    // 1. Get initial position
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          // Only center on user if we didn't search for something and have no destination
          if ((widget.initialQuery == null || widget.initialQuery!.isEmpty) &&
              widget.destLat == null) {
            _center = LatLng(position.latitude, position.longitude);
            _mapController.move(_center, 15.0);
            _loadNearbyShops(_center);
          } else if (widget.destLat != null) {
            // If we have destination, calculate route now that we have start pos
            _calculateRoute(
              LatLng(position.latitude, position.longitude),
              LatLng(widget.destLat!, widget.destLng!),
            );

            // Fit bounds to show both logic could go here, or just keep destination centered
            _mapController.move(LatLng(widget.destLat!, widget.destLng!), 15.0);
          }
        });
      }
    } else {
      // Just load mock shops around default center if no GPS and no search
      if (widget.initialQuery == null || widget.initialQuery!.isEmpty) {
        _loadNearbyShops(_center);
      }
    }

    // 2. Start tracking...
    _positionStream = _locationService.getPositionStream().listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        if (_isTracking &&
            (widget.initialQuery == null || widget.initialQuery!.isEmpty)) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom,
          );
        }
      }
    });
  }

  void _loadNearbyShops(LatLng center) {
    if (widget.isSelecting) return;

    // Filter shops with coordinates
    List<Shop> shops = ShopData.allShops
        .where((s) => s.latitude != null && s.longitude != null)
        .toList();

    // Sort by distance from THE CENTER provided
    shops.sort((a, b) {
      final distA = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        a.latitude!,
        a.longitude!,
      );
      final distB = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        b.latitude!,
        b.longitude!,
      );
      return distA.compareTo(distB);
    });

    // Take top 10
    setState(() {
      _nearbyShops = shops.take(10).toList();
      _lastShopLoadCenter = center;
      _showSearchAreaButton = false;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentShopIndex = index;
    });
    final shop = _nearbyShops[index];
    if (shop.latitude != null && shop.longitude != null) {
      _isTracking = false;
      _mapController.move(LatLng(shop.latitude!, shop.longitude!), 16.0);

      if (_currentPosition != null) {
        _calculateRoute(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(shop.latitude!, shop.longitude!),
        );
      }
    }
  }

  // ... (existing methods _onSearchChanged, _onSearchResultTap, etc.) ...
  void _onSearchChanged(String query) async {
    if (query.length > 2) {
      final results = await _osmService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _hasNoResults = results.isEmpty;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _hasNoResults = false;
        });
      }
    }
  }

  void _onSearchResultTap(OSMPlace place) async {
    FocusScope.of(context).unfocus();
    final dest = LatLng(place.lat, place.lon);

    // Move map and load shops around DESTINATION
    setState(() {
      _selectedDestination = place;
      _searchResults = [];
      _searchController.text = place.displayName;
      _isTracking = false;
    });

    _mapController.move(dest, 15.0);
    _loadNearbyShops(dest); // <--- LOAD SHOPS HERE

    if (!widget.isSelecting && _currentPosition != null) {
      _calculateRoute(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        dest,
      );
    }
  }

  Future<void> _calculateRoute(LatLng start, LatLng end) async {
    final points = await _osmService.getRoute(start, end);
    if (mounted) {
      setState(() {
        _routePoints = points;
      });
    }
  }

  Future<void> _openInGoogleMaps() async {
    final dest = _selectedDestination;
    Shop? shop;
    if (!widget.isSelecting && _nearbyShops.isNotEmpty) {
      shop = _nearbyShops[_currentShopIndex];
    }

    double? lat;
    double? lng;

    if (shop != null && shop.latitude != null && shop.longitude != null) {
      lat = shop.latitude;
      lng = shop.longitude;
    } else if (dest != null) {
      lat = dest.lat;
      lng = dest.lon;
    }

    if (lat != null && lng != null) {
      final Uri googleMapsUrl = Uri.parse(
        "google.navigation:q=$lat,$lng&mode=d",
      );
      final Uri webUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
      );

      try {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl);
        } else {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No destination selected to open in maps.'),
          ),
        );
      }
    }
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      setState(() {
        _isTracking = true;
      });
      final pos = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _mapController.move(pos, 17.0);
      _loadNearbyShops(pos); // Reload around user
    } else {
      _locationService.getCurrentPosition().then((pos) {
        if (pos != null && mounted) {
          setState(() {
            _currentPosition = pos;
            _isTracking = true;
          });
          final latLng = LatLng(pos.latitude, pos.longitude);
          _mapController.move(latLng, 17.0);
          _loadNearbyShops(latLng); // Reload around user
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Could not fetch GPS location. Please try again.",
                ),
              ),
            );
          }
        }
      });
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isTracking = false;
      _selectedDestination = OSMPlace(
        displayName: "Fetching address...",
        lat: point.latitude,
        lon: point.longitude,
        address: {},
      );
    });

    try {
      final place = await _osmService.getPlaceAt(point);

      if (mounted) {
        if (place != null) {
          setState(() {
            _selectedDestination = place;
            _searchController.text = place.displayName;
          });
        } else {
          // Fallback if address fetch fails/times out
          final fallbackName =
              "Location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})";
          setState(() {
            _selectedDestination = OSMPlace(
              displayName: fallbackName,
              lat: point.latitude,
              lon: point.longitude,
              address: {},
            );
            _searchController.text = fallbackName;
          });
        }
      }
    } catch (e) {
      // Fallback on error
      if (mounted) {
        final fallbackName =
            "Location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})";
        setState(() {
          _selectedDestination = OSMPlace(
            displayName: fallbackName,
            lat: point.latitude,
            lon: point.longitude,
            address: {},
          );
          _searchController.text = fallbackName;
        });
      }
    }

    if (!widget.isSelecting && _currentPosition != null) {
      _calculateRoute(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        point,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _isTracking = false;
                  });

                  // Check distance from last loaded center
                  final lastCenter = _lastShopLoadCenter;
                  final currentCenter = position.center;

                  if (lastCenter != null && currentCenter != null) {
                    final dist = Geolocator.distanceBetween(
                      currentCenter.latitude,
                      currentCenter.longitude,
                      lastCenter.latitude,
                      lastCenter.longitude,
                    );

                    if (dist > 500 &&
                        !_showSearchAreaButton &&
                        !widget.isSelecting) {
                      // moved > 500m
                      setState(() {
                        _showSearchAreaButton = true;
                      });
                    }
                  }
                }
              },
              onTap: _handleMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.townseek.app',
              ),

              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF4285F4),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // Nearby Shops Markers
                  ...() {
                    List<Marker> markers = [];
                    Marker? selectedMarker;

                    for (int i = 0; i < _nearbyShops.length; i++) {
                      final shop = _nearbyShops[i];
                      final isSelected = i == _currentShopIndex;

                      final marker = Marker(
                        point: LatLng(shop.latitude!, shop.longitude!),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              decoration: BoxDecoration(
                                color: IconHelper.getColor(
                                  shop.category,
                                  shop.tags,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                IconHelper.getIcon(shop.category, shop.tags),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      );

                      if (isSelected) {
                        selectedMarker = marker;
                      } else {
                        markers.add(marker);
                      }
                    }

                    if (selectedMarker != null) {
                      markers.add(selectedMarker);
                    }

                    return markers;
                  }(),

                  // User Location Marker
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4285F4,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4285F4),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Destination Marker
                  if (_selectedDestination != null)
                    Marker(
                      point: LatLng(
                        _selectedDestination!.lat,
                        _selectedDestination!.lon,
                      ),
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFEA4335),
                            size: 50,
                          ),
                          Positioned(
                            top: 15,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB31412),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Search Bar
          Positioned(
            top: 50,
            left: Navigator.canPop(context) ? 80 : 20, // Adjust for back button
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search dest or area...",
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _selectedDestination = null;
                                  _routePoints = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty || _hasNoResults)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: _hasNoResults
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No location found within India.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey,
                                ),
                                title: Text(
                                  place.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _onSearchResultTap(place),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          // "Search This Area" Button
          if (_showSearchAreaButton && !widget.isSelecting)
            Positioned(
              top: 120, // Below search bar
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _loadNearbyShops(_mapController.camera.center);
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Search this area"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2962FF),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),

          // User Instruction Banner for Selection Mode
          if (widget.isSelecting)
            Positioned(
              bottom: _selectedDestination != null
                  ? 100
                  : 30, // Above confirm button if visible
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tap anywhere on the map to pin a location",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Back Button (if pushed)
          if (Navigator.canPop(context))
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

          // 3. Action Buttons (Moved up to accommodate slider and view all button)
          Positioned(
            bottom: widget.isSelecting ? 100 : 250,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (!widget.isSelecting) ...[
                  FloatingActionButton.small(
                    heroTag: "refresh_map",
                    backgroundColor: Colors.white,
                    onPressed: () {
                      final center = _mapController.camera.center;
                      _loadNearbyShops(center);
                      _startDirectionsHintAnimation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Map refreshed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Icon(Icons.refresh, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                ],
                FloatingActionButton(
                  heroTag: "my_location",
                  backgroundColor: Colors.white,
                  onPressed: _centerOnUser,
                  child: Icon(
                    Icons.my_location,
                    color: _isTracking
                        ? const Color(0xFF2962FF)
                        : Colors.black54,
                  ),
                ),
                if (!widget.isSelecting) ...[
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openInGoogleMaps,
                      borderRadius: BorderRadius.circular(28),
                      child: AnimatedBuilder(
                        animation: _expandAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 56,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 + (12 * _expandAnimation.value),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2962FF),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions, color: Colors.white),
                                if (_expandAnimation.value > 0.1)
                                  Flexible(
                                    child: ClipRect(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _expandAnimation.value,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text(
                                            "Get Directions",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Nearby Shops Slider and View All button
          if (!widget.isSelecting && _nearbyShops.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20, bottom: 5),
                    child: GestureDetector(
                      onTap: _showNearbyListSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View all",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2962FF),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.list,
                              size: 18,
                              color: Color(0xFF2962FF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 140, // Height for ShopCard
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _nearbyShops.length,
                      itemBuilder: (context, index) {
                        final shop = _nearbyShops[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShopPage(
                                    title: shop.title,
                                    subtitle: shop.subtitle,
                                    rating: shop.rating,
                                    tags: shop.tags,
                                    imageUrl: shop.imageUrl,
                                    isOpen: shop.isOpen,
                                    location: shop.subtitle,
                                    latitude: shop.latitude,
                                    longitude: shop.longitude,
                                    id: shop.id,
                                    ownerId: shop.ownerId,
                                    category: shop.category,
                                  ),
                                ),
                              );
                            },
                            child: ShopCard(
                              imageUrl: shop.imageUrl,
                              title: shop.title,
                              subtitle:
                                  shop.location ??
                                  shop.subtitle, // Display location on map cards
                              rating: shop.rating,
                              tags: shop.tags,
                              isOpen: shop.isOpen,
                              category: shop.category,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // 5. Confirm Location (Only when selecting)
          if (widget.isSelecting && _selectedDestination != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 80,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedDestination);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Confirm Location",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNearbyListSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(
        0xFF1E2124,
      ), // Dark background mimicking Google Maps dark theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Nearby places",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _nearbyShops.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 64,
                    ),
                    itemBuilder: (context, index) {
                      final shop = _nearbyShops[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: shop.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: shop.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 60,
                                        height: 60,
                                        color: IconHelper.getColor(
                                          shop.category,
                                        ).withValues(alpha: 0.15),
                                        child: Icon(
                                          IconHelper.getIcon(
                                            shop.category,
                                            shop.tags,
                                          ),
                                          color: IconHelper.getColor(
                                            shop.category,
                                          ),
                                          size: 30,
                                        ),
                                      ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: IconHelper.getColor(
                                    shop.category,
                                  ).withValues(alpha: 0.15),
                                  child: Icon(
                                    IconHelper.getIcon(
                                      shop.category,
                                      shop.tags,
                                    ),
                                    color: IconHelper.getColor(shop.category),
                                    size: 30,
                                  ),
                                ),
                        ),
                        title: Text(
                          shop.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              shop.location ?? shop.subtitle,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  shop.rating,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  shop.isOpen ? "OPEN" : "CLOSED",
                                  style: TextStyle(
                                    color: shop.isOpen
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          // Close the bottom sheet
                          Navigator.pop(context);
                          // Focus the shop on the map using the page controller
                          // (this will automatically slide the cards and move the map via _onPageChanged)
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
