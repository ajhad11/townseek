import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // 1. Sign in with standard Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (response.session != null) {
        final user = response.user!;
        final supabase = Supabase.instance.client;

        // 2. Check If User Is Admin (Requirement 2)
        // Query the profiles table for role === "admin"
        final profileCheck = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        
        if (profileCheck['role'] == 'admin') {
          // 3. Log Admin Login Activity (Requirement 4)
          // This call is async but we don't necessarily need to wait for it before proceeding
          // as per Requirement 5: Logging failure must not block the login process.
          if (mounted) {
            final supabaseService = Provider.of<SupabaseService>(context, listen: false);
            supabaseService.logAdminLogin();
          }

          // Success: User is a verified admin
          if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Deny: Valid user login, but no admin status in the 'profiles' table
          await supabase.auth.signOut();
          setState(() {
            _errorMessage = 'Access Denied: Your account does not have admin privileges.';
          });
        }
      }
    } on AuthException catch (e) {
       setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Connection error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/Logo.png', height: 100),
                const SizedBox(height: 32),
                const Text(
                  'Super Admin Access',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2962FF)),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Username or Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: _obscurePassword ? Colors.grey : const Color(0xFF2962FF),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Login'),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
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
