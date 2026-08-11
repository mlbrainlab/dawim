import 'package:dawim/l10n/generated/app_localizations.dart';
import 'package:dawim/quran/mushaf_providers.dart';
import 'package:dawim/quran/mushaf_repository.dart';
import 'package:dawim/quran/screens/mushaf_reader_screen.dart';
import 'package:dawim/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Pre-resolving the repository and overriding the provider with it avoids
// ever rendering the loading spinner: an indeterminate CircularProgressIndicator
// animates forever, which makes pumpAndSettle() time out.
//
// The load itself must run via tester.runAsync(): testWidgets() executes in a
// fake-async zone that never resolves genuine platform-channel I/O (asset
// loading) unless it's explicitly escaped.
Future<Widget> _appWithLoadedRepository(WidgetTester tester) async {
  final repository = await tester.runAsync(() => MushafRepository.load());
  return ProviderScope(
    overrides: [mushafRepositoryProvider.overrideWith((ref) => repository!)],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MushafReaderScreen(),
    ),
  );
}

void main() {
  testWidgets('mushaf reader renders page 1 in the Quran font, never Roboto/Noto', (tester) async {
    await tester.pumpWidget(await _appWithLoadedRepository(tester));
    await tester.pumpAndSettle();

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    expect(textWidgets, isNotEmpty);

    var sawQuranFont = false;
    for (final widget in textWidgets) {
      final family = widget.style?.fontFamily;
      if (family == null) continue;
      expect(family, isNot('Roboto'));
      expect(family.toLowerCase(), isNot(contains('noto')));
      if (family == AppFonts.quran) sawQuranFont = true;
    }
    expect(sawQuranFont, isTrue, reason: 'expected at least one line in AppFonts.quran');
  });

  testWidgets('mushaf reader is always RTL, independent of app locale', (tester) async {
    await tester.pumpWidget(await _appWithLoadedRepository(tester));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PageView));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
