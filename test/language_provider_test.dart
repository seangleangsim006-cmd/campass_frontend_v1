import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_frontend/features/language/domain/models/app_language.dart';
import 'package:user_frontend/features/language/presentation/providers/language_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to English and restores a supported saved language', () async {
    final preferences = await SharedPreferences.getInstance();
    final defaultProvider = LanguageProvider();
    await defaultProvider.load();
    expect(defaultProvider.selectedLanguage, AppLanguage.english);
    var notifications = 0;
    defaultProvider.addListener(() => notifications++);
    expect(await defaultProvider.selectLanguage(AppLanguage.english), isTrue);
    expect(preferences.getString('app_language_code'), 'en');
    expect(notifications, 0);
    defaultProvider.dispose();

    await preferences.setString('app_language_code', 'km');
    final provider = LanguageProvider();

    await provider.load();

    expect(provider.selectedLanguage, AppLanguage.khmer);
    expect(provider.locale.languageCode, 'km');
    provider.dispose();
  });

  test('uses English when the saved language is missing or invalid', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('app_language_code', 'unknown');
    final provider = LanguageProvider();

    await provider.load();
    expect(provider.selectedLanguage, AppLanguage.english);

    await preferences.setInt('app_language_code', 7);
    await provider.load();
    expect(provider.selectedLanguage, AppLanguage.english);
    provider.dispose();
  });

  test(
    'persists changed language and avoids notifying for the same value',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final provider = LanguageProvider();
      await provider.load();
      var notifications = 0;
      provider.addListener(() => notifications++);

      expect(await provider.selectLanguage(AppLanguage.chinese), isTrue);
      expect(provider.selectedLanguage, AppLanguage.chinese);
      expect(preferences.getString('app_language_code'), 'zh');

      final notificationCount = notifications;
      expect(await provider.selectLanguage(AppLanguage.chinese), isTrue);
      expect(notifications, notificationCount);
      provider.dispose();
    },
  );
}
