import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erster Start'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: const [
            SectionTitle(
              title: 'Willkommen bei Lotto Mind AI',
              subtitle:
                  'Ein kurzer Einstieg, damit neue Nutzer die App sofort verstehen: Daten aktualisieren, Tipp erstellen, speichern und später prüfen.',
            ),
            SizedBox(height: 20),
            _IntroNotice(),
            SizedBox(height: 20),
            _StepCard(
              step: '1',
              icon: Icons.event_note_rounded,
              title: 'Ziehungen aktualisieren',
              text:
                  'Starte mit aktuellen Ziehungsdaten. Die App nutzt historische Ziehungen für Analyse, Rücktest und Signal-Tipps.',
              action: 'Start oder Ziehungen → Letzte 8 Wochen suchen',
            ),
            SizedBox(height: 14),
            _StepCard(
              step: '2',
              icon: Icons.casino_rounded,
              title: 'Tipp erstellen',
              text:
                  'Wähle im Generator einen Tipp-Pfad. Basis ist einfach, Signal nutzt Häufigkeit, Rückstand, Intervall und Muster.',
              action: 'Generator → Basis oder Analyse → Signal-Tipp',
            ),
            SizedBox(height: 14),
            _StepCard(
              step: '3',
              icon: Icons.bookmarks_rounded,
              title: 'Tipp speichern',
              text:
                  'Gespeicherte Tipps landen zentral in „Meine Tipps“. Dort siehst du Strategie, Zielziehung und Prüfstatus.',
              action: 'Generator → In Meine Tipps speichern',
            ),
            SizedBox(height: 14),
            _StepCard(
              step: '4',
              icon: Icons.fact_check_rounded,
              title: 'Tipps prüfen',
              text:
                  'Nach der passenden Ziehung prüft die App deine gespeicherten Tipps. Mittwoch-Tipps werden nicht einfach gegen Samstag geprüft.',
              action: 'Meine Tipps → Tipps prüfen',
            ),
            SizedBox(height: 14),
            _StepCard(
              step: '5',
              icon: Icons.analytics_rounded,
              title: 'Analyse richtig verstehen',
              text:
                  'Analyse, Signalmodell und Rücktest zeigen Auffälligkeiten aus vergangenen Ziehungen. Sie sind keine sichere Vorhersage.',
              action: 'Mehr → Analyse oder Tracking Pro',
            ),
            SizedBox(height: 20),
            _ResponsibleUseCard(),
          ],
        ),
      ),
    );
  }
}

class _IntroNotice extends StatelessWidget {
  const _IntroNotice();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BlockHeader(
            title: 'Was die App macht',
            subtitle:
                'Lotto Mind AI ist ein Analyse- und Assistenztool. Die App hilft, Ziehungsdaten, Tippstrategien und Rücktests verständlich zu betrachten.',
          ),
          SizedBox(height: 12),
          _BulletLine('Historische Ziehungen analysieren'),
          _BulletLine('Tipps mit Strategie speichern'),
          _BulletLine('Treffer transparent auswerten'),
          _BulletLine('Strategien über Zeit vergleichen'),
        ],
      ),
    );
  }
}

class _ResponsibleUseCard extends StatelessWidget {
  const _ResponsibleUseCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BlockHeader(
            title: 'Wichtig zu wissen',
            subtitle:
                'Die App gibt keine Gewinnzusage. Lotto-Teilnahme erfolgt ausschließlich außerhalb der App beim offiziellen Anbieter. Bitte verantwortungsvoll spielen.',
          ),
          SizedBox(height: 12),
          _BulletLine('Keine sichere Vorhersage'),
          _BulletLine('Rücktests sind historische Simulationen'),
          _BulletLine('Daten werden lokal gespeichert'),
          _BulletLine('Vor größeren Tests Backup im Export Center erstellen'),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String text;
  final String action;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: AppColors.primary),
                Positioned(
                  right: 5,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
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

class _BlockHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BlockHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
