import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Location + Profile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 10, color: Colors.white),
                        const SizedBox(height: 5),
                        Container(width: 150, height: 14, color: Colors.white),
                      ],
                    ),
                    const Spacer(),
                    Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Categories Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) => 
                     Column(
                       children: [
                         Container(
                           width: 60, height: 60,
                           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                         ),
                         const SizedBox(height: 8),
                         Container(width: 40, height: 8, color: Colors.white),
                       ],
                     )
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Shops List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(width: 120, height: 18, color: Colors.white),
              ),
              
              const SizedBox(height: 15),

              // Shop Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 150, height: 14, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Container(width: 100, height: 10, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Container(width: 80, height: 10, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
