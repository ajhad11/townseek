import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import 'user_details_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = Provider.of<SupabaseService>(context, listen: false).getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<SupabaseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('User Records', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshUsers),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Sync Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) return const Center(child: Text('No users found.'));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView.builder(
                itemCount: users.length,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final bool isBlocked = user['is_disabled'] ?? false;
                  final bool isAdmin = user['role'] == 'admin';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailsScreen(userId: user['id']))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2962FF).withOpacity(0.1),
                        backgroundImage: user['avatar_url'] != null ? CachedNetworkImageProvider(user['avatar_url']) : null,
                        child: user['avatar_url'] == null ? const Icon(Icons.person, color: Color(0xFF2962FF)) : null,
                      ),
                      title: Text(user['name'] ?? 'Anonymous User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user['role']?.toString().toUpperCase() ?? 'USER', style: TextStyle(color: isAdmin ? Colors.deepPurple : Colors.blueGrey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isBlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              color: isBlocked ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            onPressed: () async {
                              try {
                                if (isBlocked) {
                                  await service.unblockUser(user['id']);
                                } else {
                                  await service.blockUser(user['id']);
                                }
                                _refreshUsers();
                              } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                              }
                            },
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
