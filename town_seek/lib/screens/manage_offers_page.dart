import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../utils/icon_helper.dart';

class ManageOffersPage extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ManageOffersPage({super.key, required this.shop});

  @override
  State<ManageOffersPage> createState() => _ManageOffersPageState();
}

class _ManageOffersPageState extends State<ManageOffersPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _offers = [];

  List<String> _parseTags(dynamic tagsRaw) {
    if (tagsRaw == null) return [];
    if (tagsRaw is List) return List<String>.from(tagsRaw);
    if (tagsRaw is String) {
      return tagsRaw
          .replaceAll(RegExp(r'[\[\]"]'), '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  String get _offerTermSingular {
    final cat = widget.shop['category']?.toString().toLowerCase().replaceAll(' ', '') ?? '';
    if (cat == 'religious') return 'Schedule';
    if (cat == 'publicservices') return 'Announcement';
    return 'Offer';
  }

  String get _offerTermPlural {
    final cat = widget.shop['category']?.toString().toLowerCase().replaceAll(' ', '') ?? '';
    if (cat == 'religious') return 'Schedules';
    if (cat == 'publicservices') return 'Announcements';
    return 'Offers';
  }

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final shopId = widget.shop['id'];
      final response = await Supabase.instance.client
          .from('offers')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching offers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading $_offerTermPlural: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteOffer(Map<String, dynamic> offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $_offerTermSingular'),
        content: Text('Are you sure you want to delete "${offer['offer_title']}"?'),
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
          .from('offers')
          .delete()
          .eq('id', offer['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_offerTermSingular deleted successfully')));
      }
      await _fetchOffers();
    } catch (e) {
      debugPrint("Error deleting offer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete $_offerTermSingular: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddOfferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddOfferSheet(
        shopId: widget.shop['id'],
        itemTermSingular: _offerTermSingular,
        onOfferAdded: () {
          Navigator.pop(context); // Close the sheet
          _fetchOffers();
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('$_offerTermSingular added successfully!'))
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
        title: Text('Manage $_offerTermPlural', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          : _offers.isEmpty
              ? _buildEmptyState()
              : _buildOffersList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOfferSheet,
        backgroundColor: const Color(0xFF2962FF),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text('New $_offerTermSingular', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No $_offerTermPlural Yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new $_offerTermSingular to attract customers.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
             onPressed: _showAddOfferSheet,
             icon: const Icon(Icons.add),
             label: Text('Add First $_offerTermSingular'),
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

  Widget _buildOffersList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
      itemCount: _offers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        final expireDateStr = offer['expiry'];
        String formattedDate = '';
        if (expireDateStr != null) {
          try {
            final date = DateTime.parse(expireDateStr.toString());
            formattedDate = DateFormat('MMM d, yyyy').format(date);
          } catch (_) {
            formattedDate = expireDateStr.toString();
          }
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(16),
             side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (offer['poster'] != null && offer['poster'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: offer['poster'],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, err) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: IconHelper.getColor(widget.shop['category']).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Icon(
                    IconHelper.getIcon(widget.shop['category'], _parseTags(widget.shop['tags'])),
                    size: 40,
                    color: IconHelper.getColor(widget.shop['category']),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer['offer_title'] ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          if (offer['description'] != null && offer['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              offer['description'],
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                'Expires: $formattedDate',
                                style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteOffer(offer),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddOfferSheet extends StatefulWidget {
  final dynamic shopId;
  final String itemTermSingular;
  final VoidCallback onOfferAdded;

  const _AddOfferSheet({
    required this.shopId,
    required this.itemTermSingular,
    required this.onOfferAdded,
  });

  @override
  State<_AddOfferSheet> createState() => _AddOfferSheetState();
}

class _AddOfferSheetState extends State<_AddOfferSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  dynamic _selectedImage;
  DateTime? _expireDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _expireDate = picked;
      });
    }
  }

  Future<void> _saveOffer() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
        return;
    }

    bool isSchedule = widget.itemTermSingular == 'Schedule';
    bool isAnnouncement = widget.itemTermSingular == 'Announcement';

    if (!isSchedule && !isAnnouncement && _expireDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expire date is required.')));
        return;
    }

    setState(() {
       _isSaving = true;
    });

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.shopId}_offer.jpg';
        if (kIsWeb) {
          await Supabase.instance.client.storage
              .from('offer_posters')
              .uploadBinary(fileName, _selectedImage as Uint8List);
        } else {
          await Supabase.instance.client.storage
              .from('offer_posters')
              .upload(fileName, _selectedImage as io.File);
        }
            
        imageUrl = Supabase.instance.client.storage
            .from('offer_posters')
            .getPublicUrl(fileName);
      }
      
      final parsedShopId = int.tryParse(widget.shopId.toString()) ?? widget.shopId;

      await Supabase.instance.client.from('offers').insert({
         'shop_id': parsedShopId,
         'offer_title': title,
         'description': description,
         if (imageUrl != null) 'poster': imageUrl,
         if (_expireDate != null) 'expiry': _expireDate!.toIso8601String(),
      }).select();

      widget.onOfferAdded();
      
    } catch (e) {
      debugPrint("Error saving offer: $e");
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
                     'Add ${widget.itemTermSingular}',
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
                     width: double.infinity,
                     height: MediaQuery.of(context).size.width * (9/16), // 16:9 ratio
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
                               Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
                               SizedBox(height: 8),
                               Text('Add Poster Image', style: TextStyle(color: Colors.grey, fontSize: 14)),
                               Text('16:9 Aspect Ratio Recommended', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          )
                        : null,
                  ),
               ),
             ),
             
             const SizedBox(height: 24),
             
             // Form Fields
             TextField(
               controller: _titleController,
               decoration: InputDecoration(
                 labelText: '${widget.itemTermSingular} Title *',
                 hintText: 'e.g., Summer Discount 50% Off / Sunday Mass',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                 prefixIcon: const Icon(Icons.title),
                 filled: true,
                 fillColor: Colors.grey[50], 
               ),
               textCapitalization: TextCapitalization.words,
             ),
             
             const SizedBox(height: 16),
             
             TextField(
               controller: _descriptionController,
               decoration: InputDecoration(
                 labelText: 'Description (Optional)',
                 hintText: 'e.g., Valid until stocks last',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                 prefixIcon: const Icon(Icons.description_outlined),
                 filled: true,
                 fillColor: Colors.grey[50], 
               ),
               maxLines: 3,
               minLines: 1,
             ),
             
             const SizedBox(height: 16),
             
             if (widget.itemTermSingular != 'Schedule' && widget.itemTermSingular != 'Announcement') ...[
               InkWell(
                 onTap: _pickDate,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                   decoration: BoxDecoration(
                     color: Colors.grey[50],
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.grey[400]!),
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.calendar_today, color: Colors.grey),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           _expireDate == null 
                              ? 'Select Expiry Date *' 
                              : 'Expires: ${DateFormat('MMM d, yyyy').format(_expireDate!)}',
                           style: TextStyle(
                             color: _expireDate == null ? Colors.grey[600] : Colors.black87,
                             fontSize: 16,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 32),
             ] else ...[
               const SizedBox(height: 16),
             ],
             
             // Submit Button
             SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                   onPressed: _isSaving ? null : _saveOffer,
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
