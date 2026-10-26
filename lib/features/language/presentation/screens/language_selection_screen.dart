import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/app_language.dart';
import '../providers/language_provider.dart';

const _primary = Color(0xFFFF6B00);
const _background = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF202124);
const _secondaryText = Color(0xFF737373);
const _border = Color(0xFFE8E8E8);

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({
    super.key,
    this.requireAuthentication = false,
  });

  final bool requireAuthentication;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.home);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: _primaryText,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    strings.chooseYourLanguage,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.languageSelectionSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _secondaryText,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 30),
                  for (final language in AppLanguage.values) ...[
                    _LanguageOption(
                      language: language,
                      isSelected: languageProvider.selectedLanguage == language,
                      onTap: () => _selectLanguage(context, language),
                    ),
                    if (language != AppLanguage.values.last)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => requireAuthentication
                      ? context.go(RouteNames.login)
                      : context.goNamed(RouteNames.exploreRouteName),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(strings.continueButton),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage(
    BuildContext context,
    AppLanguage language,
  ) async {
    final saved = await context.read<LanguageProvider>().selectLanguage(
      language,
    );
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().persistenceError ??
                'Could not save your language preference.',
          ),
        ),
      );
    }
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final (englishName, nativeName, flag) = switch (language) {
      AppLanguage.khmer => (
        strings.khmerLanguageName,
        strings.khmerLanguageNativeName,
        '🇰🇭',
      ),
      AppLanguage.english => (
        strings.englishLanguageName,
        strings.englishLanguageNativeName,
        '🇬🇧',
      ),
      AppLanguage.chinese => (
        strings.chineseLanguageName,
        strings.chineseLanguageNativeName,
        '🇨🇳',
      ),
    };
    final label = '$englishName — $nativeName';

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primary.withValues(alpha: 0.07)
                  : _background,
              border: Border.all(
                color: isSelected ? _primary : _border,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        englishName,
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nativeName,
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('selected'),
                          color: _primary,
                          size: 24,
                        )
                      : const Icon(
                          Icons.circle_outlined,
                          key: ValueKey('unselected'),
                          color: _border,
                          size: 24,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
