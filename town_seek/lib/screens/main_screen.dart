import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'location_page.dart';
import 'wishlist_page.dart';
import 'profile_page.dart';
import 'home_navigator.dart'; // Import wrapper
import '../widgets/custom_bottom_nav_bar.dart'; // Import CustomBottomNavBar

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => MainScreenState();

  static MainScreenState of(BuildContext context) {
    return context.findAncestorStateOfType<MainScreenState>()!;
  }
}

class MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Using getter to ensure pages are recreated if needed, 
  // but with IndexedStack they are built once and kept.
  // We need to initialize the list of pages.

  void goToTab(int index) {
    _onItemTapped(index);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index && index == 0) {
      // If tapping home while on home, pop explicitly
      _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should allow system pop
    // We want to block system pop unless:
    // 1. We are on Home tab AND
    // 2. The internal Home navigator cannot pop anymore.
    
    // Actually, with PopScope canPop: false, we NEVER allow system pop automatically.
    // We manually decide what to do.
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        if (_selectedIndex != 0) {
          // If on any other tab, go to Home
          setState(() {
            _selectedIndex = 0;
          });
          return;
        } else {
          // We are on Home tab (index 0)
          // check nested navigator
          final navigator = _homeNavigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            return;
          }
          
          // If we are here, we are on the root of Home tab.
          // Now we can exit the app.
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeNavigator(navigatorKey: _homeNavigatorKey),
            LocationPage(isVisible: _selectedIndex == 1),
            const WishlistPage(),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
