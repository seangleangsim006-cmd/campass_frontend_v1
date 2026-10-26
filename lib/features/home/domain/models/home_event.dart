import '../../../../core/network/api_image_url.dart';

class HomeEvent {
  const HomeEvent({
    required this.title,
    required this.location,
    required this.description,
    required this.searchTerm,
    this.nextStartsOn,
    this.isOngoing,
    this.imageUrl,
  });

  final String title;
  final String location;
  final String description;
  final String searchTerm;
  final String? nextStartsOn;
  final bool? isOngoing;
  final String? imageUrl;

  factory HomeEvent.fromApiJson(
    Map<String, Object?> json, {
    String languageCode = 'en',
  }) {
    return HomeEvent(
      title: _readText(json['title'] ?? json['name'], languageCode),
      location: _readText(
        json['location'] ??
            json['venue'] ??
            json['place'] ??
            (json['destination'] is Map
                ? (json['destination'] as Map)['name']
                : null),
        languageCode,
      ),
      description: _readText(
        json['description'] ?? json['summary'],
        languageCode,
      ),
      searchTerm: _readText(
        json['search_term'] ??
            (json['place'] is Map ? (json['place'] as Map)['name'] : null) ??
            (json['destination'] is Map
                ? (json['destination'] as Map)['name']
                : null) ??
            json['title'] ??
            json['name'],
        languageCode,
      ),
      nextStartsOn: _readOptionalText(json['next_starts_on']),
      isOngoing: json['is_ongoing'] is bool ? json['is_ongoing'] as bool : null,
      imageUrl: _readImageUrl(json),
    );
  }
}

String? _readImageUrl(Map<String, Object?> json) {
  for (final key in [
    'cover_url',
    'image_url',
    'cover_image_url',
    'thumbnail_url',
    'image',
  ]) {
    final imageUrl = _readImagePath(json[key]);
    if (imageUrl != null) return resolveApiImageUrl(imageUrl);
  }

  for (final key in ['gallery', 'images', 'photos']) {
    final images = json[key];
    if (images is! List) continue;
    for (final image in images) {
      final imageUrl = _readImagePath(image);
      if (imageUrl != null) return resolveApiImageUrl(imageUrl);
    }
  }
  return null;
}

String? _readImagePath(Object? value) {
  if (value is String) {
    final path = value.trim();
    return path.isEmpty ? null : path;
  }
  if (value is Map) {
    for (final key in ['url', 'original_url', 'path', 'src']) {
      final path = _readImagePath(value[key]);
      if (path != null) return path;
    }
  }
  return null;
}

String? _readOptionalText(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

String _readText(Object? value, String languageCode) {
  if (value is String) return value;
  if (value is Map) {
    final text =
        value[languageCode] ??
        value['en'] ??
        value['name'] ??
        value['title'] ??
        value.values.firstOrNull;
    return text is String ? text : '';
  }
  return '';
}
