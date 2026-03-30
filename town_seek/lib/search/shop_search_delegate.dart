
import 'package:flutter/material.dart';
import '../data/shop_data.dart';
import '../widgets/shop_card.dart';
import '../screens/shop_page.dart';
import '../screens/service_details_page.dart';
import '../screens/hospital_details_page.dart';

class ShopSearchDelegate extends SearchDelegate {
  final List<Shop>? searchScope;
  List<Shop> _lastResults = [];
  String _lastQuery = '';

  ShopSearchDelegate({this.searchScope});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    // Debounce: reuse last results while user is still typing (#5)
    final source = searchScope ?? ShopData.allShops;
    final lowerQuery = query.toLowerCase();
    if (lowerQuery != _lastQuery) {
      _lastQuery = lowerQuery;
      _lastResults = source.where((shop) {
        if (lowerQuery.isEmpty) return true;
        return shop.searchKeywords.any((kw) => kw.contains(lowerQuery));
      }).toList();
    }
    final results = _lastResults;

    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No results found.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5), // Light background for the list
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final shop = results[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: GestureDetector(
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
                          location: shop.location,
                          phone: shop.phone,
                          email: shop.email,
                          latitude: shop.latitude,
                          longitude: shop.longitude,
                          workingDays: shop.workingDays,
                          id: shop.id,
                          ownerId: shop.ownerId,
                                    category: shop.category,
                           // distance is not really available here unless calculated, passing null or calculating
                          distance: null, 
                        ),
                      ),
                    );
                 }
                // Trigger rebuild of search results to show updated rating
                query = query;
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
          );
        },
      ),
    );
  }
}
