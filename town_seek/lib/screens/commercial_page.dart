import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shop_card.dart';
import '../data/shop_data.dart';
import 'shop_page.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'service_details_page.dart';

class CommercialPage extends StatefulWidget {
  const CommercialPage({super.key});

  @override
  State<CommercialPage> createState() => _CommercialPageState();
}

class _CommercialPageState extends State<CommercialPage> {
  final Set<String> _selectedFilters = {'All'}; // Default selection 'All'
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationService().getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
      });
    }
  }

  // Logic to filter shops based on selected chips
  List<Shop> get _filteredShops {
    // Start with all shops
    final allShops = ShopData.allShops;

    // Define Commercial Categories
    const commercialTags = ['B2B', 'Wholesale', 'Factory', 'Warehouse', 'Office', 'Manufacturing'];
    final commercialShops = allShops.where((shop) {
      final shopTags = shop.tags;
      final category = shop.category?.toLowerCase() ?? '';

      // Explicitly exclude other top-level categories
      if (['education', 'schools', 'entertainment', 'public services', 'publicservices', 'groceries', 'food', 'fashion', 'health', 'hospital', 'finance', 'animals', 'religious', 'services'].contains(category)) {
          return false;
      }

      // Base filter
      bool isCommercialhop = (category == 'commercial') ||
          shopTags.any((t) => commercialTags.contains(t));

      return isCommercialhop;
    }).toList();

    if (_selectedFilters.isEmpty || _selectedFilters.contains('All')) return commercialShops;

    final filtered = commercialShops.where((shop) {
      for (final filter in _selectedFilters) {
        if (filter == 'All') continue;

        // 1. Open Check
        if (filter == 'Open') {
          if (!shop.isOpen) return false;
          continue;
        }

        // 2. Parking Check
        if (filter == 'Parking') {
          bool hasParking = shop.tags.contains('Parking') || shop.tags.contains('Street parking');
          if (!hasParking) return false;
          continue;
        }

        // 3. Nearby Check
        if (filter == 'Nearby') {
          // Nearby is now a sorting option
          continue;
        }

        // 4. Offer Check
        if (filter == 'Offer') {
          if (!shop.tags.contains('Offer')) return false;
          continue;
        }

        // 5. Category Check
        if (!shop.tags.contains(filter)) return false;
      }

      return true; // Passed all checks
    }).toList();

    if (_selectedFilters.contains('Nearby') && _currentPosition != null) {
      filtered.sort((a, b) {
        if (a.latitude == null || a.longitude == null) return 1;
        if (b.latitude == null || b.longitude == null) return -1;
        final distA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude!,
          b.longitude!,
        );
        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

  void _onFilterTap(String filter) {
    setState(() {
      if (filter == 'All') {
        _selectedFilters.clear();
        _selectedFilters.add('All');
      } else {
        _selectedFilters.remove('All');
        if (_selectedFilters.contains(filter)) {
          _selectedFilters.remove(filter);
        } else {
          _selectedFilters.add(filter);
        }
        if (_selectedFilters.isEmpty) {
          _selectedFilters.add('All');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const CustomHeader(showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Parking'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Open'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Nearby'),
                          const SizedBox(width: 10),
                          _buildFilterChip('B2B'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Wholesale'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Office'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Offer'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    // Commercial Title
                    const Text(
                      'Commercial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Shop List
                    if (_filteredShops.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text("No Commercial match filters"),
                        ),
                      )
                    else
                      ..._filteredShops.map((shop) => Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: GestureDetector(
                          onTap: () async {
                            if (shop.services != null && shop.services!.isNotEmpty) {
                               Navigator.push(
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
                                      phone: shop.phone,
                                      email: shop.email,
                                      location: shop.location,
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
                          },
                          child: ShopCard(
                            title: shop.title,
                            subtitle: shop.subtitle,
                            rating: shop.rating,
                            tags: shop.tags,
                            imageUrl: shop.imageUrl,
                            isOpen: shop.isOpen,
                            category: shop.category,
                                      openNowOverride: shop.openNowOverride,
                          ),
                        ),
                      )),

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

  Widget _buildFilterChip(String text) {
    final isSelected = _selectedFilters.contains(text);
    return GestureDetector(
      onTap: () => _onFilterTap(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2962FF) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[200]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2962FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
