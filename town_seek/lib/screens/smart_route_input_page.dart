import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/smart_route_service.dart';
import 'smart_route_selection_page.dart';

class SmartRouteInputPage extends StatefulWidget {
  const SmartRouteInputPage({super.key});

  @override
  State<SmartRouteInputPage> createState() => _SmartRouteInputPageState();
}

class _SmartRouteInputPageState extends State<SmartRouteInputPage> {
  final List<String> _shoppingList = [];
  final TextEditingController _itemController = TextEditingController();
  TextEditingController? _autoCompleteController;
  List<String> _recommendations = [];
  String _selectedPreference = 'Balanced';
  bool _isLoading = false;
  
  final SmartRouteService _smartRouteService = SmartRouteService();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    final recs = await _smartRouteService.getSearchRecommendations();
    if (mounted) {
      setState(() {
        _recommendations = recs;
      });
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  void _addItem(String item) {
    if (item.trim().isEmpty) return;

    // Check if in recommendations
    final match = _recommendations.firstWhere(
      (r) => r.toLowerCase() == item.trim().toLowerCase(),
      orElse: () => '',
    );

    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item from the suggestions')),
      );
      return;
    }

    // Detect if this is a shop category
    final isCategory = SmartRouteService.categoryTypes
        .any((cat) => cat.toLowerCase() == match.toLowerCase());

    if (isCategory) {
      // Fetch departments for this category and show picker
      _showDepartmentPicker(match);
    } else {
      _finalizeAddItem(match);
    }
  }

  Future<void> _showDepartmentPicker(String category) async {
    // Show loading briefly while fetching departments
    setState(() => _isLoading = true);
    final departments = await _smartRouteService.getDepartmentsForCategory(category);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (departments.isEmpty) {
      // No departments available — add category directly
      _finalizeAddItem(category);
      return;
    }

    // Show bottom sheet with department options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, color: Colors.blue[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select Department ($category)',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Option to add the category without department
                    ListTile(
                      leading: const Icon(Icons.all_inclusive, color: Colors.grey),
                      title: Text('Any $category (no preference)'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _finalizeAddItem(category);
                      },
                    ),
                    const Divider(height: 1),
                    ...departments.map((dept) => ListTile(
                      leading: const Icon(Icons.label_outline, color: Color(0xFF2962FF)),
                      title: Text(dept),
                      subtitle: Text('Find $category with $dept'),
                      onTap: () {
                        Navigator.pop(ctx);
                        // Add as "category → department"
                        _finalizeAddItem('$category → $dept');
                      },
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _finalizeAddItem(String item) {
    if (!_shoppingList.contains(item)) {
      setState(() {
        _shoppingList.add(item);
        _itemController.clear();
        _autoCompleteController?.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _shoppingList.removeAt(index);
    });
  }

  Future<void> _generateRoute() async {
    if (_shoppingList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to your shopping list')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get User Location
      final Position? userLocation = await _locationService.getCurrentPosition();
      
      if (userLocation == null) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Could not determine your location. Please enable location services.')),
           );
           setState(() => _isLoading = false);
        }
        return;
      }

      // 2. Get all shop options
      final result = await _smartRouteService.getAllShopOptionsForProducts(
         products: _shoppingList,
         userLocation: userLocation,
         preference: _selectedPreference,
      );

      if (result.missingItems.isNotEmpty) {
         if (mounted) {
            final missing = result.missingItems.join(', ');
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Can't find $missing")),
            );
            setState(() => _isLoading = false);
         }
         return;
      }

      if (result.options.isEmpty) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Could not find any nearby shops for your selected items.')),
            );
            setState(() => _isLoading = false);
         }
         return;
      }

      // 3. Navigate to Selection View
      if (mounted) {
         setState(() => _isLoading = false);
         Navigator.push(
            context,
            MaterialPageRoute(
               builder: (context) => SmartRouteSelectionPage(
                  allOptions: result.options,
                  userLocation: userLocation,
                  preference: _selectedPreference,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Route', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Route Map',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _recommendations.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _addItem(selection);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      _autoCompleteController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search product or shop...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (value) {
                          _addItem(value);
                          controller.clear();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                     if (_autoCompleteController != null && _autoCompleteController!.text.isNotEmpty) {
                        _addItem(_autoCompleteController!.text);
                     }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _shoppingList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Your list is empty', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _shoppingList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline, color: Color(0xFF2962FF)),
                            title: Text(_shoppingList[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removeItem(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Routing Preference',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPreference,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPreference = newValue;
                      });
                    }
                  },
                  items: <String>['Cheapest', 'Fastest', 'Balanced']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateRoute,
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
                        'Generate Smart Route',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
