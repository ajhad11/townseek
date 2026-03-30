import 'package:flutter/material.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity, // Ensure full width for alignment
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(), // Push content towards center
              // Logo
              // Logo
              Container(
                 width: 120,
                 height: 120,
                 decoration: const BoxDecoration(
                   shape: BoxShape.circle,
                 ),
                 child: ClipOval(
                    child: Image.asset('assets/logo_blue_t.png', fit: BoxFit.contain),
                 ),
              ),
              
              const SizedBox(height: 80), // Gap between logo and buttons

              // Login button
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  key: const Key('login_button'),
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Less rounded
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2962FF),
                    elevation: 0, // Flat look
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign-in button
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  key: const Key('signin_button'),
                  onPressed: () => Navigator.of(context).pushNamed('/sign_in'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFEEEEEE), // Light Grey
                    foregroundColor: const Color(0xFF2962FF), // Blue Text
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign-in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const Spacer(),

              // Footer Text
              TextButton(
                onPressed: () {
                    // Optional: Action if they tap the brand name
                },
                child: const Text(
                  'Town Seek',
                  style: TextStyle(
                    color: Color(0xFF2962FF),
                    fontWeight: FontWeight.w500, // Medium weight
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

}
