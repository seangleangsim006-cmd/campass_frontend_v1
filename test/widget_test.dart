import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_frontend/app.dart';
import 'package:user_frontend/core/routing/app_router.dart';
import 'package:user_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:user_frontend/features/auth/presentation/screens/register_screen.dart';
import 'package:user_frontend/features/home/data/mock/home_content.dart';
import 'package:user_frontend/features/home/domain/models/destination.dart';
import 'package:user_frontend/features/home/domain/models/home_event.dart';
import 'package:user_frontend/features/home/domain/models/home_phrase.dart';
import 'package:user_frontend/features/onboarding/data/onboarding_content.dart';
import 'package:user_frontend/features/place/presentation/screens/category_destinations_screen.dart';
import 'package:user_frontend/features/place/presentation/screens/destination_detail_screen.dart';
import 'package:user_frontend/features/place/presentation/screens/destination_overview_screen.dart';
import 'package:user_frontend/features/explore/presentation/screens/explore_screen.dart';
import 'package:user_frontend/features/event/presentation/screens/event_detail_screen.dart';
import 'package:user_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:user_frontend/features/home/presentation/screens/phrases_screen.dart';
import 'package:user_frontend/features/home/presentation/widgets/destination_image.dart';
import 'package:user_frontend/core/network/api_client.dart';
import 'helpers/fake_repositories.dart';

KhmerCompassApp _testApp() => KhmerCompassApp(
  apiClient: ApiClient(tokenStore: FakeTokenStore()),
  authRepository: FakeAuthRepository(),
  profileRepository: FakeProfileRepository(),
  placeRepository: FakePlaceRepository(),
  destinationRepository: FakeDestinationRepository(),
  homeContentRepository: FakeHomeContentRepository(),
);

Future<void> _openLogin(WidgetTester tester) async {
  await tester.pumpWidget(_testApp());
  AppRouter.router.go('/');
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Next'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Next'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Get Started'));
  await tester.pumpAndSettle();
  AppRouter.router.go('/login');
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('onboarding leads to language selection and authentication', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Discover the Magical Cambodia'), findsOneWidget);
    final firstBackground = find.byKey(
      ValueKey(OnboardingContent.pages[0].imageAsset),
    );
    expect(firstBackground, findsOneWidget);
    expect(tester.widget<Image>(firstBackground).fit, BoxFit.cover);
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Breathtaking Places'), findsOneWidget);
    expect(
      find.byKey(ValueKey(OnboardingContent.pages[1].imageAsset)),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Experience Local Culture'), findsOneWidget);
    expect(
      find.byKey(ValueKey(OnboardingContent.pages[2].imageAsset)),
      findsOneWidget,
    );
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Language'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('onboarding_completed'), isTrue);

    AppRouter.router.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Explore shows loading, empty, and recoverable error states', (
    tester,
  ) async {
    final destinations = Completer<List<HomeDestination>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExploreScreen(
            savedDestinations: const {},
            onToggleFavorite: (_) {},
            loadDestinations: () => destinations.future,
            destinationRepository: FakeDestinationRepository(),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('explore_destination_skeleton')),
      findsWidgets,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    destinations.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('No places found'), findsOneWidget);

    var shouldFail = true;

    Future<List<HomeDestination>> loadAfterFailure() async {
      if (shouldFail) throw Exception('Temporary data error');
      return homeDestinations;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExploreScreen(
            key: const ValueKey('failure-screen'),
            savedDestinations: const {},
            onToggleFavorite: (_) {},
            loadDestinations: loadAfterFailure,
            destinationRepository: FakeDestinationRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load places'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Angkor Wat'), findsOneWidget);
  });

  testWidgets('home shows skeletons until API content finishes loading', (
    tester,
  ) async {
    final placeRepository = _LoadingPlaceRepository();
    final destinationRepository = _LoadingDestinationsRepository();
    final contentRepository = _LoadingHomeContentRepository();
    await tester.pumpWidget(
      KhmerCompassApp(
        apiClient: ApiClient(tokenStore: FakeTokenStore()),
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        placeRepository: placeRepository,
        destinationRepository: destinationRepository,
        homeContentRepository: contentRepository,
      ),
    );
    AppRouter.router.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('home_event_skeleton')), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('home_destination_grid_skeleton')),
      find.byType(CustomScrollView),
      const Offset(0, -350),
    );
    expect(
      find.byKey(const ValueKey('home_destination_grid_skeleton')),
      findsOneWidget,
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('home_destinations_skeleton')),
      find.byType(CustomScrollView),
      const Offset(0, -350),
    );
    expect(
      find.byKey(const ValueKey('home_destinations_skeleton')),
      findsOneWidget,
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('home_phrase_carousel_skeleton')),
      find.byType(CustomScrollView),
      const Offset(0, -350),
    );
    expect(
      find.byKey(const ValueKey('home_phrase_carousel_skeleton')),
      findsOneWidget,
    );

    placeRepository.places.complete(homeDestinations);
    destinationRepository.destinations.complete(
      FakeDestinationRepository.destinations,
    );
    contentRepository.events.complete([
      const HomeEvent(
        title: 'API Event',
        location: 'Siem Reap',
        description: 'A live event',
        searchTerm: 'Siem Reap',
      ),
    ]);
    contentRepository.phrases.complete([
      const HomePhrase(
        meaning: 'Welcome',
        khmerText: 'សូមស្វាគមន៍',
        romanization: 'som swam knea',
        phonetic: 'welcome',
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Welcome'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
    await tester.pump();
    expect(find.text('API Event'), findsOneWidget);
  });

  testWidgets('destination detail shows a skeleton while loading', (
    tester,
  ) async {
    final repository = _LoadingDestinationRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destinationName: 'angkor-wat',
          placeRepository: repository,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('destination_detail_skeleton')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    repository.destination.complete(homeDestinations.first);
    await tester.pump();
    await tester.pump();
    expect(find.text('Could not load this place.'), findsNothing);
  });

  testWidgets('destination overview shows a skeleton while loading', (
    tester,
  ) async {
    final repository = _LoadingDestinationOverviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationOverviewScreen(
          destinationSlug: 'siem-reap',
          destinationRepository: repository,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('destination_overview_skeleton')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    repository.destination.complete(
      await FakeDestinationRepository().loadDestination('siem-reap'),
    );
    await tester.pump();
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('Featured attractions'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Featured attractions'), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('featured_place_card_angkor-wat')),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Angkor Wat'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Explore Places'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Explore Places'), findsOneWidget);
    await tester.dragUntilVisible(
      find.widgetWithText(ChoiceChip, 'Culture'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Culture'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Culture'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('destination_place_card_bayon')),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(
      find.byKey(const ValueKey('destination_place_card_bayon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('destination_place_card_angkor-wat')),
      findsNothing,
    );
    await tester.dragUntilVisible(
      find.text('November to February'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('November to February'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Photos'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Photos'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('destination_gallery_0')),
    );
    await tester.tap(find.byKey(const ValueKey('destination_gallery_0')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close photo viewer'), findsOneWidget);
    await tester.tap(find.byTooltip('Close photo viewer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination overview hides absent optional data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationOverviewScreen(
          destinationSlug: 'empty-region',
          destinationRepository: _EmptyDestinationOverviewRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('There are no places listed for this destination yet.'),
      findsOneWidget,
    );
    expect(find.text('Featured attractions'), findsNothing);
    expect(find.text('Travel information'), findsNothing);
    expect(find.text('Photos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination overview can retry after a load error', (
    tester,
  ) async {
    final repository = _RetryingDestinationOverviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationOverviewScreen(
          destinationSlug: 'siem-reap',
          destinationRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load this destination.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load this destination.'), findsNothing);
    expect(repository.calls, 2);
  });

  testWidgets('category destinations show skeleton cards while loading', (
    tester,
  ) async {
    final repository = _LoadingPlaceRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryDestinationsScreen(
          category: 'Beaches',
          placeRepository: repository,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('category_destinations_skeleton')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    repository.places.complete(const []);
    await tester.pump();
    await tester.pump();
    expect(find.text('No destinations found in Beaches.'), findsOneWidget);
  });

  testWidgets('Explore destination cards open the detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);

    await tester.tap(find.text('Angkor Wat'));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationDetailScreen), findsOneWidget);
    expect(find.text('About This Place'), findsOneWidget);
  });

  testWidgets('Explore filters places using API destination places', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExploreScreen(
            savedDestinations: const {},
            onToggleFavorite: (_) {},
            loadDestinations: () async => homeDestinations,
            destinationRepository: FakeDestinationRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Destination'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Koh Kong'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Koh Kong'));
    await tester.pumpAndSettle();

    expect(find.text('Cardamom Mountains'), findsOneWidget);
    expect(find.text('Angkor Wat'), findsNothing);
  });

  testWidgets('login validates input and completes mock sign-in', (
    tester,
  ) async {
    await _openLogin(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'traveler@example.test',
    );
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Find your next adventure'), findsOneWidget);
  });

  testWidgets('registration checks matching passwords before mock sign-up', (
    tester,
  ) async {
    await _openLogin(tester);

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);

    final registerFields = find.descendant(
      of: find.byType(RegisterScreen),
      matching: find.byType(TextFormField),
    );
    final nameField = registerFields.at(0);
    final emailField = registerFields.at(1);
    final passwordField = registerFields.at(2);
    final confirmPasswordField = registerFields.at(3);
    final registerButton = find.descendant(
      of: find.byType(RegisterScreen),
      matching: find.widgetWithText(ElevatedButton, 'Create account'),
    );

    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Test Traveler');
    await tester.enterText(emailField, 'traveler@example.test');
    await tester.enterText(passwordField, 'password123');
    await tester.ensureVisible(confirmPasswordField);
    await tester.enterText(confirmPasswordField, 'different123');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.ensureVisible(confirmPasswordField);
    await tester.enterText(confirmPasswordField, 'password123');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Home phrases carousel opens the complete phrase list', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Essential Everyday Phrases'),
      find.byType(CustomScrollView),
      const Offset(0, -350),
    );
    expect(find.text('Thank you very much'), findsOneWidget);
    expect(find.text('Or-kun char-ran'), findsOneWidget);
    expect(find.text('Phonetic: [aw-KOON ch’ran]'), findsOneWidget);
    final phrasesCarousel = tester.widget<ListView>(
      find
          .ancestor(
            of: find.text('Thank you very much'),
            matching: find.byType(ListView),
          )
          .first,
    );
    expect(phrasesCarousel.scrollDirection, Axis.horizontal);

    await tester.tap(find.text('See all').last);
    await tester.pumpAndSettle();
    expect(find.byType(PhrasesScreen), findsOneWidget);
    expect(find.text('Everyday Phrases'), findsOneWidget);
    expect(find.text('Thank you very much'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Thank you very much'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Emergency'));
    await tester.pumpAndSettle();
    expect(
      find.text('No phrases are available in this category yet.'),
      findsOneWidget,
    );
  });

  testWidgets('event detail header displays its image when available', (
    tester,
  ) async {
    const imageUrl = 'https://images.example.test/event.jpg';
    await tester.pumpWidget(
      const MaterialApp(
        home: EventDetailScreen(
          event: HomeEvent(
            title: 'Khmer New Year',
            location: 'Siem Reap',
            description: 'Annual celebration',
            searchTerm: 'Siem Reap',
            imageUrl: imageUrl,
          ),
        ),
      ),
    );

    expect(find.byType(DestinationImage), findsOneWidget);
    expect(
      tester.widget<DestinationImage>(find.byType(DestinationImage)).source,
      imageUrl,
    );
  });

  testWidgets('home event slideshow cycles through all returned events', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('home_event_slideshow')),
      find.byType(CustomScrollView),
      const Offset(0, -350),
    );
    expect(find.text('Discover Koh Ker'), findsOneWidget);
    final pageView = find.byKey(const ValueKey('home_event_slideshow'));
    expect(
      tester.widget<PageView>(pageView).childrenDelegate.estimatedChildCount,
      2,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Khmer New Year'), findsOneWidget);
    expect(
      tester
          .widget<DestinationImage>(
            find.descendant(
              of: pageView,
              matching: find.byType(DestinationImage),
            ),
          )
          .source,
      'https://images.example.test/khmer-new-year.jpg',
    );
    await tester.drag(pageView, const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(find.text('Discover Koh Ker'), findsOneWidget);
  });

  testWidgets('guest can open home and navigate destination sections', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    AppRouter.router.go('/');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Skip'));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Your Language'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'traveler@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Explore by destination'), findsOneWidget);
    expect(find.text('Discover places across Cambodia'), findsOneWidget);
    expect(find.text('Siem Reap'), findsOneWidget);
    final destinationGrid = tester.widget<GridView>(
      find.byKey(const ValueKey('home_destination_grid')),
    );
    expect(destinationGrid.scrollDirection, Axis.horizontal);
    expect(
      (destinationGrid.gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
    expect(find.text('FEATURED EVENT'), findsOneWidget);
    expect(find.text('Discover Koh Ker'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Explore'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('About this event'), findsOneWidget);
    expect(find.text('Explore the remote temples of Koh Ker.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Explore'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text('Explore Cambodia'), findsOneWidget);
    expect(find.text('Advanced filters'), findsOneWidget);
    expect(find.text('5 places'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Beaches'));
    await tester.pumpAndSettle();
    expect(find.text('1 place'), findsOneWidget);
    expect(find.text('Koh Rong'), findsOneWidget);
    expect(find.text('Angkor Wat'), findsNothing);

    await tester.tap(find.text('Advanced filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4.8+'));
    await tester.tap(find.text('Show places'));
    await tester.pumpAndSettle();
    expect(find.text('Koh Rong'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('home_destination_grid')),
      find.byType(CustomScrollView),
      const Offset(0, -350),
    );
    final siemReapCard = find.descendant(
      of: find.byKey(const ValueKey('home_destination_grid')),
      matching: find.text('Siem Reap'),
    );
    await tester.ensureVisible(siemReapCard);
    await tester.pumpAndSettle();
    await tester.tap(siemReapCard);
    await tester.pumpAndSettle();
    expect(find.byType(DestinationOverviewScreen), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Explore Places'),
      find.byType(CustomScrollView).last,
      const Offset(0, -200),
    );
    expect(find.text('Explore Places'), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('destination_place_card_angkor-wat')),
      find.byType(CustomScrollView).last,
      const Offset(0, -200),
    );
    await tester.tap(
      find.byKey(const ValueKey('destination_place_card_angkor-wat')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DestinationDetailScreen), findsOneWidget);
    expect(find.text('Angkor Wat'), findsOneWidget);
    expect(find.text('Siem Reap, Cambodia'), findsOneWidget);
    expect(find.text('1.2k reviews'), findsOneWidget);
    expect(find.text('Temple'), findsOneWidget);
    expect(find.text('03 · DESCRIPTION'), findsOneWidget);
    expect(find.text('About This Place'), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    expect(find.text('Read more'), findsOneWidget);
    expect(find.text('Your next adventure'), findsOneWidget);
    expect(find.text('Plan your visit'), findsOneWidget);
    expect(find.text('Get Directions'), findsOneWidget);

    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Built in the 12th century'), findsOneWidget);
    expect(find.textContaining('Walk through vast galleries'), findsOneWidget);
    await tester.tap(find.text('Plan your visit'));
    await tester.pumpAndSettle();
    expect(find.text('04 · VISITOR INFORMATION'), findsOneWidget);
    expect(find.text('Travel Information'), findsOneWidget);
    expect(find.text('Opening hours'), findsOneWidget);
    expect(find.text('Dress code and visitor guidelines'), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map preview'), findsOneWidget);
    expect(find.text('Photo Gallery'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationOverviewScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Add to favorites').first);
    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Search places in Cambodia'), findsOneWidget);
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Current location'), findsOneWidget);
    expect(find.text('Angkor Wat'), findsOneWidget);
    await tester.tap(find.text('Beaches').first);
    await tester.pumpAndSettle();
    expect(find.text('Angkor Wat'), findsNothing);
    expect(find.text('Koh Rong'), findsOneWidget);
    await tester.tap(find.text('Koh Rong'));
    await tester.pumpAndSettle();
    expect(find.text('Get Directions'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    await tester.tap(find.byTooltip('Show destination list'));
    await tester.pumpAndSettle();
    expect(find.text('Koh Rong'), findsOneWidget);
    await tester.tap(find.byTooltip('Show map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved places'), findsOneWidget);
    expect(find.text('Save places to find them here.'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
  });
}

class _LoadingPlaceRepository extends FakePlaceRepository {
  final places = Completer<List<HomeDestination>>();

  @override
  Future<List<HomeDestination>> loadPlaces({String? query}) => places.future;
}

class _LoadingDestinationsRepository extends FakeDestinationRepository {
  final destinations = Completer<List<Destination>>();

  @override
  Future<List<Destination>> loadDestinations() => destinations.future;
}

class _LoadingDestinationOverviewRepository extends FakeDestinationRepository {
  final destination = Completer<DestinationDetails>();

  @override
  Future<DestinationDetails> loadDestination(String slug) => destination.future;
}

class _EmptyDestinationOverviewRepository extends FakeDestinationRepository {
  @override
  Future<DestinationDetails> loadDestination(String slug) async =>
      const DestinationDetails(
        slug: 'empty-region',
        name: 'Empty Region',
        places: [],
      );
}

class _RetryingDestinationOverviewRepository extends FakeDestinationRepository {
  int calls = 0;

  @override
  Future<DestinationDetails> loadDestination(String slug) {
    calls++;
    if (calls == 1) return Future.error(Exception('Temporary error'));
    return super.loadDestination(slug);
  }
}

class _LoadingDestinationRepository extends FakePlaceRepository {
  final destination = Completer<HomeDestination>();

  @override
  Future<HomeDestination> loadPlace(String slug) => destination.future;
}

class _LoadingHomeContentRepository extends FakeHomeContentRepository {
  final events = Completer<List<HomeEvent>>();
  final phrases = Completer<List<HomePhrase>>();

  @override
  Future<List<HomeEvent>> loadEvents() => events.future;

  @override
  Future<List<HomePhrase>> loadPhrases({String? categorySlug}) =>
      phrases.future;
}
