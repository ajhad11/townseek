import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/shop_data.dart';
import '../widgets/shop_card.dart';
import '../utils/category_term_helper.dart';

class ManageOfferingsPage extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ManageOfferingsPage({super.key, required this.shop});

  @override
  State<ManageOfferingsPage> createState() => _ManageOfferingsPageState();
}

class _ManageOfferingsPageState extends State<ManageOfferingsPage> {
  bool _isLoading = true;
  List<ShopOffering> _offerings = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    final offerings = await ShopData.fetchOfferings(widget.shop['id']?.toString());
    if (mounted) setState(() { _offerings = offerings; _isLoading = false; });
  }

  Future<void> _delete(ShopOffering offering) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${offering.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await ShopData.deleteOffering(offering.id);
    _fetchData();
  }

  void _showForm({ShopOffering? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OfferingFormSheet(
        shopId: widget.shop['id']?.toString() ?? '',
        shopCategory: widget.shop['category']?.toString() ?? '',
        existing: existing,
        onSaved: () {
          Navigator.pop(context);
          _fetchData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final term = CategoryTermHelper.getPluralTerm(widget.shop['category']?.toString());
    final singularTerm = CategoryTermHelper.getSingularTerm(widget.shop['category']?.toString());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Manage $term', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF2962FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add $singularTerm', style: const TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offerings.isEmpty
              ? _buildEmptyState(singularTerm, term)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: _offerings.length,
                  itemBuilder: (context, index) => _buildCard(_offerings[index]),
                ),
    );
  }

  Widget _buildEmptyState(String singularTerm, String term) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No $term Yet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Tap the button below to add your first $singularTerm.', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add),
            label: Text('Add $singularTerm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ShopOffering offering) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          if (offering.imageUrl != null && offering.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: offering.imageUrl!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, err) => Container(width: 90, height: 90, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
            )
          else
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: const Icon(Icons.school_outlined, color: Colors.grey),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offering.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (offering.description != null && offering.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(offering.description!, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (offering.price != null && offering.price!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(offering.price!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2962FF))),
                  ],
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF2962FF), size: 20), onPressed: () => _showForm(existing: offering)),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _delete(offering)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferingFormSheet extends StatefulWidget {
  final String shopId;
  final String shopCategory;
  final ShopOffering? existing;
  final VoidCallback onSaved;

  const _OfferingFormSheet({
    required this.shopId,
    required this.shopCategory,
    required this.onSaved,
    this.existing,
  });

  @override
  State<_OfferingFormSheet> createState() => _OfferingFormSheetState();
}

class _OfferingFormSheetState extends State<_OfferingFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  dynamic _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _descController.text = widget.existing!.description ?? '';
      _priceController.text = widget.existing!.price ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _selectedImage = bytes);
      } else {
        setState(() => _selectedImage = io.File(pickedFile.path));
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.shopId}_offering.jpg';
    if (kIsWeb) {
      await Supabase.instance.client.storage.from('shop-images').uploadBinary(fileName, _selectedImage);
    } else {
      await Supabase.instance.client.storage.from('shop-images').upload(fileName, _selectedImage as io.File);
    }
    return Supabase.instance.client.storage.from('shop-images').getPublicUrl(fileName);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? imageUrl = widget.existing?.imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }

      final data = {
        'title': title,
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'price': _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
        if (imageUrl != null) 'image_url': imageUrl,
      };

      if (widget.existing != null) {
        await ShopData.updateOffering(widget.existing!.id, data);
      } else {
        await ShopData.addOffering({...data, 'shop_id': widget.shopId});
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final singularTerm = CategoryTermHelper.getSingularTerm(widget.shopCategory);
    final isEditing = widget.existing != null;
    final existingImageUrl = widget.existing?.imageUrl;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
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
                  Text(isEditing ? 'Edit $singularTerm' : 'Add $singularTerm', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),

              // Image picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                      image: _selectedImage != null
                          ? (kIsWeb
                              ? DecorationImage(image: MemoryImage(_selectedImage as Uint8List), fit: BoxFit.cover)
                              : DecorationImage(image: FileImage(_selectedImage as io.File), fit: BoxFit.cover))
                          : (existingImageUrl != null
                              ? DecorationImage(image: NetworkImage(existingImageUrl), fit: BoxFit.cover)
                              : null),
                    ),
                    child: _selectedImage == null && existingImageUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 32),
                              SizedBox(height: 4),
                              Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : isEditing
                            ? Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                  ),
                                ),
                              )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '$singularTerm Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (optional)',
                  hintText: 'e.g. Rs 1999',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEditing ? 'Save Changes' : 'Add $singularTerm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
