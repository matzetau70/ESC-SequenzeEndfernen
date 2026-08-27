# Testumgebung für `escapeSequenteEndfernen.sh`

Diese Testumgebung prüft automatisch alle Funktionen des Skripts:

- Escape-Konvertierung (`\n`, `\t`, `\"`, `\\`)
- 2-Argument-Modus (Ausgabe in separate Datei)
- In-Place-Modus mit Backup (1 Argument)
- Zeitstempel-Backup bei bereits vorhandener `.bak`
- Hilfe (`-h` / `--help`) und Argumentfehler

## Aufbau

| Pfad | Zweck |
|---|---|
| `test/data/`      | Eingabedateien (Testfälle) |
| `test/expected/`  | Erwartete Ausgaben (vom Goldstandard erzeugt) |
| `test/output/`    | Laufzeit-Artefakte (wird bei jedem Lauf neu erzeugt) |
| `test/generate_expected.py` | Goldstandard: erzeugt `expected/` aus `data/` |
| `test/run_tests.sh` | Testläufer (Hauptprogramm) |

## Testfälle

| Datei | Testet |
|---|---|
| `simple_escapes.txt`        | einfache `\n`-Konvertierung |
| `tabs.txt`                  | `\t`-Konvertierung |
| `quotes_and_backslash.txt`  | `\\` + Hinweis: `\"` wird von `printf '%b'` NICHT expandiert |
| `umlauts.txt`               | UTF-8 mit Umlauten + Escapes |
| `no_trailing_newline.txt`   | letzte Zeile ohne abschließendes Newline |
| `empty.txt`                 | leere Datei |
| `double_backslash.txt`      | Kombination `\\` + `\t` |
| `sequential.txt`            | mehrere `\n` hintereinander |

> **Hinweis zu `\"`:** Das Skript setzt `printf '%b'` ein. Auch wenn die
> Skript-Doku `\"` -> Anführungszeichen aufführt, EXPANDIERT Bash `\"` derzeit
> NICHT – es bleibt wörtlich `\"` erhalten. Der Goldstandard bildet dieses
> reale Verhalten ab. Falls gewünscht, kann das Skript dahingehend erweitert
> werden (dann Goldstandard und Doku entsprechend anpassen).

## Verwendung

Voraussetzungen: **Bash**, **Python 3**; `escapeSequenteEndfernen.sh` liegt eine Ebene über `test/`.

1. Erwartete Ausgaben (neu) generieren:

   ```bash
   python3 test/generate_expected.py
   ```

2. Tests ausführen:

   ```bash
   cd test
   ./run_tests.sh
   ```

   Der Testläufer erzeugt laufende Artefakte unter `test/output/`
   (Diff-Dateien bleiben bei Fehlern zur Analyse liegen).

3. Ergebnis: PASS/FAIL pro Test, am Ende Exit-Code `0` = alles bestanden,
   `1` = mindestens ein Test fehlgeschlagen.

## Fehlerfälle

Explizit geprüft (erwarteter Exit-Code ungleich 0):

- Kein Argument
- Zuviele Argumente (3+)
- Nicht vorhandene / nicht lesbare Eingabedatei

## Hinweise

- Die erwarteten Ausgaben werden NICHT von Hand gepflegt, sondern
  deterministisch aus `data/` per `generate_expected.py` erzeugt.
- Nach `generate_expected.py` sollten alle Tests grün sein; wer einen
  Test hinzufügt, erzeugt zunächst dessen erwartetes Ergebnis und
  committet beide.