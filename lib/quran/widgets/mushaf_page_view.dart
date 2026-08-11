import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../models/mushaf_line.dart';
import '../models/mushaf_page.dart';

const double _referenceFontSize = 24;
const double _ayahLineHeight = 1.8;
const double _surahNameFontSize = 22;
const double _surahNameVerticalPadding = 16;
const double _horizontalPadding = 8;
const double _verticalPadding = 8;

/// Renders a single mushaf page body. Ayah/basmallah lines are rendered
/// exactly as sourced from QUL, in KFGQPC Uthmanic Hafs — see CLAUDE.md
/// non-negotiable #1. Like the printed mushaf, non-centered lines are
/// justified edge-to-edge; the justification stretches only the gaps
/// between words (TextStyle.wordSpacing). Letterforms, letter spacing, and
/// kashida are never touched.
///
/// Each line in the source data is a real, precomputed mushaf line break —
/// it must always render on exactly one physical line, never wrap. The font
/// size is chosen so the page's widest line exactly fills the available
/// width (the print behavior), capped by the available height.
class MushafPageView extends StatelessWidget {
  const MushafPageView({super.key, required this.page});

  final MushafPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
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
              for (final line in page.lines)
                _MushafLineWidget(line: line, scale: scale, lineWidth: constraints.maxWidth),
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
      naturalHeight += _referenceFontSize * _ayahLineHeight;
      final width = _measureLineWidth(line.text!, _referenceFontSize);
      if (width > maxNaturalWidth) maxNaturalWidth = width;
    }

    if (naturalHeight <= 0 || maxNaturalWidth <= 0) return 1;

    // Widest line fills the width exactly; height is a hard cap.
    final widthScale = availableWidth / maxNaturalWidth;
    final heightScale = availableHeight / naturalHeight;
    return (widthScale < heightScale ? widthScale : heightScale).clamp(0.3, 2.0);
  }
}

double _measureLineWidth(String text, double fontSize, {double wordSpacing = 0}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: AppFonts.quran, fontSize: fontSize, wordSpacing: wordSpacing),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  return painter.width;
}

class _MushafLineWidget extends StatelessWidget {
  const _MushafLineWidget({required this.line, required this.scale, required this.lineWidth});

  final MushafLine line;
  final double scale;
  final double lineWidth;

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
        final fontSize = _referenceFontSize * scale;
        return Text(
          line.text!,
          textAlign: line.isCentered ? TextAlign.center : TextAlign.start,
          softWrap: false,
          style: TextStyle(
            fontFamily: AppFonts.quran,
            fontSize: fontSize,
            height: _ayahLineHeight,
            wordSpacing: line.isCentered ? 0 : _justifyWordSpacing(fontSize),
          ),
        );
    }
  }

  /// Extra space per word gap so the line exactly fills [lineWidth] —
  /// print-style justification. Word gaps only; letterforms untouched.
  double _justifyWordSpacing(double fontSize) {
    final gaps = ' '.allMatches(line.text!).length;
    if (gaps == 0) return 0;
    final naturalWidth = _measureLineWidth(line.text!, fontSize);
    final extra = lineWidth - naturalWidth - 0.5;
    if (extra <= 0) return 0;
    // A short line stretched too far looks broken; cap the gap growth and
    // let the line stay start-aligned past that point.
    final perGap = extra / gaps;
    final maxPerGap = fontSize * 1.5;
    return perGap > maxPerGap ? 0 : perGap;
  }
}
