// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get chooseYourLanguage => 'ជ្រើសរើសភាសារបស់អ្នក';

  @override
  String get languageSelectionSubtitle =>
      'ជ្រើសរើសភាសាដែលអ្នកចូលចិត្ត ដើម្បីស្វែងយល់ពីសម្រស់នៃប្រទេសកម្ពុជា។';

  @override
  String get continueButton => 'បន្ត';

  @override
  String get languageSettings => 'ភាសា';

  @override
  String get homeTab => 'ទំព័រដើម';

  @override
  String get exploreTab => 'ស្វែងយល់';

  @override
  String get mapTab => 'ផែនទី';

  @override
  String get savedTab => 'បានរក្សាទុក';

  @override
  String get profileTab => 'ប្រវត្តិរូប';

  @override
  String get profileTitle => 'ប្រវត្តិរូបរបស់អ្នក';

  @override
  String get profileDescription =>
      'ចូលគណនីដើម្បីគ្រប់គ្រងប្រវត្តិរូប និងដំណើរកម្សាន្តរបស់អ្នក។';

  @override
  String get khmerLanguageName => 'ខ្មែរ';

  @override
  String get khmerLanguageNativeName => 'ភាសាខ្មែរ';

  @override
  String get englishLanguageName => 'អង់គ្លេស';

  @override
  String get englishLanguageNativeName => 'English';

  @override
  String get chineseLanguageName => 'ចិន';

  @override
  String get chineseLanguageNativeName => '中文';

  @override
  String languageSelected(String language) {
    return 'បានជ្រើសរើស $language';
  }
}
