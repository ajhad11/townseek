import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/supabase_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('en_US', null);
    Intl.defaultLocale = 'en_US';
  } catch (e) {
    debugPrint('DateFormat init error: $e');
  }
  
  await Supabase.initialize(
    url: 'https://bxjasdlhozceeztnxhcj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupabaseService()),
      ],
      child: const AdminApp(),
    ),
  );
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<bool> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _checkAdminStatus();
  }

  Future<bool> _checkAdminStatus() async {
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    
    if (currentUser == null) return false;

    try {
      final adminCheck = await client
          .from('admins')
          .select()
          .eq('profile_id', currentUser.id)
          .eq('is_active', true)
          .maybeSingle();

      if (adminCheck != null) return true;
      
      // If not an admin, sign out
      await client.auth.signOut();
      return false;
    } catch (e) {
      debugPrint('AuthWrapper Check Error: $e');
      await client.auth.signOut();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/Logo.png', height: 80),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Color(0xFF2962FF)),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TownSeek Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2962FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2962FF),
          primary: const Color(0xFF2962FF),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2962FF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
