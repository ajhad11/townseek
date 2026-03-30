import 'package:flutter/material.dart';

class IconHelper {
  static IconData getIcon(String? category, List<String>? tags) {
    final lowerTags = tags?.map((t) => t.toLowerCase()).toList() ?? [];
    final lowerCategory = category?.toLowerCase() ?? '';

    // Category-first: each category gets its home-screen icon by default.
    // Tags only override within specific categories.
    switch (lowerCategory) {
      case 'groceries':
        return Icons.shopping_basket;

      case 'food':
        if (lowerTags.contains('cafe') || lowerTags.contains('coffee')) return Icons.local_cafe;
        if (lowerTags.contains('bakery')) return Icons.bakery_dining;
        if (lowerTags.contains('fast food') || lowerTags.contains('pizza')) return Icons.local_pizza;
        return Icons.fastfood;

      case 'fashion':
        return Icons.shopping_bag;

      case 'health':
        if (lowerTags.contains('pharmacy')) return Icons.local_pharmacy;
        if (lowerTags.contains('dentist') || lowerTags.contains('dental')) return Icons.health_and_safety;
        if (lowerTags.contains('ayurveda')) return Icons.spa;
        if (lowerTags.contains('opticals')) return Icons.visibility;
        if (lowerTags.contains('lab')) return Icons.biotech;
        return Icons.medical_services;

      case 'services':
        if (lowerTags.contains('salon') || lowerTags.contains('haircut')) return Icons.content_cut;
        if (lowerTags.contains('plumbing')) return Icons.plumbing;
        if (lowerTags.contains('cleaning') || lowerTags.contains('laundry')) return Icons.cleaning_services;
        if (lowerTags.contains('electrical')) return Icons.electrical_services;
        return Icons.handyman;

      case 'finance':
        return Icons.account_balance;

      case 'animals':
        return Icons.pets;

      case 'education':
        if (lowerTags.contains('library')) return Icons.local_library;
        if (lowerTags.contains('sports')) return Icons.sports_soccer;
        if (lowerTags.contains('music')) return Icons.music_note;
        return Icons.school;

      case 'religious':
        if (lowerTags.contains('mosque')) return Icons.mosque;
        if (lowerTags.contains('temple')) return Icons.temple_hindu;
        if (lowerTags.contains('church')) return Icons.church;
        return Icons.temple_buddhist;

      case 'entertainment':
        return Icons.local_movies;

      case 'publicservices':
      case 'public services':
        return Icons.account_balance;

      case 'commercial':
        if (lowerTags.contains('warehouse') || lowerTags.contains('wholesale')) return Icons.warehouse;
        if (lowerTags.contains('office') || lowerTags.contains('coworking')) return Icons.business;
        return Icons.storefront;

      case 'hospital':
        return Icons.local_hospital;

      default:
        // No category — infer from tags as last resort
        if (lowerTags.contains('mosque')) return Icons.mosque;
        if (lowerTags.contains('temple')) return Icons.temple_hindu;
        if (lowerTags.contains('church')) return Icons.church;
        if (lowerTags.contains('pharmacy')) return Icons.local_pharmacy;
        if (lowerTags.contains('cafe') || lowerTags.contains('coffee')) return Icons.local_cafe;
        if (lowerTags.contains('bakery')) return Icons.bakery_dining;
        if (lowerTags.contains('salon') || lowerTags.contains('haircut')) return Icons.content_cut;
        return Icons.store;
    }
  }

  static Color getColor(String? category, [List<String>? tags]) {
    String? effectiveCategory = category;

    // Infer category from tags if missing
    if ((effectiveCategory == null || effectiveCategory.isEmpty) && tags != null && tags.isNotEmpty) {
      final lowerTags = tags.map((t) => t.toLowerCase()).toList();
      if (lowerTags.any((t) => ['mosque', 'temple', 'church'].contains(t))) { effectiveCategory = 'religious'; }
      else if (lowerTags.any((t) => ['pharmacy', 'clinic', 'dentist', 'dental', 'ayurveda', 'opticals', 'lab'].contains(t))) { effectiveCategory = 'health'; }
      else if (lowerTags.any((t) => ['cafe', 'coffee', 'bakery', 'fast food', 'pizza'].contains(t))) { effectiveCategory = 'food'; }
      else if (lowerTags.any((t) => ['salon', 'haircut', 'repair', 'mechanic', 'plumbing', 'cleaning', 'laundry', 'electrical'].contains(t))) { effectiveCategory = 'services'; }
      else if (lowerTags.any((t) => ['library', 'sports', 'music'].contains(t))) { effectiveCategory = 'education'; }
      else if (lowerTags.any((t) => ['vegetables', 'fruits', 'organic', 'frozen', 'beverages'].contains(t))) { effectiveCategory = 'groceries'; }
      else if (lowerTags.any((t) => ['warehouse', 'wholesale', 'office', 'coworking'].contains(t))) { effectiveCategory = 'commercial'; }
    }

    if (effectiveCategory == null || effectiveCategory.isEmpty) return const Color(0xFF2962FF);
    switch (effectiveCategory.toLowerCase()) {
      case 'groceries': return Colors.orange;
      case 'food': return Colors.green;
      case 'fashion': return Colors.purple;
      case 'health': return Colors.blue;
      case 'services': return Colors.red;
      case 'finance': return const Color(0xFF1B5E20);
      case 'animals': return const Color(0xFF795548);
      case 'education': return const Color(0xFFFBC02D);
      case 'religious': return const Color(0xFFE65100);
      case 'entertainment': return const Color(0xFFE91E63);
      case 'publicservices':
      case 'public services': return const Color(0xFF607D8B);
      case 'commercial': return const Color(0xFF795548);
      case 'hospital': return const Color(0xFFD32F2F);
      default: return const Color(0xFF2962FF);
    }
  }
}
