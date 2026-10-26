import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_image_url.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/destination.dart';
import '../../domain/repositories/destination_repository.dart';

class ApiDestinationRepository implements DestinationRepository {
  ApiDestinationRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Destination>> loadDestinations() async {
    final destinations = <Destination>[];
    var page = 1;
    var lastPage = 1;

    do {
      final response = await _client.get(
        '/destinations',
        queryParameters: {'page': page},
      );
      final data = response['data'];
      if (data is! List) {
        throw const ApiException(
          'The destinations response is missing its data.',
        );
      }
      destinations.addAll(
        data.map((value) {
          if (value is! Map) {
            throw const ApiException(
              'The destinations response contains invalid data.',
            );
          }
          return _parseDestination(Map<String, Object?>.from(value));
        }),
      );

      final meta = response['meta'];
      if (meta is Map && meta['last_page'] is num) {
        lastPage = (meta['last_page'] as num).toInt();
      }
      page++;
    } while (page <= lastPage);

    return destinations;
  }

  @override
  Future<DestinationDetails> loadDestination(String slug) async {
    final response = await _client.get(
      '/destinations/${Uri.encodeComponent(slug)}',
    );
    final data = response['data'];
    if (data is! Map) {
      throw const ApiException('The destination response is missing its data.');
    }
    final json = Map<String, Object?>.from(data);
    final placesValue = json['places'];
    if (placesValue is! List) {
      throw const ApiException(
        'The destination response is missing its places.',
      );
    }

    final destination = _parseDestination(json);
    return DestinationDetails(
      slug: destination.slug,
      name: destination.name,
      region: destination.region,
      description: destination.description,
      imageUrl: destination.imageUrl,
      isPremium: destination.isPremium,
      bestTimeToVisit: destination.bestTimeToVisit,
      howToGetThere: destination.howToGetThere,
      entranceFees: destination.entranceFees,
      accessibility: destination.accessibility,
      travelTips: destination.travelTips,
      galleryUrls: destination.galleryUrls,
      places: placesValue.map((value) {
        if (value is! Map) {
          throw const ApiException(
            'The destination response contains invalid places.',
          );
        }
        final place = Map<String, Object?>.from(value);
        return DestinationPlace(
          slug: _string(place['slug']),
          name: _localizedText(place['name'], _client.languageCode),
          category: _localizedText(
            place['category'] is Map
                ? (place['category'] as Map)['name']
                : place['category'],
            _client.languageCode,
          ),
          imageUrl: resolveApiImageUrl(_imageUrl(place)),
          rating: _number(
            place['rating'] ?? place['average_rating'] ?? place['rating_avg'],
          ),
          distanceKm: _number(place['distance_km']),
          isFeatured: place['is_featured'] == true,
        );
      }).toList(),
    );
  }

  Destination _parseDestination(Map<String, Object?> json) {
    final slug = _string(json['slug']);
    final name = _localizedText(json['name'], _client.languageCode);
    if (slug.isEmpty || name.isEmpty) {
      throw const ApiException('A destination is missing its slug or name.');
    }
    final region = json['region'];
    final galleryUrls = _imageUrls(
      json,
    ).map(resolveApiImageUrl).whereType<String>().toList();
    return Destination(
      slug: slug,
      name: name,
      region: region is Map
          ? _localizedText(region['name'], _client.languageCode)
          : _localizedText(region, _client.languageCode),
      description: _localizedText(
        json['short_description'] ?? json['description'] ?? json['summary'],
        _client.languageCode,
      ),
      imageUrl: resolveApiImageUrl(_imageUrl(json)) ?? galleryUrls.firstOrNull,
      isPremium: json['is_premium'] == true,
      bestTimeToVisit: _optionalText(json['best_time_to_visit']),
      howToGetThere: _optionalText(json['how_to_get_there']),
      entranceFees: _optionalText(
        json['entrance_fees'] ?? json['entrance_fee'] ?? json['ticket_info'],
      ),
      accessibility: _optionalText(json['accessibility']),
      travelTips: _optionalText(json['travel_tips'] ?? json['visitor_tips']),
      galleryUrls: galleryUrls,
    );
  }

  String? _imageUrl(Map<String, Object?> json) {
    for (final key in [
      'cover_url',
      'image_url',
      'imageUrl',
      'cover_image_url',
      'thumbnail_url',
      'photo_url',
      'image',
    ]) {
      final url = _imagePath(json[key]);
      if (url != null) return url;
    }
    for (final key in ['images', 'photos', 'gallery']) {
      final images = json[key];
      if (images is! List) continue;
      for (final image in images) {
        final url = _imagePath(image);
        if (url != null) return url;
      }
    }
    return null;
  }

  List<String> _imageUrls(Map<String, Object?> json) {
    final values = json['images'] ?? json['photos'] ?? json['gallery'];
    if (values is! List) return const [];
    return values.map(_imagePath).whereType<String>().toList();
  }

  String? _imagePath(Object? value) {
    if (value is String) {
      final path = value.trim();
      return path.isEmpty ? null : path;
    }
    if (value is Map) {
      for (final key in ['url', 'original_url', 'path', 'src', 'image_url']) {
        final path = _imagePath(value[key]);
        if (path != null) return path;
      }
    }
    return null;
  }

  String? _optionalText(Object? value) {
    final text = _localizedText(value, _client.languageCode).trim();
    return text.isEmpty ? null : text;
  }

  double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _string(Object? value) => value is String ? value : '';

  String _localizedText(Object? value, String languageCode) {
    if (value is String) return value;
    if (value is Map) {
      final localized =
          value[languageCode] ?? value['en'] ?? value['name'] ?? value['title'];
      return localized is String ? localized : '';
    }
    return '';
  }
}
