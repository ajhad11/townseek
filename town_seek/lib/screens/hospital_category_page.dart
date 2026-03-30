import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shop_card.dart';
import '../data/shop_data.dart';
import 'service_details_page.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'hospital_details_page.dart';

class HospitalCategoryPage extends StatefulWidget {
  const HospitalCategoryPage({super.key});

  @override
  State<HospitalCategoryPage> createState() => _HospitalCategoryPageState();
}

class _HospitalCategoryPageState extends State<HospitalCategoryPage> {
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

    // The user wants healthcare related services in this page.
    // Let's rely on the chips. "All" shows all Hospitals.
    
    // Define Hospital Categories
    const hospitalTags = ['Emergency', 'Pharmacy', 'OPD', 'Maternity', 'ICU', 'Pediatrics'];

    final hospitalShops = allShops.where((shop) {
      final shopTags = shop.tags;
      final category = shop.category?.toLowerCase().replaceAll(' ', '') ?? '';

      // Strict exclusion of other categories
      if (['education', 'schools', 'entertainment', 'publicservices', 'groceries', 'food', 'fashion', 'health', 'services', 'finance', 'animals', 'religious', 'commercial'].contains(category)) {
          return false;
      }

      // Base filter
      bool isHospitalhop = (category == 'hospital') ||
          shopTags.any((t) => hospitalTags.contains(t));

      return isHospitalhop;
    }).toList();

    if (_selectedFilters.isEmpty || _selectedFilters.contains('All')) return hospitalShops;

    final filtered = hospitalShops.where((shop) {
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
                          _buildFilterChip('Emergency'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Pharmacy'),
                          const SizedBox(width: 10),
                          _buildFilterChip('OPD'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Maternity'),
                          const SizedBox(width: 10),
                          _buildFilterChip('ICU'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Pediatrics'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Offer'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    // Hospital Title
                    const Text(
                      'Hospital',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Shop List
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
                                  builder: (context) => HospitalDetailsPage(shop: shop),
                                ),
                              );
                              setState(() {}); // Refresh to show updated rating
                          }
                        },
                        child: ShopCard(
                          imageUrl: shop.imageUrl,
                          title: shop.title,
                          subtitle: shop.subtitle,
                          rating: shop.rating,
                          tags: shop.tags,
                          isOpen: shop.isOpen,
                          category: shop.category,
                        ),
                      ),
                    )),
                    
                    if (_filteredShops.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child:  Center(child: Text("No Hospital match filters")),
                      ),

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
