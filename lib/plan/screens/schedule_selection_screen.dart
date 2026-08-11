import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/app_state_providers.dart';
import '../reading_schedule.dart';

class ScheduleSelectionScreen extends ConsumerWidget {
  const ScheduleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentSchedule = ref.watch(appStateProvider).valueOrNull?.schedule;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            Text(l10n.scheduleSelectionTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.scheduleSelectionSubtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            for (final schedule in ReadingSchedule.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScheduleCard(
                  schedule: schedule,
                  isSelected: schedule == currentSchedule,
                  onTap: () async {
                    await ref.read(appStateProvider.notifier).setSchedule(schedule);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.isSelected,
    required this.onTap,
  });

  final ReadingSchedule schedule;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final (name, description) = switch (schedule) {
      ReadingSchedule.twoSlots => (
        l10n.scheduleTwoSlotsName,
        l10n.scheduleTwoSlotsDescription,
      ),
      ReadingSchedule.fourSlots => (
        l10n.scheduleFourSlotsName,
        l10n.scheduleFourSlotsDescription,
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
