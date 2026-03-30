import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EstablishmentAdminDashboard extends StatefulWidget {
  final String shopId;

  const EstablishmentAdminDashboard({Key? key, required this.shopId}) : super(key: key);

  @override
  State<EstablishmentAdminDashboard> createState() => _EstablishmentAdminDashboardState();
}

class _EstablishmentAdminDashboardState extends State<EstablishmentAdminDashboard> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  // Real-time streams
  late Stream<List<Map<String, dynamic>>> _shopStream;
  late Stream<List<Map<String, dynamic>>> _productsStream;
  late Stream<List<Map<String, dynamic>>> _doctorsStream;
  late Stream<List<Map<String, dynamic>>> _servicesStream;
  late Stream<List<Map<String, dynamic>>> _reviewsStream;
  late Stream<List<Map<String, dynamic>>> _ordersStream; // assuming appointments or orders
  late Stream<List<Map<String, dynamic>>> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initStreams();
  }

  void _initStreams() {
    _shopStream = _supabase
        .from('shops')
        .stream(primaryKey: ['id'])
        .eq('id', widget.shopId);

    _productsStream = _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('shop_id', widget.shopId);

    _doctorsStream = _supabase
        .from('doctors')
        .stream(primaryKey: ['id'])
        .eq('shop_id', widget.shopId);

    _servicesStream = _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('shop_id', widget.shopId);

    _reviewsStream = _supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('shop_id', widget.shopId);

    // Using appointments as orders based on schema
    _ordersStream = _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('shop_id', widget.shopId);

    _categoriesStream = _supabase
        .from('product_categories')
        .stream(primaryKey: ['id'])
        .eq('shop_id', widget.shopId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Establishment Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initStreams();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
            Tab(text: 'Doctors/Services'),
            Tab(text: 'Orders/Appointments'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _shopStream,
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final shopData = shopSnapshot.data?.isNotEmpty == true ? shopSnapshot.data!.first : null;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(shopData),
              _buildProductsTab(),
              _buildCategoriesTab(),
              _buildDoctorsServicesTab(),
              _buildOrdersTab(),
              _buildReviewsTab(),
            ],
          );
        },
      ),
      floatingActionButton: _buildAddButtons(),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic>? shopData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shopData != null) _buildHeaderSection(shopData),
          const SizedBox(height: 24),
          const Text('Statistics Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStatisticsCards(),
          const SizedBox(height: 24),
          if (shopData != null) _buildEstablishmentDetails(shopData),
          const SizedBox(height: 24),
          const Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildAnalyticsPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> shopData) {
    bool isActive = !(shopData['is_blocked'] ?? false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: shopData['logo_url'] != null ? NetworkImage(shopData['logo_url']) : null,
            child: shopData['logo_url'] == null 
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
                )
              : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (shopData['name'] ?? 'Unknown Establishment').toString(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Type: ${(shopData['shop_type'] ?? 'N/A').toString()}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 400 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Products', Icons.inventory, Colors.blue, _productsStream),
            _buildStatCard('Categories', Icons.category, Colors.orange, _categoriesStream),
            _buildStatCard('Doctors', Icons.medical_services, Colors.teal, _doctorsStream),
            _buildStatCard('Services', Icons.design_services, Colors.purple, _servicesStream),
            _buildStatCard('Orders', Icons.shopping_cart, Colors.green, _ordersStream),
            _buildStatCard('Reviews', Icons.star, Colors.amber, _reviewsStream),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, Stream<List<Map<String, dynamic>>> stream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = snapshot.data!.length.toString();
        }
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstablishmentDetails(Map<String, dynamic> shopData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Establishment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _buildDetailRow(Icons.phone, 'Phone', (shopData['phone_number'] ?? 'N/A').toString()),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.email, 'Email', (shopData['email'] ?? 'N/A').toString()), 
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, 'Address', (shopData['address'] ?? 'N/A').toString()),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.info, 'Description', (shopData['description'] ?? 'N/A').toString()),
            const SizedBox(height: 12),
            _buildStreamDetailRow(Icons.inventory, 'Total Products', _productsStream),
            const SizedBox(height: 12),
            _buildStreamDetailRow(Icons.star, 'Total Reviews', _reviewsStream),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamDetailRow(IconData icon, String label, Stream<List<Map<String, dynamic>>> stream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        String value = 'Loading...';
        if (snapshot.hasData) {
          value = snapshot.data!.length.toString();
        }
        return _buildDetailRow(icon, label, value);
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsPlaceholder() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Analytics Charts (Monthly Products, Orders, Popular Categories)\nWill be rendered using charts_flutter or fl_chart',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // --- Products Tab ---
  Widget _buildProductsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!;
        if (products.isEmpty) return const Center(child: Text('No products found.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                  columns: const [
                    DataColumn(label: Text('Image')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: products.map((product) {
                    bool isAvailable = product['is_available'] ?? true;
                    return DataRow(cells: [
                      DataCell(
                        product['image_url'] != null
                            ? Image.network(product['image_url'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image))
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                      DataCell(Text((product['name'] ?? 'N/A').toString())),
                      DataCell(Text('₹${product['price'] ?? 0}')),
                      DataCell(Text(isAvailable ? 'In Stock' : 'Out of Stock', style: TextStyle(color: isAvailable ? Colors.green : Colors.red))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Categories Tab ---
  Widget _buildCategoriesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _categoriesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;
        if (categories.isEmpty) return const Center(child: Text('No categories found.'));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category, size: 40, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 12),
                    Text((category['name'] ?? 'Unknown').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text('Total Items: --', style: TextStyle(color: Colors.grey)), // Would need a join query to get true counts
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Doctors / Services Tab ---
  Widget _buildDoctorsServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Doctors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _doctorsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final doctors = snapshot.data!;
            if (doctors.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text('No doctors found.'));
            return Column(
              children: doctors.map((doc) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(backgroundImage: doc['image_url'] != null ? NetworkImage(doc['image_url']) : null, child: doc['image_url'] == null ? const Icon(Icons.person) : null),
                  title: Text((doc['name'] ?? 'N/A').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${doc['specialization'] ?? 'General'} • Exp: ${doc['experience_years'] ?? 0} yrs'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                    ],
                  ),
                ),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _servicesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final services = snapshot.data!;
            if (services.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text('No services found.'));
            return Column(
              children: services.map((service) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text((service['name'] ?? 'N/A').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Price: ₹${service['price'] ?? 0}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                    ],
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- Orders / Appointments Tab ---
  Widget _buildOrdersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        if (orders.isEmpty) return const Center(child: Text('No orders/appointments found.'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: orders.map((order) {
            final date = order['appointment_date'] != null ? DateTime.tryParse(order['appointment_date']) : null;
            final dateStr = _formatDate(order['appointment_date'], showTime: true);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order/Appt #${order['id'].toString().substring(0, 8)}...', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(order['status'] ?? 'Pending', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Date: $dateStr', style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(icon: const Icon(Icons.visibility), label: const Text('View Details'), onPressed: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- Reviews Tab ---
  Widget _buildReviewsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reviewsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;
        if (reviews.isEmpty) return const Center(child: Text('No reviews found.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (starIndex) {
                            int rating = review['rating'] ?? 0;
                            return Icon(
                              starIndex < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(review['comment'] ?? 'No comment provided.', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    Text(
                      _formatDate(review['created_at']),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddButtons() {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(leading: const Icon(Icons.inventory), title: const Text('Add Product'), onTap: () => Navigator.pop(context)),
                  ListTile(leading: const Icon(Icons.category), title: const Text('Add Category'), onTap: () => Navigator.pop(context)),
                  ListTile(leading: const Icon(Icons.medical_services), title: const Text('Add Doctor'), onTap: () => Navigator.pop(context)),
                  ListTile(leading: const Icon(Icons.design_services), title: const Text('Add Service'), onTap: () => Navigator.pop(context)),
                  ListTile(leading: const Icon(Icons.local_offer), title: const Text('Add Offer'), onTap: () => Navigator.pop(context)),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Add New'),
    );
  }

  String _formatDate(dynamic dateStr, {bool showTime = false}) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.tryParse(dateStr.toString());
      if (dateTime == null) return dateStr.toString();
      return DateFormat(showTime ? 'MMM dd, yyyy HH:mm' : 'MMM dd, yyyy', 'en_US').format(dateTime);
    } catch (e) {
      return dateStr.toString();
    }
  }
}
