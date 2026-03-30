import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Color primaryBlue = Color(0xFF2566FF);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(); // Changed from username
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null && mounted) {
        await UserManager.instance.fetchProfile();
        if (mounted) {
          if (UserManager.instance.phone.isEmpty || UserManager.instance.name == 'User' || UserManager.instance.name.isEmpty) {
            Navigator.of(context).pushNamedAndRemoveUntil('/user_details', (route) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;

      if (user != null && mounted) {
        // Login Success - The auth listener in initState will handle navigation 
        // to either /user_details or /onboarding after fetchProfile is called there.
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Spacer to replace the removed back button and keep layout identical
                const SizedBox(height: 56),

                // Logo
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
                ),

                const SizedBox(height: 40),

                // Title
                const Text(
                  'Login in to your account',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2566FF),
                  ),
                ),
                
                const SizedBox(height: 30),

                // Email Field
                _GreyTextField(
                  controller: _emailController,
                  hintText: 'Email', // Changed from User name
                ),

                const SizedBox(height: 16),

                // Password Field
                _GreyTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                const SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2566FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Login',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // "Or"
                const Text(
                  'Or',
                  style: TextStyle(
                    color: Color(0xFF2566FF),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                // Don't have a account Sign-in
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have a account ",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/sign_in'),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2566FF),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30), // Pushes footer down

                // Footer
                 TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Town Seek',
                    style: TextStyle(
                      color: Color(0xFF2566FF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreyTextField extends StatefulWidget {
  final bool obscureText;
  final TextEditingController? controller;
  final String hintText;
  
  const _GreyTextField({
    this.obscureText = false, 
    this.controller,
    required this.hintText,
  });

  @override
  State<_GreyTextField> createState() => _GreyTextFieldState();
}

class _GreyTextFieldState extends State<_GreyTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light Grey
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          // Suffix Icon logic mainly for password
            suffixIcon: widget.obscureText || _obscureText 
            // Note: This logic is slightly tricky if we want to toggle.
            // If original widget.obscureText was true, we show toggle.
            // If it was false (username), we don't.
              ? widget.obscureText ? IconButton(
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                ) : null
              : null,
        ),
      ),
    );
  }
}

// End of file
