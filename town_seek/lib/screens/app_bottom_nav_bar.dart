import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'location_page.dart';
import 'wishlist_page.dart';
import 'profile_page.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const AppBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2962FF),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(context, Icons.home_filled, 0),
          _buildNavItem(context, Icons.location_on, 1),
          _buildNavItem(context, Icons.favorite, 2),
          _buildNavItem(context, Icons.person, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == currentIndex) return;
        Widget page;
        switch (index) {
          case 0:
            page = const HomeScreen();
            break;
          case 1:
            page = const LocationPage();
            break;
          case 2:
            page = const WishlistPage();
            break;
          case 3:
            page = const ProfilePage();
            break;
          default:
            return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (BuildContext context) => page),
          (Route<dynamic> route) => false,
        );
      },
      child: isSelected
          ? Container(
              width: 90,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0x80D9D9D9),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2962FF),
                size: 26,
              ),
            )
          : Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
    );
  }
}
