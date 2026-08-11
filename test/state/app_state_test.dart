import 'package:dawim/plan/reading_schedule.dart';
import 'package:dawim/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fresh state has no schedule and no progress', () {
    const state = DawimState();
    expect(state.hasSchedule, isFalse);
    expect(state.completedJuz, isEmpty);
    expect(state.schemaVersion, DawimState.currentSchemaVersion);
  });

  test('round-trips through JSON with every field preserved', () {
    final original = DawimState(
      schedule: ReadingSchedule.fourSlots,
      khatmahStartedOn: DateTime.utc(2026, 8, 11, 9, 30),
      completedJuz: {1, 2, 5},
      completedSlotsByJuz: {
        3: {0, 2},
        7: {1},
      },
    );

    final restored = DawimState.fromJson(original.toJson());

    expect(restored.schemaVersion, DawimState.currentSchemaVersion);
    expect(restored.schedule, ReadingSchedule.fourSlots);
    expect(restored.khatmahStartedOn, original.khatmahStartedOn);
    expect(restored.completedJuz, {1, 2, 5});
    expect(restored.completedSlotsByJuz, {
      3: {0, 2},
      7: {1},
    });
  });

  test('writes a schema version so future migrations have something to branch on', () {
    expect(const DawimState().toJson()['schemaVersion'], DawimState.currentSchemaVersion);
  });

  test('parses a document written before any progress existed', () {
    final restored = DawimState.fromJson({
      'schemaVersion': 1,
      'schedule': 'twoSlots',
      'khatmahStartedOn': null,
      'completedJuz': <int>[],
      'completedSlotsByJuz': <String, dynamic>{},
    });
    expect(restored.schedule, ReadingSchedule.twoSlots);
    expect(restored.khatmahStartedOn, isNull);
    expect(restored.completedSlotsFor(1), isEmpty);
  });

  group('withSlotCompleted', () {
    test('records slots until the last one completes the juz', () {
      var state = const DawimState(schedule: ReadingSchedule.fourSlots);

      state = state.withSlotCompleted(1, 0);
      expect(state.completedSlotsFor(1), {0});
      expect(state.completedJuz, isEmpty);

      state = state.withSlotCompleted(1, 1).withSlotCompleted(1, 2);
      expect(state.completedJuz, isEmpty);

      state = state.withSlotCompleted(1, 3);
      expect(state.completedJuz, {1});
      expect(
        state.completedSlotsFor(1),
        {0, 1, 2, 3},
        reason: 'the record is kept so the final slot stays undoable',
      );
    });
  });

  group('withSlotUncompleted', () {
    test('retracts the claim but keeps the reading evidence', () {
      final read = const DawimState(schedule: ReadingSchedule.fourSlots)
          .withPageViewed(1, 0, 3)
          .withSecondsOnPage(1, 0, 3, 45)
          .withSlotCompleted(1, 0);
      expect(read.completedSlotsFor(1), {0});

      final undone = read.withSlotUncompleted(1, 0);
      expect(undone.completedSlotsFor(1), isEmpty);
      expect(
        undone.progressFor(1, 0).secondsByPage,
        {3: 45},
        reason: 'an accidental undo must not force a re-read',
      );
    });

    test('reopens a juz when its finishing slot is undone', () {
      var state = const DawimState(schedule: ReadingSchedule.twoSlots)
          .withSlotCompleted(2, 0)
          .withSlotCompleted(2, 1);
      expect(state.completedJuz, {2});

      state = state.withSlotUncompleted(2, 1);
      expect(state.completedJuz, isEmpty);
      expect(state.completedSlotsFor(2), {0});
    });
  });

  group('reading progress', () {
    test('round-trips through JSON', () {
      final original = const DawimState(schedule: ReadingSchedule.twoSlots)
          .withPageViewed(3, 1, 50)
          .withSecondsOnPage(3, 1, 50, 20)
          .withSecondsOnPage(3, 1, 51, 15);

      final restored = DawimState.fromJson(original.toJson());
      final progress = restored.progressFor(3, 1);
      expect(progress.secondsByPage, {50: 20, 51: 15});
      expect(progress.lastPage, 50);
    });

    test('viewing a page records it and remembers the resume point', () {
      final state = const DawimState().withPageViewed(1, 0, 5);
      expect(state.progressFor(1, 0).visitedPages, {5});
      expect(state.progressFor(1, 0).lastPage, 5);
    });

    test('re-viewing a page keeps its accrued seconds', () {
      final state = const DawimState()
          .withSecondsOnPage(1, 0, 5, 30)
          .withPageViewed(1, 0, 5);
      expect(state.progressFor(1, 0).secondsByPage, {5: 30});
    });
  });

  group('withSchedule', () {
    test('sets the schedule and stamps the khatmah start once', () {
      final started = DateTime.utc(2026, 8, 11);
      final state = const DawimState().withSchedule(ReadingSchedule.twoSlots, started);
      expect(state.schedule, ReadingSchedule.twoSlots);
      expect(state.khatmahStartedOn, started);

      final later = state.withSchedule(ReadingSchedule.fourSlots, DateTime.utc(2026, 9, 1));
      expect(later.khatmahStartedOn, started, reason: 'the khatmah start is not reset');
    });

    test('drops in-progress slots so a switched plan cannot strand a juz', () {
      // Regression: slots are recorded by index. Two of four slots done, then
      // a switch to the 2-slot plan reinterpreted indices {0,1} as *both*
      // slots of the new plan — every visible slot read "done" while the juz'
      // never completed, leaving no way to finish it.
      final midJuz = const DawimState(schedule: ReadingSchedule.fourSlots)
          .withSlotCompleted(2, 0)
          .withSlotCompleted(2, 1);
      expect(midJuz.completedSlotsFor(2), {0, 1});

      final switched = midJuz.withSchedule(ReadingSchedule.twoSlots, DateTime.utc(2026, 8, 11));
      expect(switched.completedSlotsFor(2), isEmpty);

      // The juz' is completable again under the new plan.
      final finished = switched.withSlotCompleted(2, 0).withSlotCompleted(2, 1);
      expect(finished.completedJuz, {2});
    });

    test('keeps finished juz across a schedule change', () {
      final state = const DawimState(
        schedule: ReadingSchedule.fourSlots,
        completedJuz: {1, 2},
      ).withSchedule(ReadingSchedule.twoSlots, DateTime.utc(2026, 8, 11));
      expect(state.completedJuz, {1, 2});
    });

    test('re-picking the same schedule leaves progress untouched', () {
      final state = const DawimState(schedule: ReadingSchedule.fourSlots)
          .withSlotCompleted(3, 0)
          .withSchedule(ReadingSchedule.fourSlots, DateTime.utc(2026, 8, 11));
      expect(state.completedSlotsFor(3), {0});
    });
  });

  group('normalized', () {
    test('repairs a juz stranded with every slot done by an earlier build', () {
      // Exactly the document seen on device: two slots recorded under the
      // 4-slot plan, then switched to the 2-slot plan, so both of the new
      // plan's slots read done while the juz' stayed unfinished.
      const stranded = DawimState(
        schedule: ReadingSchedule.twoSlots,
        completedJuz: {1},
        completedSlotsByJuz: {
          2: {0, 1},
        },
      );

      final repaired = stranded.normalized();
      expect(repaired.completedJuz, {1, 2});
    });

    test('leaves genuinely partial progress alone', () {
      const partial = DawimState(
        schedule: ReadingSchedule.fourSlots,
        completedSlotsByJuz: {
          3: {0, 1},
        },
      );
      expect(partial.normalized().completedJuz, isEmpty);
      expect(partial.normalized().completedSlotsFor(3), {0, 1});
    });

    test('is a no-op before a schedule is chosen', () {
      const state = DawimState();
      expect(state.normalized().completedJuz, isEmpty);
    });
  });

  test('copyWith preserves untouched fields', () {
    const original = DawimState(schedule: ReadingSchedule.twoSlots, completedJuz: {1});
    final updated = original.copyWith(completedJuz: {1, 2});
    expect(updated.schedule, ReadingSchedule.twoSlots);
    expect(updated.completedJuz, {1, 2});
  });
}
