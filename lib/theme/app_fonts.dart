/// Font family names, matching the `fonts:` block in pubspec.yaml.
///
/// Roboto and the Noto Naskh family must never render anywhere in the app —
/// see CLAUDE.md non-negotiable #2. Any text style in this app must resolve
/// to one of the families below.
abstract final class AppFonts {
  static const String serifDisplay = 'ThmanyahSerifDisplay';
  static const String sans = 'ThmanyahSans';

  /// KFGQPC Uthmanic Hafs — mushaf verses only. Never apply kashida,
  /// letter-spacing, or other styling transforms to text in this font;
  /// see CLAUDE.md non-negotiable #1.
  static const String quran = 'UthmanicHafs';
}
