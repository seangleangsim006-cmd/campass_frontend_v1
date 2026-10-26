import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_frontend/app.dart';
import 'package:user_frontend/core/routing/app_router.dart';
import 'package:user_frontend/core/routing/route_names.dart';
import 'package:user_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:user_frontend/features/language/domain/models/app_language.dart';
import 'package:user_frontend/features/language/presentation/providers/language_provider.dart';
import 'package:user_frontend/core/network/api_client.dart';
import 'helpers/fake_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  testWidgets('selection changes locale, persists, and continues to Explore', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = LanguageProvider();
    await provider.load();
    await tester.pumpWidget(
      KhmerCompassApp(
        languageProvider: provider,
        apiClient: ApiClient(tokenStore: FakeTokenStore()),
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        placeRepository: FakePlaceRepository(),
        destinationRepository: FakeDestinationRepository(),
        homeContentRepository: FakeHomeContentRepository(),
      ),
    );
    AppRouter.router.go(RouteNames.languageSelection);
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Language'), findsOneWidget);
    expect(find.text('Khmer'), findsOneWidget);
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('Chinese'), findsOneWidget);

    await tester.ensureVisible(find.text('Chinese'));
    await tester.tap(find.text('Chinese'));
    await tester.pumpAndSettle();

    expect(provider.selectedLanguage, AppLanguage.chinese);
    expect(find.text('选择您的语言'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language_code'), 'zh');

    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Explore Cambodia'), findsOneWidget);
    expect(find.text('探索'), findsOneWidget);

    await tester.tap(find.text('个人资料'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();
    expect(find.text('选择您的语言'), findsOneWidget);
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    expect(find.text('探索'), findsOneWidget);
  });
}
