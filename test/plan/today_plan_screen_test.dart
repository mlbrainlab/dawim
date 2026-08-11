import 'package:dawim/l10n/generated/app_localizations.dart';
import 'package:dawim/plan/reading_schedule.dart';
import 'package:dawim/plan/reading_verifier.dart';
import 'package:dawim/plan/screens/today_plan_screen.dart';
import 'package:dawim/quran/mushaf_providers.dart';
import 'package:dawim/quran/mushaf_repository.dart';
import 'package:dawim/state/app_state.dart';
import 'package:dawim/state/app_state_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a fixed state so the screen can be exercised without hive.
class _FakeAppState extends AppStateNotifier {
  _FakeAppState(this.initial);

  final DawimState initial;

  @override
  Future<DawimState> build() async => initial;
}

/// Juz' 1 on the 4-slot plan is pages 1-6 / 7-11 / 12-16 / 17-21.
DawimState _stateWithFirstSlot({required int secondsPerPage, required bool markedDone}) {
  var state = const DawimState(schedule: ReadingSchedule.fourSlots);
  for (var page = 1; page <= 6; page++) {
    state = state.withPageViewed(1, 0, page).withSecondsOnPage(1, 0, page, secondsPerPage);
  }
  return markedDone ? state.withSlotCompleted(1, 0) : state;
}

Future<void> _pumpScreen(WidgetTester tester, DawimState state) async {
  final repository = await tester.runAsync(MushafRepository.load);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mushafRepositoryProvider.overrideWith((ref) => repository!),
        appStateProvider.overrideWith(() => _FakeAppState(state)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TodayPlanScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The enabled/disabled state of the button on the first slot card.
bool _firstSlotButtonEnabled(WidgetTester tester, String label) {
  final button = tester.widget<TextButton>(
    find.ancestor(of: find.text(label).first, matching: find.byType(TextButton)).first,
  );
  return button.onPressed != null;
}

void main() {
  testWidgets('an unread slot is locked, and says how much is left', (tester) async {
    await _pumpScreen(tester, const DawimState(schedule: ReadingSchedule.fourSlots));

    expect(_firstSlotButtonEnabled(tester, 'Mark done'), isFalse);
    // Nothing read yet: 0 of 6 pages, 0:00 of the 3:00 a 6-page slot needs.
    expect(find.text('Page 0 of 6 · 0:00 of 3:00'), findsOneWidget);
  });

  testWidgets('a partly-read slot stays locked and shows real progress', (tester) async {
    var state = const DawimState(schedule: ReadingSchedule.fourSlots);
    for (var page = 1; page <= 3; page++) {
      state = state.withPageViewed(1, 0, page).withSecondsOnPage(1, 0, page, 20);
    }
    await _pumpScreen(tester, state);

    expect(_firstSlotButtonEnabled(tester, 'Mark done'), isFalse);
    expect(find.text('Page 3 of 6 · 1:00 of 3:00'), findsOneWidget);
  });

  testWidgets('a fully-read slot unlocks the button', (tester) async {
    await _pumpScreen(
      tester,
      _stateWithFirstSlot(secondsPerPage: ReadingVerifier.secondsPerPage, markedDone: false),
    );

    expect(_firstSlotButtonEnabled(tester, 'Mark done'), isTrue);
    expect(find.text('Ready to finish'), findsOneWidget);
  });

  testWidgets('a finished slot offers undo instead of mark-done', (tester) async {
    await _pumpScreen(
      tester,
      _stateWithFirstSlot(secondsPerPage: ReadingVerifier.secondsPerPage, markedDone: true),
    );

    expect(find.text('Undo'), findsOneWidget);
    // The other three slots still show their own locked buttons.
    expect(find.text('Mark done'), findsNWidgets(3));
  });
}
