import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_header.dart';

class ManageResourcesPage extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ManageResourcesPage({super.key, required this.shop});

  @override
  State<ManageResourcesPage> createState() => _ManageResourcesPageState();
}

class _ManageResourcesPageState extends State<ManageResourcesPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _youtubeVideoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMediaLinks();
  }

  Future<void> _fetchMediaLinks() async {
    try {
      final response = await Supabase.instance.client
          .from('media')
          .select()
          .eq('shop_id', widget.shop['id'])
          .maybeSingle();

      if (response != null) {
        _websiteController.text = response['website'] ?? '';
        _instagramController.text = response['instagram'] ?? '';
        _facebookController.text = response['facebook'] ?? '';
        _youtubeController.text = response['youtube'] ?? '';
        _youtubeVideoController.text = response['youtube_video'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching media links: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMediaLinks() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final mediaData = {
        'shop_id': widget.shop['id'],
        'website': _websiteController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'youtube': _youtubeController.text.trim(),
        'youtube_video': _youtubeVideoController.text.trim(),
      };

      // Check if entry exists
      final existing = await Supabase.instance.client
          .from('media')
          .select('id')
          .eq('shop_id', widget.shop['id'])
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('media')
            .update(mediaData)
            .eq('shop_id', widget.shop['id']);
      } else {
        await Supabase.instance.client.from('media').insert(mediaData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resources updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving resources: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomHeader(
            title: 'Manage Resources',
            showBackButton: true,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Social Media Links",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Provide links to your social media profiles. These will appear as icons on your shop's About section.",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          _buildLinkField(
                            controller: _websiteController,
                            label: 'Website URL',
                            icon: Icons.language,
                            hint: 'https://example.com',
                          ),
                          const SizedBox(height: 16),
                          _buildLinkField(
                            controller: _instagramController,
                            label: 'Instagram URL',
                            icon: Icons.camera_alt_outlined,
                            hint: 'https://instagram.com/yourshop',
                          ),
                          const SizedBox(height: 16),
                          _buildLinkField(
                            controller: _facebookController,
                            label: 'Facebook URL',
                            icon: Icons.facebook,
                            hint: 'https://facebook.com/yourshop',
                          ),
                          const SizedBox(height: 16),
                          _buildLinkField(
                            controller: _youtubeController,
                            label: 'YouTube Channel URL',
                            icon: Icons.play_circle_fill,
                            hint: 'https://youtube.com/@yourchannel',
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            "Product Spotlight Video",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Enter a YouTube video link to showcase your shop. This video will be playable directly on your profile page.",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          _buildLinkField(
                            controller: _youtubeVideoController,
                            label: 'YouTube Video URL',
                            icon: Icons.smart_display_rounded,
                            hint: 'https://youtube.com/watch?v=...',
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveMediaLinks,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2962FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'SAVE RESOURCES',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2962FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
            return 'Please enter a valid URL (include http:// or https://)';
          }
        }
        return null;
      },
    );
  }
}
