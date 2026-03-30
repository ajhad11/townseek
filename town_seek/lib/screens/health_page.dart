import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shop_card.dart';
import '../data/shop_data.dart';
import 'shop_page.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'hospital_details_page.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final Set<String> _selectedFilters = {'All'};
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

  List<Shop> get _filteredShops {
    final allShops = ShopData.allShops;
    const healthTags = ['Clinic', 'Pharmacy', 'Gym', 'Spa', 'Yoga', 'Dentist', 'Optician'];

    final healthShops = allShops.where((shop) {
      final shopTags = shop.tags;
      final category = shop.category?.toLowerCase() ?? '';

      if (['education', 'schools', 'entertainment', 'public services', 'publicservices', 'groceries', 'food', 'fashion', 'services', 'finance', 'animals', 'religious', 'commercial', 'hospital'].contains(category)) {
          return false;
      }

      bool isHealthShop = (category == 'health') ||
          shopTags.any((t) => healthTags.contains(t));

      return isHealthShop;
    }).toList();

    if (_selectedFilters.isEmpty || _selectedFilters.contains('All')) return healthShops;

    final filtered = healthShops.where((shop) {
      for (final filter in _selectedFilters) {
        if (filter == 'All') continue;
        if (filter == 'Open') {
          if (!shop.isOpen) return false;
          continue;
        }
        if (filter == 'Parking') {
          if (!shop.tags.contains('Parking')) return false;
          continue;
        }
        if (filter == 'Nearby') {
          // Nearby is now a sorting option
          continue;
        }
        if (filter == 'Offer') {
          if (!shop.tags.contains('Offer')) return false;
          continue;
        }
        if (!shop.tags.contains(filter)) return false;
      }
      return true;
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
                          const SizedBox(width: 10),
                          _buildFilterChip('Pharmacy'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Laboratory'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Gym'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Clinics'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Ayurvedha'),
                          const SizedBox(width: 10),
                          _buildFilterChip('Offer'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Health',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ..._filteredShops.map((shop) => Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: GestureDetector(
                        onTap: () async {
                          if (shop.tags.contains('Hospital') || shop.tags.contains('Clinic') || shop.tags.contains('Dental') || shop.tags.contains('Clinics')) {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HospitalDetailsPage(shop: shop),
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
                                  distance: null,
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
                            setState(() {});
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
                          openNowOverride: shop.openNowOverride,
                        ),
                      ),
                    )),
                    if (_filteredShops.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("No shops matches filters")),
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
