import 'package:flutter/material.dart';

class OnboardingContent {
  const OnboardingContent({
    required this.title,
    required this.description,
    required this.imageAsset,
    this.category,
    this.categoryIcon,
  });

  final String title;
  final String description;
  final String imageAsset;
  final String? category;
  final IconData? categoryIcon;

  static const pages = [
    OnboardingContent(
      title: 'Discover the Magical Cambodia',
      description:
          'Ancient temples, pristine beaches, rich culture and unforgettable '
          'experiences await you.',
      imageAsset: 'https://blog.bangkokair.com/wp-content/uploads/2024/07/visiting-angkor-wat-guide.jpg',
    ),
    OnboardingContent(
      title: 'Explore Breathtaking Places',
      description:
          'From Angkor Wat to Koh Rong, find your next adventure in Cambodia.',
      imageAsset: 'https://d122axpxm39woi.cloudfront.net/images/destinations/origin/684161671e05d.jpg',
      category: 'Beaches',
      categoryIcon: Icons.beach_access,
    ),
    OnboardingContent(
      title: 'Experience Local Culture',
      description:
          "Meet friendly people, taste authentic food and immerse yourself "
          "in Cambodia's unique heritage.",
      imageAsset: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDziPoISUEytGLSTDelKr5EWm8-XP50NA5bqVpromsSC61d-i1MW_F4to&s=10',
      category: 'Culture',
      categoryIcon: Icons.diversity_3,
    ),
  ];
}
