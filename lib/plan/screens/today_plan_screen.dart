import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/digits.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../quran/screens/mushaf_reader_screen.dart';
import '../../state/app_state_providers.dart';
import '../daily_segment.dart';
import '../reading_schedule.dart';
import 'schedule_selection_screen.dart';

/// The day's task: one juz' split into the chosen schedule's slots.
/// Deliberately plain — milestone 6 replaces this with the 30-node path and
/// today's task card.
class TodayPlanScreen extends ConsumerWidget {
  const TodayPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final state = ref.watch(appStateProvider).valueOrNull;
    final segment = ref.watch(todaySegmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.todayPlanTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.changeSchedule,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ScheduleSelectionScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (segment) {
          null when state != null && state.completedJuz.length >= 30 => _KhatmahComplete(),
          null => const Center(child: CircularProgressIndicator()),
          final segment => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              Text(
                l10n.todayJuzLabel(localizedDigits(segment.juzNumber, locale)),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (final slot in segment.slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SlotCard(
                    slot: slot,
                    juzNumber: segment.juzNumber,
                    isDone: state?.completedSlotsFor(segment.juzNumber).contains(slot.index) ?? false,
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  const _SlotCard({required this.slot, required this.juzNumber, required this.isDone});

  final ReadingSlot slot;
  final int juzNumber;
  final bool isDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDone
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_anchorLabel(l10n, slot.anchor), style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.slotPagesLabel(
                    localizedDigits(slot.firstPage, locale),
                    localizedDigits(slot.lastPage, locale),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (isDone)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(l10n.slotDone, style: theme.textTheme.labelLarge),
                ],
              ),
            )
          else ...[
            // TEMPORARY: milestone 4 replaces this with completion earned by
            // timer-verified reading pace.
            TextButton(
              onPressed: () => ref
                  .read(appStateProvider.notifier)
                  .markSlotComplete(juzNumber, slot.index),
              child: Text(l10n.markSlotDone),
            ),
            IconButton(
              icon: const Icon(Icons.menu_book),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MushafReaderScreen(initialPage: slot.firstPage),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _anchorLabel(AppLocalizations l10n, SlotAnchor anchor) => switch (anchor) {
    SlotAnchor.morning => l10n.slotAnchorMorning,
    SlotAnchor.evening => l10n.slotAnchorEvening,
    SlotAnchor.afterDhuhr => l10n.slotAnchorAfterDhuhr,
    SlotAnchor.afterAsr => l10n.slotAnchorAfterAsr,
    SlotAnchor.afterMaghrib => l10n.slotAnchorAfterMaghrib,
    SlotAnchor.afterIsha => l10n.slotAnchorAfterIsha,
  };
}

class _KhatmahComplete extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.khatmahCompleteTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.khatmahCompleteBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
