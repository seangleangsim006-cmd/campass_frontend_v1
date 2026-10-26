import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_language.dart';

class LanguageProvider extends ChangeNotifier {
  static const _languageKey = 'app_language_code';

  SharedPreferences? _preferences;
  AppLanguage _selectedLanguage = AppLanguage.english;
  String? _persistenceError;
  Future<void> _pendingSave = Future<void>.value();

  AppLanguage get selectedLanguage => _selectedLanguage;
  Locale get locale => _selectedLanguage.locale;
  String? get persistenceError => _persistenceError;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    String? savedCode;
    try {
      savedCode = _preferences!.getString(_languageKey);
    } on TypeError {
      savedCode = null;
    }
    final restoredLanguage = AppLanguage.fromCode(savedCode);
    if (_selectedLanguage != restoredLanguage) {
      _selectedLanguage = restoredLanguage;
      notifyListeners();
    }
  }

  Future<bool> selectLanguage(AppLanguage language) async {
    if (_selectedLanguage == language) {
      return _persistUnchangedLanguage(language);
    }

    _selectedLanguage = language;
    _persistenceError = null;
    notifyListeners();

    var persisted = true;
    final save = _pendingSave.then((_) async {
      final previousError = _persistenceError;
      try {
        final preferences = _preferences ??=
            await SharedPreferences.getInstance();
        final saved = await preferences.setString(_languageKey, language.code);
        if (!saved) {
          _persistenceError = 'Could not save your language preference.';
          persisted = false;
        } else {
          _persistenceError = null;
        }
      } on Exception {
        _persistenceError = 'Could not save your language preference.';
        persisted = false;
      }
      if (previousError != _persistenceError) notifyListeners();
    });
    _pendingSave = save;
    await save;
    return persisted;
  }

  Future<bool> _persistUnchangedLanguage(AppLanguage language) async {
    final previousError = _persistenceError;
    var persisted = true;
    try {
      final preferences = _preferences ??=
          await SharedPreferences.getInstance();
      String? savedCode;
      try {
        savedCode = preferences.getString(_languageKey);
      } on TypeError {
        savedCode = null;
      }
      if (savedCode != language.code) {
        persisted = await preferences.setString(_languageKey, language.code);
      }
      _persistenceError = persisted
          ? null
          : 'Could not save your language preference.';
    } on Exception {
      persisted = false;
      _persistenceError = 'Could not save your language preference.';
    }
    if (previousError != _persistenceError) notifyListeners();
    return persisted;
  }
}
