class Surah {
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.versesCount,
    required this.bismillahPre,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] as int,
      nameArabic: json['name_arabic'] as String,
      nameSimple: json['name_simple'] as String,
      versesCount: json['verses_count'] as int,
      bismillahPre: json['bismillah_pre'] as bool,
    );
  }

  final int id;
  final String nameArabic;
  final String nameSimple;
  final int versesCount;
  final bool bismillahPre;
}
