import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/api_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/home/data/repositories/api_place_repository.dart';
import 'features/home/data/repositories/api_destination_repository.dart';
import 'features/home/data/repositories/api_home_content_repository.dart';
import 'features/home/domain/repositories/destination_repository.dart';
import 'features/home/domain/repositories/home_content_repository.dart';
import 'features/home/domain/repositories/place_repository.dart';
import 'features/language/presentation/providers/language_provider.dart';
import 'features/profile/data/repositories/api_profile_repository.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'l10n/generated/app_localizations.dart';

class KhmerCompassApp extends StatelessWidget {
  const KhmerCompassApp({
    super.key,
    this.languageProvider,
    this.apiClient,
    this.authRepository,
    this.profileRepository,
    this.placeRepository,
    this.destinationRepository,
    this.homeContentRepository,
  });

  final LanguageProvider? languageProvider;
  final ApiClient? apiClient;
  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;
  final PlaceRepository? placeRepository;
  final DestinationRepository? destinationRepository;
  final HomeContentRepository? homeContentRepository;

  @override
  Widget build(BuildContext context) {
    final client = apiClient ?? ApiClient();
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        Provider<AuthRepository>.value(
          value: authRepository ?? ApiAuthRepository(client),
        ),
        Provider<ProfileRepository>.value(
          value: profileRepository ?? ApiProfileRepository(client),
        ),
        Provider<PlaceRepository>.value(
          value: placeRepository ?? ApiPlaceRepository(client),
        ),
        Provider<DestinationRepository>.value(
          value: destinationRepository ?? ApiDestinationRepository(client),
        ),
        Provider<HomeContentRepository>.value(
          value: homeContentRepository ?? ApiHomeContentRepository(client),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) {
            final provider = languageProvider ?? LanguageProvider();
            if (languageProvider == null) unawaited(provider.load());
            return provider;
          },
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (context) =>
              ProfileProvider(repository: context.read<ProfileRepository>()),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, provider, child) {
          client.setLanguage(provider.locale.languageCode);
          return MaterialApp.router(
            title: 'Khmer Compass',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: provider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
