#!/usr/bin/env python3
"""One-time conversion: join the KFGQPC V4 tajweed (1441H) mushaf layout
sqlite export with the QPC V4 glyph word-by-word codes into a compact
per-page/per-line JSON asset for the app to bundle.

Each mushaf page renders with its own KFGQPC font (assets/fonts/qcf4/p{n}.ttf,
family QCF4_P{n}); the per-word `text` in the glyph JSON is a codepoint that
only makes sense inside that page's font.

Inputs (raw QUL exports, read from ~/Downloads, never committed to the repo):
  - qpc-v4-tajweed-15-lines.db  (resources/mushaf-layout/19, KFGQPC V4 1441H print)
  - qpc-v4.json                 (resources/quran-script/47, V4 glyph codes word by word)
  - surah-names.json            (resources/quran-metadata/70)

Output (committed as an app asset):
  - assets/quran/mushaf_v4_pages.json

Re-run only if the mushaf edition/layout changes.
"""

import json
import sqlite3
from pathlib import Path

DOWNLOADS = Path.home() / "Downloads"
DB_PATH = DOWNLOADS / "qpc-v4-tajweed-15-lines.db"
WORDS_PATH = DOWNLOADS / "qpc-v4.json"
SURAHS_PATH = DOWNLOADS / "surah-names.json"

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_PATH = REPO_ROOT / "assets" / "quran" / "mushaf_v4_pages.json"


def load_words():
    with WORDS_PATH.open(encoding="utf-8") as f:
        raw = json.load(f)
    words = {}
    for entry in raw.values():
        words[entry["id"]] = entry
    return words


def load_surah_names():
    with SURAHS_PATH.open(encoding="utf-8") as f:
        raw = json.load(f)
    return {int(k): v["name_arabic"] for k, v in raw.items()}


def build_basmalah_text(words):
    # Al-Fatihah's own basmalah, words 1-4 (word 5 is the ayah-end marker).
    # These are page-1 glyphs: the renderer draws basmalah lines with the
    # QCF4_P1 font on every page.
    return " ".join(words[i]["text"] for i in range(1, 5))


def main():
    words = load_words()
    surah_names = load_surah_names()
    basmalah_text = build_basmalah_text(words)

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT page_number, line_number, line_type, is_centered, "
        "first_word_id, last_word_id, surah_number FROM pages "
        "ORDER BY page_number, line_number"
    ).fetchall()
    conn.close()

    pages = {}
    for row in rows:
        page_number = row["page_number"]
        line_type = row["line_type"]
        is_centered = bool(row["is_centered"])

        line = {"type": line_type, "isCentered": is_centered}

        if line_type == "ayah":
            first_id = int(row["first_word_id"])
            last_id = int(row["last_word_id"])
            word_entries = [words[i] for i in range(first_id, last_id + 1)]
            line["text"] = " ".join(w["text"] for w in word_entries)
            seen_keys = []
            for w in word_entries:
                key = f"{w['surah']}:{w['ayah']}"
                if key not in seen_keys:
                    seen_keys.append(key)
            line["verseKeys"] = seen_keys
        elif line_type == "basmallah":
            line["text"] = basmalah_text
        elif line_type == "surah_name":
            surah_number = int(row["surah_number"])
            line["surahNumber"] = surah_number
            line["text"] = surah_names[surah_number]
        else:
            raise ValueError(f"unknown line_type: {line_type}")

        pages.setdefault(page_number, []).append(line)

    ordered_pages = [
        {"pageNumber": page_number, "lines": pages[page_number]}
        for page_number in sorted(pages)
    ]

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(ordered_pages, f, ensure_ascii=False, separators=(",", ":"))

    print(f"Wrote {len(ordered_pages)} pages to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
