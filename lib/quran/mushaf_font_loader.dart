import 'package:flutter/services.dart';

import 'models/mushaf_line.dart';
import 'models/mushaf_page.dart';

/// Lazily loads the KFGQPC QPC V4 per-page glyph fonts (one font per mushaf
/// page, bundled under assets/fonts/qcf4/). 604 fonts can't reasonably be
/// declared in pubspec's `fonts:` section, and eagerly loading them all
/// would waste memory — each page's font is registered with the engine the
/// first time that page is about to render.
class MushafFontLoader {
  MushafFontLoader._();

  static final MushafFontLoader instance = MushafFontLoader._();

  final Map<int, Future<void>> _loads = {};
  final Map<int, Future<void>> _pageLoads = {};
  final Set<int> _readyPages = {};

  /// True once everything [ensurePageLoaded] needs for this page has
  /// finished loading — lets callers skip the async path entirely.
  bool isPageReady(int pageNumber) => _readyPages.contains(pageNumber);

  static String familyForPage(int pageNumber) => 'QCF4_P$pageNumber';

  /// The font family a given line renders in. Basmalah lines use page 1's
  /// font (they are Al-Fatihah's basmalah glyphs); ayah lines use their own
  /// page's font.
  static String familyForLine(MushafLine line, int pageNumber) =>
      line.type == MushafLineType.basmallah ? familyForPage(1) : familyForPage(pageNumber);

  /// Loads everything [page] needs to render: its own font, plus page 1's
  /// font when the page contains a basmalah line. Each font is loaded once
  /// per session. Memoized per page so repeated calls (e.g. from a
  /// FutureBuilder rebuilding) always receive the same future instance.
  Future<void> ensurePageLoaded(MushafPage page) {
    return _pageLoads.putIfAbsent(page.pageNumber, () {
      final futures = <Future<void>>[_ensureFontLoaded(page.pageNumber)];
      if (page.lines.any((l) => l.type == MushafLineType.basmallah)) {
        futures.add(_ensureFontLoaded(1));
      }
      return Future.wait(futures).then((_) => _readyPages.add(page.pageNumber));
    });
  }

  Future<void> _ensureFontLoaded(int pageNumber) {
    return _loads.putIfAbsent(pageNumber, () {
      final loader = FontLoader(familyForPage(pageNumber))
        ..addFont(rootBundle.load('assets/fonts/qcf4/p$pageNumber.ttf'));
      return loader.load();
    });
  }
}
