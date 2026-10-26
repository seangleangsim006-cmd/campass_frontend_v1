import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:user_frontend/app.dart';
import 'package:user_frontend/core/routing/app_router.dart';
import 'package:user_frontend/l10n/generated/app_localizations.dart';
import 'package:user_frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:user_frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:user_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:user_frontend/core/network/api_client.dart';
import 'helpers/fake_repositories.dart';

void main() {
  testWidgets('edit profile uses a skeleton until profile data is available', (
    tester,
  ) async {
    final provider = ProfileProvider(repository: FakeProfileRepository());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: EditProfileScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('edit_profile_skeleton')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    provider.dispose();
  });

  testWidgets('profile renders on a narrow screen and logout can be canceled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = ProfileProvider(repository: FakeProfileRepository());
    await provider.load();
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SafeArea(
              child: ProfileScreen(onSelectTab: _ignoreTabSelection),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Traveler'), findsOneWidget);
    expect(find.text('Places visited'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsNothing);
  });

  testWidgets('profile edit route updates the shared profile provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      KhmerCompassApp(
        apiClient: ApiClient(tokenStore: FakeTokenStore()),
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        placeRepository: FakePlaceRepository(),
        destinationRepository: FakeDestinationRepository(),
        homeContentRepository: FakeHomeContentRepository(),
      ),
    );
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile').first);
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Sophea Dara',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Sophea Dara'), findsOneWidget);
  });
}

void _ignoreTabSelection(int index) {}
