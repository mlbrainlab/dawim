import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../plan/screens/schedule_selection_screen.dart';
import '../plan/screens/today_plan_screen.dart';
import '../quran/screens/mushaf_reader_screen.dart';
import '../state/app_state_providers.dart';

/// Milestone 1 placeholder — verifies typography, RTL, and l10n wiring on
/// device. Replaced by the real 30-node progress path in milestone 6.
class PlaceholderHomeScreen extends ConsumerWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasSchedule = ref.watch(appStateProvider).valueOrNull?.hasSchedule ?? false;

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
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => hasSchedule
                            ? const TodayPlanScreen()
                            : const ScheduleSelectionScreen(),
                      ),
                    );
                  },
                  child: Text(hasSchedule ? l10n.todayPlanTitle : l10n.scheduleSelectionTitle),
                ),
                const SizedBox(height: 12),
                TextButton(
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
