import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import '../data/user_manager.dart'; // Import UserManager
import 'main_screen.dart';
import 'edit_profile_page.dart';
import 'business_adding_page.dart';
import 'business_dashboard_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'orders_bookings_page.dart';
import '../services/login_log_service.dart';


/// Profile Page
///
/// Displays user profile information and settings.
/// This page is accessed when the user taps the Person icon in bottom navigation.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Removed local state variables in favor of UserManager
  bool _isListingOwner = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('shops')
          .select('id')
          .eq('owner_id', user.id)
          .limit(1);

      if (mounted && response.isNotEmpty) {
        setState(() {
          _isListingOwner = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _editProfile() async {
    final user = UserManager.instance;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentName: user.name,
          currentImage: user.profileImage, // Edit page might need logic to handle local image too? 
          // EditPage takes string currentImage. If we have local, we might need to pass path? 
          // Current EditProfilePage implementation takes 'currentImage' as String(URL) and doesn't explicitly take File. 
          // But it has `_selectedImage` logic. 
          // Let's pass the URL for now as placeholder if local exists, OR pass local path?
          // If local exists, EditPage should ideally show it. 
          // EditPage logic: `backgroundImage: _imageFile != null ? FileImage ... : NetworkImage`.
          // We can't easily pass File to EditPage constructor without changing it.
          // For now let's pass the URL. If user has local image, EditPage won't show it initially unless we update EditPage.
          // BUT, we can simple pass the profileImage URL. The user can pick new one.
          // Improvement: Update EditProfilePage to accept File? or path.
          // For now, let's keep it simple.
          currentPhone: user.phone,
        ),
      ),
    );

    if (result != null && result is Map) {
      if (result['isLocalImage'] == true) {
        final dynamic localImage = result['image'];
        setState(() => _isLoading = true);
        try {
           final String? uploadedUrl = await UserManager.instance.uploadProfileImage(localImage);
           
           if (uploadedUrl != null) {
                UserManager.instance.updateProfile(
                 name: result['name'],
                 phone: result['phone'],
                 image: uploadedUrl,
                 localImage: localImage 
               );
           }
        } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text("Upload failed: ${e.toString().replaceAll('StorageException:', '')}"),
                 backgroundColor: Colors.red,
                 duration: const Duration(seconds: 5),
               )
             );
           }
           UserManager.instance.updateProfile(
              name: result['name'],
              phone: result['phone'],
              localImage: localImage,
           );
        }
        setState(() => _isLoading = false);
      } else {
        if (result['image'] == '') {
          setState(() => _isLoading = true);
          try {
             await UserManager.instance.deleteProfileImage();
          } catch(e) {
             debugPrint('Failed to delete image: $e');
          }
        }
        UserManager.instance.updateProfile(
          name: result['name'],
          phone: result['phone'],
          image: result['image'] is String ? result['image'] : '',
          clearLocalImage: true, 
        );
         setState(() => _isLoading = false);
      }
    }
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  "Are You Sure\nWant To Sign Out?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                const Text(
                  "You will need to sign in again to access your account and saved data.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Yes button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user != null) {
                        await LoginLogService.logLogout(user.id);
                      }
                      await Supabase.instance.client.auth.signOut();
                      UserManager.instance.clearProfile();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Yes I'm",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Not Now button
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "Not Now",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2962FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: UserManager.instance,
            builder: (context, child) {
              final user = UserManager.instance;
              return Column(
                children: [

              // ── FIXED HEADER ──────────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Gradient background
                  Container(
                    height: 210,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A47CC), Color(0xFF2962FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -20, right: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40, left: -20,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Back button top-left
                  Positioned(
                    top: 52, left: 20,
                    child: InkWell(
                      onTap: () {
                        final mainScreen = context.findAncestorStateOfType<MainScreenState>();
                        if (mainScreen != null) {
                          mainScreen.goToTab(0);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  // Title
                  const Positioned(
                    top: 60, left: 0, right: 0,
                    child: Center(
                      child: Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Avatar card — overlaps into body
                  Positioned(
                    bottom: -55,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 6))],
                      ),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: _editProfile,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundImage: user.localImageFile != null
                                  ? (kIsWeb 
                                      ? MemoryImage(user.localImageFile!) 
                                      : FileImage(user.localImageFile!) as ImageProvider)
                                  : NetworkImage(user.profileImage),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 68), // space for avatar overflow

              // ── NAME & BADGE ───────────────────────────────────────────
              Text(
                user.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isListingOwner ? '✦ Listing Owner' : '✦ Explorer',
                  style: const TextStyle(color: blue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),

              // ── SCROLLABLE SETTINGS BODY ───────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      // ── SETTINGS SECTIONS ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Section: Account
                            _buildSectionLabel('Account'),
                            const SizedBox(height: 10),
                            _buildMenuItem('Edit Profile',     icon: Icons.person_outline,      color: blue,                     onTap: _editProfile),
                            const SizedBox(height: 10),
                            _buildMenuItem('Orders & Bookings', icon: Icons.receipt_long_outlined, color: const Color(0xFF00897B),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersBookingsPage()))),

                            const SizedBox(height: 24),

                            // Business Banner
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessAddingPage())),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1A47CC), Color(0xFF4C7FFF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: blue.withValues(alpha: 0.3),
                                      blurRadius: 16, offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Add Your Establishment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                          SizedBox(height: 3),
                                          Text('Reach more customers in your area', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Section: Business
                            _buildSectionLabel('Business'),
                            const SizedBox(height: 10),
                            _buildMenuItem('Business Dashboard', icon: Icons.dashboard_outlined, color: const Color(0xFF8E24AA),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessDashboardPage()));
                                _checkOwnership();
                              }),

                            const SizedBox(height: 24),

                            // Section: More
                            _buildSectionLabel('More'),
                            const SizedBox(height: 10),
                            _buildMenuItem('About Us', icon: Icons.info_outline_rounded, color: const Color(0xFFFB8C00)),
                            const SizedBox(height: 10),
                            _buildMenuItem('Sign Out', icon: Icons.logout_rounded, color: Colors.red,
                              onTap: _showSignOutConfirmation, textColor: Colors.red),

                            const SizedBox(height: 36),
                          ],
                        ),
                      ),

                      // ── FOOTER ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Column(
                          children: [
                            Image.asset('assets/Logo.png', height: 28),
                            const SizedBox(height: 6),
                            const Text('Town Seek',
                              style: TextStyle(color: blue, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('v1.0.0', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      if (_isLoading)
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(color: blue),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }


  Widget _buildMenuItem(String title, {
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon chip
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
          ],
        ),
      ),
    );
  }
}
