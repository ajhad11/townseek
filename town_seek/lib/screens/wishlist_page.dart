import 'package:flutter/material.dart';
import '../widgets/shop_card.dart';
import 'shop_page.dart';
import 'service_details_page.dart';
import 'hospital_details_page.dart';
import '../data/wishlist_manager.dart';
import '../search/shop_search_delegate.dart';
import '../widgets/custom_header.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final List<String> _categories = ['All', 'Groceries', 'Food', 'Service', 'Fashion', 'Finance', 'Animals', 'Education', 'Religious', 'Entertainment', 'Public Services', 'Commercial', 'Hospital'];
  String _selectedCategory = 'All';

  void _onCategoryTap(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _removeFromWishlist(Shop shop) {
    WishlistManager().removeFromWishlist(shop);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${shop.title} removed from wishlist"),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            WishlistManager().addToWishlist(shop);
          },
        ),
      ),
    );
  }

  List<Shop> _getFilteredShops(List<Shop> allWishlistShops) {
    if (_selectedCategory == 'All') {
      return allWishlistShops;
    }
    return allWishlistShops.where((shop) {
      if (_selectedCategory == 'Groceries') {
        return shop.tags.any((t) => ['Vegetables', 'Fruits', 'Groceries', 'Bakery'].contains(t));
      } else if (_selectedCategory == 'Food') {
        return shop.tags.any((t) => ['Restaurant', 'Cafe', 'Dining', 'Snacks', 'Burger'].contains(t));
      } else if (_selectedCategory == 'Service') {
         return shop.tags.any((t) => ['Services', 'Tailor', 'Rental', 'Repair', 'Lodge'].contains(t));
      } else if (_selectedCategory == 'Fashion') {
        return shop.tags.any((t) => ['Fashion', 'Clothing', 'Shoes'].contains(t));
      } else if (_selectedCategory == 'Finance') {
        return shop.category?.toLowerCase() == 'finance' || shop.tags.any((t) => ['Finance', 'Bank', 'ATM', 'Loan'].contains(t));
      } else if (_selectedCategory == 'Animals') {
        return shop.category?.toLowerCase() == 'animals' || shop.tags.any((t) => ['Animals', 'Pets', 'Vet', 'Grooming'].contains(t));
      } else if (_selectedCategory == 'Education') {
        return shop.category?.toLowerCase() == 'education' || shop.tags.any((t) => ['Education', 'School', 'Tuition', 'Books'].contains(t));
      } else if (_selectedCategory == 'Religious') {
        return shop.category?.toLowerCase() == 'religious' || shop.tags.any((t) => ['Religious', 'Temple', 'Mosque', 'Church'].contains(t));
      } else if (_selectedCategory == 'Entertainment') {
        return shop.category?.toLowerCase() == 'entertainment' || shop.tags.any((t) => ['Cinema', 'Gaming', 'Amusement Park', 'Theater'].contains(t));
      } else if (_selectedCategory == 'Public Services') {
        final category = shop.category?.toLowerCase().replaceAll(' ', '') ?? '';
        return category == 'publicservices' || shop.tags.any((t) => ['Government', 'Post Office', 'Police', 'Fire Station'].contains(t));
      } else if (_selectedCategory == 'Commercial') {
        return shop.category?.toLowerCase() == 'commercial' || shop.tags.any((t) => ['Office', 'Coworking', 'Warehouse', 'Wholesale'].contains(t));
      } else if (_selectedCategory == 'Hospital') {
        return shop.category?.toLowerCase() == 'hospital' || shop.tags.any((t) => ['Emergency', 'Pharmacy', 'OPD', 'Maternity', 'ICU', 'Pediatrics'].contains(t));
      }
      return shop.tags.contains(_selectedCategory);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomHeader(
            showBackButton: false,
            title: 'Wishlists',
            onSearchTap: () {
              showSearch(
                context: context,
                delegate: ShopSearchDelegate(searchScope: WishlistManager().wishlistShops),
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await WishlistManager().loadWishlist();
              },
              color: const Color(0xFF2962FF),
              child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FA), Color(0xFFE3E8F0)],
              stops: [0.0, 1.0],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => _onCategoryTap(category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2962FF) : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey[300]!,
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
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListenableBuilder(
                    listenable: WishlistManager(),
                    builder: (context, child) {
                      final allWishlistShops = WishlistManager().wishlistShops;
                      final displayShops = _getFilteredShops(allWishlistShops);

                      if (displayShops.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF2962FF).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)
                                      ]
                                    ),
                                    child: const Icon(Icons.favorite_border, size: 64, color: Color(0xFF2962FF)),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text("Your wishlist is empty", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text("Find shops and services you love\nand save them here.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      }

                      return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: displayShops.length,
                          itemBuilder: (context, index) {
                            final shop = displayShops[index];
                            return _buildWishlistShopItem(shop);
                          },
                        );
                    },
                  ),
                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistShopItem(Shop shop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          GestureDetector(
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
                  setState(() {});
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
          Positioned.fill(
            right: 8,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                iconSize: 32,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
                    ]
                  ),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 24),
                ),
                onPressed: () => _removeFromWishlist(shop),
              ),
            ),
          ),
        ],
      ),
    );
  }
}