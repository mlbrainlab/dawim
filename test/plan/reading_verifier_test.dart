import 'package:dawim/plan/daily_segment.dart';
import 'package:dawim/plan/reading_schedule.dart';
import 'package:dawim/plan/reading_verifier.dart';
import 'package:dawim/state/slot_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const _slot = ReadingSlot(
  index: 0,
  anchor: SlotAnchor.afterDhuhr,
  firstPage: 1,
  lastPage: 6,
);

SlotProgress _progress(Map<int, int> secondsByPage) => SlotProgress(secondsByPage: secondsByPage);

/// Every page read for exactly [seconds].
SlotProgress _wholeSlotAt(int seconds) =>
    _progress({for (var page = _slot.firstPage; page <= _slot.lastPage; page++) page: seconds});

void main() {
  group('requiredSecondsFor', () {
    test('scales with the length of the passage', () {
      expect(ReadingVerifier.requiredSecondsFor(_slot), 6 * 30);
      expect(
        ReadingVerifier.requiredSecondsFor(
          const ReadingSlot(
            index: 0,
            anchor: SlotAnchor.morning,
            firstPage: 22,
            lastPage: 31,
          ),
        ),
        10 * 30,
      );
    });
  });

  group('isUnlocked', () {
    test('needs the whole passage covered, not just the time', () {
      // Two pages read at length: plenty of seconds, but four pages unseen.
      final progress = _progress({1: 200, 2: 200});
      expect(ReadingVerifier.creditedSeconds(progress), greaterThan(0));
      expect(ReadingVerifier.isUnlocked(_slot, progress), isFalse);
    });

    test('needs the time, not just page coverage', () {
      // Every page opened but immediately swiped past.
      expect(ReadingVerifier.isUnlocked(_slot, _wholeSlotAt(1)), isFalse);
    });

    test('unlocks when the passage is covered and the time is spent', () {
      expect(ReadingVerifier.isUnlocked(_slot, _wholeSlotAt(30)), isTrue);
    });

    test('idling on a single page cannot buy the unlock', () {
      // An hour parked on page 1 — the per-page cap keeps it worth 60s.
      final idled = _progress({1: 3600});
      expect(ReadingVerifier.creditedSeconds(idled), ReadingVerifier.maxSecondsCreditedPerPage);
      expect(ReadingVerifier.isUnlocked(_slot, idled), isFalse);

      // Even with every page visited, idling on one still falls short.
      final idledPlusGlances = _progress({1: 3600, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1});
      expect(ReadingVerifier.isUnlocked(_slot, idledPlusGlances), isFalse);
    });

    test('counts only pages inside the slot', () {
      final wrongPages = _progress({100: 60, 101: 60, 102: 60, 103: 60, 104: 60, 105: 60});
      expect(ReadingVerifier.pagesVisited(_slot, wrongPages), 0);
      expect(ReadingVerifier.isUnlocked(_slot, wrongPages), isFalse);
    });
  });

  group('shouldAccrue', () {
    bool accrue({
      bool isForeground = true,
      int currentPage = 3,
      int secondsSinceLastPageChange = 0,
    }) {
      return ReadingVerifier.shouldAccrue(
        isForeground: isForeground,
        currentPage: currentPage,
        slot: _slot,
        secondsSinceLastPageChange: secondsSinceLastPageChange,
      );
    }

    test('counts while reading inside the passage in the foreground', () {
      expect(accrue(), isTrue);
    });

    test('stops when the app is backgrounded', () {
      expect(accrue(isForeground: false), isFalse);
    });

    test('stops when the reader wanders outside the passage', () {
      expect(accrue(currentPage: 60), isFalse);
      expect(accrue(currentPage: 0), isFalse);
    });

    test('stops once the page has sat static past the threshold', () {
      expect(accrue(secondsSinceLastPageChange: ReadingVerifier.staticPageTimeoutSeconds - 1), isTrue);
      expect(accrue(secondsSinceLastPageChange: ReadingVerifier.staticPageTimeoutSeconds), isFalse);
    });
  });
}
