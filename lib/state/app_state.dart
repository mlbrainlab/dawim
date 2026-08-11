import '../plan/reading_schedule.dart';

/// The whole persisted state of the app, as one serializable document
/// (CLAUDE.md non-negotiable #5) so cloud sync can later upload it as-is.
class DawimState {
  const DawimState({
    this.schemaVersion = currentSchemaVersion,
    this.schedule,
    this.khatmahStartedOn,
    this.completedJuz = const {},
    this.completedSlotsByJuz = const {},
  });

  factory DawimState.fromJson(Map<String, dynamic> json) {
    final rawSlots = (json['completedSlotsByJuz'] as Map<String, dynamic>?) ?? const {};
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
    );
  }

  /// Bumped whenever the persisted shape changes; read before parsing so a
  /// future version can migrate rather than guess.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final ReadingSchedule? schedule;
  final DateTime? khatmahStartedOn;

  /// Juz' the reader has finished, 1-30.
  final Set<int> completedJuz;

  /// Slot indices finished per juz', for juz' still in progress.
  final Map<int, Set<int>> completedSlotsByJuz;

  bool get hasSchedule => schedule != null;

  Set<int> completedSlotsFor(int juzNumber) => completedSlotsByJuz[juzNumber] ?? const {};

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'schedule': schedule?.name,
    'khatmahStartedOn': khatmahStartedOn?.toIso8601String(),
    'completedJuz': completedJuz.toList()..sort(),
    'completedSlotsByJuz': {
      for (final entry in completedSlotsByJuz.entries)
        '${entry.key}': entry.value.toList()..sort(),
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
    final inProgress = <int, Set<int>>{};
    for (final entry in completedSlotsByJuz.entries) {
      if (entry.value.length >= currentSchedule.slotCount) {
        finished.add(entry.key);
      } else {
        inProgress[entry.key] = entry.value;
      }
    }

    return copyWith(completedJuz: finished, completedSlotsByJuz: inProgress);
  }

  /// Applies a schedule choice. Any *in-progress* slot record is dropped:
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
      completedSlotsByJuz: const {},
    );
  }

  /// Records a finished slot. Completing the last slot of a juz' promotes it
  /// to a finished juz' and clears its per-slot record.
  DawimState withSlotCompleted(int juzNumber, int slotIndex) {
    final currentSchedule = schedule;
    if (currentSchedule == null) return this;

    final slots = {...completedSlotsFor(juzNumber), slotIndex};
    if (slots.length >= currentSchedule.slotCount) {
      return copyWith(
        completedJuz: {...completedJuz, juzNumber},
        completedSlotsByJuz: {...completedSlotsByJuz}..remove(juzNumber),
      );
    }
    return copyWith(
      completedSlotsByJuz: {...completedSlotsByJuz, juzNumber: slots},
    );
  }

  DawimState copyWith({
    ReadingSchedule? schedule,
    DateTime? khatmahStartedOn,
    Set<int>? completedJuz,
    Map<int, Set<int>>? completedSlotsByJuz,
  }) {
    return DawimState(
      schemaVersion: schemaVersion,
      schedule: schedule ?? this.schedule,
      khatmahStartedOn: khatmahStartedOn ?? this.khatmahStartedOn,
      completedJuz: completedJuz ?? this.completedJuz,
      completedSlotsByJuz: completedSlotsByJuz ?? this.completedSlotsByJuz,
    );
  }
}
