import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_manager.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && !_isRedirecting) {
        setState(() {
          _isRedirecting = true;
        });
        await _handlePostConfirmation(session);
      }
    });
  }

  Future<void> _handlePostConfirmation(Session session) async {
    try {
      // Fetch/Create profile via UserManager
      await UserManager.instance.fetchProfile();

      // Navigate to user details to complete profile
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/user_details', (route) => false);
      }
    } catch (e) {
      debugPrint('Error during post-confirmation setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup error: $e. Please contact support if this persists.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Illustration/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2566FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 60,
                      color: Color(0xFF2566FF),
                    ),
                  ),
                  const SizedBox(height: 40),
    
                  // Title
                  const Text(
                    'Verify your email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
    
                  // Subtitle
                  Text(
                    'We\'ve sent a confirmation link to:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2566FF),
                    ),
                  ),
                  const SizedBox(height: 32),
    
                  // Status Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2566FF)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Waiting for confirmation...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
    
                  // Instructions
                  Text(
                    'Click the link in the email to automatically log in to Town Seek. If you don\'t see the email, please check your spam folder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
    
                  // Back to Login
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Color(0xFF2566FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
