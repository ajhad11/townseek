import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import '../utils/category_term_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/shop_card.dart';
import '../data/shop_data.dart';

class ManageProductsPage extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ManageProductsPage({super.key, required this.shop});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  bool _isLoading = true;
  List<ShopProductCategory> _categories = [];
  final Map<String, List<ShopProduct>> _productsByCategory = {};

  final _categoryController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shopId = widget.shop['id'];
      final fetchedCategories = await ShopData.fetchProductCategories(shopId);
      final fetchedProducts = await ShopData.fetchProducts(shopId);

      _categories = fetchedCategories;
      
      _productsByCategory.clear();
      for (var cat in _categories) {
        _productsByCategory[cat.id] = fetchedProducts.where((p) => p.categoryId == cat.id).toList();
      }

      // Refresh global search cache in the background so updates become searchable instantly
      ShopData.fetchShops();
    } catch (e) {
      debugPrint("Error fetching product data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddCategorySheet({ShopProductCategory? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCategorySheet(
        shopId: widget.shop['id'],
        shopCategory: widget.shop['category'] ?? '',
        itemTermSingular: CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString()),
        category: category,
        onCategoryAdded: () {
          Navigator.pop(context);
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(category == null ? 'Category added successfully!' : 'Category updated successfully!'))
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(ShopProductCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will also delete all products inside it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('product_categories')
          .delete()
          .eq('id', category.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully')));
      }
      await _fetchData();
    } catch (e) {
      debugPrint("Error deleting category: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete category: $e')));
         setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(ShopProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString())}'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', product.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString())} deleted successfully')));
      }
      await _fetchData();
    } catch (e) {
      debugPrint("Error deleting product: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete product: $e')));
         setState(() => _isLoading = false);
       }
    }
  }

  Future<void> _toggleProductStock(ShopProduct product, bool newValue) async {
    try {
      await Supabase.instance.client
          .from('products')
          .update({'stock': newValue})
          .eq('id', product.id);
      
      if (mounted) {
        setState(() {
          // Update local state for immediate feedback
          final categoryId = product.categoryId;
          final products = _productsByCategory[categoryId] ?? [];
          final index = products.indexWhere((p) => p.id == product.id);
          if (index != -1) {
            final oldP = products[index];
            products[index] = ShopProduct(
              id: oldP.id,
              shopId: oldP.shopId,
              categoryId: oldP.categoryId,
              name: oldP.name,
              price: oldP.price,
              imageUrl: oldP.imageUrl,
              isAvailable: newValue,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error toggling stock: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update stock: $e')));
      }
    }
  }

  void _showAddProductSheet(ShopProductCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddProductSheet(
        shopId: widget.shop['id'],
        categoryId: category.id,
        categoryName: category.name,
        itemTermSingular: CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString()),
        onProductAdded: () {
          Navigator.pop(context); // Close the sheet
          _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('${CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString())} added successfully!'))
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Manage ${CategoryTermHelper.getPluralTerm(widget.shop['category']?.toString())}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildEmptyState()
              : _buildCategoriesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategorySheet,
        backgroundColor: const Color(0xFF2962FF),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('New Category', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Categories Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a category to start adding ${CategoryTermHelper.getPluralTerm(widget.shop['category']?.toString()).toLowerCase()}.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
             onPressed: _showAddCategorySheet,
             icon: const Icon(Icons.add),
             label: Text('Add First ${CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString())} Category'),
             style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
             ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final products = _productsByCategory[category.id] ?? [];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(16),
             side: BorderSide(color: Colors.grey[200]!),
          ),
          child: _buildCategoryContent(category, products),
        );
      },
    );
  }

  Widget _buildCategoryContent(ShopProductCategory category, List<ShopProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (category.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, err) => const Icon(Icons.category, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    category.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              Row(
                children: [
                   Text(
                      '${products.length} ${CategoryTermHelper.getPluralTerm(widget.shop['category']?.toString()).toLowerCase()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                   ),
                   const SizedBox(width: 8),
                   InkWell(
                     onTap: () => _showAddCategorySheet(category: category),
                     child: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2962FF)),
                   ),
                   const SizedBox(width: 8),
                   InkWell(
                     onTap: () => _deleteCategory(category),
                     child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                   ),
                ],
              )
            ],
          ),
        ),

        // Product List
        if (products.isEmpty)
           Padding(
             padding: const EdgeInsets.all(24.0),
             child: Center(
               child: Text('No ${CategoryTermHelper.getPluralTerm(widget.shop['category']?.toString()).toLowerCase()} in this category.', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
             ),
           )
        else
           ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                 final product = products[index];
                 return ListTile(
                    leading: Container(
                       width: 48,
                       height: 48,
                       decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                       ),
                       child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, err) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                              ),
                            )
                          : const Icon(Icons.inventory, color: Colors.grey, size: 20),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(product.price, style: const TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Stock', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: product.isAvailable,
                            onChanged: (val) => _toggleProductStock(product, val),
                            activeThumbColor: const Color(0xFF2962FF),
                          ),
                        ),
                        IconButton(
                           icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                           onPressed: () => _deleteProduct(product),
                        ),
                      ],
                    ),
                  );
              },
           ),

        // Add Product Button
        InkWell(
          onTap: () => _showAddProductSheet(category),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 18, color: Color(0xFF2962FF)),
                const SizedBox(width: 4),
                Text(
                  'Add ${CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString())}',
                  style: const TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _AddProductSheet extends StatefulWidget {
  final dynamic shopId;
  final dynamic categoryId;
  final String categoryName;
  final String itemTermSingular;
  final VoidCallback onProductAdded;

  const _AddProductSheet({
    required this.shopId,
    required this.categoryId,
    required this.categoryName,
    required this.itemTermSingular,
    required this.onProductAdded,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  dynamic _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = bytes;
        });
      } else {
        setState(() {
          _selectedImage = io.File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();

    if (name.isEmpty || price.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Price are required.')));
        return;
    }

    if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.itemTermSingular} image is required.')));
        return;
    }

    setState(() {
       _isSaving = true;
    });

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.shopId}_product.jpg';
        if (kIsWeb) {
          await Supabase.instance.client.storage
              .from('shop-images')
              .uploadBinary(fileName, _selectedImage as Uint8List);
        } else {
          await Supabase.instance.client.storage
              .from('shop-images')
              .upload(fileName, _selectedImage as io.File);
        }
            
        imageUrl = Supabase.instance.client.storage
            .from('shop-images')
            .getPublicUrl(fileName);
      }
      
      final parsedShopId = int.tryParse(widget.shopId.toString()) ?? widget.shopId;
      final parsedCategoryId = int.tryParse(widget.categoryId.toString()) ?? widget.categoryId;

      await Supabase.instance.client.from('products').insert({
         'shop_id': parsedShopId,
         'category_id': parsedCategoryId,
         'name': name,
         'price': price,
         if (imageUrl != null) 'image_url': imageUrl,
      }).select();

      // Execute parent callback but without risking widget unmounting if it had inner navigations
      widget.onProductAdded();
      
    } catch (e) {
      debugPrint("Error saving product: $e");
      if (mounted) {
         showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
               title: const Text('Error'),
               content: Text(e.toString()),
               actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('OK'))]
            )
         );
      }
    } finally {
      if (mounted) {
         setState(() {
            _isSaving = false;
         });
      }
    }
  }

  List<String> _getSuggestedProducts() {
    final Map<String, List<String>> suggestedProductsMap = {
      'government': ['Document Filing', 'Certification', 'License Renewal', 'Public Consultation'],
      'community': ['Event Registration', 'Information Desk', 'Membership Enrollment'],
      'utilities': ['Bill Payment', 'Meter Reading', 'New Connection', 'Repair Request'],
      'fruits': ['Apple', 'Banana', 'Orange', 'Mango', 'Grapes', 'Watermelon'],
      'vegetables': ['Onion', 'Tomato', 'Potato', 'Carrot', 'Cabbage', 'Spinach'],
      'dairy': ['Milk', 'Butter', 'Cheese', 'Paneer', 'Curd'],
      'bakery': ['Bread', 'Buns', 'Cakes', 'Cookies', 'Rusks'],
      'snacks': ['Chips', 'Biscuits', 'Namkeen', 'Popcorn', 'Nuts'],
      'drinks': ['Cold Drink', 'Juice', 'Energy Drink', 'Water', 'Soda'],
      'staples': ['Rice', 'Wheat', 'Dal', 'Sugar', 'Salt', 'Cooking Oil'],
      'meat': ['Chicken', 'Mutton', 'Beef', 'Pork', 'Sausages'],
      'fish': ['Salmon', 'Tuna', 'Prawns', 'Crab', 'Surmai'],
      'medicines': ['Paracetamol', 'Cough Syrup', 'Antacid', 'Painkiller', 'Vitamins'],
      'main course': ['Paneer Butter Masala', 'Chicken Biryani', 'Dal Makhani', 'Roti', 'Naan'],
      'starters': ['Manchow Soup', 'Paneer Tikka', 'Chicken 65', 'Veg Crispy'],
      'beverages': ['Tea', 'Coffee', 'Lassi', 'Cold Coffee', 'Mojito'],
      'desserts': ['Gulab Jamun', 'Rasmalai', 'Ice Cream', 'Brownie'],
      'men': ['Shirt', 'T-Shirt', 'Jeans', 'Trousers', 'Jacket'],
      'women': ['Kurti', 'Saree', 'Top', 'Jeans', 'Dress'],
      'kids': ['T-Shirt', 'Toys', 'Jeans', 'Dress', 'Shoes'],
      'movies': ['Movie Ticket', 'Popcorn Combo', 'VIP Seat'],
      'musical events': ['Concert Ticket', 'Backstage Pass', 'Merchandise'],
      'comedy shows': ['Show Ticket', 'Meet & Greet', 'VIP Package'],
      'theater': ['Play Ticket', 'Program Guide', 'Season Pass'],
      'concerts': ['Concert Ticket', 'Fan Zone Access', 'Limited Edition Poster'],
      'exhibitions': ['Entry Ticket', 'Guided Tour', 'Catalog'],
    };

    final key = widget.categoryName.toLowerCase();
    for (final mapKey in suggestedProductsMap.keys) {
      if (key.contains(mapKey) || mapKey.contains(key)) {
        return suggestedProductsMap[mapKey]!;
      }
    }
    
    return ['Standard Item', 'Premium Item', 'Pack of 2', 'Combo'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
         bottom: MediaQuery.of(context).viewInsets.bottom,
         top: 24,
         left: 24,
         right: 24,
      ),
      decoration: const BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     'Add to ${widget.categoryName}',
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                   IconButton(
                     onPressed: _isSaving ? null : () => Navigator.pop(context),
                     icon: const Icon(Icons.close),
                   )
                ],
             ),
             const SizedBox(height: 16),
             
             // Image Picker
             Center(
               child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                     width: 100,
                     height: 100,
                     decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        image: _selectedImage != null 
                           ? (kIsWeb 
                                ? DecorationImage(image: MemoryImage(_selectedImage as Uint8List), fit: BoxFit.cover)
                                : DecorationImage(image: FileImage(_selectedImage as io.File), fit: BoxFit.cover))
                           : null,
                     ),
                     child: _selectedImage == null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                               Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 32),
                               SizedBox(height: 4),
                               Text('Add Photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
               ),
             ),
             
             const SizedBox(height: 24),
             
             // Product Suggestions
             if (_getSuggestedProducts().isNotEmpty) ...[
               Text('Suggested ${widget.itemTermSingular}s', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
               const SizedBox(height: 12),
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: _getSuggestedProducts().map((tag) {
                   final isSelected = _nameController.text == tag;
                   return FilterChip(
                     label: Text(tag),
                     selected: isSelected,
                     onSelected: (selected) {
                       setState(() {
                         if (selected) {
                           _nameController.text = tag;
                         } else {
                           _nameController.clear();
                         }
                       });
                     },
                     selectedColor: Colors.blue.shade100,
                     checkmarkColor: const Color(0xFF2962FF),
                   );
                 }).toList(),
               ),
               const SizedBox(height: 24),
             ],
             
             // Form Fields
             TextField(
               controller: _nameController,
               decoration: InputDecoration(
                 labelText: '${widget.itemTermSingular} Name',
                  hintText: widget.itemTermSingular == 'Event' 
                    ? 'e.g., Spider-Man, Standup Special, Beginner Math...' 
                    : (widget.itemTermSingular == 'Service' 
                        ? 'e.g., General Checkup, AC Repair, Consultation...' 
                        : 'e.g., Apple, T-Shirt, Coffee Mug...'),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                 prefixIcon: const Icon(Icons.shopping_bag_outlined),
                 filled: true,
                 fillColor: Colors.grey[50], 
               ),
               textCapitalization: TextCapitalization.words,
               onChanged: (val) {
                 setState(() {});
               },
             ),
             
             const SizedBox(height: 16),
             
             TextField(
               controller: _priceController,
               decoration: InputDecoration(
                 labelText: widget.itemTermSingular == 'Event' ? 'Ticket Price / Entry Fee' : 'Price',
                 hintText: widget.itemTermSingular == 'Event' ? 'e.g., ₹250' : 'e.g., ₹150 / kg',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                 prefixIcon: const Icon(Icons.sell_outlined),
                 filled: true,
                 fillColor: Colors.grey[50], 
               ),
             ),
             
             const SizedBox(height: 32),
             
             // Submit Button
             SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                   onPressed: _isSaving ? null : _saveProduct,
                   style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save ${widget.itemTermSingular}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
             ),
             const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  final dynamic shopId;
  final String shopCategory;
  final String itemTermSingular;
  final ShopProductCategory? category;
  final VoidCallback onCategoryAdded;

  const _AddCategorySheet({
    required this.shopId,
    required this.shopCategory,
    required this.itemTermSingular,
    required this.onCategoryAdded,
    this.category,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _categoryController = TextEditingController();
  bool _isSaving = false;
  String _selectedSuggestion = '';
  dynamic _selectedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _categoryController.text = widget.category!.name;
      _existingImageUrl = widget.category!.imageUrl;
    }
  }

  final Map<String, List<String>> _suggestedCategories = {
    'publicservices': ['Government', 'Community', 'Utilities', 'Social Services', 'Security', 'Health & Welfare', 'Infrastructure'],
    'groceries': ['Fruits', 'Vegetables', 'Dairy', 'Bakery', 'Snacks', 'Drinks', 'Staples', 'Meat', 'Fish'],
    'health': ['Medicines', 'Supplements', 'Personal Care', 'Baby Care', 'Medical Devices'],
    'restaurants': ['Main Course', 'Starters', 'Desserts', 'Beverages', 'Breads', 'Biryani'],
    'electronics': ['Mobiles', 'Laptops', 'Accessories', 'Home Appliances', 'Wearables'],
    'clothing': ['Men', 'Women', 'Kids', 'Accessories', 'Footwear'],
    'services': ['Plumbing', 'Cleaning', 'Electrical', 'Painting', 'Carpentry'],
    'education': ['Books', 'Stationery', 'Online Courses', 'Tuition', 'Uniforms'],
    'automobile': ['Car Wash', 'Bike Repair', 'Spares', 'Accessories', 'Servicing'],
    'entertainment': ['Movies', 'Musical Events', 'Comedy Shows', 'Theater', 'Concerts', 'Exhibitions'],
  };

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = bytes;
        });
      } else {
        setState(() {
          _selectedImage = io.File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _saveCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category name cannot be empty.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.shopId}_category.jpg';
        if (kIsWeb) {
          await Supabase.instance.client.storage
              .from('category_image')
              .uploadBinary(fileName, _selectedImage as Uint8List);
        } else {
          await Supabase.instance.client.storage
              .from('category_image')
              .upload(fileName, _selectedImage as io.File);
        }
            
        imageUrl = Supabase.instance.client.storage
            .from('category_image')
            .getPublicUrl(fileName);
      } else {
        imageUrl = _existingImageUrl;
      }

      final parsedShopId = int.tryParse(widget.shopId.toString()) ?? widget.shopId;

      if (widget.category != null) {
        // Update
        await Supabase.instance.client.from('product_categories').update({
          'name': name,
          'image_url': imageUrl,
        }).eq('id', widget.category!.id);
      } else {
        // Insert
        await Supabase.instance.client.from('product_categories').insert({
          'shop_id': parsedShopId,
          'name': name,
          if (imageUrl != null) 'image_url': imageUrl,
        }).select();
      }

      widget.onCategoryAdded();
    } catch (e) {
      debugPrint("Error adding category: $e");
      if (mounted) {
         showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
               title: const Text('Error'),
               content: Text(e.toString()),
               actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('OK'))]
            )
         );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  List<String> _getSuggestions() {
    final key = widget.shopCategory.toLowerCase();
    for (final mapKey in _suggestedCategories.keys) {
      if (key.contains(mapKey) || mapKey.contains(key)) {
        return _suggestedCategories[mapKey]!;
      }
    }
    return ['Featured', 'New Arrivals', 'Discounts', 'Best Sellers', 'Others'];
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();
    
    return Container(
      padding: EdgeInsets.only(
         bottom: MediaQuery.of(context).viewInsets.bottom,
         top: 24,
         left: 24,
         right: 24,
      ),
      decoration: const BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     widget.category == null ? 'Add ${widget.itemTermSingular} Category' : 'Edit ${widget.itemTermSingular} Category',
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                   IconButton(
                     onPressed: _isSaving ? null : () => Navigator.pop(context),
                     icon: const Icon(Icons.close),
                   )
                ],
             ),
             const SizedBox(height: 16),
             
             // Image Picker
             Center(
               child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                     width: 100,
                     height: 100,
                     decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        image: (_selectedImage != null) 
                           ? (kIsWeb 
                                ? DecorationImage(image: MemoryImage(_selectedImage as Uint8List), fit: BoxFit.cover)
                                : DecorationImage(image: FileImage(_selectedImage as io.File), fit: BoxFit.cover))
                           : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                ? DecorationImage(image: CachedNetworkImageProvider(_existingImageUrl!), fit: BoxFit.cover)
                                : null,
                     ),
                     child: (_selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                               Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 32),
                               SizedBox(height: 4),
                               Text('Category Image', style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                            ],
                          )
                        : null,
                  ),
               ),
             ),
             
             const SizedBox(height: 24),
             const Text('Suggested Categories', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
             const SizedBox(height: 12),
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: suggestions.map((tag) {
                 final isSelected = _selectedSuggestion == tag || _categoryController.text == tag;
                 return FilterChip(
                   label: Text(tag),
                   selected: isSelected,
                   onSelected: (selected) {
                     setState(() {
                       if (selected) {
                         _selectedSuggestion = tag;
                         _categoryController.text = tag;
                       } else {
                         _selectedSuggestion = '';
                         _categoryController.clear();
                       }
                     });
                   },
                   selectedColor: Colors.blue.shade100,
                   checkmarkColor: const Color(0xFF2962FF),
                 );
               }).toList(),
             ),
             const SizedBox(height: 24),
             TextField(
               controller: _categoryController,
               decoration: InputDecoration(
                 labelText: 'Custom ${widget.itemTermSingular} Category',
                 hintText: 'e.g., Action Movies, Grade 10 Math...',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                 prefixIcon: const Icon(Icons.category_outlined),
                 filled: true,
                 fillColor: Colors.grey[50],
               ),
               textCapitalization: TextCapitalization.words,
               onChanged: (val) {
                 setState(() {
                   _selectedSuggestion = '';
                 });
               },
             ),
             const SizedBox(height: 32),
             SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                   onPressed: _isSaving ? null : _saveCategory,
                   style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
             ),
             const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }
}
