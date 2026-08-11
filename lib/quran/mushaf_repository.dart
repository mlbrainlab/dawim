import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/juz.dart';
import 'models/mushaf_page.dart';
import 'models/surah.dart';
import 'models/verse.dart';

class MushafRepository {
  const MushafRepository({
    required this.pages,
    required this._versesByKey,
    required this._surahsById,
    required this._juzList,
  });

  static Future<MushafRepository> load() async {
    final pagesJson =
        jsonDecode(await rootBundle.loadString('assets/quran/mushaf_v4_pages.json')) as List<dynamic>;
    final versesJson =
        jsonDecode(await rootBundle.loadString('assets/quran/verses.json')) as Map<String, dynamic>;
    final surahsJson =
        jsonDecode(await rootBundle.loadString('assets/quran/surahs.json')) as Map<String, dynamic>;
    final juzJson =
        jsonDecode(await rootBundle.loadString('assets/quran/juz.json')) as Map<String, dynamic>;

    final pages = pagesJson
        .map((e) => MushafPage.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final versesByKey = versesJson.map(
      (key, value) => MapEntry(key, Verse.fromJson(value as Map<String, dynamic>)),
    );

    final surahsById = surahsJson.map(
      (key, value) => MapEntry(int.parse(key), Surah.fromJson(value as Map<String, dynamic>)),
    );

    final juzList = juzJson.values
        .map((e) => Juz.fromJson(e as Map<String, dynamic>))
        .toList(growable: false)
      ..sort((a, b) => a.juzNumber.compareTo(b.juzNumber));

    return MushafRepository(
      pages: pages,
      versesByKey: versesByKey,
      surahsById: surahsById,
      juzList: juzList,
    );
  }

  final List<MushafPage> pages;
  final Map<String, Verse> _versesByKey;
  final Map<int, Surah> _surahsById;
  final List<Juz> _juzList;

  Verse? verseByKey(String verseKey) => _versesByKey[verseKey];

  Surah? surahByNumber(int surahNumber) => _surahsById[surahNumber];

  /// The juz' (1-30) that a given verse belongs to, or null if not found.
  int? juzNumberForVerse(String verseKey) {
    final parts = verseKey.split(':');
    final surah = int.parse(parts[0]);
    final ayah = int.parse(parts[1]);
    for (final juz in _juzList) {
      if (juz.containsVerse(surah, ayah)) return juz.juzNumber;
    }
    return null;
  }
}
