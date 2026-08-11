import '../plan/reading_schedule.dart';
import 'slot_progress.dart';

/// The whole persisted state of the app, as one serializable document
/// (CLAUDE.md non-negotiable #5) so cloud sync can later upload it as-is.
class DawimState {
  const DawimState({
    this.schemaVersion = currentSchemaVersion,
    this.schedule,
    this.khatmahStartedOn,
    this.completedJuz = const {},
    this.completedSlotsByJuz = const {},
    this.slotProgress = const {},
  });

  factory DawimState.fromJson(Map<String, dynamic> json) {
    final rawSlots = (json['completedSlotsByJuz'] as Map<String, dynamic>?) ?? const {};
    final rawProgress = (json['slotProgress'] as Map<String, dynamic>?) ?? const {};
    return DawimState(
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      schedule: ReadingSchedule.fromName(json['schedule'] as String?),
      khatmahStartedOn: switch (json['khatmahStartedOn']) {
        final String iso => DateTime.parse(iso),
        _ => null,
      },
      completedJuz: ((json['completedJuz'] as List<dynamic>?) ?? const [])
          .map((e) => e as int)
          .toSet(),
      completedSlotsByJuz: rawSlots.map(
        (juz, slots) => MapEntry(
          int.parse(juz),
          (slots as List<dynamic>).map((e) => e as int).toSet(),
        ),
      ),
      slotProgress: rawProgress.map(
        (key, value) => MapEntry(key, SlotProgress.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  static String slotKey(int juzNumber, int slotIndex) => '$juzNumber:$slotIndex';

  /// Bumped whenever the persisted shape changes; read before parsing so a
  /// future version can migrate rather than guess.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final ReadingSchedule? schedule;
  final DateTime? khatmahStartedOn;

  /// Juz' the reader has finished, 1-30.
  final Set<int> completedJuz;

  /// Slot indices the reader has marked done, per juz'. Kept even after the
  /// juz' completes so the final slot stays undoable; [completedJuz] remains
  /// the authority on whether a juz' is finished.
  final Map<int, Set<int>> completedSlotsByJuz;

  /// Reading evidence per slot, keyed by [slotKey].
  final Map<String, SlotProgress> slotProgress;

  bool get hasSchedule => schedule != null;

  Set<int> completedSlotsFor(int juzNumber) => completedSlotsByJuz[juzNumber] ?? const {};

  SlotProgress progressFor(int juzNumber, int slotIndex) =>
      slotProgress[slotKey(juzNumber, slotIndex)] ?? const SlotProgress();

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'schedule': schedule?.name,
    'khatmahStartedOn': khatmahStartedOn?.toIso8601String(),
    'completedJuz': completedJuz.toList()..sort(),
    'completedSlotsByJuz': {
      for (final entry in completedSlotsByJuz.entries)
        '${entry.key}': entry.value.toList()..sort(),
    },
    'slotProgress': {
      for (final entry in slotProgress.entries) entry.key: entry.value.toJson(),
    },
  };

  /// Enforces the model's own rule — a juz' with every slot recorded done
  /// *is* a finished juz' — repairing any document that violates it. Applied
  /// on load so state written by an earlier build can't leave a juz' stuck
  /// showing all slots done while never completing.
  DawimState normalized() {
    final currentSchedule = schedule;
    if (currentSchedule == null || completedSlotsByJuz.isEmpty) return this;

    final finished = {...completedJuz};
    for (final entry in completedSlotsByJuz.entries) {
      if (entry.value.length >= currentSchedule.slotCount) finished.add(entry.key);
    }
    if (finished.length == completedJuz.length) return this;

    return copyWith(completedJuz: finished);
  }

  /// Applies a schedule choice. Records for *unfinished* juz' are dropped:
  /// slots are recorded by index, and index 0 of a 2-slot plan covers
  /// different pages than index 0 of a 4-slot plan, so carrying them over
  /// would both overstate progress and strand the juz' in a state where
  /// every visible slot reads done but the juz' never completes. Finished
  /// juz' are unaffected — a whole juz' means the same under either plan.
  DawimState withSchedule(ReadingSchedule newSchedule, DateTime now) {
    if (newSchedule == schedule) return this;
    return DawimState(
      schemaVersion: schemaVersion,
      schedule: newSchedule,
      khatmahStartedOn: khatmahStartedOn ?? now,
      completedJuz: completedJuz,
      completedSlotsByJuz: {
        for (final entry in completedSlotsByJuz.entries)
          if (completedJuz.contains(entry.key)) entry.key: entry.value,
      },
      slotProgress: {
        for (final entry in slotProgress.entries)
          if (completedJuz.contains(_juzOfKey(entry.key))) entry.key: entry.value,
      },
    );
  }

  /// Records a finished slot. Completing the last slot of a juz' finishes the
  /// juz'; the per-slot record is kept so the slot stays undoable.
  DawimState withSlotCompleted(int juzNumber, int slotIndex) {
    final currentSchedule = schedule;
    if (currentSchedule == null) return this;

    final slots = {...completedSlotsFor(juzNumber), slotIndex};
    return copyWith(
      completedJuz: slots.length >= currentSchedule.slotCount
          ? {...completedJuz, juzNumber}
          : completedJuz,
      completedSlotsByJuz: {...completedSlotsByJuz, juzNumber: slots},
    );
  }

  /// Undoes a slot the reader marked done — for the mis-tap. Only the *claim*
  /// is retracted: the reading evidence in [slotProgress] is untouched, so the
  /// slot can be re-marked immediately without reading it again. If that slot
  /// had finished the juz', the juz' reopens too.
  DawimState withSlotUncompleted(int juzNumber, int slotIndex) {
    final slots = {...completedSlotsFor(juzNumber)}..remove(slotIndex);
    return copyWith(
      completedJuz: {...completedJuz}..remove(juzNumber),
      completedSlotsByJuz: {...completedSlotsByJuz, juzNumber: slots},
    );
  }

  /// Notes that a page of a slot was shown, and remembers it as the resume
  /// point.
  DawimState withPageViewed(int juzNumber, int slotIndex, int page) {
    final key = slotKey(juzNumber, slotIndex);
    return copyWith(
      slotProgress: {...slotProgress, key: progressFor(juzNumber, slotIndex).withPageViewed(page)},
    );
  }

  /// Adds verified reading seconds to a page of a slot.
  DawimState withSecondsOnPage(int juzNumber, int slotIndex, int page, int seconds) {
    if (seconds <= 0) return this;
    final key = slotKey(juzNumber, slotIndex);
    return copyWith(
      slotProgress: {
        ...slotProgress,
        key: progressFor(juzNumber, slotIndex).withSecondsOnPage(page, seconds),
      },
    );
  }

  static int _juzOfKey(String key) => int.parse(key.split(':').first);

  DawimState copyWith({
    ReadingSchedule? schedule,
    DateTime? khatmahStartedOn,
    Set<int>? completedJuz,
    Map<int, Set<int>>? completedSlotsByJuz,
    Map<String, SlotProgress>? slotProgress,
  }) {
    return DawimState(
      schemaVersion: schemaVersion,
      schedule: schedule ?? this.schedule,
      khatmahStartedOn: khatmahStartedOn ?? this.khatmahStartedOn,
      completedJuz: completedJuz ?? this.completedJuz,
      completedSlotsByJuz: completedSlotsByJuz ?? this.completedSlotsByJuz,
      slotProgress: slotProgress ?? this.slotProgress,
    );
  }
}
