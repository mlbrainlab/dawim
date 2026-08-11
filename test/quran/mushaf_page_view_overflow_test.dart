import 'package:dawim/quran/mushaf_repository.dart';
import 'package:dawim/quran/widgets/mushaf_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MushafRepository repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repository = await MushafRepository.load();
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
    // line budget — the densest, most overflow-prone case (regression test
    // for a real bug found on-device: RenderFlex overflowed by 68 pixels).
    await pumpPage(tester, 3, viewport: const Size(360, 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the single widest line in the whole mushaf never overflows a phone width', (
    tester,
  ) async {
    // Page 565 has the longest single line (113 chars) across all 604 pages.
    await pumpPage(tester, 565, viewport: const Size(360, 700));
    expect(tester.takeException(), isNull);
  });
}
