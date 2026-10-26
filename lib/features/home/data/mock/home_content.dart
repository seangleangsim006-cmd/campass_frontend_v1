import 'package:flutter/material.dart';

class InterestCategory {
  const InterestCategory({
    required this.title,
    required this.filterCategory,
    required this.icon,
    required this.subtitle,
    required this.imageAsset,
  });

  final String title;
  final String filterCategory;
  final IconData icon;
  final String subtitle;
  final String imageAsset;
}

class HomeDestination {
  const HomeDestination({
    required this.name,
    this.slug,
    required this.location,
    required this.province,
    required this.category,
    this.categorySlug,
    required this.description,
    required this.rating,
    required this.icon,
    required this.accent,
    required this.reviewCount,
    required this.tags,
    required this.history,
    required this.visitorExperience,
    required this.openingHours,
    required this.ticketInfo,
    required this.bestTimeToVisit,
    required this.visitDuration,
    required this.dressCode,
    required this.address,
    required this.mapQuery,
    required this.latitude,
    required this.longitude,
    this.imageAsset,
    this.galleryAssets = const [],
  });

  final String name;
  final String? slug;
  final String location;
  final String province;
  final String category;
  final String? categorySlug;
  final String description;
  final String rating;
  final IconData icon;
  final Color accent;
  final String? imageAsset;
  final int reviewCount;
  final List<String> tags;
  final String history;
  final String visitorExperience;
  final String openingHours;
  final String ticketInfo;
  final String bestTimeToVisit;
  final String visitDuration;
  final String dressCode;
  final String address;
  final String mapQuery;
  final double latitude;
  final double longitude;
  final List<String> galleryAssets;

  List<String> get photos {
    if (galleryAssets.isNotEmpty) return galleryAssets;
    return imageAsset == null ? const [] : [imageAsset!];
  }

  String get key => slug ?? name;

  factory HomeDestination.fromApiJson(
    Map<String, Object?> json, {
    String languageCode = 'en',
    String? Function(String?)? resolveImageUrl,
  }) {
    final categoryValue = json['category'];
    final regionValue = json['region'] ?? json['province'] ?? json['location'];
    final category = _localizedText(
      categoryValue is Map ? categoryValue['name'] : categoryValue,
      languageCode,
    );
    final region = _localizedText(
      regionValue is Map ? regionValue['name'] : regionValue,
      languageCode,
    );
    final name = _localizedText(json['name'], languageCode);
    final primaryImage = _imageUrl(json);
    final gallery = _imageUrls(
      json,
    ).map((url) => resolveImageUrl?.call(url) ?? url).toList();
    final image =
        resolveImageUrl?.call(primaryImage) ??
        primaryImage ??
        gallery.firstOrNull;
    final tagsValue = json['tags'];
    final tags = tagsValue is List
        ? tagsValue
              .map((tag) => _localizedText(tag, languageCode))
              .where((tag) => tag.isNotEmpty)
              .toList()
        : <String>[];
    final story = _firstContentText(json['stories'], languageCode);
    final tips = _contentListText(json['tips'], languageCode);
    final categoryLabel = category.isEmpty ? 'Places' : category;
    final coordinates = json['coordinates'];
    final coordinateMap = coordinates is Map ? coordinates : const {};
    final latitude =
        _number(json['latitude']) ?? _number(coordinateMap['latitude']) ?? 0;
    final longitude =
        _number(json['longitude']) ?? _number(coordinateMap['longitude']) ?? 0;

    return HomeDestination(
      name: name.isEmpty ? 'Untitled place' : name,
      slug: json['slug'] is String ? json['slug'] as String : null,
      location: region.isEmpty ? 'Cambodia' : region,
      province: region.isEmpty ? 'Cambodia' : region,
      category: categoryLabel,
      categorySlug: categoryValue is Map && categoryValue['slug'] is String
          ? categoryValue['slug'] as String
          : category.toLowerCase(),
      description: _localizedText(
        json['short_description'] ?? json['description'] ?? json['summary'],
        languageCode,
      ),
      rating:
          (_number(
                    json['rating'] ??
                        json['average_rating'] ??
                        json['rating_avg'],
                  ) ??
                  0)
              .toStringAsFixed(1),
      icon: _categoryIcon(categoryLabel),
      accent: _categoryColor(categoryLabel),
      imageAsset: image,
      reviewCount: (_number(json['reviews_count'] ?? json['review_count']) ?? 0)
          .toInt(),
      tags: tags,
      history: _localizedText(
        json['history'] ?? json['historical_background'] ?? story,
        languageCode,
      ),
      visitorExperience: _localizedText(
        json['visitor_experience'] ?? json['visitor_tips'] ?? tips,
        languageCode,
      ),
      openingHours: _localizedText(json['opening_hours'], languageCode),
      ticketInfo: _localizedText(
        json['ticket_info'] ?? json['entrance_fee'],
        languageCode,
      ),
      bestTimeToVisit: _localizedText(json['best_time_to_visit'], languageCode),
      visitDuration: _localizedText(
        json['visit_duration'] ?? json['recommended_duration'],
        languageCode,
      ),
      dressCode: _localizedText(json['dress_code'], languageCode),
      address: _localizedText(json['address'], languageCode),
      mapQuery: '$name, ${region.isEmpty ? 'Cambodia' : region}, Cambodia',
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      galleryAssets: gallery.isEmpty && image != null ? [image] : gallery,
    );
  }
}

String _localizedText(Object? value, String languageCode) {
  if (value is String) return value;
  if (value is num) return value.toString();
  if (value is Map) {
    final localized =
        value[languageCode] ??
        value['en'] ??
        value['name'] ??
        value['title'] ??
        value['label'] ??
        value.values.firstOrNull;
    return localized is String ? localized : '';
  }
  return '';
}

String _firstContentText(Object? value, String languageCode) {
  if (value is! List || value.isEmpty) return '';
  final first = value.first;
  if (first is Map) {
    return _localizedText(
      first['content'] ??
          first['body'] ??
          first['description'] ??
          first['title'],
      languageCode,
    );
  }
  return _localizedText(first, languageCode);
}

String _contentListText(Object? value, String languageCode) {
  if (value is! List) return '';
  return value
      .map((item) {
        if (item is Map) {
          return _localizedText(
            item['content'] ??
                item['body'] ??
                item['description'] ??
                item['text'],
            languageCode,
          );
        }
        return _localizedText(item, languageCode);
      })
      .where((text) => text.isNotEmpty)
      .join('\n');
}

double? _number(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _imageUrl(Map<String, Object?> json) {
  for (final key in [
    'image_url',
    'cover_image_url',
    'thumbnail_url',
    'image',
  ]) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value is Map) {
      final url = value['url'] ?? value['original_url'];
      if (url is String && url.isNotEmpty) return url;
    }
  }
  return null;
}

List<String> _imageUrls(Map<String, Object?> json) {
  final values = json['images'] ?? json['photos'] ?? json['gallery'];
  if (values is! List) return const [];
  return values
      .map((value) {
        if (value is String) return value;
        if (value is Map) {
          final url = value['url'] ?? value['original_url'];
          return url is String ? url : '';
        }
        return '';
      })
      .where((url) => url.isNotEmpty)
      .toList();
}

IconData _categoryIcon(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('temple')) return Icons.temple_buddhist;
  if (normalized.contains('beach') || normalized.contains('island')) {
    return Icons.beach_access;
  }
  if (normalized.contains('mountain') || normalized.contains('nature')) {
    return Icons.forest;
  }
  return Icons.location_on_outlined;
}

Color _categoryColor(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('temple')) return const Color(0xFF795E3D);
  if (normalized.contains('beach') || normalized.contains('island')) {
    return const Color(0xFF248B9A);
  }
  if (normalized.contains('mountain') || normalized.contains('nature')) {
    return const Color(0xFF426A4D);
  }
  return const Color(0xFF92704B);
}

const homeCategories = [
  InterestCategory(
    title: 'Temples',
    filterCategory: 'Temples',
    icon: Icons.temple_buddhist_outlined,
    subtitle: '120+ sacred sites',
    imageAsset: 'assets/image/angkor_wat_sunset.png',
  ),
  InterestCategory(
    title: 'Beaches',
    filterCategory: 'Beaches',
    icon: Icons.waves,
    subtitle: 'Secret lagoons',
    imageAsset: 'assets/image/koh_rong_boats.jpg',
  ),
  InterestCategory(
    title: 'Mountains',
    filterCategory: 'Mountains',
    icon: Icons.landscape_outlined,
    subtitle: 'Cloud forests',
    imageAsset: 'assets/image/cardamom_mountains.jpg',
  ),
  InterestCategory(
    title: 'Culture',
    filterCategory: 'Culture',
    icon: Icons.account_balance_outlined,
    subtitle: 'Palaces & bites',
    imageAsset: 'assets/image/royal_palace_phnom_penh.jpg',
  ),
];

const homeDestinations = [
  HomeDestination(
    name: 'Angkor Wat',
    slug: 'angkor-wat',
    location: 'Siem Reap',
    province: 'Siem Reap',
    category: 'Temples',
    description: 'The world’s largest temple complex',
    rating: '4.9',
    icon: Icons.temple_buddhist,
    imageAsset: 'assets/image/angkor_wat_sunset.png',
    accent: Color(0xFF4B5854),
    reviewCount: 1248,
    tags: ['Temple', 'Historical', 'Cultural'],
    history:
        'Built in the 12th century under King Suryavarman II, Angkor Wat began '
        'as a Hindu temple dedicated to Vishnu and later became an important '
        'Buddhist sanctuary. Its architecture and bas-reliefs reflect the '
        'artistry and beliefs of the Khmer Empire.',
    visitorExperience:
        'Walk through vast galleries, study intricate bas-reliefs, and watch '
        'the sunrise illuminate the temple towers and reflecting pools.',
    openingHours: 'Typically 5:00 AM–5:30 PM; hours may vary by area.',
    ticketInfo:
        'An Angkor Pass is required. Check the official ticket office for '
        'current prices and pass options.',
    bestTimeToVisit: 'Early morning; November to February is generally cooler.',
    visitDuration: 'Allow 3–5 hours for the main temple.',
    dressCode:
        'Wear modest clothing covering shoulders and knees. Follow posted '
        'temple and photography guidance.',
    address: 'Angkor Archaeological Park, Siem Reap, Cambodia',
    mapQuery: 'Angkor Wat, Siem Reap, Cambodia',
    latitude: 13.4125,
    longitude: 103.8670,
    galleryAssets: ['assets/image/angkor_wat_sunset.png'],
  ),
  HomeDestination(
    name: 'Koh Ker',
    location: 'Preah Vihear',
    province: 'Preah Vihear',
    category: 'Temples',
    description: 'An ancient pyramid temple in the forest',
    rating: '4.7',
    icon: Icons.temple_buddhist,
    accent: Color(0xFF795E3D),
    reviewCount: 286,
    tags: ['Temple', 'Historical', 'Archaeological'],
    history:
        'Koh Ker served as a Khmer capital in the 10th century. The site is '
        'known for its stepped pyramid and temples scattered through forest.',
    visitorExperience:
        'Explore the pyramid temple, quieter forest ruins, and the wider '
        'archaeological landscape at a relaxed pace.',
    openingHours: 'Daylight visiting hours; confirm locally before travel.',
    ticketInfo:
        'A site ticket may be required; confirm current access locally.',
    bestTimeToVisit: 'Early morning during the drier, cooler months.',
    visitDuration: 'Allow 2–4 hours for the main site.',
    dressCode:
        'Wear comfortable walking shoes and modest, respectful clothing.',
    address: 'Koh Ker Archaeological Site, Preah Vihear, Cambodia',
    mapQuery: 'Koh Ker, Preah Vihear, Cambodia',
    latitude: 13.7846,
    longitude: 104.5370,
  ),
  HomeDestination(
    name: 'Koh Rong',
    location: 'Sihanoukville',
    province: 'Sihanoukville',
    category: 'Beaches',
    description: 'Turquoise waters and quiet shores',
    rating: '4.8',
    icon: Icons.beach_access,
    accent: Color(0xFF248B9A),
    reviewCount: 934,
    tags: ['Beach', 'Island', 'Nature'],
    history:
        'Koh Rong is a Cambodian island known for its coastal communities, '
        'clear-water bays, and tropical forest interior.',
    visitorExperience:
        'Enjoy beaches and swimming, take a boat trip, or explore island '
        'trails. Check sea conditions before water activities.',
    openingHours: 'Open daily; boat schedules vary by season and operator.',
    ticketInfo:
        'No general island admission ticket; transport and activities vary.',
    bestTimeToVisit: 'November to May is typically drier.',
    visitDuration: 'Plan 1–3 days depending on activities.',
    dressCode:
        'Beachwear is suitable at the shore; dress modestly in villages.',
    address: 'Koh Rong, Sihanoukville, Cambodia',
    mapQuery: 'Koh Rong, Cambodia',
    latitude: 10.7060,
    longitude: 103.2300,
    galleryAssets: ['assets/image/koh_rong_boats.jpg'],
  ),
  HomeDestination(
    name: 'Cardamom Mountains',
    location: 'Koh Kong',
    province: 'Koh Kong',
    category: 'Mountains',
    description: 'Rainforest trails and wild landscapes',
    rating: '4.7',
    icon: Icons.forest,
    accent: Color(0xFF426A4D),
    reviewCount: 412,
    tags: ['Mountains', 'Nature', 'Adventure'],
    history:
        'The Cardamom Mountains form one of Southeast Asia’s largest '
        'rainforest landscapes and support a rich range of wildlife and '
        'communities.',
    visitorExperience:
        'Discover forest trails, rivers, waterfalls, and community-based '
        'ecotourism with a knowledgeable local guide.',
    openingHours: 'Access depends on the trail, lodge, and local guide.',
    ticketInfo: 'Fees and permits vary by activity and protected area.',
    bestTimeToVisit: 'November to April is generally drier for trekking.',
    visitDuration: 'Plan at least a full day; multi-day trips are available.',
    dressCode: 'Wear sturdy shoes, lightweight layers, and rain protection.',
    address: 'Cardamom Mountains, Southwest Cambodia',
    mapQuery: 'Cardamom Mountains, Cambodia',
    latitude: 11.7500,
    longitude: 103.2500,
    galleryAssets: ['assets/image/cardamom_mountains.jpg'],
  ),
  HomeDestination(
    name: 'Phnom Penh',
    location: 'Phnom Penh',
    province: 'Phnom Penh',
    category: 'Culture',
    description: 'Riverside energy and Khmer heritage',
    rating: '4.6',
    icon: Icons.location_city,
    accent: Color(0xFF92704B),
    reviewCount: 1672,
    tags: ['Culture', 'City', 'Heritage'],
    history:
        'Cambodia’s capital sits at the meeting of the Mekong and Tonle Sap '
        'rivers, with layers of royal, colonial, and contemporary history.',
    visitorExperience:
        'Visit museums and historic landmarks, explore markets, and enjoy '
        'Khmer food along the riverside.',
    openingHours: 'City attractions have different hours; check each venue.',
    ticketInfo: 'Admission fees vary by attraction.',
    bestTimeToVisit: 'November to February is generally cooler for walking.',
    visitDuration: 'Allow 1–3 days to explore the city.',
    dressCode: 'Dress modestly at religious sites and royal landmarks.',
    address: 'Phnom Penh, Cambodia',
    mapQuery: 'Phnom Penh, Cambodia',
    latitude: 11.5564,
    longitude: 104.9282,
    galleryAssets: ['assets/image/royal_palace_phnom_penh.jpg'],
  ),
];
