import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import 'shop_details_screen.dart';
import 'hospital_details_screen.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  late Future<List<Map<String, dynamic>>> _pendingShopsFuture;
  final Map<String, bool> _loadingShops = {};

  @override
  void initState() {
    super.initState();
    _refreshPendingShops();
  }

  void _refreshPendingShops() {
    setState(() {
      _pendingShopsFuture = Provider.of<SupabaseService>(context, listen: false).getPendingShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<SupabaseService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pending Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPendingShops,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingShopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline_rounded, size: 60, color: Colors.orangeAccent),
                   const SizedBox(height: 16),
                   Text('Failed to fetch pending requests: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                   const SizedBox(height: 16),
                   ElevatedButton(onPressed: _refreshPendingShops, child: const Text('Try Again')),
                ],
              ),
            );
          }

          final pendingShops = snapshot.data ?? [];

          if (pendingShops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Text('No establishments are currently pending verification.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingShops.length,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemBuilder: (context, index) {
              final shop = pendingShops[index];
              final shopId = shop['id'].toString();
              final bool isUpdating = _loadingShops[shopId] ?? false;
              final owner = shop['profiles'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.orange.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        // Routing logic remains same as shop list
                        final String category = (shop['category'] ?? '').toString().toLowerCase();
                        final String name = (shop['name'] ?? '').toString().toLowerCase();
                        if (category.contains('hospital') || name.contains('hospital')) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HospitalDetailsScreen(shopId: shop['id'])));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ShopDetailsScreen(shopId: shop['id'])));
                        }
                      },
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: (shop['logo_url'] != null || shop['image_url'] != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: (shop['logo_url'] ?? shop['image_url']).toString(),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Icon(Icons.storefront_rounded, color: Colors.orange),
                                  errorWidget: (context, url, error) => const Icon(Icons.storefront_rounded, color: Colors.orange),
                                ),
                              )
                            : const Icon(Icons.storefront_rounded, color: Colors.orange),
                      ),
                      title: Text(shop['name'] ?? 'Establishment', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Owner: ${owner != null ? owner['name'] ?? 'System ID' : 'Unknown'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.grey),
                            onPressed: () {
                               if ((shop['category'] ?? '').toString().toLowerCase().contains('hospital')) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => HospitalDetailsScreen(shopId: shop['id'])));
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ShopDetailsScreen(shopId: shop['id'])));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text('Awaiting Verification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
                            ],
                          ),
                          isUpdating
                              ? const SizedBox(width: 100, height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)))
                              : ElevatedButton(
                                  onPressed: () async {
                                    setState(() => _loadingShops[shopId] = true);
                                    try {
                                      await service.toggleShopVerification(shopId, true);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Establishment Verified successfully.')));
                                      _refreshPendingShops();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
                                    } finally {
                                      if (mounted) setState(() => _loadingShops[shopId] = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2962FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  child: const Text('VERIFY NOW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
