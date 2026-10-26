// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get chooseYourLanguage => '选择您的语言';

  @override
  String get languageSelectionSubtitle => '选择您偏好的语言，探索柬埔寨之美。';

  @override
  String get continueButton => '继续';

  @override
  String get languageSettings => '语言';

  @override
  String get homeTab => '首页';

  @override
  String get exploreTab => '探索';

  @override
  String get mapTab => '地图';

  @override
  String get savedTab => '收藏';

  @override
  String get profileTab => '个人资料';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileDescription => '登录以管理您的个人资料和旅行。';

  @override
  String get khmerLanguageName => '高棉语';

  @override
  String get khmerLanguageNativeName => 'ភាសាខ្មែរ';

  @override
  String get englishLanguageName => '英语';

  @override
  String get englishLanguageNativeName => 'English';

  @override
  String get chineseLanguageName => '中文';

  @override
  String get chineseLanguageNativeName => '中文';

  @override
  String languageSelected(String language) {
    return '已选择$language';
  }
}
