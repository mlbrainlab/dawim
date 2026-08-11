/// When a reading slot is nominally due. These are anchors only — milestone 5
/// binds the prayer-relative ones to times computed by adhan_dart.
enum SlotAnchor { morning, evening, afterDhuhr, afterAsr, afterMaghrib, afterIsha }

/// The two daily plans from the product spec: 20 minutes a day, split either
/// into 2 longer sittings or 4 short ones anchored to prayers.
enum ReadingSchedule {
  twoSlots(minutesPerSlot: 10, anchors: [SlotAnchor.morning, SlotAnchor.evening]),
  fourSlots(
    minutesPerSlot: 5,
    anchors: [
      SlotAnchor.afterDhuhr,
      SlotAnchor.afterAsr,
      SlotAnchor.afterMaghrib,
      SlotAnchor.afterIsha,
    ],
  );

  const ReadingSchedule({required this.minutesPerSlot, required this.anchors});

  final int minutesPerSlot;
  final List<SlotAnchor> anchors;

  int get slotCount => anchors.length;

  static ReadingSchedule? fromName(String? name) {
    for (final schedule in values) {
      if (schedule.name == name) return schedule;
    }
    return null;
  }
}
