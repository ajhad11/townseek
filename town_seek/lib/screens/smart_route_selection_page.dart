import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/smart_route_service.dart';
import 'smart_route_map_page.dart';

class SmartRouteSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> allOptions;
  final Position userLocation;
  final String preference;

  const SmartRouteSelectionPage({
    super.key,
    required this.allOptions,
    required this.userLocation,
    required this.preference,
  });

  @override
  State<SmartRouteSelectionPage> createState() => _SmartRouteSelectionPageState();
}

class _SmartRouteSelectionPageState extends State<SmartRouteSelectionPage> {
  final SmartRouteService _smartRouteService = SmartRouteService();
  bool _isLoading = false;
  
  // Maps the index of the item group to the currently selected option index within that group
  late Map<int, int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    _selectedIndices = {};
    // Pre-select the top option (index 0) for each item, as options are presorted by score
    for (int i = 0; i < widget.allOptions.length; i++) {
        _selectedIndices[i] = 0;
    }
  }

  Future<void> _confirmAndRoute() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Gather all selected options
      List<Map<String, dynamic>> chosenOptions = [];
      for (int i = 0; i < widget.allOptions.length; i++) {
         final group = widget.allOptions[i];
         final options = group['options'] as List<Map<String, dynamic>>;
         final selectedIndex = _selectedIndices[i] ?? 0;
         if (options.isNotEmpty && selectedIndex < options.length) {
             chosenOptions.add(options[selectedIndex]);
         }
      }

      // 2. Group them back into shops format expected by generateRoute
      final shopsForRoute = _smartRouteService.groupSelectedOptionsIntoShops(chosenOptions);

      // 3. Generate Route
      final routeData = await _smartRouteService.generateRoute(
         userLocation: widget.userLocation,
         shops: shopsForRoute,
      );

      if (routeData == null) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Could not generate path between the selected shops.')),
            );
            setState(() => _isLoading = false);
         }
         return;
      }

      // 4. Navigate to Map View
      if (mounted) {
         setState(() => _isLoading = false);
         // Notice we use pushReplacement to avoid adding this selection page to backstack unnecessarily
         Navigator.pushReplacement(
            context,
            MaterialPageRoute(
               builder: (context) => SmartRouteMapPage(
                  routeData: routeData,
                  userLocation: widget.userLocation,
               ),
            ),
         );
      }

    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating route: $e')),
         );
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Review Shop Selections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             color: Colors.white,
             width: double.infinity,
             child: Text(
                'We pre-selected the best options for your "${widget.preference}" preference. Tap to change the shop for any item.',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
             ),
           ),
           Expanded(
             child: ListView.builder(
               padding: const EdgeInsets.all(16),
               itemCount: widget.allOptions.length,
               itemBuilder: (context, index) {
                 final group = widget.allOptions[index];
                 final itemName = group['itemName'] as String;
                 final options = group['options'] as List<Map<String, dynamic>>;
                 
                 // Find the cheapest price in this group for badging
                 double minPrice = double.maxFinite;
                 for (var opt in options) {
                    final p = opt['product'];
                    if (p != null) {
                       double price = double.tryParse(p['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                       if (price > 0 && price < minPrice) minPrice = price;
                    }
                 }
                 
                 return Card(
                   margin: const EdgeInsets.only(bottom: 20),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 2,
                   surfaceTintColor: Colors.white,
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.shopping_bag, color: Colors.blue[700], size: 20),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 itemName.toUpperCase(),
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         ...options.asMap().entries.map((entry) {
                            final optionIndex = entry.key;
                            final optionData = entry.value;
                            
                            final shop = optionData['shop'];
                            final product = optionData['product'];
                            
                            final shopName = shop['name'] ?? 'Unknown Shop';
                            final double distance = optionData['distance'] as double? ?? 0.0;
                            final double rating = optionData['rating'] as double? ?? 0.0;
                            final priceStr = product['price']?.toString() ?? 'N/A';
                            
                            final isSelected = _selectedIndices[index] == optionIndex;

                            return GestureDetector(
                               onTap: () {
                                  setState(() {
                                     _selectedIndices[index] = optionIndex;
                                  });
                               },
                               child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                     border: Border.all(
                                        color: isSelected ? const Color(0xFF2962FF) : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                     ),
                                     borderRadius: BorderRadius.circular(12),
                                     color: isSelected ? Colors.blue[50] : Colors.transparent,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       // ignore: deprecated_member_use
                                       Radio<int>(
                                          value: optionIndex,
                                          // ignore: deprecated_member_use
                                          groupValue: _selectedIndices[index],
                                          activeColor: const Color(0xFF2962FF),
                                          // ignore: deprecated_member_use
                                          onChanged: (val) {
                                             if (val != null) {
                                                setState(() {
                                                   _selectedIndices[index] = val;
                                                });
                                             }
                                          },
                                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                       ),
                                       const SizedBox(width: 8),
                                       Expanded(
                                          child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                                Text(
                                                   shopName, 
                                                   style: TextStyle(
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                      fontSize: 15,
                                                      color: Colors.black87
                                                   )
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                   spacing: 4,
                                                   crossAxisAlignment: WrapCrossAlignment.center,
                                                   children: [
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.star, color: Colors.amber[600], size: 14),
                                                          const SizedBox(width: 2),
                                                          Text(rating > 0 ? rating.toStringAsFixed(1) : 'New', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.location_on, color: Colors.grey[500], size: 14),
                                                          const SizedBox(width: 2),
                                                          Text('${(distance / 1000).toStringAsFixed(1)} km', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                        ],
                                                      ),
                                                   ],
                                                ),
                                             ],
                                          )
                                       ),
                                       Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                             Text(
                                                priceStr == '0' || priceStr == 'N/A' ? 'Check Store' : '₹$priceStr',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                                             ),
                                             if (double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) == minPrice && minPrice != double.maxFinite)
                                                Container(
                                                   margin: const EdgeInsets.only(top: 4),
                                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                   decoration: BoxDecoration(
                                                      color: Colors.green[100],
                                                      borderRadius: BorderRadius.circular(4),
                                                   ),
                                                   child: Text('CHEAPEST', style: TextStyle(color: Colors.green[800], fontSize: 9, fontWeight: FontWeight.bold)),
                                                ),
                                             if (optionData['hasParking'] == true)
                                                Padding(
                                                   padding: const EdgeInsets.only(top: 4),
                                                   child: Row(
                                                      children: [
                                                         Icon(Icons.local_parking, size: 12, color: Colors.blue[700]),
                                                         const SizedBox(width: 2),
                                                         Text('Parking', style: TextStyle(fontSize: 10, color: Colors.blue[700])),
                                                      ],
                                                   ),
                                                ),
                                          ]
                                       )
                                    ],
                                  )
                               ),
                            );
                         }),
                       ],
                     ),
                   ),
                 );
               },
             ),
           ),
           
           // Bottom Button Area
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
               ]
             ),
             child: SafeArea(
                child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: _isLoading ? null : _confirmAndRoute,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF2962FF),
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       elevation: 2,
                     ),
                     child: _isLoading
                         ? const SizedBox(
                             height: 20,
                             width: 20,
                             child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                           )
                         : const Text(
                             'Confirm & Generate Route',
                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                           ),
                   ),
                ),
             ),
           )
        ],
      )
    );
  }
}
