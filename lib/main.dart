import 'package:flutter/material.dart';

import 'app.dart';
import 'features/language/presentation/providers/language_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageProvider = LanguageProvider();
  await languageProvider.load();
  runApp(KhmerCompassApp(languageProvider: languageProvider));
}
