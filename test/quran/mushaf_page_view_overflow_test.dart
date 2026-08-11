import 'package:dawim/quran/mushaf_font_loader.dart';
import 'package:dawim/quran/mushaf_repository.dart';
import 'package:dawim/quran/widgets/mushaf_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MushafRepository repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repository = await MushafRepository.load();
    for (final pageNumber in [3, 565]) {
      await MushafFontLoader.instance.ensurePageLoaded(
        repository.pages.firstWhere((p) => p.pageNumber == pageNumber),
      );
    }
  });

  Future<void> pumpPage(WidgetTester tester, int pageNumber, {required Size viewport}) async {
    final page = repository.pages.firstWhere((p) => p.pageNumber == pageNumber);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: MushafPageView(page: page),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a full 15-ayah-line page never overflows on a small phone body height', (
    tester,
  ) async {
    // Page 3: 15 lines, all type ayah, no surah-name header to shrink the
    // line budget — the densest, most overflow-prone case.
    await pumpPage(tester, 3, viewport: const Size(360, 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page with the longest line in the mushaf never overflows a phone width', (
    tester,
  ) async {
    await pumpPage(tester, 565, viewport: const Size(360, 700));
    expect(tester.takeException(), isNull);
  });
}
