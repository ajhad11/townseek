import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class ShopDetailsScreen extends StatefulWidget {
  final String shopId;
  const ShopDetailsScreen({super.key, required this.shopId});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _refreshDetails();
  }

  void _refreshDetails() {
    setState(() {
      _detailsFuture = Provider.of<SupabaseService>(context, listen: false).getShopDetails(widget.shopId);
    });
  }

  double _calculateAverageRating(List reviews) {
    if (reviews.isEmpty) return 0.0;
    double total = 0;
    for (var review in reviews) {
      total += (review['rating'] ?? 0).toDouble();
    }
    return total / reviews.length;
  }

  Future<void> _handleDeleteProduct(String productId) async {
    final confirmed = await _showConfirmDialog('Delete Product', 'Are you sure you want to delete this product?');
    if (confirmed) {
      try {
        await Provider.of<SupabaseService>(context, listen: false).deleteProduct(productId);
        _refreshDetails();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleToggleProduct(String productId, bool currentlyDisabled) async {
    try {
      await Provider.of<SupabaseService>(context, listen: false).toggleProductStatus(productId, !currentlyDisabled);
      _refreshDetails();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product ${!currentlyDisabled ? 'disabled' : 'enabled'}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleDeleteOffer(String offerId) async {
    final confirmed = await _showConfirmDialog('Delete Offer', 'Are you sure you want to delete this offer?');
    if (confirmed) {
      try {
        await Provider.of<SupabaseService>(context, listen: false).deleteOffer(offerId);
        _refreshDetails();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleDeleteReview(String reviewId) async {
    final confirmed = await _showConfirmDialog('Delete Review', 'Are you sure you want to delete this review?');
    if (confirmed) {
      try {
        await Provider.of<SupabaseService>(context, listen: false).deleteReview(reviewId);
        _refreshDetails();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Shop Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDetails,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refreshDetails, child: const Text('Retry')),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final shop = data['shop'] ?? {};
          final products = (data['products'] as List? ?? []);
          final offers = (data['offers'] as List? ?? []);
          final reviews = (data['reviews'] as List? ?? []);
          final workingDays = (data['working_days'] as List? ?? []);
          final media = (data['media'] as Map<String, dynamic>? ?? {});

          final avgRating = _calculateAverageRating(reviews);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShopHeader(shop),
                const SizedBox(height: 24),
                _buildStatisticsGrid(products.length, offers.length, reviews.length, avgRating),
                const SizedBox(height: 24),
                _buildSectionTitle('Products'),
                _buildProductsList(products),
                const SizedBox(height: 24),
                _buildSectionTitle('Offers'),
                _buildOffersList(offers),
                const SizedBox(height: 24),
                _buildSectionTitle('Reviews'),
                _buildReviewsList(reviews),
                const SizedBox(height: 24),
                _buildSectionTitle('Working Days Monitoring'),
                _buildWorkingDaysList(workingDays),
                const SizedBox(height: 24),
                _buildSectionTitle('Media Management'),
                _buildMediaSection(media),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopHeader(Map<String, dynamic> shop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: shop['image_url'] != null
                    ? Image.network(shop['image_url'], width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholderImage())
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((shop['name'] ?? 'Unnamed Shop').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text((shop['category'] ?? 'No Category').toString(), style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text((shop['address'] ?? 'No Address').toString(), style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text((shop['phone'] ?? 'No Phone').toString(), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Verification Status: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Switch(
                          value: shop['is_verified'] ?? false,
                          onChanged: (value) async {
                            try {
                              await Provider.of<SupabaseService>(context, listen: false).toggleShopVerification(shop['id'], value);
                              _refreshDetails();
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shop ${value ? 'verified' : 'unverified'}')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text((shop['description'] ?? 'No description available.').toString(), style: TextStyle(color: Colors.grey[700], height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Opens: ${shop['opening_time'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[50],
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        'assets/Logo.png',
        fit: BoxFit.contain,
        colorBlendMode: BlendMode.dstIn,
      ),
    );
  }

  Widget _buildStatisticsGrid(int totalProducts, int totalOffers, int totalReviews, double avgRating) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.2,
          children: [
            _buildStatCard('Total Products', totalProducts.toString(), Icons.shopping_bag_outlined, Colors.blue),
            _buildStatCard('Total Offers', totalOffers.toString(), Icons.local_offer_outlined, Colors.orange),
            _buildStatCard('Total Reviews', totalReviews.toString(), Icons.rate_review_outlined, Colors.green),
            _buildStatCard('Average Rating', avgRating.toStringAsFixed(1), Icons.star_outline, Colors.amber),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    );
  }

  Widget _buildProductsList(List products) {
    if (products.isEmpty) return _buildEmptyState('No products found');
    return Column(
      children: products.map((product) {
        final bool isDisabled = product['is_disabled'] ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDisabled ? Colors.red.withOpacity(0.2) : Colors.transparent),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product['image_url'] != null
                  ? Image.network(product['image_url'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildItemPlaceholder())
                  : _buildItemPlaceholder(),
            ),
            title: Text((product['name'] ?? 'Unnamed Product').toString(), style: TextStyle(fontWeight: FontWeight.bold, decoration: isDisabled ? TextDecoration.lineThrough : null)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((product['category'] ?? 'General').toString(), style: TextStyle(color: Colors.blue[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text((product['description'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                Text('Created: ${_formatDate(product['created_at'])}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isDisabled ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDisabled ? Colors.orange : Colors.grey),
                  onPressed: () => _handleToggleProduct(product['id'], isDisabled),
                  tooltip: isDisabled ? 'Enable' : 'Disable',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _handleDeleteProduct(product['id']),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOffersList(List offers) {
    if (offers.isEmpty) return _buildEmptyState('No offers found');
    return Column(
      children: offers.map((offer) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: offer['poster'] != null
                  ? Image.network(offer['poster'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildItemPlaceholder())
                  : _buildItemPlaceholder(),
            ),
            title: Text((offer['offer_title'] ?? 'No Title').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((offer['description'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('Expires: ${offer['expiry'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                Text('Created: ${_formatDate(offer['created_at'])}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _handleDeleteOffer(offer['id']),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewsList(List reviews) {
    if (reviews.isEmpty) return _buildEmptyState('No reviews found');
    return Column(
      children: reviews.map((review) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundImage: review['profiles']?['avatar_url'] != null ? NetworkImage(review['profiles']['avatar_url']) : null,
              child: review['profiles']?['avatar_url'] == null ? const Icon(Icons.person) : null,
            ),
            title: Row(
              children: [
                Text(review['profiles']?['name'] ?? 'User ${(review['user_id']?.toString() ?? '...').substring(0, (review['user_id']?.toString() ?? '').length > 5 ? 5 : (review['user_id']?.toString() ?? '').length)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(review['rating']?.toString() ?? '0', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(review['review_text'] ?? 'No review text', style: TextStyle(color: Colors.grey[800])),
                const SizedBox(height: 8),
                Text(_formatDate(review['created_at'], showTime: true), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _handleDeleteReview(review['id']),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkingDaysList(List workingDays) {
    if (workingDays.isEmpty) return _buildEmptyState('No working days scheduled');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: workingDays.map((day) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text((day['day_of_week'] ?? day['day_name'] ?? 'Unknown Day').toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                const Spacer(),
                Text('${day['start_time'] ?? day['open_time'] ?? 'N/A'} - ${day['end_time'] ?? day['close_time'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaSection(Map media) {
    if (media.isEmpty) return _buildEmptyState('No media links available');
    
    final links = {
      'Instagram': {'value': media['instagram'], 'icon': Icons.camera_alt_outlined, 'color': Colors.pink},
      'Website': {'value': media['website'], 'icon': Icons.language, 'color': Colors.blue},
      'YouTube': {'value': media['youtube'], 'icon': Icons.play_circle_outline, 'color': Colors.red},
      'Facebook': {'value': media['facebook'], 'icon': Icons.facebook, 'color': Colors.indigo},
      'YouTube Video': {'value': media['youtube_video'], 'icon': Icons.video_library_outlined, 'color': Colors.redAccent},
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: links.entries.map((entry) {
          final val = entry.value['value'];
          if (val == null || val.toString().isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(entry.value['icon'] as IconData, color: entry.value['color'] as Color, size: 20),
                const SizedBox(width: 12),
                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: Text(
                    val.toString(),
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.blue, fontSize: 13, decoration: TextDecoration.underline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Center(child: Text(message, style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic))),
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(width: 60, height: 60, color: Colors.grey[100], child: const Icon(Icons.image, color: Colors.grey));
  }

  String _formatDate(dynamic dateStr, {bool showTime = false}) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.tryParse(dateStr.toString());
      if (dateTime == null) return dateStr.toString();
      // Explicitly forcing en_US locale for DateFormat
      return DateFormat(showTime ? 'MMM dd, yyyy HH:mm' : 'MMM dd, yyyy', 'en_US').format(dateTime);
    } catch (e) {
      return dateStr.toString();
    }
  }
}
