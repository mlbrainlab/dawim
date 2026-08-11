import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../quran/screens/mushaf_reader_screen.dart';

/// Milestone 1 placeholder — verifies typography, RTL, and l10n wiring on
/// device. Replaced by the real 30-node progress path in milestone 6.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.appTitle, style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 12),
                Text(
                  l10n.tagline,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.placeholderScaffoldMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const MushafReaderScreen()),
                    );
                  },
                  child: Text(l10n.openMushafButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
