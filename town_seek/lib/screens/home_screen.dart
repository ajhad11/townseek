/// Home Screen for Town Seek App
///
/// This file contains the main home screen implementation for the Town Seek application,
/// a local services and shopping discovery app. The screen displays various sections
/// including location header, service categories, promotional banners, nearby shops,
/// and bottom navigation.
///
/// Features:
/// - Scrollable content with multiple sections
/// - Interactive bottom navigation (currently visual only)
/// - Network image loading with error handling
/// - Responsive design with proper spacing and shadows
/// - Custom UI components for consistent branding
library;

import 'package:flutter/material.dart';
import 'package:town_seek/widgets/custom_header.dart';
import 'groceries_page.dart';
import 'food_page.dart';
import 'fashion_page.dart';
import 'health_page.dart';
import 'services_page.dart';
import 'finance_page.dart';
import 'animals_page.dart';
import 'education_page.dart';
import 'religious_page.dart';
import 'entertainment_page.dart';
import 'public_services_page.dart';
import 'commercial_page.dart';
import 'hospital_category_page.dart';
import 'shop_page.dart';

import 'service_details_page.dart';
import 'hospital_details_page.dart';
import 'smart_route_input_page.dart';
import '../widgets/shop_card.dart';
import '../data/shop_data.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Main Home Screen Widget
///
/// This is the primary screen of the Town Seek app, displaying a scrollable
/// interface with various sections for local service discovery.


// ... (imports)

import '../widgets/home_skeleton.dart';
import '../data/wishlist_manager.dart'; // Added for initialization
import 'dart:async';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _isFirstLoad = true; // Static to track across tab switches
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    if (_isFirstLoad) {
      _isLoading = true;
      ShopData.fetchShops().then((_) async {
        await WishlistManager().loadWishlist(); // Sync wishlist immediately after shops are ready
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isFirstLoad = false;
          });
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      ShopData.fetchShops(),
      WishlistManager().loadWishlist(),
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const HomeSkeleton();
    }

    return Scaffold(
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF2962FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    const CategoriesSection(),
                    const SizedBox(height: 20),
                    const OffersSlideshow(),
                    const SizedBox(height: 20),
                    NearbyShopsList(shops: ShopData.allShops),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom navigation logic removed




// ---------------------------------------------------------------------------
// 2. Categories Section
// ---------------------------------------------------------------------------
/// Categories Section Widget
///
/// Displays horizontal row of service categories (Groceries, Food, Fashion, Health)
/// with colored icons and labels. Each category is represented as a circular
/// button with shadow effects.
class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  final List<Map<String, dynamic>> _categories = const <Map<String, dynamic>>[
    {'name': 'Smart Route', 'icon': Icons.route, 'iconColor': Color(0xFF00C853)}, // Green
    {'name': 'Groceries', 'icon': Icons.shopping_basket, 'iconColor': Colors.orange},
    {'name': 'Food', 'icon': Icons.fastfood, 'iconColor': Colors.green},
    {'name': 'Fashion', 'icon': Icons.shopping_bag, 'iconColor': Colors.purple},
    {'name': 'Health', 'icon': Icons.medical_services, 'iconColor': Colors.blue},
    {'name': 'Services', 'icon': Icons.handyman, 'iconColor': Colors.red},
    {'name': 'Finance', 'icon': Icons.account_balance, 'iconColor': Color(0xFF1B5E20)},
    {'name': 'Animals', 'icon': Icons.pets, 'iconColor': Color(0xFF795548)},
    {'name': 'Education', 'icon': Icons.school, 'iconColor': Color(0xFFFBC02D)},
    {'name': 'Religious', 'icon': Icons.temple_buddhist, 'iconColor': Color(0xFFE65100)}, // Dark Orange
    {'name': 'Entertainment', 'icon': Icons.local_movies, 'iconColor': Color(0xFFE91E63)}, // Pink
    {'name': 'Public Services', 'icon': Icons.account_balance, 'iconColor': Color(0xFF607D8B)}, // Blue Grey
    {'name': 'Commercial', 'icon': Icons.storefront, 'iconColor': Color(0xFF795548)}, // Brown
    {'name': 'Hospital', 'icon': Icons.local_hospital, 'iconColor': Color(0xFFD32F2F)}, // Red
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _categories.map<Widget>((Map<String, dynamic> cat) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10), // Add padding between items
              child: GestureDetector(
                onTap: () {
                  // Navigate to the appropriate page based on category name
                  switch (cat['name'] as String) {
                    case 'Groceries':
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const GroceriesPage(),
                        ),
                      );
                      break;
                    case 'Food':
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const FoodPage(),
                        ),
                      );
                      break;
                    case 'Fashion':
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const FashionPage(),
                        ),
                      );
                      break;
                    case 'Health':
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const HealthPage(),
                        ),
                      );
                      break;
                    case 'Services':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const ServicesPage(),
                        ),
                      );
                      break;
                    case 'Finance':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const FinancePage(),
                        ),
                      );
                      break;
                    case 'Animals':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const AnimalsPage(),
                        ),
                      );
                      break;
                    case 'Education':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const EducationPage(),
                        ),
                      );
                      break;
                    case 'Religious':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const ReligiousPage(),
                        ),
                      );
                      break;
                    case 'Entertainment':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const EntertainmentPage(),
                        ),
                      );
                      break;
                    case 'Public Services':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const PublicServicesPage(),
                        ),
                      );
                      break;
                    case 'Commercial':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const CommercialPage(),
                        ),
                      );
                      break;
                    case 'Hospital':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const HospitalCategoryPage(),
                        ),
                      );
                      break;
                    case 'Smart Route':
                       Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const SmartRouteInputPage(),
                        ),
                      );
                      break;
                  }
                },
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0x80D9D9D9),
                          width: 1,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        cat['icon']! as IconData,
                        color: cat['iconColor']! as Color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name']! as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Offers Slideshow Section
// ---------------------------------------------------------------------------
/// Offers Slideshow Widget
///
/// Displays a dynamic slideshow of offers from the nearest shops.
/// Excludes religious and public services. Shows one poster per shop up to 7 nearest shops.
/// Each slide stays for 5 seconds.
class OffersSlideshow extends StatefulWidget {
  const OffersSlideshow({super.key});

  @override
  State<OffersSlideshow> createState() => _OffersSlideshowState();
}

class _OffersSlideshowState extends State<OffersSlideshow> with WidgetsBindingObserver {
  Position? _userPosition;
  bool _isLoading = true;
  List<Map<String, dynamic>> _offersSlides = [];
  int _currentIndex = 0;
  Timer? _timer;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationAndFetchOffers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_offersSlides.isEmpty && !_isLoading) {
         _initLocationAndFetchOffers();
      }
    }
  }

  Future<void> _initLocationAndFetchOffers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final hasPermission = await LocationService().checkPermission();
    if (!hasPermission) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final position = await LocationService().getCurrentPosition();
      _userPosition = position;
      await _fetchNearestOffers();
    } catch (e) {
      debugPrint("Error getting location for slideshow: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearestOffers() async {
    if (_userPosition == null || !mounted) return;

    try {
      // 1. Get all shops, exclude religious
      List<Shop> validShops = ShopData.allShops.where((shop) {
        final cat = shop.category?.toLowerCase() ?? '';
        return cat != 'religious';
      }).toList();

      // 2. Sort by distance
      validShops.sort((a, b) {
        final distA = Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, a.latitude ?? 0, a.longitude ?? 0);
        final distB = Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, b.latitude ?? 0, b.longitude ?? 0);
        return distA.compareTo(distB);
      });

      // 3. Extract IDs in order (UUID strings)
      final sortedShopIds = validShops
          .map((s) => s.id)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      if (sortedShopIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 4. Fetch offers
      // We'll fetch active offers for these shops natively without strict joins to prevent query failures. 
      final response = await Supabase.instance.client
          .from('offers')
          .select()
          .inFilter('shop_id', sortedShopIds)
          // Ensure it has a poster
          .not('poster', 'is', null)
          .neq('poster', '')
          .order('created_at', ascending: false);

      final List<dynamic> rawOffers = response;

      // 5. Pick exactly ONE latest offer per shop, up to 7 nearest shops
      List<Map<String, dynamic>> finalSlides = [];
      Set<String> processedShopIds = {};

      // Since we want them ordered by *distance of the shop*, we iterate the sortedShopIds
      for (final shopId in sortedShopIds) {
         if (finalSlides.length >= 7) break;
         
         // Find the latest offer for this shop from the fetched offers
         // Since rawOffers is ordered by created_at DESC, the first one we find is the latest.
         final shopOffer = rawOffers.cast<Map<String, dynamic>>().firstWhere(
           (o) => o['shop_id'].toString() == shopId.toString(),
           orElse: () => <String, dynamic>{}, // Return empty map if not found
         );

         if (shopOffer.isNotEmpty) {
            // Found an offer for this shop, add to slides
            final shop = validShops.firstWhere((s) => s.id == shopId.toString());
            finalSlides.add({
               'offer': shopOffer,
               'shop': shop,
            });
            processedShopIds.add(shopId.toString());
         }
      }

      if (mounted) {
        setState(() {
          _offersSlides = finalSlides;
          _isLoading = false;
        });

        if (_offersSlides.length > 1) {
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint("Error fetching nearest offers: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients) {
        int nextPage = _currentIndex + 1;
        if (nextPage >= _offersSlides.length) {
          nextPage = 0;
          _pageController.jumpToPage(nextPage);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[300],
          ),
        ),
      );
    }

    if (_offersSlides.isEmpty) {
      // Default banner when no nearby offers are found
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circle top-right
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('🎉 Welcome', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Discover local businesses\nnear you!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore shops, services & more',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Right icon
              const Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.store_mall_directory_rounded, size: 60, color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _offersSlides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slideInfo = _offersSlides[index];
                  final offer = slideInfo['offer'];
                  final Shop shop = slideInfo['shop'];

                  return GestureDetector(
                    onTap: () async {
                      bool isHospital = (shop.category?.toLowerCase() == 'hospital') || shop.tags.any((t) => ['Emergency', 'Pharmacy', 'OPD', 'Maternity', 'ICU', 'Pediatrics'].contains(t));

                      if (isHospital) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HospitalDetailsPage(shop: shop),
                            ),
                          );
                      } else if (shop.services != null && shop.services!.isNotEmpty) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceDetailsPage(
                                shop: shop,
                                initialTabIndex: 1,
                              ),
                            ),
                          );
                      } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => ShopPage(
                                title: shop.title,
                                subtitle: shop.subtitle,
                                rating: shop.rating,
                                tags: shop.tags,
                                imageUrl: shop.imageUrl,
                                isOpen: shop.isOpen,
                                openingTime: shop.openingTime,
                                closingTime: shop.closingTime,
                                googleMapsLink: shop.googleMapsLink,
                                description: shop.description,
                                location: shop.location,
                                distance: "", // No distance passed here since it's from banner
                                phone: shop.phone,
                                email: shop.email,
                                latitude: shop.latitude,
                                longitude: shop.longitude,
                                workingDays: shop.workingDays,
                                id: shop.id,
                                ownerId: shop.ownerId,
                                category: shop.category,
                                openNowOverride: shop.openNowOverride,
                                initialTabIndex: 1,
                              ),
                            ),
                          );
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Poster
                        Image.network(
                          offer['poster'],
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image)),
                        ),
                        
                        // Dark Gradient Overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Text Content
                        Positioned(
                          left: 16,
                          bottom: 24,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer['offer_title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.storefront, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      shop.title,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (_offersSlides.length > 1)
            Positioned(
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_offersSlides.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? const Color(0xFF2962FF) : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Nearby Shops List
// ---------------------------------------------------------------------------

/// Nearby Shops List Widget
///
/// Displays a vertical list of nearby shops with their information.
/// Includes section header and individual shop cards.
class NearbyShopsList extends StatefulWidget {
  final List<Shop> shops;

  const NearbyShopsList({super.key, required this.shops});

  @override
  State<NearbyShopsList> createState() => _NearbyShopsListState();
}

class _NearbyShopsListState extends State<NearbyShopsList> with WidgetsBindingObserver {
  Position? _userPosition;
  bool _isLoadingLocation = true;
  List<Shop> _sortedShops = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationAndSort();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initLocationAndSort();
    }
  }

  @override
  void didUpdateWidget(NearbyShopsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shops != widget.shops) {
      _sortShops();
    }
  }

  Future<void> _initLocationAndSort() async {
    // Check permission status explicitly
    final hasPermission = await LocationService().checkPermission();
    
    if (!hasPermission) {
      return;
    }

    try {
      final position = await LocationService().getCurrentPosition();
      if (mounted) {
        setState(() {
          _userPosition = position;
          _isLoadingLocation = false;
          _sortShops();
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _sortShops(); 
        });
      }
    }
  }


  
  void _sortShops() {
    List<Shop> shops = List.from(widget.shops);

    if (_userPosition != null) {
      shops.sort((a, b) {
        final distA = _calculateDistance(a.latitude, a.longitude);
        final distB = _calculateDistance(b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
    }
    
    setState(() {
       _sortedShops = shops;
    });
  }

  double _calculateDistance(double? lat, double? lng) {
    if (_userPosition == null || lat == null || lng == null) return double.maxFinite;
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    );
  }

  String _formatDistance(double? lat, double? lng) {
    if (_userPosition == null || lat == null || lng == null) return "";
    final distanceMeters = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    );
    
    if (distanceMeters < 1000) {
      return "${distanceMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distanceMeters / 1000).toStringAsFixed(1)} km";
    }
  }

  @override
  Widget build(BuildContext context) {
    // If waiting for location, we can show a loader or just show unsorted. 
    // Showing unsorted/loading is better than nothing.
    final shopsToShow = _isLoadingLocation && _sortedShops.isEmpty ? widget.shops : _sortedShops;

    if (shopsToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: <Widget>[
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Shops',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                 if (_userPosition != null)
                  const Text(
                    "Sorted by distance",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15), // Space between header and list
        // List Items
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 700;
              
              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    mainAxisExtent: 130, // Approximate height of ShopCard
                  ),
                  itemCount: shopsToShow.length,
                  itemBuilder: (context, index) {
                    return _buildShopListItem(shopsToShow[index]);
                  },
                );
              } else {
                return Column(
                  children: shopsToShow.map<Widget>((Shop shop) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildShopListItem(shop),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopListItem(Shop shop) {
    final distanceString = _formatDistance(shop.latitude, shop.longitude);
    final locationText = (shop.location != null && shop.location!.trim().isNotEmpty)
        ? shop.location!
        : shop.subtitle;
    final subtitle = distanceString.isNotEmpty ? "$locationText • $distanceString" : locationText;

    return GestureDetector(
      onTap: () async {
        bool isHospital = (shop.category?.toLowerCase() == 'hospital') ||
            shop.tags.any((t) => [
                  'Emergency',
                  'Pharmacy',
                  'OPD',
                  'Maternity',
                  'ICU',
                  'Pediatrics'
                ].contains(t));

        if (isHospital) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HospitalDetailsPage(shop: shop),
            ),
          );
        } else if (shop.services != null && shop.services!.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailsPage(shop: shop),
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopPage(
                title: shop.title,
                subtitle: shop.subtitle,
                rating: shop.rating,
                tags: shop.tags,
                imageUrl: shop.imageUrl,
                isOpen: shop.isOpen,
                openingTime: shop.openingTime,
                closingTime: shop.closingTime,
                googleMapsLink: shop.googleMapsLink,
                description: shop.description,
                location: shop.location,
                distance: distanceString,
                phone: shop.phone,
                email: shop.email,
                latitude: shop.latitude,
                longitude: shop.longitude,
                workingDays: shop.workingDays,
                id: shop.id,
                ownerId: shop.ownerId,
                category: shop.category,
                openNowOverride: shop.openNowOverride,
              ),
            ),
          );
        }
        if (mounted) setState(() {});
      },
      child: ShopCard(
        imageUrl: shop.imageUrl,
        title: shop.title,
        subtitle: subtitle,
        rating: shop.rating,
        tags: shop.tags,
        isOpen: shop.isOpen,
        category: shop.category,
        openNowOverride: shop.openNowOverride,
      ),
    );
  }
}
