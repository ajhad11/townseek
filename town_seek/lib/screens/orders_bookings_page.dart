import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:intl/intl.dart'; // Unused
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/custom_header.dart';

class OrdersBookingsPage extends StatefulWidget {
  final String? shopId; // If null, show user's personal bookings
  final String? shopName;

  const OrdersBookingsPage({super.key, this.shopId, this.shopName});

  @override
  State<OrdersBookingsPage> createState() => _OrdersBookingsPageState();
}

class _OrdersBookingsPageState extends State<OrdersBookingsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  String? _errorMessage;
  final String _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

  bool get isOwnerView => widget.shopId != null;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_currentUserId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Please sign in to view bookings.";
        });
        return;
      }

      // Fetch appointments
      var apptQuery = Supabase.instance.client
          .from('doctor_appointments')
          .select('*, shops:shop_id(name, image_url), doctors:doctor_id(name)');

      if (isOwnerView) {
        apptQuery = apptQuery.eq('shop_id', widget.shopId!);
      } else {
        apptQuery = apptQuery.eq('user_id', _currentUserId);
      }

      final apptResponse = await apptQuery;
      
      // Fetch orders
      var orderQuery = Supabase.instance.client
          .from('orders')
          .select('*, shops:shop_id(name, image_url), products:product_id(name, price, image_url)');

      if (isOwnerView) {
        orderQuery = orderQuery.eq('shop_id', widget.shopId!);
      } else {
        orderQuery = orderQuery.eq('user_id', _currentUserId);
      }
      
      final orderResponse = await orderQuery;

      List<Map<String, dynamic>> combined = [];

      for (var appt in apptResponse as List<dynamic>) {
        Map<String, dynamic> item = Map<String, dynamic>.from(appt);
        item['type'] = 'appointment';
        // For sorting: try to combine appointment_date and start_time if possible, or use created_at
        String dateStr = item['appointment_date']?.toString() ?? item['created_at']?.toString() ?? '';
        item['sortDate'] = dateStr;
        combined.add(item);
      }

      for (var order in orderResponse as List<dynamic>) {
        Map<String, dynamic> item = Map<String, dynamic>.from(order);
        item['type'] = 'order';
        item['sortDate'] = item['created_at']?.toString() ?? '';
        combined.add(item);
      }

      // Sort combined descending by sortDate
      combined.sort((a, b) => (b['sortDate'] as String).compareTo(a['sortDate'] as String));

      setState(() {
        _bookings = combined;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching bookings/orders: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load bookings and orders. Please check your connection.";
      });
    }
  }

  Future<void> _updateStatus(String id, String status, String type) async {
    try {
      final table = type == 'order' ? 'orders' : 'doctor_appointments';
      await Supabase.instance.client
          .from(table)
          .update({'status': status})
          .eq('id', id);
      
      await _fetchBookings(); // Await so list refreshes only after DB write completes
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isOwnerView ? "Manage Orders & Bookings" : "Orders and Bookings";
    final subtitle = isOwnerView ? (widget.shopName ?? "Business Orders & Bookings") : "Your appointments and orders";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomHeader(
            title: title,
            showBackButton: true,
            onBack: () => Navigator.pop(context),
          ),
          
          // Filter/Summary Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoading ? "Loading..." : "${_bookings.length} Orders & Bookings Found",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchBookings,
              color: const Color(0xFF2962FF),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _bookings.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _bookings.length,
                              itemBuilder: (context, index) {
                                return _buildBookingCard(_bookings[index]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final type = booking['type'] ?? 'appointment';
    final shop = booking['shops'];
    final doctor = booking['doctors'];
    final product = booking['products'];
    final rawStatus = booking['status']?.toString() ?? (type == 'order' ? 'pending' : 'booked');
    final status = (rawStatus.trim().isEmpty ? (type == 'order' ? 'pending' : 'booked') : rawStatus).toLowerCase();
    final tokenId = booking['token_no']?.toString();
    final imageUrl = (type == 'order' && product?['image_url'] != null) 
        ? product['image_url'] 
        : (shop?['image_url'] ?? '');
    
    Color statusColor;
    switch (status) {
      // 'confirmed' is not in the DB check constraint natively, but allowed if text constraint is removed
      case 'confirmed':
        statusColor = const Color(0xFF2962FF);
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.amber.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status & ID & Token
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    if (tokenId != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2962FF).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "TOKEN #$tokenId",
                          style: const TextStyle(
                            color: Color(0xFF2962FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  "#${booking['id'].toString().substring(0, 8).toUpperCase()}",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // Main Info Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Shop Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey.shade100,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => Icon(Icons.storefront_rounded, color: Colors.grey.shade400, size: 30),
                        )
                      : Icon(Icons.storefront_rounded, color: Colors.grey.shade400, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwnerView 
                          ? ((type == 'order' ? booking['customer_name'] : booking['full_name']) ?? "Guest User")
                          : (shop?['name'] ?? shop?['title'] ?? "Town Seek Establishment"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type == 'order' 
                            ? "${product?['name'] ?? 'Product'} (x${booking['quantity'] ?? 1})" 
                            : (isOwnerView ? "Patient / Customer" : "Dr. ${doctor?['name'] ?? 'Medical Specialist'}"),
                        style: TextStyle(
                          color: (isOwnerView && type != 'order') ? Colors.grey : const Color(0xFF2962FF),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 14, color: Color(0xFF1A47CC)),
                            const SizedBox(width: 6),
                            Text(
                              type == 'order' 
                                  ? (booking['created_at']?.toString().split('T').first ?? "N/A") 
                                  : (booking['appointment_date'] ?? "N/A"),
                              style: const TextStyle(color: Color(0xFF1A47CC), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time_filled, size: 14, color: Color(0xFF1A47CC)),
                            const SizedBox(width: 6),
                            Text(
                              type == 'order' 
                                  ? (booking['created_at'] != null 
                                      ? booking['created_at'].toString().split('T').last.substring(0, 5) 
                                      : "N/A")
                                  : (booking['start_time'] ?? "N/A"),
                              style: const TextStyle(color: Color(0xFF1A47CC), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Footer Actions (Cancel Booking/Order)
          if (!isOwnerView && status == 'booked' || status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("Cancel ${type == 'order' ? 'Order' : 'Booking'}?"),
                        content: Text("Are you sure you want to cancel this ${type == 'order' ? 'order' : 'appointment'}? This action cannot be undone."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No, Keep it")),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _updateStatus(booking['id'].toString(), 'cancelled', type);
                            },
                            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade100),
                    ),
                  ),
                  child: Text("Cancel ${type == 'order' ? 'Order' : 'Appointment'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          // Owner Footer (Status Management)
          if (isOwnerView && status != 'cancelled' && status != 'delivered' && (status != 'confirmed' || type == 'order'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(booking['id'].toString(), 'cancelled', type),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (status == 'pending' || status == 'booked')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(booking['id'].toString(), 'confirmed', type),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Confirm"),
                      ),
                    )
                  else if (status == 'confirmed' && type == 'order')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(booking['id'].toString(), 'delivered', type),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Delivered"),
                      ),
                    ),
                ],
              ),
            ),
          

          // Booking Details (Visible to both users and owners)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type == 'order' ? "ORDER DETAILS" : "BOOKING DETAILS", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.person_rounded, (type == 'order' ? booking['customer_name'] : booking['full_name'])?.toString() ?? "N/A"),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.phone_rounded, (type == 'order' ? booking['phone_no'] : booking['ph_no'])?.toString() ?? "N/A"),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.location_on_rounded, (type == 'order' ? booking['location'] : booking['full_address']) ?? "No address provided"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No orders or bookings found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            isOwnerView ? "When customers place orders or book appointments, they will appear here." : "Your orders and bookings will appear here.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              "Something went wrong while loading your orders and bookings.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchBookings,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
