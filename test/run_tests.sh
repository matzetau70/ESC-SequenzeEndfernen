#!/bin/bash
# Testlaeufer fuer escapeSequenteEndfernen.sh
#
# Verwendung:
#   ./run_tests.sh                       (aus test/ heraus)
#   SCRIPT=/pfad/zum/skript ./run_tests.sh
#
# Exit-Code 0 = alle Tests bestanden, sonst 1.

set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(dirname "$TEST_DIR")"

# Das zu testende Skript ermitteln: 
# 1. explizit per SCRIPT=..., sonst
# 2. verschobene Entwicklungskopie im Schwester-Ordner, sonst
# 3. eine Ebene über test/
if [ -n "${SCRIPT:-}" ]; then
    :
else
    EXTERNAL_SCRIPT="/media/matze/Data0/_Projekte-DEV/___github-matzetau70/ESC-SequenzeEndfernen/escapeSequenteEndfernen.sh"
    if [ -x "$EXTERNAL_SCRIPT" ]; then
        SCRIPT="$EXTERNAL_SCRIPT"
    else
        SCRIPT="$SCRIPT_DIR/escapeSequenteEndfernen.sh"
    fi
fi

DATA_DIR="$TEST_DIR/data"
EXPECTED_DIR="$TEST_DIR/expected"
OUTPUT_DIR="$TEST_DIR/output"

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
NC=$'\033[0m'

PASS=0
FAIL=0
FAILED=()

ok()  { echo "${GREEN}PASS${NC}  $*"; PASS=$((PASS + 1)); }
bad() { echo "${RED}FAIL${NC}  $*"; FAIL=$((FAIL + 1)); FAILED+=("$*"); }

echo
echo "=== Testumgebung fuer escapeSequenteEndfernen.sh ==="

if [ ! -x "$SCRIPT" ]; then
    bad "Skript nicht auffindbar/ausfuehrbar: $SCRIPT"
    echo "Tipp: SCRIPT=/pfad/zu/escapeSequenteEndfernen.sh $0"
    exit 1
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/inplace" "$OUTPUT_DIR/double" "$OUTPUT_DIR/errors"

# --- Testfall im 2-Argument-Modus -------------------------------------
diff_test() {
    local name="$1"
    "$SCRIPT" "$DATA_DIR/$name" "$OUTPUT_DIR/$name" >/dev/null 2>&1
    if diff -u "$EXPECTED_DIR/$name" "$OUTPUT_DIR/$name" > "$OUTPUT_DIR/$name.diff" 2>&1; then
        ok "2-Argument: $name"
    else
        bad "2-Argument: $name"
    fi
}

# --- In-Place-Modus: Inhalt + Backup -----------------------------------
inplace_test() {
    local name="$1"
    cp "$DATA_DIR/$name" "$OUTPUT_DIR/inplace/$name"
    "$SCRIPT" "$OUTPUT_DIR/inplace/$name" >/dev/null 2>&1
    if diff -u "$EXPECTED_DIR/$name" "$OUTPUT_DIR/inplace/$name" > "$OUTPUT_DIR/inplace/$name.diff" 2>&1; then
        ok "In-Place: $name (Inhalt)"
    else
        bad "In-Place: $name (Inhalt)"
    fi
    if [ -f "$OUTPUT_DIR/inplace/$name.bak" ] \
        && diff -q "$DATA_DIR/$name" "$OUTPUT_DIR/inplace/$name.bak" >/dev/null 2>&1; then
        ok "In-Place: $name (Backup vorhanden + identisch)"
    else
        bad "In-Place: $name (Backup fehlt oder ungleich)"
    fi
}

# --- [1] 2-Argument-Modus ----------------------------------------------
echo
echo "[1] 2-Argument-Modus  ($DATA_DIR -> $EXPECTED_DIR)"
for f in "$DATA_DIR"/*.txt; do
    diff_test "$(basename "$f")"
done

# --- [2] In-Place-Modus mit Backup -------------------------------------
echo
echo "[2] In-Place-Modus mit Backup (1 Argument)"
for f in "$DATA_DIR"/*.txt; do
    inplace_test "$(basename "$f")"
done

# --- [3] Backup-Konflikt -> Zeitstempel --------------------------------
echo
echo "[3] Backup-Konflikt -> Zeitstempel-Datei"
cp "$DATA_DIR/simple_escapes.txt" "$OUTPUT_DIR/double/simple.txt"
cp "$DATA_DIR/simple_escapes.txt" "$OUTPUT_DIR/double/simple.txt.bak"
"$SCRIPT" "$OUTPUT_DIR/double/simple.txt" >/dev/null 2>&1
if ls "$OUTPUT_DIR/double/simple.txt.bak".* >/dev/null 2>&1; then
    ok "Zeitstempel-Backup angelegt"
else
    bad "Zeitstempel-Backup fehlt"
fi

# --- [4] Hilfe und Argumentfehler --------------------------------------
echo
echo "[4] Hilfe und Argumentfehler"
if "$SCRIPT" --help > "$OUTPUT_DIR/errors/help.txt" 2>&1; then
    ok "--help beendet mit Exit 0"
else
    bad "--help liefert Exit != 0"
fi
if grep -q "VERSION" "$OUTPUT_DIR/errors/help.txt"; then
    ok "Hilfe enthaelt VERSION-Abschnitt"
else
    bad "Hilfe ohne VERSION-Abschnitt"
fi
if "$SCRIPT" -h >/dev/null 2>&1; then
    ok "-h beendet mit Exit 0"
else
    bad "-h liefert Exit != 0"
fi
if "$SCRIPT" >/dev/null 2>&1; then
    bad "0 Argumente sollte Exit != 0 liefern"
else
    ok "0 Argumente -> Exit != 0"
fi
if "$SCRIPT" a b c >/dev/null 2>&1; then
    bad "3 Argumente sollte Exit != 0 liefern"
else
    ok "3 Argumente -> Exit != 0"
fi
if "$SCRIPT" "$DATA_DIR/gibtsnicht.txt" >/dev/null 2>&1; then
    bad "Nicht-lesbare Datei sollte Exit != 0 liefern"
else
    ok "Nicht-lesbare Datei -> Exit != 0"
fi

# --- Ergebnis -----------------------------------------------------------
echo
echo "=================================================="
echo "  PASS: $PASS    FAIL: $FAIL"
if [ "$FAIL" -ne 0 ]; then
    printf '  Fehlgeschlagene Tests: %s\n' "${FAILED[@]}"
    echo "=================================================="
    exit 1
fi
echo "  ALLE TESTS BESTANDEN"
echo "=================================================="