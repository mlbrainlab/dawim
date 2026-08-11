import 'package:dawim/quran/models/mushaf_line.dart';
import 'package:dawim/quran/mushaf_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MushafRepository repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repository = await MushafRepository.load();
  });

  test('loads all 604 mushaf pages', () {
    expect(repository.pages.length, 604);
    expect(repository.pages.first.pageNumber, 1);
    expect(repository.pages.last.pageNumber, 604);
  });

  test('line-type counts match the known KFGQPC V2 layout structure', () {
    final counts = <MushafLineType, int>{};
    for (final page in repository.pages) {
      for (final line in page.lines) {
        counts[line.type] = (counts[line.type] ?? 0) + 1;
      }
    }
    expect(counts[MushafLineType.surahName], 114);
    expect(counts[MushafLineType.basmallah], 112);
    expect(counts[MushafLineType.ayah], 8820);
  });

  test('ayah lines cover every verse exactly once, in order, start to finish', () {
    final coveredKeys = <String>[];
    for (final page in repository.pages) {
      for (final line in page.lines) {
        if (line.type != MushafLineType.ayah) continue;
        for (final key in line.verseKeys!) {
          if (coveredKeys.isEmpty || coveredKeys.last != key) {
            coveredKeys.add(key);
          }
        }
      }
    }
    expect(coveredKeys.first, '1:1');
    expect(coveredKeys.last, '114:6');
    expect(coveredKeys.toSet().length, 6236);
  });

  test('verseByKey resolves known verses', () {
    final fatiha1 = repository.verseByKey('1:1');
    expect(fatiha1, isNotNull);
    expect(fatiha1!.text, contains('بِسۡمِ'));

    final nas6 = repository.verseByKey('114:6');
    expect(nas6, isNotNull);
  });

  test('surahByNumber resolves Arabic names', () {
    expect(repository.surahByNumber(1)!.nameArabic, 'الفاتحة');
    expect(repository.surahByNumber(114)!.nameArabic, 'الناس');
  });

  test('juzNumberForVerse resolves known juz\' boundaries', () {
    expect(repository.juzNumberForVerse('1:1'), 1);
    expect(repository.juzNumberForVerse('2:141'), 1);
    expect(repository.juzNumberForVerse('2:142'), 2);
    expect(repository.juzNumberForVerse('114:6'), 30);
  });
}
