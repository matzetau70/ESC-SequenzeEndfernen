#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------------
# escapeSequenteEndfernen.sh
# Version: 1.3.0
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
    \\\\   -> Backslash

BEISPIELE:
    $script_name datei.txt                  # In-Place-Konvertierung mit Backup
    $script_name datei.txt sauber.md        # Konvertierung in neue Datei
    $script_name --help                     # Diese Hilfe anzeigen

VERSION:
    1.3.0
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
