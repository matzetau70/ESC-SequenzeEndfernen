# Zusammenfassung: `escapeSequenteEndfernen.sh`

**Version:** 1.4.0
**Stand:** 27.08.2026
**Projekt:** 2dGame_02

---

## Versionshistorie

| Version | Datum | Änderungen |
|---------|-------|------------|
| 1.0.0   | 27.08.2026 | Robuste Basisversion: zeilenweise Verarbeitung mit `read -r` + `printf '%b'` statt `echo -e "$(cat ...)"` |
| 1.1.0   | 27.08.2026 | Ein- und Ausgabedatei als Argumente (`$0 <eingabedatei> <ausgabedatei>`) |
| 1.2.0   | 27.08.2026 | In-Place-Modus mit Backup bei nur einem Argument (`$0 <eingabedatei>`) |
| 1.4.0   | 27.08.2026 | Versionsnummer erhöht, Doku/Changelog aktualisiert (keine funktionalen Änderungen) |
| 1.3.0   | 27.08.2026 | Help-Funktion (`-h` / `--help`) mit Usage, Modi, Beispielen und Version |

---

## 1. Aufgabe

Das Shell-Skript `escapeSequenteEndfernen.sh` wandelt Backslash-Escape-Sequenzen in echte Zeichen um (`\n` → Zeilenumbruch, `\t` → Tabulator, `\"` → Anführungszeichen, `\\` → Backslash). Es wurde schrittweise robuster gemacht und um einen **In-Place-Modus mit Backup** erweitert.

---

## 2. Entwicklungsschritte

1. **Robuste Basisversion:** Zeilenweise Verarbeitung mit `read -r` + `printf '%b'` statt `echo -e "$(cat ...)"` (kein ARG_MAX-Problem, keine verlorenen Trailing-Newlines).
2. **Ein-/Ausgabedatei als Argumente:** `$0 <eingabedatei> <ausgabedatei>`.
3. **In-Place-Modus bei nur einem Argument:** Backup anlegen und direkt in die Originaldatei konvertieren.
4. **Help-Funktion:** `$0 -h` bzw. `$0 --help` zeigt Usage, Modi, Optionen, Escape-Sequenzen, Beispiele und Version.

---

## 3. Aktuelles Skript

```bash
#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------------
# escapeSequenteEndfernen.sh
# Version: 1.4.0
#
# Wandelt Backslash-Escape-Sequenzen in echte Zeichen um:
#   \n  -> Zeilenumbruch
#   \t  -> Tabulator
#   \"  -> Anführungszeichen
#   \\  -> Backslash
#
# Aufruf (2 Modi):
#   $0 <eingabedatei>
#       Konvertiert die Datei direkt in sich selbst (In-Place).
#       Vorher wird ein Backup als <eingabedatei>.bak angelegt
#       (bei bereits vorhandenem Backup mit Zeitstempel).
#
#   $0 <eingabedatei> <ausgabedatei>
#       Schreibt das Ergebnis in <ausgabedatei>; die
#       Eingabedatei bleibt unverändert.
# ------------------------------------------------------------------

# Zeigt die Hilfe/Usage an und beendet das Skript (Exit 0).
script_name="$(basename "$0")"
show_help() {
    cat <<EOF
$script_name - Konvertiert Backslash-Escape-Sequenzen in echte Zeichen

VERWENDUNG:
    $script_name <eingabedatei> [<ausgabedatei>]

MODI:
    $script_name <eingabedatei>
        Konvertiert die Datei direkt in sich selbst (In-Place).
        Vorher wird ein Backup als <eingabedatei>.bak angelegt
        (bei bereits vorhandenem Backup mit Zeitstempel).

    $script_name <eingabedatei> <ausgabedatei>
        Schreibt das Ergebnis in <ausgabedatei>;
        die Eingabedatei bleibt unverändert.

OPTIONEN:
    -h, --help   Zeigt diese Hilfe an und beendet das Skript.

UNTERSTUETZTE ESCAPE-SEQUENZEN:
    \n   -> Zeilenumbruch
    \t   -> Tabulator
    \"   -> Anführungszeichen
    \\   -> Backslash

BEISPIELE:
    $script_name datei.txt                  # In-Place-Konvertierung mit Backup
    $script_name datei.txt sauber.md        # Konvertierung in neue Datei
    $script_name --help                     # Diese Hilfe anzeigen

VERSION:
    1.4.0
EOF
}

if [ "$#" -ge 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    show_help
    exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Verwendung: $0 <eingabedatei> [<ausgabedatei>]" >&2
    echo "Für Hilfe:  $0 --help" >&2
    exit 1
fi

input_file="$1"

if [ ! -r "$input_file" ]; then
    echo "Fehler: Eingabedatei nicht lesbar oder nicht vorhanden: $input_file" >&2
    exit 1
fi

# Liest von der Eingabedatei und schreibt die konvertierte Ausgabe nach "$1"
convert() {
    while IFS= read -r line || [ -n "$line" ]; do
        printf '%b\n' "$line"
    done < "$input_file" > "$1"
}

if [ "$#" -eq 1 ]; then
    # --- In-Place-Modus: Backup + Konvertierung in die Originaldatei ---
    backup_file="${input_file}.bak"
    if [ -e "$backup_file" ]; then
        backup_file="${input_file}.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    cp "$input_file" "$backup_file"

    # Temporäre Datei (gleiches Verzeichnis -> mv bleibt atomar),
    # wird bei Abbruch automatisch entfernt.
    tmp_file="$(mktemp "${input_file}.XXXXXX")"
    trap 'rm -f "$tmp_file"' EXIT

    convert "$tmp_file"
    # Ursprüngliche Dateirechte beibehalten (mktemp erzeugt sonst 600)
    chmod --reference="$input_file" "$tmp_file"
    mv "$tmp_file" "$input_file"

    echo "Fertig: $input_file konvertiert (In-Place). Backup: $backup_file"
else
    # --- Zwei-Argument-Modus: in Ausgabedatei schreiben ---
    output_file="$2"
    convert "$output_file"
    echo "Fertig: $output_file aus $input_file erzeugt."
fi
```

---

## 4. Verhalten im Detail

| Fall | Verhalten |
| --- | --- |
| `-h` / `--help` | Zeigt die Hilfe an, Exit-Code 0 |
| 0 oder 3+ Argumente | Usage-Meldung `<eingabedatei> [<ausgabedatei>]`, Exit-Code 1 |
| 1 Argument | Backup `<datei>.bak` (bei Konflikt mit Zeitstempel), dann In-Place-Konvertierung |
| 2 Argumente | Ergebnis in `<ausgabedatei>`, Eingabedatei bleibt unverändert |
| Eingabe nicht lesbar | Fehlermeldung, Exit-Code 1 |
| Abbruch während Konvertierung | Temp-Datei wird per `trap` aufgeräumt |

---

## 5. Verifikation / Tests

1. **Syntaxcheck:** `bash -n` OK.
2. **In-Place-Lauf (Kopie von `Vorschlaege.md`):** Originaldatei danach 1.227 Zeilen / 36.052 Byte; **Backup byte-identisch** mit der Rohdatei (37.280 Byte).
3. **Doppelter In-Place-Lauf:** Zweites Backup mit Zeitstempel (`<datei>.bak.20260827-233010`) korrekt angelegt.
4. **Dateirechte:** `644` bleibt `644` (durch `chmod --reference`).
5. **2-Argument-Modus:** `Zeile1\nZeile2\tTab` → Ausgabe korrekt mit echtem Umbruch (`$`) und echtem Tab (`^I`); Eingabedatei unverändert.
6. **Fehlerfälle:** 0 / 3 Argumente sowie nicht vorhandene Eingabedatei → jeweils Exit-Code 1 mit Meldung.
7. **Help-Funktion:** `-h` und `--help` zeigen die Hilfe mit korrekt dargestellten Escape-Sequenzen, Exit-Code 0.
