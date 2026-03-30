import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:town_seek/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Color primaryBlue = const Color(0xFF2962FF);

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Discover Local Favorites",
      "text": "Find the best shops, hospitals, and services right in your neighborhood with ease.",
    },
    {
      "title": "List Your Business",
      "text": "Reach more customers by adding your own establishment to our growing community map.",
    },
    {
      "title": "Seamless Appointments",
      "text": "Book appointments easily with doctors, salons, and various local services.",
    },
    {
      "title": "Exclusive Local Deals",
      "text": "Access special offers and discounts from your favorite local businesses.",
    },
    {
      "title": "Engage & Connect",
      "text": "Leave reviews, add to your wishlist, and instantly connect with local business owners.",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextTap() {
    if (_currentPage == onboardingData.length - 1) {
      // Navigate to Main App
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkipTap() {
     Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top Right Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onSkipTap,
                child: Text('Skip', style: TextStyle(color: primaryBlue, fontSize: 16)),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: onboardingData[index]["title"]!,
                  text: onboardingData[index]["text"]!,
                  index: index,
                ),
              ),
            ),
            
            // Bottom UI (Dots and Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index: index),
                    ),
                  ),
                  
                  // Next / Let's Go Button
                  ElevatedButton(
                    onPressed: _onNextTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      _currentPage == onboardingData.length - 1 ? "Let's Go" : "Next",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? primaryBlue : primaryBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.title,
    required this.text,
    required this.index,
  });

  final String title, text;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Determine dynamic icon based on the index to act as our illustrative element
    IconData displayIcon;
    if (index == 0) {
      displayIcon = Icons.storefront_outlined;
    } else if (index == 1) {
      displayIcon = Icons.add_business_rounded;
    } else if (index == 2) {
      displayIcon = Icons.calendar_month_outlined;
    } else if (index == 3) {
      displayIcon = Icons.local_offer_outlined;
    } else {
      displayIcon = Icons.connect_without_contact;
    }

    const primaryBlue = Color(0xFF2962FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustrative Circle Element
          Container(
             width: 200,
             height: 200,
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               color: primaryBlue.withValues(alpha: 0.1),
             ),
             child: Center(
               child: Icon(
                 displayIcon,
                 size: 100,
                 color: primaryBlue,
               ),
             ),
          ),
          
          const SizedBox(height: 60),
          
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}
