import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class HospitalDetailsScreen extends StatefulWidget {
  final String shopId;
  const HospitalDetailsScreen({super.key, required this.shopId});

  @override
  State<HospitalDetailsScreen> createState() => _HospitalDetailsScreenState();
}

class _HospitalDetailsScreenState extends State<HospitalDetailsScreen> {
  late Future<Map<String, dynamic>> _hospitalFuture;

  @override
  void initState() {
    super.initState();
    _refreshDetails();
  }

  void _refreshDetails() {
    setState(() {
      _hospitalFuture = Provider.of<SupabaseService>(context, listen: false).getHospitalDetails(widget.shopId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hospital Overview', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
        future: _hospitalFuture,
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
          final doctors = (data['doctors'] as List? ?? []);
          final appointments = (data['appointments'] as List? ?? []);
          final departments = (data['departments'] as List? ?? []);
          final isMobile = MediaQuery.of(context).size.width < 600;
          final reviews = (data['reviews'] as List? ?? []);
          final media = (data['media'] as Map<String, dynamic>? ?? {});

          final avgRating = _calculateAverageRating(reviews);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  _buildHospitalHeader(shop),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Dashboard Overview', Icons.analytics_rounded),
                  _buildStatisticsGrid(doctors.length, departments.length, appointments.length, reviews.length, avgRating, isMobile),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Medical Departments', Icons.account_tree_rounded),
                  _buildDepartmentsSection(departments, doctors),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Authorized Medical Staff', Icons.medical_services_rounded),
                  _buildDoctorsList(doctors, departments),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Appointment Logs', Icons.event_note_rounded),
                  _buildAppointmentsList(appointments, doctors),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Patient Testimonials', Icons.rate_review_rounded),
                  _buildReviewsList(reviews),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Communication Channels', Icons.contact_support_rounded),
                  _buildMediaSection(media),
                  const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHospitalHeader(Map<String, dynamic> shop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.blue.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'shop_image_${shop['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: shop['image_url'] != null
                      ? Image.network(shop['image_url'].toString(), width: 110, height: 110, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholderImage())
                      : _buildPlaceholderImage(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (shop['name'] ?? 'Unnamed Hospital').toString(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                      child: Text((shop['category'] ?? 'Hospital').toString(), style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                    _buildIconInfo(Icons.location_on_rounded, (shop['address'] ?? 'No Address').toString()),
                    const SizedBox(height: 6),
                    _buildIconInfo(Icons.phone_rounded, (shop['phone'] ?? 'No Phone').toString()),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Verification: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(width: 8),
                        Switch(
                          value: shop['is_verified'] ?? false,
                          onChanged: (value) async {
                             try {
                               await Provider.of<SupabaseService>(context, listen: false).toggleShopVerification(shop['id'], value);
                               _refreshDetails();
                               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hospital ${value ? 'verified' : 'unverified'}')));
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, thickness: 1.5, color: Color(0xFFF1F5F9)),
          ),
          const Text('About Establishment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          Text(
            (shop['description'] ?? 'No description available.').toString(),
            style: TextStyle(color: Colors.blueGrey[600], height: 1.6, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEDF2F7))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 20, color: Colors.blue),
                const SizedBox(width: 10),
                Text('Standard Hours: ', style: TextStyle(color: Colors.blueGrey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                Text((shop['opening_time'] ?? 'N/A').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey[400]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.blueGrey[500], fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
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
      ),
    );
  }

  Widget _buildStatisticsGrid(int totalDoctors, int totalDepts, int totalAppts, int totalReviews, double avgRating, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 1.2 : 1.3,
          children: [
            _buildStatCard('Total Doctors', totalDoctors.toString(), Icons.people_outline, Colors.blue),
            _buildStatCard('Departments', totalDepts.toString(), Icons.account_tree_outlined, Colors.indigo),
            _buildStatCard('Appointments', totalAppts.toString(), Icons.calendar_today_outlined, Colors.green),
            _buildStatCard('Avg Rating', avgRating.toStringAsFixed(1), Icons.star_outline, Colors.amber),
            if (constraints.maxWidth > 600) _buildStatCard('Reviews', totalReviews.toString(), Icons.rate_review_outlined, Colors.teal),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey[500], fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.5),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Divider(thickness: 1, color: Color(0xFFF1F5F9))),
        ],
      ),
    );
  }

  Widget _buildDepartmentsSection(List departments, List doctors) {
    if (departments.isEmpty && doctors.isEmpty) return _buildEmptyState('No department data found');
    
    // Group doctors by department string if the departments table is empty
    Map<String, int> deptCounts = {};
    if (departments.isNotEmpty) {
      for (var dept in departments) {
        final name = (dept['name'] ?? 'Unnamed').toString();
        final deptId = dept['id'];
        deptCounts[name] = doctors.where((d) => d['department_id'] == deptId).length;
      }
    } else {
      for (var doc in doctors) {
        final name = (doc['department'] ?? 'General').toString();
        deptCounts[name] = (deptCounts[name] ?? 0) + 1;
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: deptCounts.length,
      itemBuilder: (context, index) {
        String name = deptCounts.keys.elementAt(index);
        int count = deptCounts[name]!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: const Icon(Icons.account_tree_rounded, size: 16, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('$count Staff', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoctorsList(List doctors, List departments) {
    if (doctors.isEmpty) return _buildEmptyState('No doctors found');
    return Column(
      children: doctors.map((doc) {
        final bool isDisabled = doc['is_disabled'] ?? false;
        final String deptName = (doc['department'] ?? 'General').toString();
        final qualifications = (doc['doctor_qualifications'] as List? ?? []).map((q) => q['qualification']).join(', ');
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDisabled ? Colors.red.withOpacity(0.3) : const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: doc['image_url'] != null ? NetworkImage(doc['image_url'].toString()) : null,
                      child: doc['image_url'] == null ? const Icon(Icons.person_rounded, color: Colors.blue, size: 30) : null,
                    ),
                    if (isDisabled)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.block_flipped, color: Colors.red, size: 18),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (doc['name'] ?? 'Unnamed Doctor').toString(),
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: const Color(0xFF1E293B),
                          decoration: isDisabled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(deptName.toUpperCase(), style: TextStyle(color: Colors.blue[600], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      if (qualifications.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(qualifications, style: TextStyle(color: Colors.blueGrey[500], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildMiniBadge(Icons.star_rounded, 'Exp: ${(doc['experience_years'] ?? 0).toString()} yrs', Colors.orange),
                          _buildMiniBadge(Icons.calendar_today_rounded, 'Since: ${_formatDate(doc['created_at'])}', Colors.blueGrey),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildActionButton(
                      isDisabled ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                      isDisabled ? Colors.orange : Colors.blueGrey,
                      () => _handleToggleDoctor(doc['id'], isDisabled)
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(Icons.delete_outline_rounded, Colors.red, () => _handleDeleteDoctor(doc['id'])),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAvailabilityList(List doctors) {
    List availability = [];
    for (var doc in doctors) {
      final docAvailability = doc['doctor_availability'] as List? ?? [];
      for (var slot in docAvailability) {
        availability.add({...slot, 'doctor_name': doc['name']});
      }
    }

    if (availability.isEmpty) return _buildEmptyState('No availability schedules found');

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: availability.map((slot) {
          return ListTile(
            title: Text((slot['doctor_name'] ?? 'Unknown Dr').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${(slot['day_of_week'] ?? 'N/A').toString()} | ${(slot['start_time'] ?? 'N/A').toString()} - ${(slot['end_time'] ?? 'N/A').toString()}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Text('Limit: ${(slot['booking_limit'] ?? 0).toString()}', style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppointmentsList(List appointments, List doctors) {
    if (appointments.isEmpty) return _buildEmptyState('No recent appointments');
    return Column(
      children: appointments.map((appt) {
        final status = (appt['status'] ?? 'Pending').toString();
        final drObj = appt['doctors'];
        final String drName = drObj != null ? (drObj['name'] ?? 'Unknown').toString() : 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildStatusIcon(status),
            title: Text((appt['patient_name'] ?? 'Unknown Patient').toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Dr. $drName \u2022 ${_formatDate(appt['appointment_date'])}', style: TextStyle(color: Colors.blueGrey[500], fontSize: 13)),
            ),
            trailing: _buildStatusBadge(status),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusIcon(String status) {
    final isDone = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: (isDone ? Colors.green : Colors.blue).withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(isDone ? Icons.check_circle_rounded : Icons.calendar_today_rounded, color: isDone ? Colors.green : Colors.blue, size: 20),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isDone = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: (isDone ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: isDone ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildReviewsList(List reviews) {
    if (reviews.isEmpty) return _buildEmptyState('No patient reviews yet');
    return Column(
      children: reviews.map((review) {
        final profile = review['profiles'] ?? {};
        final double rating = (review['rating'] ?? 0).toDouble();

        return Container(
          
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url'].toString()) : null,
                    child: profile['avatar_url'] == null ? const Icon(Icons.person_rounded, color: Colors.blueGrey) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profile['name'] ?? 'Patient').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        Text(_formatDate(review['created_at']), style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  _buildRatingStars(rating),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFF8FAFC)),
              ),
              Text(
                (review['review_text'] ?? review['comment'] ?? '').toString(),
                style: TextStyle(color: Colors.blueGrey[600], height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _handleDeleteReview(review['id']),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('Remove Feedback', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          Icons.star_rounded,
          size: 16,
          color: i < rating ? Colors.amber : const Color(0xFFF1F5F9),
        );
      }),
    );
  }

  Widget _buildMediaSection(Map<String, dynamic> media) {
    final links = {
      'Official Website': {'value': media['website'], 'icon': Icons.public_rounded, 'color': Colors.blue},
      'Instagram': {'value': media['instagram'], 'icon': Icons.camera_rounded, 'color': Colors.pink},
      'Facebook': {'value': media['facebook'], 'icon': Icons.facebook_rounded, 'color': Colors.indigo},
    };

    final activeLinks = links.entries.where((e) => e.value['value'] != null && e.value['value'].toString().isNotEmpty).toList();

    if (activeLinks.isEmpty) return _buildEmptyState('No social links or website configured');

    return LayoutBuilder(
      builder: (context, constraints) {
        double itemWidth = constraints.maxWidth > 800 ? (constraints.maxWidth - 48) / 3 : (constraints.maxWidth > 500 ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: activeLinks.map((entry) {
            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Icon(entry.value['icon'] as IconData, color: entry.value['color'] as Color, size: 28),
                  const SizedBox(height: 10),
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(
                    entry.value['value'].toString(), 
                    style: TextStyle(color: Colors.blue[600], fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDF2F7), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_clear_rounded, size: 48, color: Colors.blueGrey[200]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey[500], fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.tryParse(dateStr.toString());
      if (dateTime == null) return dateStr.toString();
      return DateFormat('MMM dd, yyyy', 'en_US').format(dateTime);
    } catch (e) {
      return dateStr.toString();
    }
  }

  Future<void> _handleDeleteDoctor(String id) async {
    final confirm = await _showConfirmDialog('Remove Doctor', 'Permanently remove this doctor and their schedules?');
    if (confirm) {
      try {
        await Provider.of<SupabaseService>(context, listen: false).deleteDoctor(id);
        _refreshDetails();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleToggleDoctor(String id, bool currentlyDisabled) async {
    try {
      await Provider.of<SupabaseService>(context, listen: false).toggleDoctorStatus(id, !currentlyDisabled);
      _refreshDetails();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleDeleteReview(String id) async {
    final confirm = await _showConfirmDialog('Delete Review', 'Permanently remove this patient review?');
    if (confirm) {
      try {
        await Provider.of<SupabaseService>(context, listen: false).deleteReview(id);
        _refreshDetails();
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('PROCEED', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }
}
