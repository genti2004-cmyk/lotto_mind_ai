# Lotto Mind AI – v30 Release-Kandidat

Dieser Stand bündelt die stabil getesteten Refactor-Schritte v1 bis v29.

## Enthalten

- Normal / Pro / Premium als Produktstruktur vorbereitet.
- Meine Tipps als zentrale Tipp-Ablage.
- Zielziehung und Zieldatum für gespeicherte Tipps.
- Auswertung nur gegen passende Ziehung.
- Vereinfachte Startseite, Navigation, Ziehungen, Mehr, Einstellungen und Export Center.
- Tracking Pro mit Rücktest-Transparenz und Strategie-Vergleich.
- Analyse-Signalmodell mit Häufigkeit, Rückstand, Intervall, Muster und Hybrid.
- Signal-Tipp im Generator inklusive verständlicher Erklärung.
- Strategie-Metadaten für Basis, Analyse, Signal, Pro und System.
- Analyzer-Cleanup aus v26.
- Regressionstest v27 bestanden.

## Nicht als Zukunftsversprechen formulieren

Die App bewertet historische Auffälligkeiten aus Ziehungsdaten. Sie darf nicht als sichere Vorhersage oder Gewinnzusage beschrieben werden.

## Vor Store-Release prüfen

1. `flutter analyze`
2. Test auf echtem Android-Gerät
3. Import: letzte 8 Wochen, Superzahl, Spiel 77, SUPER 6
4. Generator: Basis, Signal, Pro, System speichern
5. Meine Tipps: Strategie und Zielziehung sichtbar
6. Tracking Pro: Rücktest und Strategie-Vergleich sichtbar
7. Export Center: Backup-Vorschau / Teilen
8. App schließen und neu starten: Daten bleiben erhalten
9. Version / versionCode erhöhen
10. Release-AAB mit Signatur erzeugen
