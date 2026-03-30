import 'package:flutter/material.dart';
import '../data/user_manager.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  static const Color primaryBlue = Color(0xFF2566FF);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await UserManager.instance.updateProfile(name: name, phone: phone);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
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
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 56),

                          // Premium Illustration/Icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: UserDetailsScreen.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 60,
                              color: UserDetailsScreen.primaryBlue,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Title
                          const Text(
                            "Complete your profile",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: UserDetailsScreen.primaryBlue,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Name
                          _GreyTextField(
                            controller: _nameController,
                            hintText: 'Name',
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                          ),

                          const SizedBox(height: 16),
                          
                          // Phone No
                          _GreyTextField(
                            controller: _phoneController,
                            hintText: 'Phone No',
                            validator: (value) => value == null || value.isEmpty ? 'Please enter a phone number' : null,
                          ),

                          const SizedBox(height: 30),

                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: UserDetailsScreen.primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Continue",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const Spacer(),

                          // Footer
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Town Seek',
                              style: TextStyle(
                                color: UserDetailsScreen.primaryBlue,
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
          },
        ),
      ),
    );
  }
}

class _GreyTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? Function(String?)? validator;

  const _GreyTextField({
    this.controller,
    required this.hintText,
    this.validator,
  });

  @override
  State<_GreyTextField> createState() => _GreyTextFieldState();
}

class _GreyTextFieldState extends State<_GreyTextField> {
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
        validator: widget.validator,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          errorStyle: const TextStyle(height: 0.8),
        ),
      ),
    );
  }
}
