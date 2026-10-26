import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_section_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/place/presentation/screens/category_destinations_screen.dart';
import '../../features/place/presentation/screens/destination_detail_screen.dart';
import '../../features/place/presentation/screens/destination_overview_screen.dart';
import '../../features/home/domain/repositories/destination_repository.dart';
import '../../features/home/domain/repositories/place_repository.dart';
import '../../features/home/domain/repositories/home_content_repository.dart';
import '../../features/home/domain/models/home_event.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/phrases_screen.dart';
import '../../features/event/presentation/screens/event_detail_screen.dart';
import '../../features/language/presentation/screens/language_selection_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.onboarding,
    redirect: (context, state) async {
      if (state.matchedLocation != RouteNames.onboarding) return null;
      final apiClient = context.read<ApiClient>();
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool('onboarding_completed') != true) return null;
      await apiClient.initialize();
      return apiClient.isAuthenticated ? RouteNames.home : RouteNames.login;
    },
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.languageSelection,
        name: RouteNames.languageSelectionRouteName,
        builder: (context, state) => LanguageSelectionScreen(
          requireAuthentication:
              state.uri.queryParameters['require_auth'] == 'true',
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(repository: context.read<AuthRepository>()),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(repository: context.read<AuthRepository>()),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(repository: context.read<AuthRepository>()),
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => HomeScreen(
          placeRepository: context.read<PlaceRepository>(),
          homeContentRepository: context.read<HomeContentRepository>(),
          destinationRepository: context.read<DestinationRepository>(),
        ),
      ),
      GoRoute(
        path: RouteNames.explore,
        name: RouteNames.exploreRouteName,
        builder: (context, state) => HomeScreen(
          initialNavigationIndex: 1,
          placeRepository: context.read<PlaceRepository>(),
          homeContentRepository: context.read<HomeContentRepository>(),
          destinationRepository: context.read<DestinationRepository>(),
        ),
      ),
      GoRoute(
        path: RouteNames.categoryDestinations,
        builder: (context, state) => CategoryDestinationsScreen(
          category: state.pathParameters['category']!,
          placeRepository: context.read<PlaceRepository>(),
        ),
      ),
      GoRoute(
        path: RouteNames.destinationDetails,
        builder: (context, state) => DestinationDetailScreen(
          destinationName: state.pathParameters['destination']!,
          placeRepository: context.read<PlaceRepository>(),
        ),
      ),
      GoRoute(
        path: RouteNames.destinationOverview,
        builder: (context, state) => DestinationOverviewScreen(
          destinationSlug: state.pathParameters['destination']!,
          destinationRepository: context.read<DestinationRepository>(),
        ),
      ),
      GoRoute(
        path: RouteNames.phrases,
        builder: (context, state) =>
            PhrasesScreen(repository: context.read<HomeContentRepository>()),
      ),
      GoRoute(
        path: RouteNames.eventDetails,
        builder: (context, state) =>
            EventDetailScreen(event: state.extra! as HomeEvent),
      ),
      GoRoute(
        path: RouteNames.profileEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.profileTrips,
        builder: (context, state) => const ProfileSectionScreen(
          title: 'My Trips',
          description:
              'A couple of sample trip plans to inspire your next visit.',
          icon: Icons.luggage_outlined,
          entries: [
            'Angkor Wat sunrise · Siem Reap · 12 Nov',
            'Koh Rong weekend · Preah Sihanouk · 03 Dec',
          ],
        ),
      ),
      GoRoute(
        path: RouteNames.profileHistory,
        builder: (context, state) => const ProfileSectionScreen(
          title: 'Travel History',
          description: 'Sample destinations from your travel journal.',
          icon: Icons.history_rounded,
          entries: [
            'Royal Palace · Phnom Penh',
            'Angkor Wat · Siem Reap',
            'Cardamom Mountains · Koh Kong',
          ],
        ),
      ),
      GoRoute(
        path: RouteNames.profileNotifications,
        builder: (context, state) => const ProfileSectionScreen(
          title: 'Notifications',
          description:
              'Notification preferences will be available when notification '
              'services are connected.',
          icon: Icons.notifications_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.profilePrivacy,
        builder: (context, state) => const ProfileSectionScreen(
          title: 'Privacy & Security',
          description:
              'Account security controls will be available when authentication '
              'is connected.',
          icon: Icons.lock_outline_rounded,
        ),
      ),
      GoRoute(
        path: RouteNames.profileHelp,
        builder: (context, state) => const ProfileSectionScreen(
          title: 'Help & Support',
          description:
              'Support resources will be available here. Please check back '
              'soon.',
          icon: Icons.help_outline_rounded,
        ),
      ),
      GoRoute(
        path: RouteNames.profileAbout,
        builder: (context, state) => const ProfileSectionScreen(
          title: 'About Khmer Compass',
          description:
              'Discover Cambodia with destination guides, local insights, '
              'and tools for planning your next trip.',
          icon: Icons.info_outline_rounded,
          version: '1.0.0',
        ),
      ),
    ],
  );
}
