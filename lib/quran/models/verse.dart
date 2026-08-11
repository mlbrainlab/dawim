class Verse {
  const Verse({
    required this.surah,
    required this.ayah,
    required this.verseKey,
    required this.text,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      verseKey: json['verse_key'] as String,
      text: json['text'] as String,
    );
  }

  final int surah;
  final int ayah;
  final String verseKey;
  final String text;
}
