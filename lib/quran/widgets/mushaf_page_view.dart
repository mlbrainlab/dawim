import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../models/mushaf_line.dart';
import '../models/mushaf_page.dart';

const double _ayahFontSize = 24;
const double _ayahLineHeight = 1.8;
const double _surahNameFontSize = 22;
const double _surahNameVerticalPadding = 16;
const double _pagePadding = 24; // 12 top + 12 bottom

/// Renders a single mushaf page. Ayah/basmallah lines are rendered exactly
/// as sourced from QUL, in KFGQPC Uthmanic Hafs, with no kashida, letter
/// spacing, or justification applied — see CLAUDE.md non-negotiable #1.
///
/// Each line in the source data is already a real, precomputed mushaf line
/// break — it must always render on exactly one physical line, never wrap
/// (wrapping would silently re-break lines the printed mushaf didn't break
/// there, and would blow past any height budget). Screen sizes vary, so the
/// font is scaled down just enough that both the widest line fits the
/// available width and all lines fit the available height.
class MushafPageView extends StatelessWidget {
  const MushafPageView({super.key, required this.page});

  final MushafPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = _fitScale(
            availableWidth: constraints.maxWidth,
            availableHeight: constraints.maxHeight,
          );
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final line in page.lines) _MushafLineWidget(line: line, scale: scale),
            ],
          );
        },
      ),
    );
  }

  double _fitScale({required double availableWidth, required double availableHeight}) {
    var naturalHeight = 0.0;
    var maxNaturalWidth = 0.0;
    for (final line in page.lines) {
      if (line.type == MushafLineType.surahName) {
        naturalHeight += _surahNameFontSize * 1.3 + _surahNameVerticalPadding;
        continue;
      }
      naturalHeight += _ayahFontSize * _ayahLineHeight;
      final painter = TextPainter(
        text: TextSpan(
          text: line.text,
          style: const TextStyle(fontFamily: AppFonts.quran, fontSize: _ayahFontSize),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      if (painter.width > maxNaturalWidth) maxNaturalWidth = painter.width;
    }

    if (naturalHeight <= 0) return 1;

    final heightScale = (availableHeight - _pagePadding) / naturalHeight;
    final widthScale = maxNaturalWidth <= 0 ? 1.0 : availableWidth / maxNaturalWidth;

    return [heightScale, widthScale, 1.0].reduce((a, b) => a < b ? a : b).clamp(0.3, 1.0);
  }
}

class _MushafLineWidget extends StatelessWidget {
  const _MushafLineWidget({required this.line, required this.scale});

  final MushafLine line;
  final double scale;

  @override
  Widget build(BuildContext context) {
    switch (line.type) {
      case MushafLineType.surahName:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: _surahNameVerticalPadding * scale / 2),
          child: Text(
            line.text!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.serifDisplay,
              fontSize: _surahNameFontSize * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case MushafLineType.basmallah:
      case MushafLineType.ayah:
        return Text(
          line.text!,
          textAlign: line.isCentered ? TextAlign.center : TextAlign.start,
          softWrap: false,
          style: TextStyle(
            fontFamily: AppFonts.quran,
            fontSize: _ayahFontSize * scale,
            height: _ayahLineHeight,
          ),
        );
    }
  }
}
