import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for listEquals
import '../utils/category_term_helper.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher, used for maps and sharing
import '../widgets/shop_tag.dart';
import '../data/wishlist_manager.dart';
import '../data/shop_data.dart';
import '../widgets/shop_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/review_section.dart'; // Import ReviewSection
import '../utils/time_helper.dart';
import 'location_page.dart';
import '../utils/icon_helper.dart';
import '../widgets/qr_display_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/osm_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ShopPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String rating;
  final List<String> tags;
  final String imageUrl;
  final bool isOpen;
  final String? openingTime;
  final String? closingTime;
  final String? description;
  final String? googleMapsLink;
  final String? location;
  final String? distance;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final List<int>? workingDays;
  final String? id;
  final String? ownerId;
  final String? category;
  final bool? openNowOverride;
  final int initialTabIndex;

  const ShopPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.tags,
    required this.imageUrl,
    required this.isOpen,
    this.openingTime,
    this.closingTime,
    this.description,
    this.googleMapsLink,
    this.location,
    this.distance,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.workingDays,
    this.id,
    this.ownerId,
    this.category,
    this.openNowOverride,
    this.initialTabIndex = 0,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;
  late String _currentRating;
  Map<String, dynamic>? _mediaLinks;
  YoutubePlayerController? _youtubeController;
  bool _showYouTubePlayer = false;

  bool _isLoadingProducts = true;
  List<ShopProductCategory> _categories = [];
  List<ShopProduct> _products = [];
  List<ShopOffering> _offerings = [];
  bool _isLoadingOfferings = false;
  ShopProductCategory? _selectedCategory;
  bool _isLoadingOffers = true;
  List<Map<String, dynamic>> _offers = [];
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    // Delay click tracking to avoid counting immediate bounces (#7)
    if (widget.id != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) ShopData.incrementClicks(widget.id!, widget.ownerId);
      });
    }
    _currentRating = widget.rating;
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 220) {
        if (!_showTitle) setState(() => _showTitle = true);
      } else {
        if (_showTitle) setState(() => _showTitle = false);
      }
    });
    // Parallel fetch all data (#2)
    Future.wait([
      _fetchDynamicProducts(),
      _fetchOfferings(),
      _fetchOffers(),
      _fetchMediaLinks(),
    ]);
  }

  Future<void> _fetchOfferings() async {
    // Use helper instead of inline list (#8)
    if (!CategoryTermHelper.isOfferingCategory(widget.category)) return;

    setState(() => _isLoadingOfferings = true);
    try {
      final offerings = await ShopData.fetchOfferings(widget.id);
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _isLoadingOfferings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOfferings = false);
    }
  }


  Future<void> _fetchMediaLinks() async {
    if (widget.id == null) return;
    try {
      final response = await Supabase.instance.client
          .from('media')
          .select()
          .eq('shop_id', widget.id!)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _mediaLinks = response;
          final videoUrl = response['youtube_video'] as String?;
          if (videoUrl != null && videoUrl.isNotEmpty) {
            final videoId = YoutubePlayer.convertUrlToId(videoUrl);
            if (videoId != null) {
              _youtubeController = YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: true,
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching media links: $e');
    }
  }

  Future<void> _fetchOffers() async {
    if (widget.id == null) {
      if (mounted) setState(() => _isLoadingOffers = false);
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('offers')
          .select()
          .eq('shop_id', widget.id!)
          .or('expiry.gte.${DateTime.now().toIso8601String()},expiry.is.null')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(response);
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      if (mounted) {
        setState(() => _isLoadingOffers = false);
      }
    }
  }

  Future<void> _fetchDynamicProducts() async {
    if (widget.id == null) return;
    try {
      final fetchedCategories = await ShopData.fetchProductCategories(
        widget.id,
      );
      final fetchedProducts = await ShopData.fetchProducts(widget.id);

      if (mounted) {
        setState(() {
          _categories = fetchedCategories;
          _products = fetchedProducts;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching shop products: $e');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  // List<String> get _availableCategories {
  //   return _categories.map((c) => c.name).toList();
  // }



  String _getPrimaryTabLabel() {
    return CategoryTermHelper.getPluralTerm(widget.category);
  }

  bool get _isReligious {
    final cat = widget.category?.toLowerCase() ?? '';
    if (cat == 'religious') return true;

    // Fallback search in tags
    final religiousTags = ['mosque', 'temple', 'church', 'masjid', 'religious'];
    return widget.tags.any((tag) => religiousTags.contains(tag.toLowerCase()));
  }

  bool get _isPublicService {
    final cat = widget.category?.toLowerCase().replaceAll(' ', '') ?? '';
    return cat == 'publicservices';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // 1. Sliver AppBar with Image and Sticky Title
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF2962FF),
              // Show title based on manual scroll controller
              title: _showTitle
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "${widget.location ?? (widget.tags.isNotEmpty ? widget.tags.first : 'Shop')} • ${widget.distance ?? '1.5 km'}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : null,
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
                        widget.id,
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.id != null)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => QRDisplayDialog(
                                    shopId: widget.id!,
                                    shopTitle: widget.title,
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
                              final shop = Shop(
                                title: widget.title,
                                subtitle: widget.subtitle,
                                rating: widget.rating,
                                tags: widget.tags,
                                imageUrl: widget.imageUrl,
                                isOpen: widget.isOpen,
                                workingDays: widget.workingDays,
                                id: widget.id,
                                openNowOverride: widget.openNowOverride,
                              );
                              WishlistManager().toggleWishlist(shop);
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
                background: widget.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: IconHelper.getColor(
                          null,
                          widget.tags,
                        ).withValues(alpha: 0.15),
                        child: Icon(
                          IconHelper.getIcon(null, widget.tags),
                          size: 80,
                          color: IconHelper.getColor(null, widget.tags),
                        ),
                      ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Container(
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Shop Info (Scrolling)
            SliverToBoxAdapter(child: _buildShopDetailsContent()),

            // 3. Tab Bar (Unpinned)
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2962FF),
                  unselectedLabelColor: Colors.black,
                  indicatorColor: const Color(0xFF2962FF),
                  // backgroundColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: _getPrimaryTabLabel()),
                    Tab(
                      text: _isReligious
                          ? "Schedules"
                          : (_isPublicService ? "Announcements" : "Offers"),
                    ),
                    const Tab(text: "Review"),
                  ],
                ),
              ),
              pinned: false, // Changed to false
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            (_isReligious || _isPublicService) ? _buildSchedulesTab() : _buildOffersTab(),
            _buildReviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildShopDetailsContent() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        10,
      ), // Adjust top padding to 0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // We can render the full Title/Subtitle here too, so it looks seamless before scrolling.
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF176).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _currentRating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            widget.subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2962FF), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${widget.location ?? widget.subtitle}${widget.distance != null ? ' • ${widget.distance}' : ''}",
                  style: const TextStyle(color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF2962FF), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (widget.openingTime != null && widget.closingTime != null)
                      ? (TimeHelper.is24Hours(widget.openingTime, widget.closingTime)
                          ? "24 Hours   "
                          : "${TimeHelper.formatTimeString(widget.openingTime)}  TO  ${TimeHelper.formatTimeString(widget.closingTime)}   ")
                      : "08:00 AM  TO  10:00 PM   ",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              Builder(
                builder: (context) {
                    final isOpen = widget.openNowOverride ?? TimeHelper.isShopOpen(
                      widget.openingTime,
                      widget.closingTime,
                      defaultStatus: widget.isOpen,
                    );
                  return Text(
                    isOpen ? "OPEN" : "CLOSED",
                    style: TextStyle(
                      color: isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Working Days
          if (widget.workingDays != null && widget.workingDays!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF2962FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatWorkingDays(widget.workingDays!),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Description
          if (widget.description != null &&
              widget.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              "About",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            if (_mediaLinks != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                   if (_mediaLinks!['website']?.toString().isNotEmpty ?? false)
                    _buildSocialIcon(Icons.language, _mediaLinks!['website'], Colors.blueGrey),
                   if (_mediaLinks!['instagram']?.toString().isNotEmpty ?? false)
                    _buildSocialIcon(Icons.camera_alt_outlined, _mediaLinks!['instagram'], Colors.pink),
                   if (_mediaLinks!['facebook']?.toString().isNotEmpty ?? false)
                    _buildSocialIcon(Icons.facebook, _mediaLinks!['facebook'], const Color(0xFF1877F2)),
                   if (_mediaLinks!['youtube']?.toString().isNotEmpty ?? false)
                    _buildSocialIcon(Icons.play_circle_fill, _mediaLinks!['youtube'], Colors.red),
                ],
              ),
            ],
            const SizedBox(height: 12),
          ],

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) => ShopTag(text: tag)).toList(),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                Icons.call,
                "Call",
                const Color(0xFFC8E6C9),
                const Color(0xFF00C853),
                onTap: () async {
                  if (widget.phone != null && widget.phone!.isNotEmpty) {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: widget.phone,
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  } else {
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
                  if (widget.latitude != null && widget.longitude != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPage(
                          destLat: widget.latitude,
                          destLng: widget.longitude,
                          destName: widget.title,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Location coordinates not available for this shop."),
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
                  if (widget.email != null && widget.email!.isNotEmpty) {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: widget.email,
                      queryParameters: {
                        'subject': 'Inquiry about ${widget.title}',
                      },
                    );
                    
                    try {
                      await launchUrl(emailLaunchUri, mode: LaunchMode.platformDefault);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Could not open email app. Please ensure an email account is set up.")),
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email not available")),
                      );
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

  Widget _buildYouTubePlayer() {
    if (_youtubeController == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 40),
          const Text(
            "Store Video",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _showYouTubePlayer
                ? Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: const Color(0xFF2962FF),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          radius: 18,
                          child: IconButton(
                            icon: Icon(
                               _isMuted
                                   ? Icons.volume_off_rounded
                                   : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _isMuted = !_isMuted;
                                if (_isMuted) {
                                  _youtubeController!.mute();
                                } else {
                                  _youtubeController!.unMute();
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => setState(() => _showYouTubePlayer = true),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          YoutubePlayer.getThumbnail(
                            videoId: _youtubeController!.initialVideoId,
                            quality: ThumbnailQuality.max,
                          ),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.black12,
                            child: const Icon(Icons.error),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String? url, Color color) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
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
    final Color containerColor = label == "Call"
        ? const Color(0xFFCEF5D5)
        : const Color(0xFFDCE2FA);
    final Color effectiveIconColor = label == "Call"
        ? const Color(0xFF00C853)
        : const Color(0xFF2962FF);

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
              Icon(icon, color: effectiveIconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: effectiveIconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // NOTE: For NestedScrollView to work, internal scrollables must use CustomScrollView or equivalent
  // that supports slivers if put in header, BUT in 'body', they should just be normal scrollables.
  // HOWEVER, because we want them to link with the outer scroll, we typically use
  // CustomScrollView with SliverOverlapInjector, OR simpler:
  // Just use ListView/GridView and Flutter handles the NestedScrollView linkage automatically via PrimaryScrollController.

  Widget _buildProductsTab() {
    if (_isLoadingProducts || _isLoadingOfferings) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool isPremium = ['education', 'publicservices', 'finance', 'religious', 'entertainment']
        .contains(widget.category?.toLowerCase().replaceAll(' ', '') ?? '');

    // If categories are empty but we have offerings, bypass drill-down
    if (_categories.isEmpty && _offerings.isNotEmpty && isPremium) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildOfferingCard(_offerings[index]),
                );
              }, childCount: _offerings.length),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          SliverToBoxAdapter(child: _buildYouTubePlayer()),
        ],
      );
    }

    if (_categories.isEmpty && _offerings.isEmpty) {
      return Center(
        child: Text(
          "No ${_getPrimaryTabLabel().toLowerCase()} available",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_selectedCategory == null) {
      // 1. Categories Grid View
      return CustomScrollView(
        key: const PageStorageKey('categories'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: _buildCategoryCard(category.name, category.imageUrl),
                );
              }, childCount: _categories.length),
            ),
          ),
          SliverToBoxAdapter(child: _buildYouTubePlayer()),
        ],
      );
    } else {
      // 2. Selected Category View (Drill-down)
      final category = _selectedCategory!;
      final products = _products
          .where((p) => p.categoryId == category.id)
          .toList();
      final offerings = _offerings
          .where((o) => o.categoryId == category.id || o.categoryId == null)
          .toList();

      final bool isPremium = ['education', 'publicservices', 'finance', 'religious', 'entertainment']
          .contains(widget.category?.toLowerCase().replaceAll(' ', '') ?? '');

      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _selectedCategory = null),
                    ),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: isPremium && offerings.isNotEmpty
                ? SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildOfferingCard(offerings[index]),
                      );
                    }, childCount: offerings.length),
                  )
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: _isOrderable() ? 0.65 : 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final p = products[index];
                      return _buildProductCard(p);
                    }, childCount: products.length),
                  ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          SliverToBoxAdapter(child: _buildYouTubePlayer()),
        ],
      );
    }
  }

  Widget _buildOfferingCard(ShopOffering offering) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offering.imageUrl != null && offering.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: offering.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  height: 160,
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        offering.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (offering.price != null && offering.price!.isNotEmpty)
                      Text(
                        offering.price!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2962FF),
                        ),
                      ),
                  ],
                ),
                if (offering.description != null && offering.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    offering.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SizedBox(
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Icon(
                          IconHelper.getIcon(widget.category, widget.tags),
                          color: IconHelper.getColor(widget.category, widget.tags),
                          size: 40,
                        ),
                      )
                    : Container(
                        color: IconHelper.getColor(widget.category, widget.tags).withValues(alpha: 0.1),
                        child: Icon(
                          IconHelper.getIcon(widget.category, widget.tags),
                          color: IconHelper.getColor(widget.category, widget.tags),
                          size: 50,
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOrderable() {
    final cat = widget.category?.toString().toLowerCase().replaceAll(' ', '') ?? '';
    final hasDeliveryTag = widget.tags.any((t) => t.toLowerCase() == 'delivery');
    return ['food', 'groceries', 'groceriesandfood'].contains(cat) && hasDeliveryTag;
  }

  Widget _buildProductCard(ShopProduct product) {
    final bool canOrder = _isOrderable();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            // Expand image to fill available space
            child: Stack(
              children: [
                product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          color: IconHelper.getColor(widget.category, widget.tags).withValues(alpha: 0.1),
                          child: Icon(
                            IconHelper.getIcon(widget.category, widget.tags),
                            color: IconHelper.getColor(widget.category, widget.tags),
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        color: IconHelper.getColor(widget.category, widget.tags).withValues(alpha: 0.1),
                        child: Icon(
                          IconHelper.getIcon(widget.category, widget.tags),
                          size: 50,
                          color: IconHelper.getColor(widget.category, widget.tags),
                        ),
                      ),
                // Stock Label
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (product.isAvailable ? Colors.green : Colors.red).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.isAvailable ? "IN STOCK" : "OUT OF STOCK",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  product.price,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (canOrder) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: product.isAvailable
                          ? () => _showOrderDialog(product)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        product.isAvailable ? 'Order' : 'Out of Stock',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderDialog(ShopProduct product) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    int quantity = 1;
    bool isLocating = false;

    // Prefill from current profile if possible
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('name, phone, location')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          nameController.text = profile['name']?.toString() ?? '';
          phoneController.text = profile['phone']?.toString() ?? '';
          if (profile['location'] != null && profile['location'].toString().isNotEmpty) {
             locationController.text = profile['location'].toString();
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ordering: ${product.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Price: ${product.price}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selector
                  Row(
                    children: [
                      const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setStateBuilder(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => setStateBuilder(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Name (From Profile)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number (From Profile)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Delivery Location / Address',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: isLocating ? null : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setStateBuilder(() => isLocating = true);
                            try {
                              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) throw 'Location services disabled.';
                              LocationPermission permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission = await Geolocator.requestPermission();
                                if (permission == LocationPermission.denied) throw 'Permission denied.';
                              }
                              if (permission == LocationPermission.deniedForever) throw 'Permission permanently denied.';
                              
                              Position position = await Geolocator.getCurrentPosition();
                              
                              // Use OSMService to reverse geocode
                              final osm = OSMService();
                              final place = await osm.getPlaceAt(LatLng(position.latitude, position.longitude));
                              
                              if (place != null) {
                                locationController.text = place.displayName;
                              } else {
                                locationController.text = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Could not get location: $e')),
                                );
                              }
                            } finally {
                              setStateBuilder(() => isLocating = false);
                            }
                          },
                          icon: isLocating 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, color: Color(0xFF2962FF)),
                          tooltip: 'Use Current Location',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final loc = locationController.text.trim();

                        if (name.isEmpty || phone.isEmpty || loc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context); // Close dialog
                        
                        try {
                          await Supabase.instance.client.from('orders').insert({
                            'shop_id': product.shopId,
                            'product_id': product.id,
                            'user_id': user?.id,
                            'customer_name': name,
                            'phone_no': phone,
                            'location': loc,
                            'quantity': quantity,
                            'status': 'pending',
                          });

                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Order placed successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to place order: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOffersTab() {
    if (_isLoadingOffers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_offers.isEmpty) {
      return const Center(
        child: Text("No offers available at the moment", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _offers.length + 1,
      itemBuilder: (context, index) {
        if (index == _offers.length) {
          return _buildYouTubePlayer();
        }
        final offer = _offers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (offer['poster'] != null && offer['poster'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: offer['poster'],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, err) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: IconHelper.getColor(widget.category).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Icon(
                    IconHelper.getIcon(widget.category, widget.tags),
                    size: 48,
                    color: IconHelper.getColor(widget.category),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer['offer_title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (offer['description'] != null && offer['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        offer['description'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (offer['expiry'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Text(
                          "Expires: ${offer['expiry'].toString().split('T').first}",
                          style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold),
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
  }

  Widget _buildSchedulesTab() {
    if (_isLoadingOffers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_offers.isEmpty) {
      final term = _isReligious ? "schedules" : "announcements";
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Text("No $term available at the moment", style: const TextStyle(color: Colors.grey)),
            ),
          ),
          _buildYouTubePlayer(),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _offers.length + 1,
      itemBuilder: (context, index) {
        if (index == _offers.length) {
          return _buildYouTubePlayer();
        }
        final schedule = _offers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2962FF).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(IconHelper.getIcon(widget.category, widget.tags), color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['offer_title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (schedule['expiry'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Until ${schedule['expiry'].toString().split('T').first}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              if (schedule['description'] != null && schedule['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule['description'],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
              if (schedule['poster'] != null && schedule['poster'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: schedule['poster'],
                    fit: BoxFit.cover,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    IconHelper.getIcon(widget.category, widget.tags),
                    size: 40,
                    color: Colors.white70,
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }


  Widget _buildReviewTab() {
    if (widget.id == null) {
      return const Center(child: Text("Reviews unavailable for this shop."));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          ReviewSection(
            shopId: widget.id!,
            ownerId: widget.ownerId,
            onRatingChanged: (newRating) {
              if (mounted) {
                // Check mounted
                setState(() {
                  _currentRating = newRating.toStringAsFixed(1);
                });
              }
            },
          ),
          _buildYouTubePlayer(),
        ],
      ),
    );
  }

  String _formatWorkingDays(List<int> days) {
    if (days.length == 7) return "All Days";

    final sortedDays = List<int>.from(days)..sort();

    if (listEquals(sortedDays, [1, 2, 3, 4, 5])) return "Mon - Fri";
    if (listEquals(sortedDays, [1, 2, 3, 4, 5, 6])) return "Mon - Sat";

    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return sortedDays.map((d) => weekDays[d]).join(', ');
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 1; // +1 bottom border?
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
          const Divider(height: 1, color: Color(0xFFEEEEEE)), // Bottom divider
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// Add the new delegate class
