// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get chooseYourLanguage => 'Choose Your Language';

  @override
  String get languageSelectionSubtitle =>
      'Select your preferred language to explore the beauty of Cambodia.';

  @override
  String get continueButton => 'Continue';

  @override
  String get languageSettings => 'Language';

  @override
  String get homeTab => 'Home';

  @override
  String get exploreTab => 'Explore';

  @override
  String get mapTab => 'Map';

  @override
  String get savedTab => 'Saved';

  @override
  String get profileTab => 'Profile';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileDescription => 'Sign in to manage your profile and trips.';

  @override
  String get khmerLanguageName => 'Khmer';

  @override
  String get khmerLanguageNativeName => 'ភាសាខ្មែរ';

  @override
  String get englishLanguageName => 'English';

  @override
  String get englishLanguageNativeName => 'English';

  @override
  String get chineseLanguageName => 'Chinese';

  @override
  String get chineseLanguageNativeName => '中文';

  @override
  String languageSelected(String language) {
    return '$language selected';
  }
}
