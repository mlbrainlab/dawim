import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'screens/placeholder_home_screen.dart';
import 'theme/app_theme.dart';

class DawimApp extends StatelessWidget {
  const DawimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PlaceholderHomeScreen(),
    );
  }
}
