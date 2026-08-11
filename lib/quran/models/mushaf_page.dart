import 'mushaf_line.dart';

class MushafPage {
  const MushafPage({required this.pageNumber, required this.lines});

  factory MushafPage.fromJson(Map<String, dynamic> json) {
    return MushafPage(
      pageNumber: json['pageNumber'] as int,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => MushafLine.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int pageNumber;
  final List<MushafLine> lines;

  /// Verse key of the first ayah on this page, e.g. '2:6'. Every page has at
  /// least one ayah line.
  String get firstVerseKey =>
      lines.firstWhere((l) => l.type == MushafLineType.ayah).verseKeys!.first;
}
