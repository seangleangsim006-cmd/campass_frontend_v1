import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_image_url.dart';
import '../../domain/repositories/place_repository.dart';
import '../mock/home_content.dart';

class ApiPlaceRepository implements PlaceRepository {
  ApiPlaceRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<HomeDestination>> loadPlaces({String? query}) async {
    final places = <HomeDestination>[];
    var page = 1;
    var lastPage = 1;

    do {
      final response = await _client.get(
        '/places',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'page': page,
        },
      );
      final data = response['data'];
      if (data is! List) {
        throw const ApiException('The places response is missing its data.');
      }
      places.addAll(
        data.map((value) {
          if (value is! Map) {
            throw const ApiException(
              'The places response contains invalid data.',
            );
          }
          return _parsePlace(Map<String, Object?>.from(value));
        }),
      );

      final meta = response['meta'];
      if (meta is Map && meta['last_page'] is num) {
        lastPage = (meta['last_page'] as num).toInt();
      }
      page++;
    } while (page <= lastPage);

    return places;
  }

  @override
  Future<HomeDestination> loadPlace(String slug) async {
    final response = await _client.get('/places/${Uri.encodeComponent(slug)}');
    final data = response['data'];
    if (data is! Map) {
      throw const ApiException('The place response is missing its data.');
    }
    return _parsePlace(Map<String, Object?>.from(data));
  }

  @override
  Future<Set<String>> loadSavedPlaceSlugs() async {
    if (!_client.isAuthenticated) return {};
    final response = await _client.get('/me/saved-places');
    final data = response['data'];
    if (data is! List) {
      throw const ApiException('The saved places response is invalid.');
    }
    return data
        .whereType<Map>()
        .map((place) => place['slug'])
        .whereType<String>()
        .toSet();
  }

  @override
  Future<void> setPlaceSaved(String slug, {required bool saved}) async {
    if (!_client.isAuthenticated) {
      throw const ApiException('Sign in to save places.');
    }
    final path = '/me/saved-places/${Uri.encodeComponent(slug)}';
    final response = saved
        ? await _client.put(path)
        : await _client.delete(path);
    if (response['saved'] != saved) {
      throw const ApiException('The server did not update the saved place.');
    }
  }

  HomeDestination _parsePlace(Map<String, Object?> data) {
    final place = HomeDestination.fromApiJson(
      data,
      languageCode: _client.languageCode,
      resolveImageUrl: _resolveImage,
    );
    return place;
  }

  String? _resolveImage(String? image) {
    return resolveApiImageUrl(image);
  }
}
