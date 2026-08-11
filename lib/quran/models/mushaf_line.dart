enum MushafLineType { ayah, basmallah, surahName }

MushafLineType _parseLineType(String raw) {
  switch (raw) {
    case 'ayah':
      return MushafLineType.ayah;
    case 'basmallah':
      return MushafLineType.basmallah;
    case 'surah_name':
      return MushafLineType.surahName;
  }
  throw ArgumentError('Unknown mushaf line type: $raw');
}

class MushafLine {
  const MushafLine({
    required this.type,
    required this.isCentered,
    this.text,
    this.surahNumber,
    this.verseKeys,
  });

  factory MushafLine.fromJson(Map<String, dynamic> json) {
    return MushafLine(
      type: _parseLineType(json['type'] as String),
      isCentered: json['isCentered'] as bool,
      text: json['text'] as String?,
      surahNumber: json['surahNumber'] as int?,
      verseKeys: (json['verseKeys'] as List<dynamic>?)?.cast<String>(),
    );
  }

  final MushafLineType type;
  final bool isCentered;

  /// Set for [MushafLineType.ayah] (joined Uthmani text) and
  /// [MushafLineType.basmallah] (canonical basmalah text). For
  /// [MushafLineType.surahName] this is the Arabic surah name.
  final String? text;

  /// Set only for [MushafLineType.surahName].
  final int? surahNumber;

  /// Set only for [MushafLineType.ayah] — the verse key(s) this line spans.
  final List<String>? verseKeys;
}
