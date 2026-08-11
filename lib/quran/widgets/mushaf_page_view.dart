import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../models/mushaf_line.dart';
import '../models/mushaf_page.dart';
import '../mushaf_font_loader.dart';

const double _referenceFontSize = 24;
const double _ayahLineHeight = 1.7;
const int _linesPerPage = 15;
const double _horizontalPadding = 8;
const double _verticalPadding = 8;

/// Renders a single mushaf page body using the KFGQPC QPC V4 per-page glyph
/// fonts — the print's own typesetting, so lines fill their width by design
/// with no justification applied by us (CLAUDE.md non-negotiable #1). The
/// page's font must already be loaded (MushafFontLoader.ensurePageLoaded)
/// before this widget builds, or glyphs would measure/render wrong.
///
/// Layout mirrors the print: the page height is divided into 15 equal line
/// slots (vertical overflow is impossible by construction — dense pages use
/// one Expanded per line). The ornament pages (1-2) have only 8 lines and
/// render as a compact centered block of fixed-height slots. One data line
/// always renders as exactly one physical line (softWrap: false).
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
          final slotHeight = constraints.maxHeight / _linesPerPage;
          final fontSize = _ayahFontSize(constraints.maxWidth, slotHeight);
          final isSparsePage = page.lines.length < _linesPerPage;

          return Column(
            mainAxisAlignment: isSparsePage ? MainAxisAlignment.center : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final line in page.lines)
                if (isSparsePage)
                  SizedBox(
                    height: slotHeight,
                    child: _MushafLineWidget(line: line, page: page, fontSize: fontSize),
                  )
                else
                  Expanded(
                    child: _MushafLineWidget(line: line, page: page, fontSize: fontSize),
                  ),
            ],
          );
        },
      ),
    );
  }

  /// The page-wide ayah font size: the widest line exactly fills the width,
  /// capped so a line box always fits its slot.
  double _ayahFontSize(double availableWidth, double slotHeight) {
    var maxNaturalWidth = 0.0;
    for (final line in page.lines) {
      if (line.type == MushafLineType.surahName) continue;
      final painter = TextPainter(
        text: TextSpan(
          text: line.text,
          style: TextStyle(
            fontFamily: MushafFontLoader.familyForLine(line, page.pageNumber),
            fontSize: _referenceFontSize,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      if (painter.width > maxNaturalWidth) maxNaturalWidth = painter.width;
    }
    if (maxNaturalWidth <= 0) return _referenceFontSize;

    final widthFit = _referenceFontSize * availableWidth / maxNaturalWidth;
    final heightFit = slotHeight / _ayahLineHeight;
    return widthFit < heightFit ? widthFit : heightFit;
  }
}

class _MushafLineWidget extends StatelessWidget {
  const _MushafLineWidget({required this.line, required this.page, required this.fontSize});

  final MushafLine line;
  final MushafPage page;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    switch (line.type) {
      case MushafLineType.surahName:
        // FittedBox guarantees the header fits its slot whatever the
        // Thmanyah metrics are.
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              line.text!,
              style: TextStyle(
                fontFamily: AppFonts.serifDisplay,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      case MushafLineType.basmallah:
      case MushafLineType.ayah:
        return Align(
          alignment: line.isCentered ? Alignment.center : AlignmentDirectional.centerStart,
          child: Text(
            line.text!,
            softWrap: false,
            style: TextStyle(
              fontFamily: MushafFontLoader.familyForLine(line, page.pageNumber),
              fontSize: fontSize,
              height: _ayahLineHeight,
            ),
          ),
        );
    }
  }
}
