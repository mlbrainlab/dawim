import '../state/slot_progress.dart';
import 'daily_segment.dart';

/// Decides whether a passage has actually been read.
///
/// CLAUDE.md's reading-verification rule: the timer counts only while the
/// mushaf view advances at a plausible pace, pauses on app background and on
/// a static page position, and raw screen-open time is never the metric.
/// Pure logic, kept free of Flutter so it can be tested directly.
abstract final class ReadingVerifier {
  /// Roughly half the nominal reading pace — forgiving, but a passage can't
  /// be cleared by a glance.
  static const int secondsPerPage = 30;

  /// The most credit a single page can contribute. Without this ceiling a
  /// reader could park on one page and idle their way to the time gate.
  static const int maxSecondsCreditedPerPage = secondsPerPage * 2;

  /// No page turn for this long means the reader has stopped reading, so
  /// time stops accruing until they move again.
  static const int staticPageTimeoutSeconds = 120;

  static int requiredSecondsFor(ReadingSlot slot) => secondsPerPage * slot.pageCount;

  /// Verified seconds, with each page's contribution capped.
  static int creditedSeconds(SlotProgress progress) {
    var total = 0;
    for (final seconds in progress.secondsByPage.values) {
      total += seconds < maxSecondsCreditedPerPage ? seconds : maxSecondsCreditedPerPage;
    }
    return total;
  }

  /// How many of the slot's pages the reader has actually opened.
  static int pagesVisited(ReadingSlot slot, SlotProgress progress) {
    return progress.visitedPages
        .where((page) => page >= slot.firstPage && page <= slot.lastPage)
        .length;
  }

  /// A slot unlocks only when the reader has been through every page *and*
  /// spent the time — either alone is easy to fake.
  static bool isUnlocked(ReadingSlot slot, SlotProgress progress) {
    return pagesVisited(slot, progress) >= slot.pageCount &&
        creditedSeconds(progress) >= requiredSecondsFor(slot);
  }

  /// Whether the current second counts as reading.
  static bool shouldAccrue({
    required bool isForeground,
    required int currentPage,
    required ReadingSlot slot,
    required int secondsSinceLastPageChange,
  }) {
    if (!isForeground) return false;
    if (currentPage < slot.firstPage || currentPage > slot.lastPage) return false;
    return secondsSinceLastPageChange < staticPageTimeoutSeconds;
  }
}
