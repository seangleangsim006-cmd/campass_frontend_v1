import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_image_url.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<UserProfile> loadProfile() async {
    final responses = await Future.wait([
      _client.get('/me'),
      _client.get('/me/visited-places'),
      _client.get('/me/saved-places'),
      _client.get('/me/trips'),
    ]);
    final response = responses[0];
    final data = response['data'];
    if (data is! Map) {
      throw const ApiException('The profile response is missing its data.');
    }
    final visitedPlaces = _readList(responses[1], 'visited places');
    final savedPlaces = _readList(responses[2], 'saved places');
    final trips = _readList(responses[3], 'trips');
    return _readProfile(
      Map<String, Object?>.from(data),
      visitedPlaces: visitedPlaces,
      savedPlaces: savedPlaces,
      trips: trips,
    );
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await _client.patch(
      '/me',
      data: {'name': profile.fullName},
    );
    final data = response['data'];
    if (data is! Map) {
      throw const ApiException('The profile update response is invalid.');
    }
    return _readProfile(Map<String, Object?>.from(data)).copyWith(
      visitedPlaceCount: profile.visitedPlaceCount,
      savedPlaceCount: profile.savedPlaceCount,
      plannedTripCount: profile.plannedTripCount,
      recentPlaces: profile.recentPlaces,
    );
  }

  UserProfile _readProfile(
    Map<String, Object?> json, {
    List<Map<String, Object?>> visitedPlaces = const [],
    List<Map<String, Object?>> savedPlaces = const [],
    List<Map<String, Object?>> trips = const [],
  }) {
    final name = json['name'];
    final email = json['email'];
    final id = json['id'];
    if (name is! String || email is! String || id == null) {
      throw const ApiException('The profile response is incomplete.');
    }
    return UserProfile(
      id: id.toString(),
      fullName: name,
      email: email,
      photoUrl: resolveApiImageUrl(
        _readText(json['avatar'] ?? json['avatar_url']),
      ),
      visitedPlaceCount: visitedPlaces.length,
      savedPlaceCount: savedPlaces.length,
      plannedTripCount: trips.length,
      recentPlaces: visitedPlaces.take(5).map(_readPlace).toList(),
    );
  }

  List<Map<String, Object?>> _readList(
    Map<String, Object?> response,
    String label,
  ) {
    final data = response['data'];
    if (data is! List) {
      throw ApiException('The $label response is missing its data.');
    }
    return data.map((item) {
      if (item is! Map) {
        throw ApiException('The $label response contains invalid data.');
      }
      return Map<String, Object?>.from(item);
    }).toList();
  }

  ProfilePlace _readPlace(Map<String, Object?> json) {
    final destination = json['destination'];
    final image = json['cover_url'] ?? json['image_url'];
    final gallery = json['gallery'];
    final galleryImage = gallery is List && gallery.isNotEmpty
        ? gallery.first
        : null;
    return ProfilePlace(
      slug: json['slug'] is String ? json['slug'] as String : '',
      name: _readText(json['name']),
      location: destination is Map ? _readText(destination['name']) : '',
      imageUrl: resolveApiImageUrl(
        image is String ? image : _readText(galleryImage),
      ),
    );
  }

  String _readText(Object? value) => value is String ? value : '';
}
