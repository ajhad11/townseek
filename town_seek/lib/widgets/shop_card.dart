/// Shop Card Widget & Model
///
/// Contains the Shop data model and the ShopCard widget for displaying shop details.
library;

import 'package:flutter/material.dart';
import 'shop_tag.dart';
import '../utils/icon_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Data Model for Shop Information
class Doctor {
  final String? id;
  final String name;
  final String speciality;
  final String qualification;
  final String availability;
  final String imageUrl;
  final List<String>? availableDays;
  final int? bookingLimit;

  const Doctor({
    this.id,
    required this.name,
    required this.speciality,
    required this.qualification,
    required this.availability,
    this.imageUrl = "",
    this.availableDays,
    this.bookingLimit,
  });
}

class ServiceItem {
  final String name;
  final String price; // e.g., "Rs 300 /PCS"
  final String imageUrl;

  const ServiceItem({
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}

class ShopProductCategory {
  final String id;
  final String shopId;
  final String name;
  final String? imageUrl;

  const ShopProductCategory({
    required this.id,
    required this.shopId,
    required this.name,
    this.imageUrl,
  });
}

class ShopProduct {
  final String id;
  final String shopId;
  final String categoryId;
  final String name;
  final String price;
  final String? imageUrl;
  final bool isAvailable;

  const ShopProduct({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
  });
}

class ShopOffering {
  final String id;
  final String shopId;
  final String? categoryId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? price;

  const ShopOffering({
    required this.id,
    required this.shopId,
    this.categoryId,
    required this.title,
    this.description,
    this.imageUrl,
    this.price,
  });
}

class Shop {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String rating;
  final List<String> tags;
  final bool isOpen;
  final List<String>? facilities;
  final List<Doctor>? doctors;
  final List<ServiceItem>? services;
  final String? googleMapsLink;
  final String? openingTime;
  final String? closingTime;
  final double? latitude;
  final double? longitude;
  final String? category;
  final String? description;
  final String? location;
  final String? phone;
  final String? email;
  final List<int>? workingDays; // 0=Sun, 6=Sat
  final String? id;
  final String? ownerId;
  final int profileClicks;
  final List<String> searchKeywords;
  final bool? openNowOverride;

  const Shop({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.tags,
    required this.isOpen,
    this.facilities,
    this.doctors,
    this.services,
    this.googleMapsLink,
    this.openingTime,
    this.closingTime,
    this.latitude,
    this.longitude,
    this.category,
    this.description,
    this.location,
    this.phone,
    this.email,
    this.workingDays,
    this.id,
    this.ownerId,
    this.profileClicks = 0,
    this.searchKeywords = const [],
    this.openNowOverride,
  });
}

/// Individual Shop Card Widget
class ShopCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String rating;
  final List<String> tags;
  final bool isOpen;
  final String? category;
  final bool? openNowOverride;

  const ShopCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.tags,
    required this.isOpen,
    this.category,
    this.openNowOverride,
  });



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x80D9D9D9),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Shop Image with Category Icon Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            Container(width: 100, height: 100, color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.white70)),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: IconHelper.getColor(category).withValues(alpha: 0.15),
                        child: Icon(
                          IconHelper.getIcon(category, tags),
                          size: 45,
                          color: IconHelper.getColor(category),
                        ),
                      ),
              ),
              if (category != null && category!.isNotEmpty)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: IconHelper.getColor(category),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      IconHelper.getIcon(category, tags),
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          // Details
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.star, size: 12, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map<Widget>((String tag) => ShopTag(text: tag)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Builder(
                      builder: (context) {
                        final effectiveOpen = openNowOverride ?? isOpen;
                        return Text(
                          effectiveOpen ? "OPEN" : "CLOSED",
                          style: TextStyle(
                            color: effectiveOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
