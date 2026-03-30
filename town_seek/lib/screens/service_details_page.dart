import 'package:flutter/material.dart';
import '../utils/category_term_helper.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import '../widgets/shop_card.dart'; // For Shop and ServiceItem classes
import 'location_page.dart'; // Import LocationPage
import '../data/wishlist_manager.dart';
import '../data/shop_data.dart';
import '../widgets/shop_tag.dart';
import '../widgets/review_section.dart'; // Import ReviewSection
import '../utils/time_helper.dart';
import '../utils/icon_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/qr_display_dialog.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ServiceDetailsPage extends StatefulWidget {
  final Shop shop;
  final int initialTabIndex;

  const ServiceDetailsPage({
    super.key,
    required this.shop,
    this.initialTabIndex = 0,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;
  late String _currentRating;
  bool _isLoadingOffers = true;
  List<Map<String, dynamic>> _offers = [];
  Map<String, dynamic>? _mediaLinks;
  bool _isMuted = true;
  YoutubePlayerController? _youtubeController;
  bool _showYouTubePlayer = false;
  List<ShopOffering> _offerings = [];
  bool _isLoadingOfferings = false;

  @override
  void initState() {
    super.initState();
    // Delay click tracking to avoid counting bounces (#7)
    if (widget.shop.id != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) ShopData.incrementClicks(widget.shop.id!, widget.shop.ownerId);
      });
    }
    _currentRating = widget.shop.rating;
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 190) {
        if (!_showTitle) setState(() => _showTitle = true);
      } else {
        if (_showTitle) setState(() => _showTitle = false);
      }
    });
    // Parallel fetch all data (#3)
    Future.wait([
      _fetchOffers(),
      _fetchOfferings(),
      _fetchMediaLinks(),
    ]);
  }

  Future<void> _fetchMediaLinks() async {
    if (widget.shop.id == null) return;
    try {
      final response = await Supabase.instance.client
          .from('media')
          .select()
          .eq('shop_id', widget.shop.id!)
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

  Future<void> _fetchOfferings() async {
    // Use helper instead of inline list (#8)
    if (!CategoryTermHelper.isOfferingCategory(widget.shop.category)) return;

    if (mounted) setState(() => _isLoadingOfferings = true);
    try {
      final offerings = await ShopData.fetchOfferings(widget.shop.id!);
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

  Future<void> _fetchOffers() async {
    if (widget.shop.id == null) {
      if (mounted) setState(() => _isLoadingOffers = false);
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('offers')
          .select()
          .eq('shop_id', widget.shop.id!)
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

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  String _getPrimaryTabLabel() {
    return CategoryTermHelper.getPluralTerm(widget.shop.category);
  }

  bool get _isReligious {
    final cat = widget.shop.category?.toLowerCase() ?? '';
    if (cat == 'religious') return true;

    // Fallback search in tags
    final religiousTags = ['mosque', 'temple', 'church', 'masjid', 'religious'];
    return widget.shop.tags
        .any((tag) => religiousTags.contains(tag.toLowerCase()));
  }

  bool get _isPublicService {
    final cat = widget.shop.category?.toLowerCase().replaceAll(' ', '') ?? '';
    return cat == 'publicservices';
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
              backgroundColor: const Color(0xFF2962FF),
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
                        Text(
                          "${widget.shop.location ?? (widget.shop.tags.isNotEmpty ? widget.shop.tags.first : CategoryTermHelper.getSingularTerm(widget.shop.category))} • 1.5 km",
                          style: const TextStyle(
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
                            Icons.build,
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

            // Persistent Header -> Scrolling Adapter
            SliverToBoxAdapter(child: _buildServiceDetailsContent()),

            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2962FF),
                  unselectedLabelColor: Colors.black,
                  indicatorColor: const Color(0xFF2962FF),
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
              pinned: false,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServicesTab(), // Grid of Service Items
            (_isReligious || _isPublicService) ? _buildSchedulesTab() : _buildOffersTab(),
            _buildReviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsContent() {
    final shop = widget.shop;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Rating
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.title,
                  style: const TextStyle(
                    fontSize: 22,
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
            shop.subtitle,
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
                  shop.location ?? shop.subtitle,
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
              if (shop.openingTime != null && shop.closingTime != null)
                Text(
                  "${TimeHelper.formatTimeString(shop.openingTime)}  TO  ${TimeHelper.formatTimeString(shop.closingTime)}   ",
                  style: const TextStyle(color: Colors.black),
                )
              else
                const Text(
                  "08:00 AM  TO  10:00 PM   ",
                  style: TextStyle(color: Colors.black),
                ), // const Text
              Text(
                shop.isOpen ? "OPEN" : "CLOSED",
                style: TextStyle(
                  color: shop.isOpen ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description (About)
          if (shop.description != null && shop.description!.isNotEmpty) ...[
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
              shop.description!,
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
            children: shop.tags.map((tag) => ShopTag(text: tag)).toList(),
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
                  if (widget.shop.email != null &&
                      widget.shop.email!.isNotEmpty) {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: widget.shop.email,
                      queryParameters: {
                        'subject': 'Inquiry about ${widget.shop.title}',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email not available")),
                    );
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

  Widget _buildServicesTab() {
    if (_isLoadingOfferings) {
      return const Center(child: CircularProgressIndicator());
    }
    final services = widget.shop.services ?? [];
    final cat = widget.shop.category?.toLowerCase().replaceAll(' ', '') ?? '';
    final isPremium = ['education', 'publicservices', 'finance', 'religious', 'entertainment'].contains(cat);

    if (services.isEmpty && _offerings.isEmpty) {
      return Center(child: Text("No specific ${_getPrimaryTabLabel().toLowerCase()} listed"));
    }

    return CustomScrollView(
      slivers: [
        if (isPremium && _offerings.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildOfferingCard(_offerings[index]),
                ),
                childCount: _offerings.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildServiceCard(services[index]),
                childCount: services.length,
              ),
            ),
          ),
        SliverToBoxAdapter(child: _buildYouTubePlayer()),
      ],
    );
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

  Widget _buildServiceCard(ServiceItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
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
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: const Color(0xFFFFF3E0), // Light orange background
                      child: const Icon(
                        Icons.handyman,
                        size: 50,
                        color: Color(0xFFF57C00),
                      ), // Handyman icon
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                    if (offer['expire_date'] != null)
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
                          "Expires: ${offer['expire_date'].toString().split('T').first}",
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
      return Center(
        child: Text("No $term available at the moment", style: const TextStyle(color: Colors.grey)),
      );
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
                    child: Icon(IconHelper.getIcon(widget.shop.category, widget.shop.tags), color: Colors.white, size: 30),
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
                    IconHelper.getIcon(widget.shop.category, widget.shop.tags),
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
    if (widget.shop.id == null) {
      return const Center(child: Text("Reviews unavailable"));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          ReviewSection(
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
          _buildYouTubePlayer(),
        ],
      ),
    );
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
