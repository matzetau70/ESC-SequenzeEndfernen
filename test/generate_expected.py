#!/usr/bin/env python3
"""Erzeugt die erwarteten Ausgabedateien fuer die Tests von escapeSequenteEndfernen.sh.

Dieses Skript ist der unabhaengige "Goldstandard": Es bildet die Konvertierungslogik
des Shell-Skripts exakt nach (Zeilenweises Lesen, Interpretation von \\n, \\t, \\" und \\\\
sowie Anhaengen eines abschliessenden Newlines pro Zeile) und schreibt daraus die
erwarteten Ergebnisse nach test/expected/.

Verwendung:
    python3 generate_expected.py
"""
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
EXPECTED_DIR = BASE_DIR / "expected"


def convert_line(text: str) -> str:
    """Interpretiert \\n, \\t und \\\\ wie printf '%b' (Teilmenge).

    WICHTIG: Bash's printf '%b' erweitert ''\"'' (Backslash + Anfuehrungszeichen)
    NICHT -- die Sequenz bleibt woertlich erhalten (Backslash + Zitat).
    Unbekannte Sequenzen bleiben ebenfalls woertlich erhalten.
    """
    out: list[str] = []
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "\\" and i + 1 < len(text):
            nxt = text[i + 1]
            if nxt == "n":
                out.append("\n")
                i += 2
                continue
            if nxt == "t":
                out.append("\t")
                i += 2
                continue
            if nxt == "\\":
                out.append("\\")
                i += 2
                continue
            # \\" und jede andere unbekannte Sequenz bleiben woertlich
        out.append(ch)
        i += 1
    return "".join(out)


def expected_output(raw: str) -> str:
    """Bildet die Schleife 'while IFS= read -r line; do printf '%b\\n'; done' nach.

    - Datei ohne abschliessendes Newline: letzte Zeile wird trotzdem mit
      Newline abgeschlossen (printf-Herkunft).
    - Leere Datei: erzeugt keine Ausgabe.
    """
    if raw == "":
        return ""
    parts = raw.split("\n")
    if parts and parts[-1] == "":
        parts.pop()  # Datei endete mit Newline -> keine zusaetzliche leere Zeile
    return "".join(convert_line(part) + "\n" for part in parts)


def main() -> None:
    EXPECTED_DIR.mkdir(parents=True, exist_ok=True)
    generated: list[str] = []
    for src in sorted(DATA_DIR.glob("*.txt")):
        raw = src.read_text(encoding="utf-8")
        dst = EXPECTED_DIR / src.name
        dst.write_text(expected_output(raw), encoding="utf-8")
        generated.append(src.name)
    print(f"Erzeugt: {len(generated)} erwartete Ausgabedatei(en) in {EXPECTED_DIR}/")
    for name in generated:
        print(f"  - {name}")


if __name__ == "__main__":
    main()