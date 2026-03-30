import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import 'shop_details_screen.dart';
import 'hospital_details_screen.dart';

class ShopsListScreen extends StatefulWidget {
  const ShopsListScreen({super.key});

  @override
  State<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends State<ShopsListScreen> {
  late Future<List<Map<String, dynamic>>> _shopsFuture;
  final Map<String, bool> _loadingShops = {};

  @override
  void initState() {
    super.initState();
    _refreshShops();
  }

  void _refreshShops() {
    setState(() {
      _shopsFuture = Provider.of<SupabaseService>(context, listen: false).getAllShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<SupabaseService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Establishment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshShops,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                   const SizedBox(height: 16),
                   Text('Failed to sync establishments: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                   const SizedBox(height: 16),
                   ElevatedButton(onPressed: _refreshShops, child: const Text('Try Again')),
                ],
              ),
            );
          }

          final shops = snapshot.data ?? [];

          if (shops.isEmpty) {
            return const Center(child: Text('No establishments found in database.'));
          }

          return ListView.builder(
            itemCount: shops.length,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemBuilder: (context, index) {
              final shop = shops[index];
              final shopId = shop['id'].toString();
              final bool isVerified = shop['is_verified'] ?? false;
              final bool isUpdating = _loadingShops[shopId] ?? false;
              final owner = shop['profiles'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        final String category = (shop['category'] ?? '').toString().toLowerCase();
                        final String name = (shop['name'] ?? '').toString().toLowerCase();
                        if (category.contains('hospital') || name.contains('hospital')) {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => HospitalDetailsScreen(shopId: shop['id']))
                          );
                        } else {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => ShopDetailsScreen(shopId: shop['id']))
                          );
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2962FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: (shop['logo_url'] != null || shop['image_url'] != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: (shop['logo_url'] ?? shop['image_url']).toString(),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Icon(Icons.storefront_rounded, color: Color(0xFF2962FF)),
                                  errorWidget: (context, url, error) => const Icon(Icons.storefront_rounded, color: Color(0xFF2962FF)),
                                ),
                              )
                            : const Icon(Icons.storefront_rounded, color: Color(0xFF2962FF)),
                      ),
                      title: Text(shop['name'] ?? 'Unnamed Establishment', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Owner: ${owner != null ? owner['name'] ?? 'System ID' : 'Unknown Owner'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isVerified ? Colors.blue[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isVerified ? 'VERIFIED' : 'PENDING VERIFICATION',
                              style: TextStyle(
                                color: isVerified ? Colors.blue : Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF2962FF)),
                            onPressed: () {
                              final String category = (shop['category'] ?? '').toString().toLowerCase();
                              final String name = (shop['name'] ?? '').toString().toLowerCase();
                              if (category.contains('hospital') || name.contains('hospital')) {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => HospitalDetailsScreen(shopId: shop['id']))
                                );
                              } else {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => ShopDetailsScreen(shopId: shop['id']))
                                );
                              }
                            },
                          ),
                          Tooltip(
                            message: 'Wipe Establishment Record',
                            child: IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.orangeAccent),
                              onPressed: () async {
                                 final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Wipe this establishment?'),
                                      content: Text('Remove "${shop['name']}"? This also wipes its schedules, doctors, and reviews permanently.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true), 
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('WIPE DATA'),
                                        ),
                                      ],
                                    ),
                                 );

                                 if (confirm == true) {
                                    try {
                                      await service.deleteShop(shopId);
                                      _refreshShops();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Establishment data wiped.')));
                                    } catch (e) {
                                       if (!context.mounted) return;
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wipe failed: $e')));
                                    }
                                 }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isVerified ? Icons.verified_rounded : Icons.verified_outlined,
                                size: 20,
                                color: isVerified ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Verification',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                           isUpdating
                              ? const SizedBox(
                                  width: 100,
                                  height: 36,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      _loadingShops[shopId] = true;
                                    });
                                    try {
                                      await service.toggleShopVerification(shopId, !isVerified);
                                      _refreshShops();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(!isVerified ? 'Establishment verified.' : 'Verification revoked.'),
                                          backgroundColor: !isVerified ? Colors.blue : Colors.grey[800],
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _loadingShops[shopId] = false;
                                        });
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isVerified ? Colors.blue : Colors.grey[200],
                                    foregroundColor: isVerified ? Colors.white : Colors.black87,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: Text(
                                    isVerified ? 'VERIFIED' : 'VERIFY',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
