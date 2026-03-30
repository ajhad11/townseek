import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/shop_card.dart';
import '../data/shop_data.dart';
import 'shop_page.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class FashionPage extends StatefulWidget {
  const FashionPage({super.key});

  @override
  State<FashionPage> createState() => _FashionPageState();
}

class _FashionPageState extends State<FashionPage> {
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
    
    // Filter ONLY Fashion related shops for this page
    final fashionShops = allShops.where((shop) {
       final category = shop.category?.toLowerCase() ?? '';
       
       // Explicitly exclude other top-level categories
       if (['education', 'schools', 'entertainment', 'public services', 'publicservices', 'groceries', 'food', 'health', 'hospital', 'services', 'finance', 'animals', 'religious', 'commercial'].contains(category)) {
          return false;
       }

       return (category == 'fashion') ||
              shop.tags.any((tag) => 
         ['Fashion', 'Clothing', 'Footwear', 'Accessories', 'Men\'s Clothing', 'Ladies Clothing', 'Kids Clothing'].contains(tag));
    }).toList();

    if (_selectedFilters.isEmpty || _selectedFilters.contains('All')) return fashionShops;

    final filtered = fashionShops.where((shop) {
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

        // General Category Check
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
                    // Filter Chips - Dynamic
                    _buildFilterChipsRow(),

                    const SizedBox(height: 25),
                    
                    // Fashion Title
                    const Text(
                      'Fashion',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Shop List - Dynamic
                    ..._buildShopList(),

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

  Widget _buildFilterChipsRow() {
    return SingleChildScrollView(
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
          _buildFilterChip("Men's Clothing"),
          const SizedBox(width: 10),
          _buildFilterChip("Ladies Clothing"),
          const SizedBox(width: 10),
          _buildFilterChip("Kids Clothing"),
          const SizedBox(width: 10),
          _buildFilterChip("Accessories"),
          const SizedBox(width: 10),
          _buildFilterChip("Footwear"),
          const SizedBox(width: 10),
          _buildFilterChip('Offer'),
        ],
      ),
    );
  }

  List<Widget> _buildShopList() {
    final shops = _filteredShops;
    
    if (shops.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: Text("No shops match filters")),
        )
      ];
    }

    return shops.map((shop) => Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: GestureDetector(
        onTap: () async {
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
    )).toList();
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
