import 'package:dawim/plan/plan_engine.dart';
import 'package:dawim/plan/reading_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('segmentForJuz', () {
    test('splits a juz into the schedule\'s slot count', () {
      for (final schedule in ReadingSchedule.values) {
        final segment = PlanEngine.segmentForJuz(
          juzNumber: 2,
          schedule: schedule,
          pageRange: (firstPage: 22, lastPage: 41),
        );
        expect(segment.slots, hasLength(schedule.slotCount));
        expect(segment.juzNumber, 2);
      }
    });

    test('slots are contiguous, gapless and cover the juz exactly', () {
      // Every real juz page span, including the 19/21/23-page outliers.
      const ranges = [
        (firstPage: 1, lastPage: 21), // 21 pages
        (firstPage: 22, lastPage: 41), // 20
        (firstPage: 102, lastPage: 120), // 19
        (firstPage: 582, lastPage: 604), // 23
      ];
      for (final range in ranges) {
        for (final schedule in ReadingSchedule.values) {
          final segment = PlanEngine.segmentForJuz(
            juzNumber: 1,
            schedule: schedule,
            pageRange: range,
          );
          expect(segment.slots.first.firstPage, range.firstPage);
          expect(segment.slots.last.lastPage, range.lastPage);
          for (var i = 1; i < segment.slots.length; i++) {
            expect(
              segment.slots[i].firstPage,
              segment.slots[i - 1].lastPage + 1,
              reason: 'slot $i must start right after the previous slot ends',
            );
          }
          final covered = segment.slots.fold(0, (sum, slot) => sum + slot.pageCount);
          expect(covered, range.lastPage - range.firstPage + 1);
        }
      }
    });

    test('remainder pages go to the earliest slots', () {
      // 21 pages over 4 slots -> 6/5/5/5.
      final segment = PlanEngine.segmentForJuz(
        juzNumber: 1,
        schedule: ReadingSchedule.fourSlots,
        pageRange: (firstPage: 1, lastPage: 21),
      );
      expect(segment.slots.map((s) => s.pageCount).toList(), [6, 5, 5, 5]);
      expect(segment.slots.map((s) => s.firstPage).toList(), [1, 7, 12, 17]);
      expect(segment.slots.map((s) => s.lastPage).toList(), [6, 11, 16, 21]);
    });

    test('carries the schedule anchors in order', () {
      final segment = PlanEngine.segmentForJuz(
        juzNumber: 1,
        schedule: ReadingSchedule.fourSlots,
        pageRange: (firstPage: 1, lastPage: 21),
      );
      expect(
        segment.slots.map((s) => s.anchor).toList(),
        ReadingSchedule.fourSlots.anchors,
      );
    });
  });

  group('activeJuz', () {
    test('is the first juz on fresh state', () {
      expect(PlanEngine.activeJuz(const {}), 1);
    });

    test('skips completed juz, adaptively — a missed day costs nothing', () {
      expect(PlanEngine.activeJuz({1, 2, 3}), 4);
      // Out-of-order completion still resolves to the lowest unfinished.
      expect(PlanEngine.activeJuz({1, 3, 4}), 2);
    });

    test('is null once the khatmah is complete', () {
      final all = {for (var juz = 1; juz <= juzCount; juz++) juz};
      expect(PlanEngine.activeJuz(all), isNull);
    });
  });
}
