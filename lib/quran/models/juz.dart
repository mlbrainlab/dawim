class Juz {
  const Juz({
    required this.juzNumber,
    required this.firstVerseKey,
    required this.lastVerseKey,
    required this.versesCount,
    required this.verseMapping,
  });

  factory Juz.fromJson(Map<String, dynamic> json) {
    final rawMapping = json['verse_mapping'] as Map<String, dynamic>;
    final mapping = <int, (int, int)>{};
    for (final entry in rawMapping.entries) {
      final surah = int.parse(entry.key);
      final range = (entry.value as String).split('-');
      mapping[surah] = (int.parse(range[0]), int.parse(range[1]));
    }
    return Juz(
      juzNumber: json['juz_number'] as int,
      firstVerseKey: json['first_verse_key'] as String,
      lastVerseKey: json['last_verse_key'] as String,
      versesCount: json['verses_count'] as int,
      verseMapping: mapping,
    );
  }

  final int juzNumber;
  final String firstVerseKey;
  final String lastVerseKey;
  final int versesCount;

  /// Surah number -> (first ayah, last ayah) covered by this juz'.
  final Map<int, (int, int)> verseMapping;

  bool containsVerse(int surah, int ayah) {
    final range = verseMapping[surah];
    if (range == null) return false;
    final (start, end) = range;
    return ayah >= start && ayah <= end;
  }
}
