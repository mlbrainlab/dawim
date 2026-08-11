import 'reading_schedule.dart';

/// One sitting: a contiguous run of mushaf pages due at a given anchor.
class ReadingSlot {
  const ReadingSlot({
    required this.index,
    required this.anchor,
    required this.firstPage,
    required this.lastPage,
  });

  /// Position within the day, 0-based.
  final int index;
  final SlotAnchor anchor;
  final int firstPage;
  final int lastPage;

  int get pageCount => lastPage - firstPage + 1;
}

/// A day's task: one juz', split into the schedule's slots.
class DailySegment {
  const DailySegment({required this.juzNumber, required this.slots});

  final int juzNumber;
  final List<ReadingSlot> slots;

  int get firstPage => slots.first.firstPage;
  int get lastPage => slots.last.lastPage;
}
