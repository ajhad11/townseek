import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/time_helper.dart';
import 'business_adding_page.dart';
import 'business_edit_page.dart';
import 'manage_products_page.dart';
import 'manage_offerings_page.dart';
import 'manage_offers_page.dart';
import 'orders_bookings_page.dart';
import 'manage_resources_page.dart';
import 'manage_doctors_page.dart';
import '../utils/category_term_helper.dart';
import 'shop_analytics_page.dart';

import '../widgets/shop_card.dart';
import '../widgets/custom_header.dart';
import '../data/shop_data.dart';
import '../widgets/qr_display_dialog.dart';

class BusinessDashboardPage extends StatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myBusinesses = [];
  String? _errorMessage;

  String _getItemTermPlural(String? category) {
    final cat = category?.toLowerCase() ?? '';
    switch (cat) {
      case 'education': return 'Courses';
      case 'services':
      case 'publicservices':
      case 'public services': return 'Services';
      case 'religious': return 'Programs';
      case 'entertainment': return 'Events';
      default: return 'Products';
    }
  }

  String _getOfferTermPlural(String? category) {
    final cat = category?.toLowerCase().replaceAll(' ', '') ?? '';
    if (cat == 'religious') {
      return 'Schedules';
    }
    if (cat == 'publicservices') {
      return 'Announcements';
    }
    return 'Offers';
  }

  @override
  void initState() {
    super.initState();
    _fetchMyBusinesses();
  }

  Future<void> _fetchMyBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in to view your businesses.';
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('shops')
          .select('*, working_days(day_of_week), reviews(rating)')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fetchedBusinesses =
          List<Map<String, dynamic>>.from(response as List);

      for (var shop in fetchedBusinesses) {
        double effectiveRating = 0.0;
        if (shop['reviews'] != null) {
          dynamic revsData = shop['reviews'];
          List<dynamic> revs = [];
          if (revsData is List) {
             revs = revsData;
          } else if (revsData is String) {
             try {
                revs = jsonDecode(revsData) as List<dynamic>;
             } catch (_) {}
          }
          if (revs.isNotEmpty) {
            double total = 0.0;
            for (var r in revs) {
              total += (r['rating'] as num).toDouble();
            }
            effectiveRating = total / revs.length;
          }
        }
        shop['rating'] = effectiveRating;
      }

      setState(() {
        _myBusinesses = fetchedBusinesses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load businesses. Please try again.';
      });
      debugPrint('Error fetching my businesses: $e');
    }
  }

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

  void _showAnalyticsSheet(Map<String, dynamic> shop) {
    final int clicks = (shop['profile_clicks'] as num?)?.toInt() ?? 0;
    final String name = shop['name'] ?? 'Business';
    final double rating = (shop['rating'] ?? 0.0) is num
        ? (shop['rating'] as num).toDouble()
        : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (shop['open_now'] != null)
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await ShopData.updateShopOpenStatus(shop['id'].toString(), null);
                            setState(() {
                              shop['open_now'] = null;
                            });
                              if (!mounted) return;
                              if (context.mounted) {
                                Navigator.pop(ctx); // Close sheet to reflect changes
                                _fetchMyBusinesses();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Status reset to automatic schedule')),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reset to Auto'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2962FF),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => QRDisplayDialog(
                            shopId: shop['id'].toString(),
                            shopTitle: name,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2962FF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code, size: 22, color: Color(0xFF2962FF)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsTile(
                    icon: Icons.touch_app_rounded,
                    label: 'Profile Clicks',
                    value: clicks.toString(),
                    iconColor: const Color(0xFF00897B),
                    bgColor: const Color(0xFFE0F2F0),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildAnalyticsTile(
                    icon: Icons.star_rounded,
                    label: 'Avg. Rating',
                    value: rating.toStringAsFixed(1),
                    iconColor: const Color(0xFFF9A825),
                    bgColor: const Color(0xFFFFF9E6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BusinessEditPage(shopToEdit: shop),
                    ),
                  ).then((_) => _fetchMyBusinesses());
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Business'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2962FF),
                  side: const BorderSide(color: Color(0xFF2962FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopAnalyticsPage(shop: shop),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_rounded, size: 20),
                label: const Text('View Detailed Analytics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFF2962FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final isOffering = CategoryTermHelper.isOfferingCategory(shop['category']?.toString());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => isOffering
                          ? ManageOfferingsPage(shop: shop)
                          : ManageProductsPage(shop: shop),
                    ),
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined, size: 16),
                label: Text('Manage ${_getItemTermPlural(shop['category']?.toString())}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageOffersPage(shop: shop),
                    ),
                  );
                },
                icon: const Icon(Icons.local_offer_outlined, size: 16),
                label: Text('Manage ${_getOfferTermPlural(shop['category']?.toString())}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFF2962FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageResourcesPage(shop: shop),
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Manage Resources'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFF673AB7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (['hospital', 'groceries', 'food', 'groceriesandfood', 'groceries & food'].contains(shop['category']?.toString().toLowerCase().replaceAll(' ', ''))) ...[
              const SizedBox(height: 12),
              if (shop['category']?.toString().toLowerCase().replaceAll(' ', '') == 'hospital') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageDoctorsPage(shop: shop),
                        ),
                      );
                    },
                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                    label: const Text('Manage Doctors'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFFE91E63),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersBookingsPage(
                          shopId: shop['id'].toString(),
                          shopName: name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: Text(
                    shop['category']?.toString().toLowerCase().replaceAll(' ', '') == 'hospital'
                        ? 'Manage Bookings'
                        : 'Manage Orders',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFF00897B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> shop) {
    final String name = shop['name'] ?? 'Unknown Business';
    final String address = shop['address'] ?? 'No address';
    final String imageUrl = shop['image_url'] ?? '';
    final String category = shop['category'] ?? '';
    final double rating = (shop['rating'] ?? 0.0) is num
        ? (shop['rating'] as num).toDouble()
        : 0.0;
    final List<String> tags = _parseTags(shop['tags']);
    final String? openStr = shop['opening_time']?.toString();
  final String? closeStr = shop['closing_time']?.toString();
  final bool? openOverride = shop['open_now'];
  final bool isOpen = openOverride ?? TimeHelper.isShopOpen(openStr, closeStr);
    final int clicks = (shop['profile_clicks'] as num?)?.toInt() ?? 0;


    return GestureDetector(
      onTap: () => _showAnalyticsSheet(shop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop card image + info
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: ShopCard(
                    imageUrl: imageUrl,
                    title: name,
                    subtitle: address,
                    rating: rating.toStringAsFixed(1),
                    tags: tags.isNotEmpty
                        ? tags.take(3).toList()
                        : [category.isEmpty ? 'Business' : _capitalize(category)],
                    isOpen: isOpen,
                    category: category,
                    openNowOverride: openOverride,
                  ),
                ),
                if (shop['is_verified'] == false)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Waiting for Verification',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (shop['is_verified'] != false)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                      // Toggle between forced open (true) and forced closed (false)
                      final bool newValue = !(openOverride ?? isOpen);
                      await ShopData.updateShopOpenStatus(shop['id'].toString(), newValue);
                      _fetchMyBusinesses();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Long press to reset to automatic schedule')),
                        );
                      }
                    },
                    onLongPress: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      // Reset to automatic (null)
                      await ShopData.updateShopOpenStatus(shop['id'].toString(), null);
                      _fetchMyBusinesses();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Status reset to automatic schedule')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOpen ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOpen ? "OPEN" : "CLOSED",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (openOverride != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, color: Colors.white, size: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Analytics strip
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Clicks
                  Icon(Icons.touch_app_rounded,
                      size: 15, color: const Color(0xFF00897B)),
                  const SizedBox(width: 4),
                  Text(
                    '$clicks clicks',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00897B)),
                  ),
                  const Spacer(),
                  // Tap hint
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2962FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Analytics',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2962FF),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded,
                            size: 14, color: Color(0xFF2962FF)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BusinessEditPage(shopToEdit: shop),
                      ),
                    );
                    _fetchMyBusinesses();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2962FF),
                    side: const BorderSide(color: Color(0xFF2962FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF2962FF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store_mall_directory_outlined,
                size: 52,
                color: Color(0xFF2962FF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Businesses Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You haven\'t added any businesses. Tap the button below to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusinessAddingPage(),
                    ),
                  );
                  _fetchMyBusinesses();
                },
                icon: const Icon(Icons.add_business, color: Colors.white),
                label: const Text(
                  'ADD YOUR BUSINESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final int count = _myBusinesses.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomHeader(
            showBackButton: true,
            title: 'Dashboard',
            onBack: () => Navigator.pop(context),
          ),
          // Listing count bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Listings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF2962FF)),
                      onPressed: _fetchMyBusinesses,
                      tooltip: 'Refresh Analytics',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _isLoading
                      ? 'Loading...'
                      : '$count listing${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchMyBusinesses,
              color: const Color(0xFF2962FF),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2962FF)),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 56, color: Colors.redAccent),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black54),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _fetchMyBusinesses,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2962FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Retry',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _myBusinesses.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                              itemCount: _myBusinesses.length,
                              itemBuilder: (context, index) =>
                                  _buildBusinessCard(_myBusinesses[index]),
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: (!_isLoading && _myBusinesses.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusinessAddingPage(),
                  ),
                );
                _fetchMyBusinesses();
              },
              backgroundColor: const Color(0xFF2962FF),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Business',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            )
          : null,
    );
  }
}
