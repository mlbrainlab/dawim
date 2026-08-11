import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../plan/daily_segment.dart';
import '../plan/plan_engine.dart';
import '../plan/reading_schedule.dart';
import '../quran/mushaf_providers.dart';
import 'app_state.dart';
import 'app_state_repository.dart';

final appStateRepositoryProvider = FutureProvider<AppStateRepository>((ref) {
  return AppStateRepository.open();
});

/// The single write path for persisted state: every mutation goes through
/// here, so saving and in-memory state can never drift apart.
class AppStateNotifier extends AsyncNotifier<DawimState> {
  @override
  Future<DawimState> build() async {
    final repository = await ref.watch(appStateRepositoryProvider.future);
    return repository.load();
  }

  Future<void> setSchedule(ReadingSchedule schedule) {
    return _update((current) => current.withSchedule(schedule, DateTime.now()));
  }

  /// Records a finished slot; the last slot of a juz' completes the juz' and
  /// the reader moves on (see [PlanEngine.activeJuz]).
  Future<void> markSlotComplete(int juzNumber, int slotIndex) {
    return _update((current) => current.withSlotCompleted(juzNumber, slotIndex));
  }

  Future<void> _update(DawimState Function(DawimState) transform) async {
    final repository = await ref.read(appStateRepositoryProvider.future);
    final next = transform(state.requireValue);
    await repository.save(next);
    state = AsyncData(next);
  }
}

final appStateProvider = AsyncNotifierProvider<AppStateNotifier, DawimState>(
  AppStateNotifier.new,
);

/// The day's task, or null while data loads / before a schedule is chosen /
/// once the khatmah is complete.
final todaySegmentProvider = Provider<DailySegment?>((ref) {
  final state = ref.watch(appStateProvider).valueOrNull;
  final repository = ref.watch(mushafRepositoryProvider).valueOrNull;
  if (state == null || repository == null) return null;

  final schedule = state.schedule;
  if (schedule == null) return null;

  final juzNumber = PlanEngine.activeJuz(state.completedJuz);
  if (juzNumber == null) return null;

  return PlanEngine.segmentForJuz(
    juzNumber: juzNumber,
    schedule: schedule,
    pageRange: repository.pageRangeForJuz(juzNumber),
  );
});
