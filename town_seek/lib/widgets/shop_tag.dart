/// Shop Tag Widget
///
/// Displays individual tags for shops with different colors based on tag type.
/// Features color-coded backgrounds and text for better visual categorization.
library;

import 'package:flutter/material.dart';

class ShopTag extends StatelessWidget {
  final String text;

  const ShopTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    // Default Style (Blue like Home Screen)
    Color bgColor = const Color(0xFFE3F2FD); // Light Blue 50
    Color txtColor = const Color(0xFF2196F3); // Blue

    // Custom Rules
    if (text == "Parking") { 
      bgColor = const Color(0xFFE8F5E9); // Green 50
      txtColor = const Color(0xFF4CAF50); // Green
    }
    if (text == "Offer" || text == "Street parking") { 
      bgColor = const Color(0xFFFFFDE7); // Yellow 50
      txtColor = const Color(0xFFFBC02D); // Yellow 700 (Visible on light yellow)
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: txtColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
