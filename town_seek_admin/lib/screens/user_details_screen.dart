import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _refreshDetails();
  }

  void _refreshDetails() {
    setState(() {
      _detailsFuture = Provider.of<SupabaseService>(context, listen: false).getFullUserDetails(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<SupabaseService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('User Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshDetails),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final profile = data['profile'] ?? {};
          final shops = data['shops'] as List? ?? [];
          final reviews = data['reviews'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(profile, service),
                const SizedBox(height: 24),
                _buildPersonalDetails(profile),
                const SizedBox(height: 24),
                _buildAccountStats(profile, shops.length, reviews.length),
                const SizedBox(height: 24),
                _buildSectionTitle('Owned Establishments'),
                _buildShopsList(shops),
                const SizedBox(height: 24),
                _buildSectionTitle('Recent Activity (Reviews)'),
                _buildReviewsList(reviews),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> profile, SupabaseService service) {
    final bool isBlocked = profile['is_disabled'] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF2962FF).withOpacity(0.1),
                backgroundImage: profile['avatar_url'] != null ? CachedNetworkImageProvider(profile['avatar_url']) : null,
                child: profile['avatar_url'] == null ? const Icon(Icons.person, size: 40, color: Color(0xFF2962FF)) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile['name'] ?? 'Anonymous', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (profile['email'] != null)
                      Text(profile['email'], style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (profile['role'] == 'admin') ? Colors.purple[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile['role']?.toString().toUpperCase() ?? 'USER',
                        style: TextStyle(
                          color: (profile['role'] == 'admin') ? Colors.purple : Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderAction(
                isBlocked ? 'ENABLE ACCOUNT' : 'DISABLE ACCOUNT',
                isBlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                isBlocked ? Colors.green : Colors.orange,
                () async {
                  try {
                    if (isBlocked) {
                      await service.unblockUser(widget.userId);
                    } else {
                      await service.blockUser(widget.userId);
                    }
                    _refreshDetails();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                },
              ),
              _buildHeaderAction(
                'DELETE PERMANENT',
                Icons.delete_forever_rounded,
                Colors.red,
                () async {
                  final confirm = await _showConfirmDelete();
                  if (confirm) {
                    try {
                      await service.deleteUser(widget.userId);
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAccountStats(Map<String, dynamic> profile, int shopCount, int reviewCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double itemWidth = (constraints.maxWidth - 32) / 3;
        if (constraints.maxWidth < 600) {
           itemWidth = (constraints.maxWidth - 16) / 2;
        }
        if (constraints.maxWidth < 400) {
           itemWidth = constraints.maxWidth;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(width: itemWidth, child: _buildStatItem('Joined', _formatDate(profile['created_at']), Icons.calendar_today)),
            SizedBox(width: itemWidth, child: _buildStatItem('Shops', shopCount.toString(), null, customIcon: Image.asset('assets/Logo.png', width: 22, height: 22))),
            SizedBox(width: itemWidth, child: _buildStatItem('Reviews', reviewCount.toString(), Icons.rate_review)),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData? icon, {Widget? customIcon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          customIcon ?? Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildShopsList(List shops) {
    if (shops.isEmpty) return _buildEmptyCard('No establishments owned.');
    final service = Provider.of<SupabaseService>(context, listen: false);
    
    return Column(
      children: shops.map((shop) {
        final bool isVerified = shop['is_verified'] ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              backgroundImage: (shop['logo_url'] ?? shop['image_url']) != null 
                  ? CachedNetworkImageProvider((shop['logo_url'] ?? shop['image_url']).toString()) 
                  : null,
              child: (shop['logo_url'] ?? shop['image_url']) == null 
                  ? const Icon(Icons.store, color: Colors.blue) 
                  : null,
            ),
            title: Text(shop['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(shop['category'] ?? 'Category', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVerified)
                  const Icon(Icons.verified, color: Colors.blue, size: 18),
                const Icon(Icons.expand_more),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShopAction(
                      isVerified ? 'UNVERIFY' : 'VERIFY',
                      isVerified ? Icons.pending_actions : Icons.verified_user,
                      isVerified ? Colors.orange : Colors.blue,
                      () async {
                        try {
                          await service.toggleShopVerification(shop['id'], !isVerified);
                          _refreshDetails();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification update failed: $e')));
                        }
                      },
                    ),
                    _buildShopAction(
                      'DELETE',
                      Icons.delete_outline,
                      Colors.red,
                      () async {
                        final confirm = await _showConfirmShopDelete(shop['name'] ?? 'this establishment');
                        if (confirm) {
                          try {
                            await service.deleteShop(shop['id']);
                            _refreshDetails();
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShopAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmShopDelete(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Establishment?'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
  }


  Widget _buildReviewsList(List reviews) {
    if (reviews.isEmpty) return _buildEmptyCard('No recent activity found.');
    return Column(
      children: reviews.map((review) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(review['shops']?['name'] ?? 'Unknown Shop'),
          subtitle: Text(review['review_text'] ?? 'No text'),
          trailing: Text('${review['rating']} ★', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
    );
  }

  Future<bool> _showConfirmDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This will wipe all data for this user. This is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('WIPE DATA')),
        ],
      ),
    ) ?? false;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('MMM yyyy').format(dt);
    } catch (_) { return 'N/A'; }
  }

  Widget _buildPersonalDetails(Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.person_outline, 'Full Name', profile['name'] ?? 'N/A'),
          if (profile['email'] != null)
            _buildDetailRow(Icons.email_outlined, 'Email Address', profile['email']!),
          _buildDetailRow(Icons.phone_outlined, 'Phone Number', profile['phone'] ?? 'Not provided'),
          _buildDetailRow(Icons.location_on_outlined, 'Location', profile['address'] ?? 'Not set'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2962FF)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
