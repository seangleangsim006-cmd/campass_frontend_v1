import 'package:flutter_test/flutter_test.dart';
import 'package:user_frontend/core/network/api_client.dart';
import 'package:user_frontend/core/network/api_image_url.dart';
import 'package:user_frontend/core/network/token_store.dart';
import 'package:user_frontend/features/auth/data/repositories/api_auth_repository.dart';
import 'package:user_frontend/features/home/data/repositories/api_place_repository.dart';
import 'package:user_frontend/features/home/data/repositories/api_destination_repository.dart';
import 'package:user_frontend/features/home/data/repositories/api_home_content_repository.dart';
import 'package:user_frontend/features/home/domain/models/home_event.dart';
import 'package:user_frontend/features/profile/data/repositories/api_profile_repository.dart';

void main() {
  test('resolves Laravel storage image URLs for mobile API host', () {
    expect(
      resolveApiImageUrl(
        'http://127.0.0.1:8000/storage/1/E5bhDZ3te9ctCjIVvqVMayM4vgWCsRkfcS07L8XX.ico',
      ),
      'http://10.0.2.2:8000/storage/1/E5bhDZ3te9ctCjIVvqVMayM4vgWCsRkfcS07L8XX.ico',
    );
    expect(
      resolveApiImageUrl('/storage/1/example.png'),
      'http://10.0.2.2:8000/storage/1/example.png',
    );
    expect(
      resolveApiImageUrl('https://cdn.example.test/storage/example.png'),
      'http://10.0.2.2:8000/storage/example.png',
    );
  });

  test('loads localized destinations and their places from the API', () async {
    final client = _FakeApiClient([
      {
        'data': [
          {
            'slug': 'siem-reap',
            'name': {'en': 'Siem Reap', 'km': 'សៀមរាប'},
            'region': {'slug': 'northwest', 'name': 'Northwest Cambodia'},
            'is_premium': true,
          },
        ],
        'meta': {'last_page': 1},
      },
      {
        'data': {
          'slug': 'siem-reap',
          'name': {'en': 'Siem Reap', 'km': 'សៀមរាប'},
          'region': {'slug': 'northwest', 'name': 'Northwest Cambodia'},
          'best_time_to_visit': {
            'en': 'November to February',
            'km': 'វិច្ឆិកា ដល់ កុម្ភៈ',
          },
          'how_to_get_there': 'Road access',
          'entrance_fee': 'Check current rates',
          'accessibility': 'Ask venue',
          'travel_tips': 'Bring water',
          'images': [
            {'url': '/storage/destinations/siem-reap.jpg'},
          ],
          'places': [
            {
              'slug': 'angkor-wat',
              'name': {'en': 'Angkor Wat', 'km': 'អង្គរវត្ត'},
              'category': {'name': 'Temple'},
              'image_url': '/storage/places/angkor-wat.jpg',
              'rating': 4.9,
              'distance_km': 2.4,
              'is_featured': true,
            },
          ],
          'emergency_contacts': [],
        },
      },
    ])..setLanguage('km');
    final repository = ApiDestinationRepository(client);

    final destinations = await repository.loadDestinations();
    final detail = await repository.loadDestination('siem-reap');

    expect(destinations.single.name, 'សៀមរាប');
    expect(destinations.single.region, 'Northwest Cambodia');
    expect(destinations.single.isPremium, isTrue);
    expect(detail.places.single.slug, 'angkor-wat');
    expect(detail.places.single.name, 'អង្គរវត្ត');
    expect(detail.places.single.category, 'Temple');
    expect(detail.places.single.rating, 4.9);
    expect(detail.places.single.distanceKm, 2.4);
    expect(detail.places.single.isFeatured, isTrue);
    expect(
      detail.places.single.imageUrl,
      endsWith('/storage/places/angkor-wat.jpg'),
    );
    expect(detail.bestTimeToVisit, 'វិច្ឆិកា ដល់ កុម្ភៈ');
    expect(detail.howToGetThere, 'Road access');
    expect(detail.entranceFees, 'Check current rates');
    expect(detail.accessibility, 'Ask venue');
    expect(detail.travelTips, 'Bring water');
    expect(
      detail.galleryUrls.single,
      endsWith('/storage/destinations/siem-reap.jpg'),
    );
    expect(client.requests.map((request) => request.path), [
      '/destinations',
      '/destinations/siem-reap',
    ]);
  });

  test('loads place images from alternate API image fields', () async {
    final repository = ApiDestinationRepository(
      _FakeApiClient([
        {
          'data': {
            'slug': 'siem-reap',
            'name': 'Siem Reap',
            'places': [
              {
                'slug': 'angkor-wat',
                'name': 'Angkor Wat',
                'imageUrl': {'src': '/storage/places/angkor-wat.jpg'},
              },
              {
                'slug': 'bayon',
                'name': 'Bayon',
                'photos': [
                  {'path': '/storage/places/bayon.jpg'},
                ],
              },
            ],
          },
        },
      ]),
    );

    final destination = await repository.loadDestination('siem-reap');

    expect(destination.places.map((place) => place.imageUrl), [
      endsWith('/storage/places/angkor-wat.jpg'),
      endsWith('/storage/places/bayon.jpg'),
    ]);
  });

  test('loads localized event and phrase content from the API', () async {
    final client = _FakeApiClient([
      {
        'data': [
          {
            'name': {'en': 'Khmer New Year', 'km': 'ចូលឆ្នាំខ្មែរ'},
            'destination': {
              'name': {'en': 'Siem Reap', 'km': 'សៀមរាប'},
            },
            'description': 'Annual celebration',
            'next_starts_on': '2026-11-09',
            'is_ongoing': false,
            'cover_url': '/storage/events/khmer-new-year.jpg',
            'gallery': ['/storage/events/khmer-new-year-gallery.jpg'],
          },
        ],
      },
      {
        'data': [
          {
            'khmer_text': 'អរគុណ',
            'meaning': {'en': 'Thank you', 'km': 'អរគុណ'},
            'romanization': 'aw koun',
            'phonetic': 'aw-KOON',
            'category': {'slug': 'greetings'},
          },
        ],
      },
      {
        'data': [
          {
            'khmer_text': 'អរុណសួស្តី',
            'meaning': 'Good morning',
            'category': {'slug': 'greetings'},
          },
        ],
      },
      {
        'data': [
          {'khmer_text': 'ជួយផង', 'meaning': 'Help', 'is_emergency': true},
        ],
      },
    ])..setLanguage('km');
    final repository = ApiHomeContentRepository(client);

    final events = await repository.loadEvents();
    final phrases = await repository.loadPhrases();
    final greetings = await repository.loadPhrases(categorySlug: 'greetings');
    final emergency = await repository.loadPhrases(categorySlug: 'emergency');

    expect(events.single.title, 'ចូលឆ្នាំខ្មែរ');
    expect(events.single.location, 'សៀមរាប');
    expect(events.single.searchTerm, 'សៀមរាប');
    expect(events.single.nextStartsOn, '2026-11-09');
    expect(events.single.isOngoing, isFalse);
    expect(
      events.single.imageUrl,
      endsWith('/storage/events/khmer-new-year.jpg'),
    );
    expect(phrases.single.meaning, 'អរគុណ');
    expect(phrases.single.khmerText, 'អរគុណ');
    expect(phrases.single.categorySlug, 'greetings');
    expect(greetings.single.categorySlug, 'greetings');
    expect(emergency.single.meaning, 'Help');
    expect(client.requests.map((request) => request.path), [
      '/events',
      '/phrases',
      '/phrases',
      '/phrases',
    ]);
    expect(client.requests[2].queryParameters, {'category': 'greetings'});
    expect(client.requests[3].queryParameters, {'emergency': 1});
  });

  test('event image falls back to gallery when cover URL is blank', () async {
    final event = HomeEvent.fromApiJson({
      'name': 'Second event',
      'cover_url': '',
      'gallery': [
        {'url': '/storage/events/second-event.jpg'},
      ],
    });

    expect(event.imageUrl, endsWith('/storage/events/second-event.jpg'));
  });

  test('loads paginated places and maps localized API fields', () async {
    final client = _FakeApiClient([
      {
        'data': [
          _placeJson(
            slug: 'angkor-wat',
            name: {'en': 'Angkor Wat', 'km': 'អង្គរវត្ត'},
          ),
        ],
        'meta': {'last_page': 2},
      },
      {
        'data': [_placeJson(slug: 'koh-rong', name: 'Koh Rong')],
        'meta': {'last_page': 2},
      },
    ])..setLanguage('km');
    final repository = ApiPlaceRepository(client);

    final places = await repository.loadPlaces();

    expect(places.map((place) => place.key), ['angkor-wat', 'koh-rong']);
    expect(places.first.name, 'អង្គរវត្ត');
    expect(places.first.categorySlug, 'temple');
    expect(places.first.latitude, 13.4);
    expect(client.requests.map((request) => request.queryParameters?['page']), [
      1,
      2,
    ]);
  });

  test('uses the first gallery image as the home card image', () async {
    final placesClient = _FakeApiClient([
      {
        'data': [
          {
            'slug': 'angkor-wat',
            'name': 'Angkor Wat',
            'images': [
              {'url': '/storage/4/angkor-wat.jpg'},
            ],
          },
        ],
        'meta': {'last_page': 1},
      },
    ]);
    final place = (await ApiPlaceRepository(placesClient).loadPlaces()).single;

    expect(place.imageAsset, endsWith('/storage/4/angkor-wat.jpg'));
    expect(place.photos.first, place.imageAsset);

    final destinationsClient = _FakeApiClient([
      {
        'data': [
          {
            'slug': 'siem-reap',
            'name': 'Siem Reap',
            'images': [
              {'url': '/storage/4/siem-reap.jpg'},
            ],
          },
        ],
        'meta': {'last_page': 1},
      },
    ]);
    final destination = (await ApiDestinationRepository(
      destinationsClient,
    ).loadDestinations()).single;

    expect(destination.imageUrl, endsWith('/storage/4/siem-reap.jpg'));
  });

  test('loads saved slugs and sends API save and unsave requests', () async {
    final client = _FakeApiClient([
      {
        'data': [
          {'slug': 'angkor-wat'},
        ],
      },
      {'saved': true},
      {'saved': false},
    ], authenticated: true);
    final repository = ApiPlaceRepository(client);

    expect(await repository.loadSavedPlaceSlugs(), {'angkor-wat'});
    await repository.setPlaceSaved('angkor-wat', saved: true);
    await repository.setPlaceSaved('angkor-wat', saved: false);

    expect(
      client.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /me/saved-places',
        'PUT /me/saved-places/angkor-wat',
        'DELETE /me/saved-places/angkor-wat',
      ],
    );
  });

  test(
    'auth repository sends credentials and retains returned token',
    () async {
      final client = _FakeApiClient([
        {
          'token': 'access-token',
          'user': {
            'id': 'user-1',
            'name': 'Traveler',
            'email': 'traveler@example.test',
            'roles': ['user'],
          },
        },
        {
          'token': 'registered-token',
          'user': {
            'id': 'user-2',
            'name': 'New Traveler',
            'email': 'new@example.test',
          },
        },
      ])..setLanguage('zh');
      final repository = ApiAuthRepository(client);

      final user = await repository.signIn(
        email: 'traveler@example.test',
        password: 'password123',
      );
      final registered = await repository.signUp(
        name: 'New Traveler',
        email: 'new@example.test',
        password: 'password123',
      );

      expect(user.name, 'Traveler');
      expect(registered.id, 'user-2');
      expect(client.isAuthenticated, isTrue);
      expect(client.requests.first.path, '/auth/login');
      expect(client.requests.first.data, {
        'email': 'traveler@example.test',
        'password': 'password123',
        'device_name': 'Khmer Compass',
      });
      expect(client.requests.last.data, {
        'name': 'New Traveler',
        'email': 'new@example.test',
        'password': 'password123',
        'country_code': 'KH',
        'preferred_language': 'zh',
      });
    },
  );

  test(
    'profile repository loads user, travel counts, recent visits and updates',
    () async {
      final client = _FakeApiClient([
        {
          'data': {
            'id': 'user-1',
            'name': 'Traveler',
            'email': 'traveler@example.test',
            'avatar': '/storage/avatars/traveler.jpg',
          },
        },
        {
          'data': [
            {
              'slug': 'angkor-wat',
              'name': 'Angkor Wat',
              'destination': {'name': 'Siem Reap'},
              'cover_url': '/storage/places/angkor-wat.jpg',
            },
          ],
        },
        {
          'data': [
            {'slug': 'angkor-wat'},
            {'slug': 'koh-rong'},
          ],
        },
        {
          'data': [
            {'id': 'trip-1', 'title': 'Cambodia trip'},
          ],
        },
        {
          'data': {
            'id': 'user-1',
            'name': 'Updated Traveler',
            'email': 'traveler@example.test',
            'avatar': '/storage/avatars/traveler.jpg',
          },
        },
      ]);
      final repository = ApiProfileRepository(client);

      final profile = await repository.loadProfile();
      final updated = await repository.updateProfile(
        profile.copyWith(fullName: 'Updated Traveler'),
      );

      expect(profile.photoUrl, endsWith('/storage/avatars/traveler.jpg'));
      expect(profile.visitedPlaceCount, 1);
      expect(profile.savedPlaceCount, 2);
      expect(profile.plannedTripCount, 1);
      expect(profile.recentPlaces.single.name, 'Angkor Wat');
      expect(profile.recentPlaces.single.location, 'Siem Reap');
      expect(
        profile.recentPlaces.single.imageUrl,
        endsWith('/storage/places/angkor-wat.jpg'),
      );
      expect(updated.fullName, 'Updated Traveler');
      expect(client.requests.last.method, 'PATCH');
      expect(client.requests.last.path, '/me');
      expect(client.requests.last.data, {'name': 'Updated Traveler'});
      expect(client.requests.take(4).map((request) => request.path), [
        '/me',
        '/me/visited-places',
        '/me/saved-places',
        '/me/trips',
      ]);
    },
  );
}

Map<String, Object?> _placeJson({required String slug, required Object name}) {
  return {
    'slug': slug,
    'name': name,
    'category': {'slug': 'temple', 'name': 'Temple'},
    'region': {'slug': 'siem-reap', 'name': 'Siem Reap'},
    'latitude': 13.4,
    'longitude': 103.8,
    'has_story': true,
    'image_url': 'https://images.example.test/$slug.jpg',
  };
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this._responses, {this.authenticated = false})
    : super(tokenStore: _FakeTokenStore());

  final List<Map<String, Object?>> _responses;
  final bool authenticated;
  final requests = <_CapturedRequest>[];

  @override
  bool get isAuthenticated => authenticated || super.isAuthenticated;

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    requests.add(
      _CapturedRequest('GET', path, queryParameters: queryParameters),
    );
    return _responses.removeAt(0);
  }

  @override
  Future<Map<String, Object?>> post(
    String path, {
    Map<String, Object?>? data,
  }) async {
    requests.add(_CapturedRequest('POST', path, data: data));
    return _responses.removeAt(0);
  }

  @override
  Future<Map<String, Object?>> patch(
    String path, {
    Map<String, Object?>? data,
  }) async {
    requests.add(_CapturedRequest('PATCH', path, data: data));
    return _responses.removeAt(0);
  }

  @override
  Future<Map<String, Object?>> put(
    String path, {
    Map<String, Object?>? data,
  }) async {
    requests.add(_CapturedRequest('PUT', path, data: data));
    return _responses.removeAt(0);
  }

  @override
  Future<Map<String, Object?>> delete(String path) async {
    requests.add(_CapturedRequest('DELETE', path));
    return _responses.removeAt(0);
  }
}

class _CapturedRequest {
  const _CapturedRequest(
    this.method,
    this.path, {
    this.data,
    this.queryParameters,
  });

  final String method;
  final String path;
  final Map<String, Object?>? data;
  final Map<String, Object?>? queryParameters;
}

class _FakeTokenStore implements TokenStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String? token) async {}
}
