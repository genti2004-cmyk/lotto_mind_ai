import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lotto_mind_ai/features/settings/domain/app_edition.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_block_header.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';

class AboutReleaseScreen extends StatelessWidget {
  const AboutReleaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Release-Info'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const SectionTitle(
              title: 'Lotto Mind AI – Release',
              subtitle: 'v37 Struktur & Performance – schnellere Generator-Tabs und sauberere Feature-Struktur',
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBlockHeader(
                    title: 'App-Status',
                    subtitle: 'Die wichtigsten Produktdaten für den Release auf einen Blick.',
                  ),
                  const SizedBox(height: 14),
                  const _InfoRow(label: 'App-Name', value: 'Lotto Mind AI'),
                  const SizedBox(height: 10),
                  const _InfoRow(label: 'Release-Stufe', value: 'v37 Struktur & Performance'),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Edition', value: state.edition.label),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Gespeicherte Tipps', value: '${state.savedTips.length}'),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Gespeicherte Ziehungen', value: '${state.drawResults.length}'),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Regelprofile', value: '${state.ruleProfiles.length}'),
                  const SizedBox(height: 10),
                  const _InfoRow(label: 'Stabilitätsstand', value: 'v30–v36 stabil + v37 Struktur, Performance und Architektur aufgeräumt'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBlockHeader(
                    title: 'Was wurde in v37 verbessert?',
                    subtitle: 'Struktur und Performance wurden verbessert, ohne Import, Tipps oder Auswertung fachlich zu ändern.',
                  ),
                  SizedBox(height: 14),
                  _ReleaseLine('Startseite technisch sauberer als Home-Bereich organisiert.'),
                  _ReleaseLine('Generator-Tabs Basis, Analyse, Pro und System reagieren schneller.'),
                  _ReleaseLine('Analyse- und Pro-Details werden erst geladen, wenn sie gebraucht werden.'),
                  _ReleaseLine('Gemeinsame UI-Bausteine wurden nach core/widgets ausgelagert.'),
                  _ReleaseLine('Datum-, Euro- und Prozentformatierungen wurden unter core/utils zentralisiert.'),
                  _ReleaseLine('Storage-Keys wurden unter core/storage zentralisiert.'),
                  _ReleaseLine('Tracking Pro liegt jetzt sauber unter features/tracking.'),
                  _ReleaseLine('Einstellungen und Produktstufen wurden intern sauberer strukturiert.'),
                  _ReleaseLine('Unverändert: Import, Superzahl-Erkennung, 8-Wochen-Suche, Generator-Logik, Meine Tipps und Auswertung.'),
                  _ReleaseLine('Wichtig: v37 ist ein Struktur- und Performance-Update, kein neues Gewinnversprechen.'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBlockHeader(
                    title: 'Release-Checkliste',
                    subtitle: 'Vor dem Upload in die Play Console einmal komplett abhaken.',
                  ),
                  SizedBox(height: 14),
                  _ReleaseLine('App startet stabil auf echtem Gerät'),
                  _ReleaseLine('Generator, Analyse, Meine Tipps und Tracking Pro laufen fehlerfrei'),
                  _ReleaseLine('Navigation, Startseite, Ziehungen, Mehr und Einstellungen sind vereinfacht'),
                  _ReleaseLine('Import, Superzahl, 8-Wochen-Suche und Persistenz wurden gegengeprüft'),
                  _ReleaseLine('Signalmodell, Strategie-Tracking und Rücktest-Anzeige sind integriert'),
                  _ReleaseLine('Vor Store-Upload: Versionsnummer, Datenschutz und AAB final prüfen'),
                  _ReleaseLine('Store-Texte ohne Gewinnversprechen oder sichere Vorhersage formulieren'),
                  _ReleaseLine('Hinweise zu Mindestalter, verantwortungsvollem Spielen und Anbieter-Abgabe sichtbar halten'),
                  _ReleaseLine('Start-Assistent auf der Startseite prüfen'),
                  _ReleaseLine('Signal-Tipp auf ausgewogene Bereiche, gerade/ungerade und Wiederholer prüfen'),
                  _ReleaseLine('Erster-Start-Anleitung für neue Nutzer öffnen und prüfen'),
                  _ReleaseLine('Normal / Pro / Premium als vorbereitet kennzeichnen, solange keine echte Paywall aktiv ist'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBlockHeader(
                    title: 'App-Store-Readiness',
                    subtitle: 'Kurze Leitplanken für Beschreibung, Screenshots und Review.',
                  ),
                  SizedBox(height: 14),
                  _ReleaseLine('Beschreibung: Analyse historischer Ziehungsdaten, keine Gewinnzusage'),
                  _ReleaseLine('Screenshots: Start, Generator, Meine Tipps, Ziehungen, Tracking Pro'),
                  _ReleaseLine('Datenschutz: lokale Speicherung, Export/Backup und externe Links klar erklären'),
                  _ReleaseLine('Review-Hinweis: Glücksspielteilnahme erfolgt außerhalb der App beim Anbieter'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBlockHeader(
                    title: 'Rechtliche Hinweise in der App',
                    subtitle: 'Diese Aussagen sind in der App sichtbar vorbereitet und sollten auch in Store-Texten konsistent bleiben.',
                  ),
                  SizedBox(height: 14),
                  _ReleaseLine('Analyse historischer Daten, keine sichere Vorhersage'),
                  _ReleaseLine('Keine Gewinnzusage durch Tipps, Rücktests oder Simulationen'),
                  _ReleaseLine('Lotto-Abgabe erfolgt ausschließlich beim offiziellen Anbieter'),
                  _ReleaseLine('Mindestalter und verantwortungsvolles Spielen beachten'),
                  _ReleaseLine('Daten werden lokal gespeichert; Backup/Export wird aktiv durch Nutzer ausgelöst'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBlockHeader(
                    title: 'Finale Schritte vor Veröffentlichung',
                    subtitle: 'Diese Punkte solltest du direkt vor dem Release noch erledigen.',
                  ),
                  SizedBox(height: 14),
                  Text(
                    '1. App-Icon und Splash final prüfen\n'
                    '2. Versionsnummer und versionCode erhöhen\n'
                    '3. Release-Signatur prüfen und AAB erzeugen\n'
                    '4. Store-Eintrag, Screenshots und Datenschutzerklärung eintragen\n'
                    '5. Interne Testspur in der Play Console nutzen\n'
                    '6. Erst nach finalem Gerätetest Produktions-Release freigeben\n'
                    '7. Git-Tag setzen, ZIP sichern und Release-Notizen archivieren',
                    style: TextStyle(height: 1.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

class _ReleaseLine extends StatelessWidget {
  final String text;

  const _ReleaseLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
