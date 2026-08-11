/// Evidence that a reading slot was actually read.
///
/// [secondsByPage] does double duty: its keys are the pages the reader has
/// visited (an entry is written on first view, even at zero seconds), and its
/// values are the verified seconds spent on each — see
/// `lib/plan/reading_verifier.dart` for how those become an unlock.
class SlotProgress {
  const SlotProgress({this.secondsByPage = const {}, this.lastPage});

  factory SlotProgress.fromJson(Map<String, dynamic> json) {
    final rawSeconds = (json['secondsByPage'] as Map<String, dynamic>?) ?? const {};
    return SlotProgress(
      secondsByPage: rawSeconds.map((page, seconds) => MapEntry(int.parse(page), seconds as int)),
      lastPage: json['lastPage'] as int?,
    );
  }

  final Map<int, int> secondsByPage;

  /// Where the reader left off, so the slot resumes rather than restarting.
  final int? lastPage;

  Set<int> get visitedPages => secondsByPage.keys.toSet();

  Map<String, dynamic> toJson() => {
    'secondsByPage': {for (final entry in secondsByPage.entries) '${entry.key}': entry.value},
    'lastPage': lastPage,
  };

  SlotProgress withPageViewed(int page) {
    if (secondsByPage.containsKey(page)) {
      return SlotProgress(secondsByPage: secondsByPage, lastPage: page);
    }
    return SlotProgress(
      secondsByPage: {...secondsByPage, page: 0},
      lastPage: page,
    );
  }

  SlotProgress withSecondsOnPage(int page, int seconds) {
    return SlotProgress(
      secondsByPage: {...secondsByPage, page: (secondsByPage[page] ?? 0) + seconds},
      lastPage: lastPage ?? page,
    );
  }
}
