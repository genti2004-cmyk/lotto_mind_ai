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
import 'rule_profiles_screen.dart';
import 'rules_editor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final edition = state.edition;

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
              'App-Status, Analyse-Regeln, Profile und Systemfunktionen verwalten',
            ),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'App-Status',
                    subtitle:
                    'Alle wichtigen Daten deiner App und deines aktuellen Arbeitsstandes.',
                  ),
                  const SizedBox(height: 16),
                  _InfoLine(label: 'Edition', value: edition.label),
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
                    label: 'Regelprofile',
                    value: state.ruleProfiles.length.toString(),
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
                    'Aktive Regeln für die AI-Analyse und Tipp-Generierung.',
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
                  FilledButton.icon(
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
              title: 'Weitere Bereiche',
              subtitle:
              'Zusätzliche Verwaltungs- und Projektbereiche in klarer Reihenfolge.',
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
              title: 'Backup & Export',
              subtitle: 'Sichern, teilen, exportieren und importieren',
              icon: Icons.ios_share_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExportCenterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _NavCard(
              title: 'Pro-Funktionen',
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
              title: 'Release-Info',
              subtitle: 'Release-Status und letzte Checkliste',
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