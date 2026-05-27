# Lotto Mind AI – v31 App-Store-Readiness

Dieser Stand baut auf dem grünen v30 Release-Kandidaten auf. Es wurden keine Kernlogiken für Import, Generator, Tipps, Tracking oder Auswertung geändert.

## Ziel

Die App ist für einen späteren Store-Test besser vorbereitet:

- Release-Info klarer auf v31 gesetzt.
- Store-Checkliste ergänzt.
- Hinweise zu Datenschutz, lokaler Speicherung, Backup und externer Lotto-Abgabe ergänzt.
- Formulierungen bleiben bewusst ohne Gewinnversprechen.
- Normal / Pro / Premium bleiben als Produktstruktur vorbereitet, ohne aktive harte Paywall.

## Vor Play-Console-Test prüfen

1. `flutter analyze`
2. Start auf echtem Android-Gerät
3. Ziehungen: letzte 8 Wochen, Superzahl, Spiel 77, SUPER 6
4. Generator: Basis, Analyse, Signal, Pro und System speichern
5. Meine Tipps: Strategie und Zielziehung sichtbar
6. Tracking Pro: Rücktest und Strategie-Vergleich sichtbar
7. Export Center: Backup-Vorschau und Teilen
8. Einstellungen → Release-Info zeigt v31
9. Datenschutzerklärung und Store-Beschreibung ohne Gewinnversprechen formulieren
10. Interne Testspur verwenden, bevor ein Produktionsrelease erfolgt

## Formulierungsregel

Die App analysiert historische Ziehungsdaten und zeigt Auffälligkeiten. Sie ist kein Vorhersage- oder Gewinnversprechen.
