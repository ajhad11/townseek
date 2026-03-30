/// Custom Header Widget
///
/// Displays the app header with location information, profile picture,
/// and search functionality. Features a blue gradient background with
/// rounded bottom corners.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../screens/profile_page.dart';
import '../search/shop_search_delegate.dart';
import '../data/user_manager.dart'; // Import UserManager
import '../services/location_service.dart';
import '../services/osm_service.dart';
import '../screens/location_page.dart';
import '../screens/qr_scanner_page.dart';
import 'dart:async';

// ---------------------------------------------------------------------------
// Cached location singleton — prevents GPS re-fetch on every category page
// ---------------------------------------------------------------------------
class _LocationCache {
  static final _LocationCache _instance = _LocationCache._internal();
  factory _LocationCache() => _instance;
  _LocationCache._internal();

  String locationText = "Locating...";
  String locationLabel = "Current Location";
  bool hasFetched = false; // true once GPS has been tried at least once
  bool userOverrode = false; // true when user manually picked a location
}

class CustomHeader extends StatefulWidget {
  final bool showBackButton;
  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onSearchTap;

  const CustomHeader({
    super.key,
    this.showBackButton = false,
    this.title,
    this.onBack,
    this.onSearchTap,
  });

  @override
  State<CustomHeader> createState() => CustomHeaderState();
}

class CustomHeaderState extends State<CustomHeader> {
  final _cache = _LocationCache();

  String get _locationText => _cache.locationText;
  String get _locationLabel => _cache.locationLabel;

  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.title == null) {
      // Only fetch GPS if we have never fetched AND user hasn't manually overridden
      if (!_cache.hasFetched && !_cache.userOverrode) {
        _fetchLocation();
      }

      if (!kIsWeb) {
        _serviceStatusStreamSubscription = Geolocator.getServiceStatusStream().listen(
          (ServiceStatus status) {
            if (status == ServiceStatus.enabled) {
              if (!_cache.userOverrode) {
                 _fetchLocation();
              }
            } else if (status == ServiceStatus.disabled) {
              if (mounted && !_cache.userOverrode) {
                setState(() {
                  _cache.locationLabel = "Location Services Disabled";
                  _cache.locationText = "Tap to enable location";
                });
              }
            }
          }
        );
      }
    }
  }

  @override
  void dispose() {
    _serviceStatusStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> refreshLocation() async {
    await _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final locationService = LocationService();
    final osmService = OSMService();

    final position = await locationService.getCurrentPosition();
    _cache.hasFetched = true;

    if (position != null && mounted) {
      final place = await osmService.getPlaceAt(
        LatLng(position.latitude, position.longitude),
      );
      if (place != null && mounted) {
        setState(() {
          _cache.locationText = place.cityCountry;
          _cache.locationLabel = "Current Location";
        });
      } else if (mounted) {
        setState(() {
          _cache.locationText = "Unknown Location";
          _cache.locationLabel = "Current Location";
        });
      }
    } else if (mounted) {
      // Location off or permission denied — show in-line prompt instead of dialog
      setState(() {
        _cache.locationLabel = "Location Services Disabled";
        _cache.locationText = "Tap to enable location";
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2962FF),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFf7f7f7), // The stroke color
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.only(
          bottom: 1,
        ), // Thickness of the bottom stroke
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A47CC), Color(0xFF2962FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(29),
              bottomRight: Radius.circular(29),
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 20,
                  right: 20,
                  bottom: 25,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Back Button (if enabled)
                    if (widget.showBackButton)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: GestureDetector(
                          onTap: widget.onBack ?? () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                    // Top Row: Location/Title/Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Location Text OR Title
                        if (widget.title != null)
                          Expanded(
                            child: Text(
                              widget.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              
                              if (kIsWeb) {
                                // On web, we don't try to open settings or check permissions 
                                // because geolocator's native dialogs aren't implemented.
                                // Just proceed to manual selection if needed.
                              } else {
                                // Mobile/Desktop logic for requesting permissions/settings
                                if (_locationText == "Tap to enable location") {
                                  final permission = await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                                      await Geolocator.requestPermission();
                                  } else if (!await Geolocator.isLocationServiceEnabled()) {
                                      await Geolocator.openLocationSettings();
                                  }
                                  // Attempt to refetch
                                  await _fetchLocation();
                                  if (_cache.locationText != "Tap to enable location") {
                                    return; // Successfully fetched, no need to open manual selector yet
                                  }
                                }
                              }

                              if (!mounted) return;
                              final result = await navigator.push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LocationPage(isSelecting: true),
                                ),
                              );

                              if (result != null &&
                                  result is OSMPlace &&
                                  mounted) {
                                setState(() {
                                  _cache.locationText = result.cityCountry;
                                  _cache.locationLabel = "User Location";
                                  _cache.userOverrode =
                                      true; // prevent GPS overriding user choice
                                });
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _locationLabel,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _locationText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        // Profile Picture and Scanner
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const QRScannerPage(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        const ProfilePage(),
                                  ),
                                );
                              },
                          child: ListenableBuilder(
                            listenable: UserManager.instance,
                            builder: (context, child) {
                              final user = UserManager.instance;
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white24,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                  image: DecorationImage(
                                    image: user.localImageFile != null
                                        ? FileImage(user.localImageFile!)
                                              as ImageProvider
                                        : NetworkImage(user.profileImage),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ],
                      ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar - full width below the location text
                    GestureDetector(
                      onTap:
                          widget.onSearchTap ??
                          () {
                            showSearch(
                              context: context,
                              delegate: ShopSearchDelegate(),
                            );
                          },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search...",
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(
                                  left: 10.0,
                                  right: 10.0,
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
