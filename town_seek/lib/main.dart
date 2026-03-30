import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/personal_registration_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/user_details_screen.dart';
import 'package:town_seek/utils/permission_manager.dart';
import 'data/user_manager.dart';
import 'widgets/no_internet_wrapper.dart';
import 'widgets/responsive_layout.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://bxjasdlhozceeztnxhcj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4amFzZGxob3pjZWV6dG54aGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTIzMzYsImV4cCI6MjA4NDEyODMzNn0.FbyOtuqQ_0SpKr4FOTfXL8e9ssPDi5PHW2RfinpDez8',
  );

  // Set status bar to white with dark icons for visibility (guarded for web)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF2962FF), // App Blue Theme
      statusBarIconBrightness: Brightness.light, // White icons
      statusBarBrightness: Brightness.dark, // For iOS
    ));
  }

  // Request permissions on startup (guarded for web) - don't await to avoid blocking splash screen
  if (!kIsWeb) {
    PermissionManager.requestInitialPermissions();
  }

  // Fetch user profile if logged in — must be fully awaited before runApp
  if (Supabase.instance.client.auth.currentUser != null) {
    await UserManager.instance.fetchProfile();
  }

  runApp(const TownSeekApp());
}

final supabase = Supabase.instance.client;
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class TownSeekApp extends StatelessWidget {
  const TownSeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TownSeek',
      navigatorObservers: [routeObserver],
      builder: (context, child) {
        return NoInternetWrapper(
          child: ResponsiveLayout(child: child!),
        );
      },
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.dmSansTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2962FF),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF2962FF),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SmoothPageTransitionsBuilder(),
            TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          },
        ),
      ),
      home: supabase.auth.currentSession != null ? const MainScreen() : const LoginScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/sign_in': (context) => const SignInScreen(),
        '/user_details': (context) => const UserDetailsScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Custom premium transition: Extremely fast Slide from right + Fade in
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0.0), // Start much closer so it snaps
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuart), // Compress into first 35% of time
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut), // Fade in instantly
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}
