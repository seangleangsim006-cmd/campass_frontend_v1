class Destination {
  const Destination({
    required this.slug,
    required this.name,
    this.region = '',
    this.description = '',
    this.imageUrl,
    this.isPremium = false,
    this.bestTimeToVisit,
    this.howToGetThere,
    this.entranceFees,
    this.accessibility,
    this.travelTips,
    this.galleryUrls = const [],
  });

  final String slug;
  final String name;
  final String region;
  final String description;
  final String? imageUrl;
  final bool isPremium;
  final String? bestTimeToVisit;
  final String? howToGetThere;
  final String? entranceFees;
  final String? accessibility;
  final String? travelTips;
  final List<String> galleryUrls;
}

class DestinationPlace {
  const DestinationPlace({
    required this.slug,
    required this.name,
    this.category = '',
    this.imageUrl,
    this.rating,
    this.distanceKm,
    this.isFeatured = false,
  });

  final String slug;
  final String name;
  final String category;
  final String? imageUrl;
  final double? rating;
  final double? distanceKm;
  final bool isFeatured;
}

class DestinationDetails extends Destination {
  const DestinationDetails({
    required super.slug,
    required super.name,
    super.region,
    super.description,
    super.imageUrl,
    super.isPremium,
    super.bestTimeToVisit,
    super.howToGetThere,
    super.entranceFees,
    super.accessibility,
    super.travelTips,
    super.galleryUrls,
    required this.places,
  });

  final List<DestinationPlace> places;
}
