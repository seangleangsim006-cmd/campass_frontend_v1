import 'package:flutter/widgets.dart';

enum AppLanguage {
  khmer(code: 'km', locale: Locale('km')),
  english(code: 'en', locale: Locale('en')),
  chinese(code: 'zh', locale: Locale('zh'));

  const AppLanguage({required this.code, required this.locale});

  final String code;
  final Locale locale;

  static AppLanguage fromCode(String? code) {
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.english;
  }
}
