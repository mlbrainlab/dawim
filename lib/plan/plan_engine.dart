import 'daily_segment.dart';
import 'reading_schedule.dart';

/// The khatmah is 30 juz', one per reading day.
const int juzCount = 30;

/// Maps the khatmah onto daily tasks. Pure logic — it takes a juz' page
/// range rather than a repository so it stays free of asset loading and is
/// directly unit-testable.
abstract final class PlanEngine {
  /// Splits a juz' into the schedule's slots: contiguous, gapless page runs
  /// covering the whole juz'. Any remainder goes to the earliest slots, so a
  /// 21-page juz' on the 4-slot plan reads 6/5/5/5.
  static DailySegment segmentForJuz({
    required int juzNumber,
    required ReadingSchedule schedule,
    required ({int firstPage, int lastPage}) pageRange,
  }) {
    final totalPages = pageRange.lastPage - pageRange.firstPage + 1;
    final basePages = totalPages ~/ schedule.slotCount;
    final remainder = totalPages % schedule.slotCount;

    final slots = <ReadingSlot>[];
    var cursor = pageRange.firstPage;
    for (var index = 0; index < schedule.slotCount; index++) {
      final pages = basePages + (index < remainder ? 1 : 0);
      slots.add(
        ReadingSlot(
          index: index,
          anchor: schedule.anchors[index],
          firstPage: cursor,
          lastPage: cursor + pages - 1,
        ),
      );
      cursor += pages;
    }

    return DailySegment(juzNumber: juzNumber, slots: slots);
  }

  /// The juz' the reader is on: the lowest one not yet finished. The khatmah
  /// is adaptive — a missed day costs nothing, it just moves later. Returns
  /// null once all 30 are done.
  static int? activeJuz(Set<int> completedJuz) {
    for (var juz = 1; juz <= juzCount; juz++) {
      if (!completedJuz.contains(juz)) return juz;
    }
    return null;
  }
}
