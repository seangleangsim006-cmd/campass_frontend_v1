import 'package:user_frontend/core/network/token_store.dart';
import 'package:user_frontend/features/auth/domain/models/app_user.dart';
import 'package:user_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:user_frontend/features/home/data/mock/home_content.dart';
import 'package:user_frontend/features/home/domain/models/destination.dart';
import 'package:user_frontend/features/home/domain/models/home_event.dart';
import 'package:user_frontend/features/home/domain/models/home_phrase.dart';
import 'package:user_frontend/features/home/domain/repositories/destination_repository.dart';
import 'package:user_frontend/features/home/domain/repositories/home_content_repository.dart';
import 'package:user_frontend/features/home/domain/repositories/place_repository.dart';
import 'package:user_frontend/features/profile/domain/models/user_profile.dart';
import 'package:user_frontend/features/profile/domain/repositories/profile_repository.dart';

class FakeAuthRepository extends AuthRepository {
  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => AppUser(id: 'test-user', name: 'Test Traveler', email: email);

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async => AppUser(id: 'test-user', name: name, email: email);

  @override
  Future<void> resetPassword({required String email}) async {}
}

class FakeProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(
    id: 'test-user',
    fullName: 'Test Traveler',
    email: 'traveler@example.test',
  );

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile;
    return _profile;
  }
}

class FakePlaceRepository implements PlaceRepository {
  final Set<String> _savedSlugs = {};

  @override
  Future<List<HomeDestination>> loadPlaces({String? query}) async {
    if (query == null || query.isEmpty) return homeDestinations;
    final normalized = query.toLowerCase();
    return homeDestinations
        .where((place) => place.name.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  Future<HomeDestination> loadPlace(String slug) async {
    return homeDestinations.firstWhere(
      (place) => place.key == slug,
      orElse: () => throw Exception('Place not found: $slug'),
    );
  }

  @override
  Future<Set<String>> loadSavedPlaceSlugs() async => Set.of(_savedSlugs);

  @override
  Future<void> setPlaceSaved(String slug, {required bool saved}) async {
    if (saved) {
      _savedSlugs.add(slug);
    } else {
      _savedSlugs.remove(slug);
    }
  }
}

class FakeDestinationRepository implements DestinationRepository {
  static const destinations = [
    Destination(
      slug: 'siem-reap',
      name: 'Siem Reap',
      region: 'Northwest Cambodia',
    ),
    Destination(
      slug: 'south-coast',
      name: 'South Coast',
      region: 'Gulf of Thailand',
    ),
    Destination(slug: 'koh-kong', name: 'Koh Kong', region: 'Southwest'),
  ];

  @override
  Future<List<Destination>> loadDestinations() async => destinations;

  @override
  Future<DestinationDetails> loadDestination(String slug) async {
    if (slug == 'koh-kong') {
      final place = homeDestinations.firstWhere(
        (destination) => destination.name == 'Cardamom Mountains',
      );
      return DestinationDetails(
        slug: 'koh-kong',
        name: 'Koh Kong',
        places: [DestinationPlace(slug: place.key, name: place.name)],
      );
    }
    final destination = destinations.firstWhere(
      (destination) => destination.slug == slug,
    );
    return DestinationDetails(
      slug: destination.slug,
      name: destination.name,
      region: destination.region,
      bestTimeToVisit: 'November to February',
      howToGetThere: 'Local transport is available.',
      entranceFees: 'Check the official site for current fees.',
      accessibility: 'Accessibility details are available on request.',
      travelTips: 'Bring water and sun protection.',
      galleryUrls: const ['https://images.example.test/siem-reap.jpg'],
      places: const [
        DestinationPlace(
          slug: 'angkor-wat',
          name: 'Angkor Wat',
          category: 'Temple',
          imageUrl: 'https://images.example.test/angkor-wat.jpg',
          rating: 4.9,
          isFeatured: true,
        ),
        DestinationPlace(
          slug: 'bayon',
          name: 'Bayon',
          category: 'Culture',
          imageUrl: 'https://images.example.test/bayon.jpg',
        ),
      ],
    );
  }
}

class FakeHomeContentRepository implements HomeContentRepository {
  @override
  Future<List<HomeEvent>> loadEvents() async => const [
    HomeEvent(
      title: 'Discover Koh Ker',
      location: 'Cambodia',
      description: 'Explore the remote temples of Koh Ker.',
      searchTerm: 'Koh Ker',
    ),
    HomeEvent(
      title: 'Khmer New Year',
      location: 'Siem Reap',
      description: 'Celebrate the new year with local traditions.',
      searchTerm: 'Siem Reap',
      imageUrl: 'https://images.example.test/khmer-new-year.jpg',
    ),
  ];

  @override
  Future<List<HomePhrase>> loadPhrases({String? categorySlug}) async {
    const phrases = [
      HomePhrase(
        meaning: 'Thank you very much',
        khmerText: 'អរគុណច្រើន',
        romanization: 'Or-kun char-ran',
        phonetic: '[aw-KOON ch’ran]',
        categorySlug: 'greetings',
      ),
      HomePhrase(
        meaning: 'Good morning',
        khmerText: 'អរុណសួស្តី',
        romanization: 'Arun suor sdei',
        phonetic: 'ah-roon soo-uh s-day',
        categorySlug: 'greetings',
      ),
      HomePhrase(
        meaning: 'Water',
        khmerText: 'ទឹក',
        romanization: 'Tuk',
        phonetic: 'took',
        categorySlug: 'food',
      ),
    ];
    if (categorySlug == null) return phrases;
    return phrases
        .where((phrase) => phrase.categorySlug == categorySlug)
        .toList();
  }
}

class FakeTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String? token) async {
    _token = token;
  }
}
