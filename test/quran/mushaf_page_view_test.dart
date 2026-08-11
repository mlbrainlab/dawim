import 'package:dawim/l10n/generated/app_localizations.dart';
import 'package:dawim/quran/mushaf_font_loader.dart';
import 'package:dawim/quran/mushaf_providers.dart';
import 'package:dawim/quran/mushaf_repository.dart';
import 'package:dawim/quran/screens/mushaf_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Pre-resolving the repository and page-1 fonts (via tester.runAsync — the
// fake-async test zone never resolves real asset I/O) and overriding the
// provider avoids rendering the loading spinner, whose indeterminate
// animation would make pumpAndSettle time out.
Future<Widget> _appWithLoadedRepository(WidgetTester tester) async {
  final repository = await tester.runAsync(() async {
    final repo = await MushafRepository.load();
    await MushafFontLoader.instance.ensurePageLoaded(repo.pages.first);
    await MushafFontLoader.instance.ensurePageLoaded(repo.pages[1]);
    return repo;
  });
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
  testWidgets('mushaf reader renders page 1 in its page glyph font, never Roboto/Noto', (
    tester,
  ) async {
    await tester.pumpWidget(await _appWithLoadedRepository(tester));
    await tester.pumpAndSettle();

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    expect(textWidgets, isNotEmpty);

    var sawPageGlyphFont = false;
    for (final widget in textWidgets) {
      final family = widget.style?.fontFamily;
      if (family == null) continue;
      expect(family, isNot('Roboto'));
      expect(family.toLowerCase(), isNot(contains('noto')));
      if (family == MushafFontLoader.familyForPage(1)) sawPageGlyphFont = true;
    }
    expect(sawPageGlyphFont, isTrue, reason: 'expected at least one line in QCF4_P1');
  });

  testWidgets('mushaf reader is always RTL, independent of app locale', (tester) async {
    await tester.pumpWidget(await _appWithLoadedRepository(tester));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PageView));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
