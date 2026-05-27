import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';

class LegalNoticeScreen extends StatelessWidget {
  const LegalNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hinweise & Verantwortung'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: const [
            SectionTitle(
              title: 'Hinweise & Verantwortung',
              subtitle:
                  'Lotto Mind AI ist ein Analyse- und Assistenztool. Die App ersetzt keine offizielle Lotto-Abgabe und gibt keine Gewinnzusage.',
            ),
            SizedBox(height: 20),
            _NoticeCard(
              icon: Icons.analytics_rounded,
              title: 'Analyse statt Vorhersage',
              text:
                  'Die App bewertet historische Ziehungsdaten, Häufigkeiten, Rückstände, Intervalle und Muster. Daraus entstehen Hinweise und Signalwerte, aber keine sichere Zukunftsvorhersage.',
            ),
            SizedBox(height: 16),
            _NoticeCard(
              icon: Icons.block_rounded,
              title: 'Keine Gewinnzusage',
              text:
                  'Treffer, Rücktests, Simulationen und Strategievergleiche sind statistische Auswertungen. Sie garantieren keinen Gewinn und erhöhen nicht sicher die Gewinnchance.',
            ),
            SizedBox(height: 16),
            _NoticeCard(
              icon: Icons.open_in_new_rounded,
              title: 'Lotto-Abgabe nur beim Anbieter',
              text:
                  'Lotto Mind AI nimmt keine Spielscheine entgegen. Eine echte Teilnahme erfolgt ausschließlich außerhalb der App beim jeweiligen offiziellen Anbieter.',
            ),
            SizedBox(height: 16),
            _NoticeCard(
              icon: Icons.verified_user_rounded,
              title: 'Mindestalter & verantwortungsvolles Spielen',
              text:
                  'Nutze Lotto-Angebote nur, wenn du die gesetzlichen Voraussetzungen erfüllst. Spiele verantwortungsvoll und setze nur Beträge ein, deren Verlust du tragen kannst.',
            ),
            SizedBox(height: 16),
            _NoticeCard(
              icon: Icons.lock_rounded,
              title: 'Datenschutz & lokale Daten',
              text:
                  'Gespeicherte Ziehungen, Tipps, Tracking-Daten und Einstellungen werden lokal in der App verwaltet. Backups und Exporte werden nur ausgelöst, wenn du sie aktiv nutzt.',
            ),
            SizedBox(height: 16),
            _NoticeCard(
              icon: Icons.history_edu_rounded,
              title: 'Rücktest richtig verstehen',
              text:
                  'Tracking Pro kann historische Prüfungen anzeigen. Diese Rücktests zeigen, wie eine Strategie auf vergangenen Ziehungen abgeschnitten hätte. Sie sind keine echte Gewinnbilanz.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
