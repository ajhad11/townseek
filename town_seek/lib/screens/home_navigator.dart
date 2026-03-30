import 'package:flutter/material.dart';
import 'home_screen.dart';

class HomeNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const HomeNavigator({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}
