import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../settings/domain/app_edition.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';
import 'about_release_screen.dart';
import 'export_center_screen.dart';
import 'pro_future_screen.dart';
import 'legal_notice_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'rule_profiles_screen.dart';
import 'rules_editor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final edition = state.edition;
    final latestWednesday = state.wednesdayDrawResults.isEmpty
        ? null
        : state.wednesdayDrawResults.first;
    final latestSaturday = state.saturdayDrawResults.isEmpty
        ? null
        : state.saturdayDrawResults.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const SectionTitle(
              title: 'Einstellungen',
              subtitle:
                  'App-Status, Datenverwaltung und Expertenoptionen an einem sicheren Ort.',
            ),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'App-Status',
                    subtitle:
                        'Kurzer Überblick über deinen aktuellen Stand in der App.',
                  ),
                  const SizedBox(height: 16),
                  _InfoLine(label: 'Aktueller Plan', value: edition.label),
                  const SizedBox(height: 10),
                  const _InfoLine(label: 'App-Status', value: 'v33 Onboarding / Erster Start'),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: 'Letzte Mittwoch-Ziehung',
                    value: latestWednesday == null
                        ? 'Noch keine Daten'
                        : _formatDate(latestWednesday.drawDate),
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: 'Letzte Samstag-Ziehung',
                    value: latestSaturday == null
                        ? 'Noch keine Daten'
                        : _formatDate(latestSaturday.drawDate),
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: 'Gespeicherte Tipps',
                    value: state.savedTips.length.toString(),
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: 'Gespeicherte Ziehungen',
                    value: state.drawResults.length.toString(),
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: 'Tracking-Prüfungen',
                    value: state.tipTrackingEntries.length.toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'Darstellung & Nutzung',
                    subtitle:
                        'Die wichtigsten Alltagsfunktionen bleiben in der Hauptnavigation. Expertenbereiche liegen unter „Mehr“.',
                  ),
                  const SizedBox(height: 14),
                  _StatusNote(
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Übersichtlicher Modus aktiv',
                    text:
                        'Start, Generator, Meine Tipps und Ziehungen sind für normale Nutzer priorisiert.',
                  ),
                  const SizedBox(height: 12),
                  _StatusNote(
                    icon: Icons.workspace_premium_rounded,
                    title: '${edition.label}-Plan',
                    text: edition.subtitle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'Datenverwaltung',
                    subtitle:
                        'Sichere deine Daten, bevor du importierst, testest oder später größere Änderungen machst.',
                  ),
                  const SizedBox(height: 14),
                  const _WarningBox(
                    text:
                        'Wichtige Daten niemals direkt löschen, ohne vorher eine Gesamtsicherung im Export Center zu erstellen.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExportCenterScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Export Center öffnen'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'Analyse-Regeln',
                    subtitle:
                        'Feinsteuerung für Tipp-Erzeugung und Analyse. Für normale Nutzung müssen diese Werte nicht geändert werden.',
                  ),
                  const SizedBox(height: 16),
                  _InfoLine(
                    label: 'Gerade Zahlen',
                    value: '${state.rules.minEven} bis ${state.rules.maxEven}',
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: 'Niedrige Zahlen (1 bis 24)',
                    value:
                        '${state.rules.minLowNumbers} bis ${state.rules.maxLowNumbers}',
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: 'Summenbereich',
                    value: '${state.rules.minSum} bis ${state.rules.maxSum}',
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RulesEditorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Regeln bearbeiten'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const _BlockHeader(
              title: 'Weitere Verwaltung',
              subtitle:
                  'Optionen für Profile, Produktstufen und technische Informationen.',
            ),
            const SizedBox(height: 12),

            _NavCard(
              title: 'Regelprofile',
              subtitle: 'Mehrere Regelsets speichern und wieder laden',
              icon: Icons.folder_copy_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RuleProfilesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _NavCard(
              title: 'Normal / Pro / Premium',
              subtitle: edition.subtitle,
              icon: Icons.workspace_premium_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProFutureScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),


            _NavCard(
              title: 'Erster Start',
              subtitle: 'Kurze Einführung für neue Nutzer',
              icon: Icons.school_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _NavCard(
              title: 'Hinweise & Verantwortung',
              subtitle: 'Keine Gewinnzusage, verantwortungsvolle Nutzung und Datenschutz',
              icon: Icons.gavel_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalNoticeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _NavCard(
              title: 'Release-Info',
              subtitle: 'Technischer Stand, Checkliste und letzte Änderungen',
              icon: Icons.rocket_launch_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AboutReleaseScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
class _BlockHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BlockHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _StatusNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _StatusNote({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
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

class _WarningBox extends StatelessWidget {
  final String text;

  const _WarningBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}
