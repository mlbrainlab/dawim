/// Font family names, matching the `fonts:` block in pubspec.yaml.
///
/// Roboto and the Noto Naskh family must never render anywhere in the app —
/// see CLAUDE.md non-negotiable #2. Any text style in this app must resolve
/// to one of the families below (or, for mushaf verses, KFGQPC Uthmanic
/// Hafs, wired in milestone 2).
abstract final class AppFonts {
  static const String serifDisplay = 'ThmanyahSerifDisplay';
  static const String sans = 'ThmanyahSans';
}
