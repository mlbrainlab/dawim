import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/digits.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../quran/mushaf_providers.dart';
import '../../quran/screens/mushaf_reader_screen.dart';
import '../../state/app_state.dart';
import '../../state/app_state_providers.dart';
import '../daily_segment.dart';
import '../plan_engine.dart';
import '../reading_session.dart';
import '../reading_verifier.dart';
import '../reading_schedule.dart';
import 'schedule_selection_screen.dart';

/// The day's task: one juz' split into the chosen schedule's slots, each
/// unlocked only by actually reading it.
///
/// Deliberately plain — milestone 6 replaces this with the 30-node path and
/// today's task card.
class TodayPlanScreen extends ConsumerStatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  ConsumerState<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends ConsumerState<TodayPlanScreen> {
  /// The juz' resolved when the screen opened. Pinning it means finishing the
  /// last slot doesn't yank the screen to the next juz' — the reader gets a
  /// "today is done" moment, and a mis-tapped final slot stays undoable.
  /// Re-entering the screen picks up wherever the reader now is.
  int? _pinnedJuz;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final state = ref.watch(appStateProvider).valueOrNull;
    final repository = ref.watch(mushafRepositoryProvider).valueOrNull;
    final schedule = state?.schedule;

    _pinnedJuz ??= state == null ? null : PlanEngine.activeJuz(state.completedJuz);

    final juzNumber = _pinnedJuz;
    final segment = (state == null || repository == null || schedule == null || juzNumber == null)
        ? null
        : PlanEngine.segmentForJuz(
            juzNumber: juzNumber,
            schedule: schedule,
            pageRange: repository.pageRangeForJuz(juzNumber),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.todayPlanTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.changeSchedule,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScheduleSelectionScreen()),
              );
              // The schedule may have changed the slot layout entirely.
              setState(() => _pinnedJuz = null);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: switch (segment) {
          null when state != null && state.completedJuz.length >= juzCount => const _KhatmahComplete(),
          null => const Center(child: CircularProgressIndicator()),
          final segment => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              Text(
                l10n.todayJuzLabel(localizedDigits(segment.juzNumber, locale)),
                style: theme.textTheme.headlineSmall,
              ),
              if (state!.completedJuz.contains(segment.juzNumber)) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.todayReadingComplete,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
              const SizedBox(height: 16),
              for (final slot in segment.slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SlotCard(state: state, juzNumber: segment.juzNumber, slot: slot),
                ),
            ],
          ),
        },
      ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  const _SlotCard({required this.state, required this.juzNumber, required this.slot});

  final DawimState state;
  final int juzNumber;
  final ReadingSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final progress = state.progressFor(juzNumber, slot.index);
    final isDone = state.completedSlotsFor(juzNumber).contains(slot.index);
    final isUnlocked = ReadingVerifier.isUnlocked(slot, progress);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MushafReaderScreen(
            // Resume where they left off, or the passage's first page.
            initialPage: progress.lastPage ?? slot.firstPage,
            slotRef: ReadingSlotRef(juzNumber: juzNumber, slot: slot),
          ),
        ),
      ),
      child: Container(
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
                  if (!isDone) ...[
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked
                          ? l10n.slotReadyToFinish
                          : l10n.slotReadingProgress(
                              localizedDigits(ReadingVerifier.pagesVisited(slot, progress), locale),
                              localizedDigits(slot.pageCount, locale),
                              _formatDuration(ReadingVerifier.creditedSeconds(progress), locale),
                              _formatDuration(ReadingVerifier.requiredSecondsFor(slot), locale),
                            ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUnlocked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isDone)
              TextButton.icon(
                onPressed: () =>
                    ref.read(appStateProvider.notifier).undoSlotComplete(juzNumber, slot.index),
                icon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
                label: Text(l10n.undoSlotDone),
              )
            else
              TextButton(
                // Stays disabled until the passage has actually been read.
                onPressed: isUnlocked
                    ? () => ref
                          .read(appStateProvider.notifier)
                          .markSlotComplete(juzNumber, slot.index)
                    : null,
                child: Text(l10n.markSlotDone),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds, Locale locale) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${localizedDigits(minutes, locale)}:'
        '${localizedDigits(remaining ~/ 10, locale)}${localizedDigits(remaining % 10, locale)}';
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
  const _KhatmahComplete();

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
