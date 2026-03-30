import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_manager.dart';
import 'email_verification_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const Color primaryBlue = Color(0xFF2566FF);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(); // Added Email
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
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

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Sign up with Supabase Auth
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'com.townseek://login-callback',
      );

      final User? user = res.user;
      final Session? session = res.session;

      if (user != null) {
        if (session == null) {
          // Email confirmation is required
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmailVerificationPage(
                  email: email,
                ),
              ),
            );
          }
          return;
        }

        // Account already created and session exists (e.g. email confirm not required or instant)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account Created Successfully')),
          );
          // Redundant fetchProfile removed as auth listener handles it
        }
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
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Row: Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SignInScreen.primaryBlue.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logo
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    "Create your account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: SignInScreen.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Email
                  _GreyTextField(
                    controller: _emailController,
                    hintText: 'Email', // Added Email
                    validator: (value) => value == null || value.isEmpty ? 'Please enter an email' : null,
                  ),

                  const SizedBox(height: 16),

                  // Password
                  _GreyTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a password' : null,
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password
                  _GreyTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    validator: (value) => value == null || value.isEmpty ? 'Please confirm your password' : null,
                  ),

                  const SizedBox(height: 30),

                  // Sign-in Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SignInScreen.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Footer
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Town Seek',
                      style: TextStyle(
                        color: SignInScreen.primaryBlue,
                        fontSize: 14,
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

class _GreyTextField extends StatefulWidget {
  final bool obscureText;
  final TextEditingController? controller;
  final String hintText;
  final String? Function(String?)? validator;

  const _GreyTextField({
    this.obscureText = false,
    this.controller,
    required this.hintText,
    this.validator,
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
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        validator: widget.validator,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          errorStyle: const TextStyle(height: 0.8),
          suffixIcon: widget.obscureText || _obscureText 
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
