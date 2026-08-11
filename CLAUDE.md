# Dawim (داوِم) — Project Constitution

## App identity

- **Name:** Dawim — Arabic display name **داوِم** (imperative: "be constant").
  Use "Dawim" in Latin contexts, "داوِم" whenever locale is Arabic.
- **Tagline (verbatim, never paraphrase):**
  - AR: **أدومها وإن قلّ**
  - EN: **Constant, even if small.**
- **Source:** from the hadith «أحب الأعمال إلى الله أدومها وإن قلّ»
  (agreed upon — al-Bukhari & Muslim, narrated by ʿĀʾishah). Where the tagline
  appears with room for attribution (onboarding, About screen), attribute it as
  a prophetic hadith; never present it as marketing copy of our own.
- Tagline is hadith, not Quran: Thmanyah Serif Display styling (including
  kashida) is permitted for it. The Quran-text rules below do NOT loosen.
- The Arabic tagline text must appear exactly as written above — no
  respelling, no diacritic changes.

Daily Quran reading habit app. Core promise: 20 minutes a day, distributed around the
user's real prayer schedule. Duolingo-style structure: tiny daily tasks on a visible
30-unit (juz') progress path. Offline-first. English + Arabic from day one.

## Non-negotiables (violating any of these is a failed task)

1. **Quran text integrity.** Mushaf text and its font come ONLY from QUL
   (Quranic Universal Library, qul.tarteel.ai / Quran.com resources). Never use
   unverified Quran JSON from random repos. Never apply kashida/tatweel, letter
   spacing, or any styling transformation to Quran text. Render it in KFGQPC
   Uthmanic Hafs exclusively.
2. **Font ban.** Roboto and the Noto Naskh family must never render anywhere in the
   app — including default dialogs, AboutDialog, license pages, and error states.
   Set `fontFamily` + `fontFamilyFallback` globally in ThemeData. Any unstyled
   Material widget that falls back to Roboto on Android is a bug.
3. **Typography system.**
   - Titles/headlines: Thmanyah Serif Display (Arabic + Latin).
   - UI/body text: Thmanyah Sans (Arabic + Latin).
   - Mushaf verses: KFGQPC Uthmanic Hafs only.
   - Font files are bundled assets (license permits app embedding). Do not expose
     them for download or reference them from any font CDN.
4. **One branded UI, both platforms.** Do NOT use platform-adaptive widgets
   (no Cupertino-on-iOS switching). Single custom design system, Duolingo-like
   temperament: floating pill-shaped bottom bar, generous rounding, soft blur.
   Full RTL correctness when locale is Arabic (directional icons, EdgeInsetsDirectional).
5. **Offline-first, no backend in v1.** All state in local storage. No accounts,
   no Firebase, no network calls at runtime except nothing — prayer times are
   computed on-device. Structure the persistence layer so cloud sync can be added
   later without migration pain (single serializable state model).

## Product spec (v1)

- **Daily plan:** user picks one schedule:
  (a) 2 slots — 10 min morning + 10 min evening, or
  (b) 4 slots — 5 min after each of Dhuhr, Asr, Maghrib, Isha.
- **Progress structure:** the month's khatmah is the map, the daily segment is the
  task. Home screen shows a 30-node path (one per juz'); today's segment is the
  active node. Completing all slots completes the day's node.
- **Reading verification:** timer counts ONLY while the mushaf view advances at a
  plausible reading pace. Pause on app background, pause when page position is
  static beyond a threshold. Raw screen-open time is never the metric.
- **Prayer times:** `adhan_dart` package, computed offline. Auto-select calculation
  method from device location; always expose a settings override for method and
  madhab (Asr). Use geolocation once, cache coordinates, degrade gracefully if
  permission denied (manual city entry).
- **Notifications:** local notifications anchored to the user's chosen slots
  (prayer-time-relative for the 4-slot plan). Gentle, encouraging copy in the
  user's locale; never guilt-based. Reschedule on timezone/location change.
- **Streaks:** daily streak based on completing the day's reading slots. Streak
  state must survive app reinstall-free scenarios (persist robustly locally).
- **Home-screen widget (native):** Android App Widget + iOS WidgetKit widget,
  2x2 or 4x2 size, showing today's reading progress (slots completed /
  total), this month's khatmah progress (juz' completed / 30), and the
  current daily streak. Icon/accent color shifts when the user is "late" on
  today's reading (a scheduled slot's window has passed uncompleted) vs
  on-track/complete — visual state only, no guilt-based copy (consistent
  with the notification tone rule above). Reads the same locally persisted
  state as the app; updates on app-state change and at minimum once daily.
  Tapping the widget opens the app — no interactive actions inside the
  widget itself.
- **Localization:** flutter_localizations + ARB files, en + ar complete at all
  times. No hardcoded strings.

## Explicitly OUT of v1 (do not build, do not scaffold)

- Social features, leaderboards, sharing
- Voice/recitation recognition
- Audio playback
- Accounts, cloud sync, any backend
- Monetization/premium gating

## Technical decisions (settled — do not revisit)

- **Framework:** Flutter (chosen over React Native for owned text rendering:
  identical Arabic shaping and mushaf fidelity on both platforms).
- **State:** Riverpod (or provider if simpler) — keep it boring.
- **Persistence:** drift or hive for structured state; shared_preferences only
  for trivial flags.
- **Packages expected:** adhan_dart, flutter_local_notifications, geolocator,
  intl/flutter_localizations. Justify any addition beyond these in one line.
- **Home-screen widget:** `home_widget` (bridges Flutter state to native
  Android App Widget / iOS WidgetKit — Flutter has no first-party
  home-screen-widget API; this is the standard community bridge), plus
  native widget code in `android/app/src/main/kotlin/.../widget/` and an
  `ios/HomeWidgetExtension/` target.
- **Never sync/commit:** `build/`, `.dart_tool/`, `ios/Pods/` (default Flutter
  .gitignore covers this — keep it intact).

## Build & deployment context

- Dev machine: Ubuntu (primary, Android device via hot reload).
- iOS builds: macOS KVM guest clones this repo over SSH from the host
  (`ssh://<user>@10.0.2.2/...`), then `flutter pub get && cd ios && pod install &&
  flutter build ipa`. Committed code is the only thing that reaches iOS builds —
  keep the repo always buildable; no broken commits to main.
- v1 "ship" target: sideloaded APK + device-installed iOS build. Not app stores yet.

## Milestone order

1. Scaffold + theme (fonts wired into ThemeData, font-ban verified) + l10n en/ar + RTL audit
2. Mushaf rendering from QUL data (juz'-segmented, paged)
3. Plan engine: schedule selection, juz'-to-daily-segment mapping
4. Timer + page-progress tracking + streak persistence
5. Prayer times (adhan_dart) + local notifications with encouraging copy
6. Home screen: 30-node progress path + today's task card
7. Home-screen widget: native Android App Widget + iOS WidgetKit surfacing
   daily/monthly progress and streak, wired to the same persisted state as
   the app.

Work milestone by milestone. At the end of each, the app must run on a device.
