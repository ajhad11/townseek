import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../widgets/shop_card.dart';
import '../widgets/shop_tag.dart';
import 'location_page.dart';
import '../data/wishlist_manager.dart';
import '../data/shop_data.dart';
import '../widgets/review_section.dart';
import '../utils/time_helper.dart';
import '../utils/icon_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/qr_display_dialog.dart';

class HospitalDetailsPage extends StatefulWidget {
  final Shop shop;

  const HospitalDetailsPage({super.key, required this.shop});

  @override
  State<HospitalDetailsPage> createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;
  late String _currentRating;
  
  // Real Departments State
  List<Map<String, dynamic>> _hospitalDepartments = [];
  bool _isLoadingDepartments = true;

  @override
  void initState() {
    super.initState();
    if (widget.shop.id != null) {
      ShopData.incrementClicks(widget.shop.id!, widget.shop.ownerId);
    }
    _currentRating = widget.shop.rating;
    _fetchDepartments();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 190) {
        if (!_showTitle) setState(() => _showTitle = true);
      } else {
        if (_showTitle) setState(() => _showTitle = false);
      }
    });
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('department, expert')
          .eq('shop_id', widget.shop.id ?? '');
          
      if (mounted) {
        setState(() {
          _hospitalDepartments = List<Map<String, dynamic>>.from(response);
          _isLoadingDepartments = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching specific hospital departments: $e');
      if (mounted) {
        setState(() => _isLoadingDepartments = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF2962FF), // Changed to Blue
              // Sticky Title - Manual Controller
              title: _showTitle
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shop.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Hospital • 1.5 km",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : null,
              elevation: 0,
              leading: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: ListenableBuilder(
                    listenable: WishlistManager(),
                    builder: (context, child) {
                      final isWishlisted = WishlistManager().isWishlisted(
                        widget.shop.id,
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.shop.id != null)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => QRDisplayDialog(
                                    shopId: widget.shop.id!,
                                    shopTitle: widget.shop.title,
                                  ),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: () {
                              WishlistManager().toggleWishlist(widget.shop);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isWishlisted ? Colors.red : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.shop.imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: widget.shop.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.local_hospital,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: IconHelper.getColor(
                          widget.shop.category,
                          widget.shop.tags,
                        ).withValues(alpha: 0.15),
                        child: Icon(
                          IconHelper.getIcon(
                            widget.shop.category,
                            widget.shop.tags,
                          ),
                          size: 80,
                          color: IconHelper.getColor(
                            widget.shop.category,
                            widget.shop.tags,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(20), // Reduced to 20
                child: Container(
                  height: 20, // Reduced to 20
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),

            // Persistent Header -> Scrolling Adapter
            SliverToBoxAdapter(child: _buildHospitalDetailsContent()),

            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2962FF),
                  unselectedLabelColor: Colors.black,
                  indicatorColor: const Color(0xFF2962FF),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "Overview"),
                    Tab(text: "Doctors"),
                    Tab(text: "Review"),
                  ],
                ),
              ),
              pinned: false,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildDoctorsTab(),
            _buildReviewTab(),
          ],
        ),
      ),
    );
  }


  Widget _buildHospitalDetailsContent() {
    final shop = widget.shop;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _currentRating,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2962FF), size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  shop.location ?? shop.subtitle,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  (shop.openingTime != null && shop.closingTime != null)
                      ? "${TimeHelper.formatTimeString(shop.openingTime)}  TO  ${TimeHelper.formatTimeString(shop.closingTime)}   "
                      : "24 hours   ",
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                ),
              ),
              Text(
                shop.isOpen ? "OPEN" : "CLOSED",
                style: TextStyle(
                  color: shop.isOpen ? const Color(0xFF00C853) : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shop.tags.map((tag) => ShopTag(text: tag)).toList(),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                Icons.call,
                "Call",
                const Color(0xFFB9F6CA),
                const Color(0xFF00C853),
                onTap: () async {
                  if (widget.shop.phone != null &&
                      widget.shop.phone!.isNotEmpty) {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: widget.shop.phone,
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Phone number not available"),
                      ),
                    );
                  }
                },
              ),
              _buildActionButton(
                Icons.location_on,
                "Route",
                const Color(0xFFBBDEFB),
                const Color(0xFF2962FF),
                onTap: () {
                  if (widget.shop.latitude != null &&
                      widget.shop.longitude != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPage(
                          destLat: widget.shop.latitude,
                          destLng: widget.shop.longitude,
                          destName: widget.shop.title,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Location coordinates not available for this hospital."),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
              _buildActionButton(
                Icons.chat_bubble,
                "Chat",
                const Color(0xFFBBDEFB),
                const Color(0xFF2962FF),
                onTap: () async {
                  if (widget.shop.email != null &&
                      widget.shop.email!.isNotEmpty) {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: widget.shop.email,
                    );
                    if (await canLaunchUrl(emailLaunchUri)) {
                      await launchUrl(emailLaunchUri);
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Could not launch email app"),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email not available")),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    Color containerColor = label == "Call"
        ? const Color(0xFFCEF5D5)
        : const Color(0xFFDCE2FA);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 80,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final facilities = widget.shop.facilities ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.shop.description != null &&
              widget.shop.description!.isNotEmpty) ...[
            const Text(
              "About",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.shop.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
          ],

          _buildDepartmentUI(),
          const SizedBox(height: 24),

          if (facilities.isNotEmpty) ...[
            const Text(
              "Facilities",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 3.0, // Increased height for facilities
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: facilities
                  .map(
                    (facility) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        facility,
                        style: const TextStyle(
                          color: Color(0xFF2962FF),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ] else if (widget.shop.description == null ||
              widget.shop.description!.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "No overview information available",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentUI() {
    if (_isLoadingDepartments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2962FF)),
          ),
        ),
      );
    }

    if (_hospitalDepartments.isEmpty) {
      return const SizedBox.shrink(); // Hide section if no departments
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Departments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Future enhancement: Navigate to all departments
              },
              child: const Row(
                children: [
                  Text(
                    "View all",
                    style: TextStyle(
                      color: Color(0xFF2962FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Color(0xFF2962FF), size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.35, // Increased height for departments
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _hospitalDepartments.map((deptData) {
            final deptName = deptData['department'].toString();
            final expertsCount = int.tryParse(deptData['expert']?.toString() ?? '1') ?? 1;
            
            final icon = _getDepartmentIcon(deptName);
            final colors = _getDepartmentColors(deptName);
            
            return _buildDepartmentCard(
              deptName,
              "$expertsCount Specialist${expertsCount > 1 ? 's' : ''}",
              icon,
              colors[0], // bgColor
              colors[1], // iconColor
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDepartmentCard(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Ensure we take minimum space
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10), // Reduced from 12
          Flexible( // Added Flexible to handle long text
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4
          Flexible( // Added Flexible
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1, // Ensure it stays in one line
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDepartmentIcon(String department) {
    switch (department.toLowerCase()) {
      case 'cardiology':
        return Icons.monitor_heart_outlined;
      case 'neurology':
      case 'psychiatry':
        return Icons.psychology_outlined;
      case 'orthopedics':
        return Icons.accessibility_new_outlined;
      case 'pediatrics':
        return Icons.child_care_outlined;
      case 'dermatology':
        return Icons.face_retouching_natural;
      case 'general medicine':
      case 'general':
        return Icons.medical_services_outlined;
      case 'gynecology':
        return Icons.pregnant_woman;
      case 'oncology':
        return Icons.coronavirus_outlined;
      case 'ent':
        return Icons.hearing_outlined;
      case 'urology':
        return Icons.water_drop_outlined;
      case 'gastroenterology':
        return Icons.local_dining_outlined;
      case 'radiology':
        return Icons.radar_outlined;
      case 'anesthesiology':
        return Icons.masks_outlined;
      case 'emergency':
        return Icons.emergency_outlined;
      default:
        return Icons.local_hospital_outlined;
    }
  }

  List<Color> _getDepartmentColors(String department) {
    switch (department.toLowerCase()) {
      case 'cardiology':
        return [const Color(0xFFFEE2E2), const Color(0xFFEF4444)];
      case 'neurology':
        return [const Color(0xFFF3E8FF), const Color(0xFFA855F7)];
      case 'orthopedics':
        return [const Color(0xFFDBEAFE), const Color(0xFF3B82F6)];
      case 'pediatrics':
        return [const Color(0xFFFEF9C3), const Color(0xFFEAB308)];
      case 'dermatology':
        return [const Color(0xFFFFEDD5), const Color(0xFFF97316)];
      case 'general medicine':
      case 'general':
        return [const Color(0xFFF1F5F9), const Color(0xFF64748B)];
      case 'gynecology':
        return [const Color(0xFFFCE7F3), const Color(0xFFEC4899)];
      case 'oncology':
        return [const Color(0xFFE0E7FF), const Color(0xFF6366F1)];
      case 'ent':
        return [const Color(0xFFFEF3C7), const Color(0xFFF59E0B)];
      case 'psychiatry':
        return [const Color(0xFFE0F2FE), const Color(0xFF0EA5E9)];
      case 'urology':
        return [const Color(0xFFCCFBF1), const Color(0xFF14B8A6)];
      case 'gastroenterology':
        return [const Color(0xFFECFCCB), const Color(0xFF84CC16)];
      case 'radiology':
        return [const Color(0xFFFAFAFA), const Color(0xFF52525B)];
      case 'anesthesiology':
        return [const Color(0xFFE2E8F0), const Color(0xFF475569)];
      case 'emergency':
        return [const Color(0xFFFEE2E2), const Color(0xFFDC2626)];
      default:
        return [const Color(0xFFE0F2FE), const Color(0xFF0284C7)];
    }
  }

  Widget _buildDoctorsTab() {
    List<Doctor> doctors = widget.shop.doctors ?? [];
    if (doctors.isEmpty) {
      return const Center(
        child: Text(
          "No doctors listed yet.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: doctors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return _buildDoctorCard(doctor);
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Avatar Placeholder
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: doctor.imageUrl.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: doctor.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.blue),
                          ),
                        )
                      : Text(
                          doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2962FF),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              doctor.speciality,
                              style: const TextStyle(
                                color: Color(0xFF2962FF),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.qualification,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                GestureDetector(
                  onTap: () {
                    _showBookingModal(doctor);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2962FF), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Enquiry",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          
          // Availability Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF2962FF)),
                    const SizedBox(width: 6),
                    const Text(
                      "Current Availability",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 12),
                // Days Row (Centered)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(7, (index) {
                    const shortDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                    const fullDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                    bool isAvailable = doctor.availableDays?.contains(fullDays[index]) ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: isAvailable ? const LinearGradient(
                          colors: [Color(0xFF2962FF), Color(0xFF1E88E5)],
                        ) : null,
                        color: isAvailable ? null : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isAvailable ? [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        shortDays[index],
                        style: TextStyle(
                          color: isAvailable ? Colors.white : Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Time Bar (Full Width)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2962FF)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          doctor.availability,
                          style: const TextStyle(
                            color: Color(0xFF2962FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingModal(Doctor doctor) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Hospital & Location)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.shop.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Color(0xFF2962FF)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.shop.location ?? "Location Details",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                  ),
  
                  // Doctor Information
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade100, Colors.blue.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.blue.shade200, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: doctor.imageUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: doctor.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.blue, size: 24),
                                ),
                              )
                            : Text(
                                doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2962FF),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${doctor.speciality} • ${doctor.qualification}",
                              style: const TextStyle(
                                color: Color(0xFF2962FF),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
  
                  const SizedBox(height: 16),
                  
                  // Availability
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Availability",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 12),
                        // Days Row (Centered)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(7, (index) {
                            const shortDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                            const fullDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                            bool isAvailable = doctor.availableDays?.contains(fullDays[index]) ?? false;
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isAvailable ? const Color(0xFF2962FF) : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                shortDays[index],
                                style: TextStyle(
                                  color: isAvailable ? Colors.white : Colors.black45,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        // Time Bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2962FF)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  doctor.availability,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
  
                  const SizedBox(height: 20),
  
                  // Inputs
                // Inputs & Submit Button
                StatefulBuilder(
                  builder: (context, setModalState) {
                    // selectDate/selectTime methods...

                    Future<void> selectDate() async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        selectableDayPredicate: (DateTime val) {
                          if (doctor.availableDays == null || doctor.availableDays!.isEmpty) {
                            return true; // No restrictions specified
                          }
                          const fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                          String dayName = fullDays[val.weekday - 1];
                          return doctor.availableDays!.contains(dayName);
                        },
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    }

                    Future<void> selectTime() async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    }

                    return Column(
                      children: [
                        // Name input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter Full Name",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                              prefixIcon: Icon(Icons.person_outline, size: 16, color: Colors.grey),
                              prefixIconConstraints: BoxConstraints(minWidth: 30, minHeight: 0),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Phone input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter Mobile Number",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                              prefixIcon: Icon(Icons.phone_android, size: 16, color: Colors.grey),
                              prefixIconConstraints: BoxConstraints(minWidth: 30, minHeight: 0),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Address input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter Full Address",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                              prefixIcon: Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                              prefixIconConstraints: BoxConstraints(minWidth: 30, minHeight: 0),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Date and Time Pickers
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedDate == null 
                                          ? "Select Date" 
                                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                        style: TextStyle(
                                          fontSize: 13, 
                                          color: selectedDate == null ? Colors.grey : Colors.black87
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: selectTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedTime == null 
                                          ? "Select Time" 
                                          : selectedTime!.format(context),
                                        style: TextStyle(
                                          fontSize: 13, 
                                          color: selectedTime == null ? Colors.grey : Colors.black87
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2962FF), Color(0xFF1565C0)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : () async {
                              if (nameController.text.trim().isEmpty || 
                                  phoneController.text.trim().isEmpty ||
                                  addressController.text.trim().isEmpty ||
                                  selectedDate == null ||
                                  selectedTime == null) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Missing Details"),
                                      content: const Text("Please fill in all details to proceed with the booking."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return;
                              }

                              // Check if selected time is within doctor's availability
                              if (!_isTimeInAvailability(selectedTime!, doctor.availability)) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Time Not Available"),
                                      content: Text("The doctor is only available at: ${doctor.availability}. Please check another time."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              
                              try {
                                final userId = Supabase.instance.client.auth.currentUser?.id;
                                final dateString = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                                final startTimeString = "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00";
                                
                                // Calculate end time (30 mins after start)
                                final startDateTime = DateTime(2000, 1, 1, selectedTime!.hour, selectedTime!.minute);
                                final endDateTime = startDateTime.add(const Duration(minutes: 30));
                                 final endTimeString = "${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}:00";
 
                                 // Fetch current booking count for this doctor on this day
                                 final countResponse = await Supabase.instance.client
                                     .from('doctor_appointments')
                                     .select('id')
                                     .eq('doctor_id', doctor.id ?? '')
                                     .eq('appointment_date', dateString);
                                 
                                 final int currentBookingsCount = (countResponse as List).length;

                                 // Check if the slot is already taken
                                 final conflictResponse = await Supabase.instance.client
                                     .from('doctor_appointments')
                                     .select('id')
                                     .eq('doctor_id', doctor.id ?? '')
                                     .eq('appointment_date', dateString)
                                     .eq('start_time', startTimeString)
                                     .maybeSingle();

                                 if (conflictResponse != null) {
                                   if (context.mounted) {
                                     showDialog(
                                       context: context,
                                       builder: (ctx) => AlertDialog(
                                         title: const Text("Slot Unavailable"),
                                         content: const Text("This time slot is already booked. Please check another time."),
                                         actions: [
                                           TextButton(
                                             onPressed: () => Navigator.pop(ctx),
                                             child: const Text("OK"),
                                           ),
                                         ],
                                       ),
                                     );
                                   }
                                   setModalState(() => isSubmitting = false);
                                   return;
                                 }

                                 // Check booking limit
                                 if (doctor.bookingLimit != null && currentBookingsCount >= doctor.bookingLimit!) {
                                   if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                         content: Text("Booking limit of ${doctor.bookingLimit} reached for this doctor on selected date."),
                                         backgroundColor: Colors.orange,
                                       ),
                                     );
                                   }
                                   setModalState(() => isSubmitting = false);
                                   return;
                                 }

                                 final int tokenNo = currentBookingsCount + 1;
 
                                 await Supabase.instance.client
                                    .from('doctor_appointments')
                                    .insert({
                                       'doctor_id': doctor.id ?? '',
                                      'shop_id': widget.shop.id,
                                      'user_id': userId,
                                      'appointment_date': dateString,
                                      'start_time': startTimeString,
                                      'end_time': endTimeString,
                                      'status': 'booked',
                                       'full_name': nameController.text.trim(),
                                       'ph_no': int.tryParse(phoneController.text.trim()),
                                       'full_address': addressController.text.trim(),
                                       'token_no': tokenNo,
                                     });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Enquiry sent for ${nameController.text.trim()}!")),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error submitting enquiry: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Submission failed: $e")),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    "Submit Enquiry",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
  
                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewTab() {
    if (widget.shop.id == null) {
      return const Center(child: Text("Reviews unavailable"));
    }
    return SingleChildScrollView(
      child: ReviewSection(
        shopId: widget.shop.id!,
        ownerId: widget.shop.ownerId,
        onRatingChanged: (newRating) {
          if (mounted) {
            setState(() {
              _currentRating = newRating.toStringAsFixed(1);
            });
          }
        },
      ),
    );
  }

  bool _isTimeInAvailability(TimeOfDay selected, String availability) {
    try {
      // Expected format: "09:00 AM - 05:00 PM"
      final parts = availability.split(' - ');
      if (parts.length != 2) return true; // Fallback if format is unexpected

      final startTime = _parseTimeOfDay(parts[0]);
      final endTime = _parseTimeOfDay(parts[1]);

      final selectedMinutes = selected.hour * 60 + selected.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      // Ensure the entire 30-minute appointment fits within the availability
      return selectedMinutes >= startMinutes && (selectedMinutes + 30) <= endMinutes;
    } catch (e) {
      debugPrint("Error parsing availability: $e");
      return true; // Fallback to allow booking if parsing fails
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    // Correctly parses "09:00 AM", "5:00 PM", etc.
    final format = DateFormat.jm();
    final dateTime = format.parse(timeStr.trim());
    return TimeOfDay.fromDateTime(dateTime);
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _tabBar,
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
