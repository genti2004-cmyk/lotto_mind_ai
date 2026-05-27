# Refactor v1 – Fundament

Diese Version ist absichtlich konservativ: Das App-Verhalten soll möglichst gleich bleiben, aber die Grundlage für eine verständlichere App-Struktur wird gelegt.

## Ziele

- Normal / Pro / Premium als Produktstufen vorbereiten.
- Alte interne Namen `free` und `future` bleiben kompatibel, werden aber im UI als Normal und Premium bezeichnet.
- Fachliche Zielmodelle vorbereiten: `DrawType`, `TipTarget`, `EvaluationStatus`, `GeneratorStrategy`.
- Die große `LottoAppState`-Datei wird in dieser Version noch nicht aggressiv zerlegt, damit die App weiter stabil startet.

## Nächster Refactor-Schritt

Refactor v2 sollte nur ein Thema anfassen:

- `Meine Tipps` als zentraler Speicherort für normale Nutzer.
- Tracking Pro bleibt Zusatz-/Statistikansicht.
- Noch keine große UI-Neustruktur und noch keine harte Paywall.

## Refactor v3 - Tipp-Zielziehung vorbereitet

- `LottoTip` speichert jetzt `targetDrawType` und `targetDrawDate`.
- Neue Tipps erhalten automatisch eine Zielziehung anhand des aktuellen Ziehungsfilters bzw. des nächsten Mittwoch-/Samstag-Termins.
- `Meine Tipps` zeigt die Zielziehung direkt auf der Tipp-Karte an.
- Die Auswertung selbst wurde bewusst noch nicht geändert; das folgt in Refactor v4.

## Refactor v8 – Generator vereinfacht

- Generator-Screen auf einen klareren Nutzerablauf ausgerichtet: Ziel wählen, Strategie nutzen, Tipp speichern.
- Tab-Begriffe vereinfacht: Basis, Analyse, Pro, System.
- Aktueller Tipp erklärt jetzt deutlicher, dass gespeicherte Tipps später unter „Meine Tipps“ geprüft werden.
- Keine Änderungen an Generator-Algorithmen, Tipp-Speicherung, Auswertung oder Ziehungsimport.

## Refactor v13 – DrawHistoryService

Technischer Refactor ohne sichtbare UI-Änderung.

- Ziehungsverlauf-/Merge-Hilfslogik aus `LottoAppState` ausgelagert.
- Neue Datei: `features/draws/services/draw_history_service.dart`.
- Enthält Datumsschlüssel, Datumsvergleich, Ziehungsbereinigung, Import-Merge und manuelle Korrekturregeln.
- Superzahl-Regel bleibt unverändert: Import ohne Superzahl löscht alte falsche Superzahl statt sie weiterzutragen.
- Spiel 77 / SUPER 6 bleiben bei Import ohne Zusatzdaten erhalten.

## Refactor v15 – GeneratedTipService

- Generator-Sitzungslogik wurde aus `LottoAppState` ausgelagert.
- Neue Datei: `features/generator/services/generated_tip_service.dart`.
- Verantwortlich für:
  - zufällige Superzahl für generierte Tipps
  - Normalisierung generierter Tippzahlen
  - Basis-Zufallstipp-Payload
  - Analyse-Tipp-Payload
  - Übernahme vorhandener Analyse-/Multi-AI-Tipps
- Sichtbares Verhalten bleibt unverändert.

## Refactor v19 – Einstellungen aufgeräumt

- Einstellungen stärker als sicherer Verwaltungsbereich strukturiert.
- App-Status zeigt Plan, Ziehungsstand, Tipps, Ziehungen und Tracking-Prüfungen.
- Datenverwaltung verweist klar auf Export Center und warnt vor Lösch-/Importaktionen ohne Backup.
- Analyse-Regeln bleiben erreichbar, werden aber als Expertenbereich erklärt.
- Keine Änderungen an Generator, Tipps, Ziehungen, Auswertung, Import oder Speicherlogik.


## v30 – Stabiler Release-Kandidat

- v1–v19: App-Struktur, Navigation, Tipps, Ziehungen, Export und Einstellungen aufgeräumt.
- v20–v22: Signalmodell, Signal-Tipp und Erklärungen vorbereitet.
- v23–v25: Strategie-Metadaten und Strategie-Vergleich vorbereitet.
- v26: Analyzer-Warnings bereinigt.
- v27: Regressionstest bestanden.
- v28–v29: Signal-/Intervallgewichtung verbessert und Analyse-Signalübersicht sichtbar gemacht.
- Release-Info auf v30 Release-Kandidat aktualisiert.


## v31 – App-Store-Readiness

Release-Info, Store-Checkliste und Hinweise zu Datenschutz/externem Anbieter ergänzt. Keine Kernlogik geändert.
