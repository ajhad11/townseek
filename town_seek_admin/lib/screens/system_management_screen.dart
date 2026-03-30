import 'package:flutter/material.dart';

class SystemManagementScreen extends StatelessWidget {
  const SystemManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Management'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Categories Management'),
            const _ActionCard(
              title: 'Manage Categories',
              subtitle: 'Add, Edit or Delete product/shop categories',
              icon: Icons.category,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Offers & Promotions'),
            const _ActionCard(
              title: 'Manage Offers',
              subtitle: 'Active platform-wide discounts and banners',
              icon: Icons.local_offer,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Platform Settings'),
            const _ActionCard(
              title: 'Global Settings',
              subtitle: 'Maintenance mode, API keys, and legal documents',
              icon: Icons.settings_applications,
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'TownSeek Admin v1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2962FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2962FF)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to specific management page
        },
      ),
    );
  }
}
