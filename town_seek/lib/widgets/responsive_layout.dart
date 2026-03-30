import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1000, // Ideal width for shop discovery on desktop
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Scaffold(
      backgroundColor: Colors.grey[200], // Background for desktop view
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
