import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../domain/app_edition.dart';

class ProFutureScreen extends StatelessWidget {
  const ProFutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final edition = state.edition;
    final gate = state.gate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Normal / Pro / Premium'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const SectionTitle(
              title: 'Produktstufen',
              subtitle: 'Interne Grundlage für Normal, Pro und Premium',
            ),
            const SizedBox(height: 20),
            _EditionCard(
              edition: AppEdition.free,
              active: edition == AppEdition.free,
              onTap: () => state.setEdition(AppEdition.free),
            ),
            const SizedBox(height: 14),
            _EditionCard(
              edition: AppEdition.pro,
              active: edition == AppEdition.pro,
              onTap: () => state.setEdition(AppEdition.pro),
            ),
            const SizedBox(height: 14),
            _EditionCard(
              edition: AppEdition.future,
              active: edition == AppEdition.future,
              onTap: () => state.setEdition(AppEdition.future),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'Aktive Freischaltungen',
                    subtitle:
                    'Hier siehst du, welche Funktionsgruppen in der aktuellen Edition verfügbar sind.',
                  ),
                  const SizedBox(height: 16),
                  _FeatureRow(
                    label: 'Favoriten-System',
                    enabled: gate.canUseFavorites,
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    label: 'Erweiterte Statistiken',
                    enabled: gate.canUseAdvancedStatistics,
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    label: 'Erweiterter Verlauf',
                    enabled: gate.canUseAdvancedHistory,
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    label: 'Premium-Regelprofile',
                    enabled: gate.canUseRuleProfiles,
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    label: 'Cloud Sync',
                    enabled: gate.canUseCloudSync,
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    label: 'Premium Export Center',
                    enabled: gate.canUseExportCenter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BlockHeader(
                    title: 'Hinweis',
                    subtitle:
                    'Diese Stufen sind bewusst lokal vorbereitet. Später kann dieselbe Struktur mit In-App-Käufen, Lizenzprüfung oder Cloud-Account verbunden werden.',
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

class _EditionCard extends StatelessWidget {
  final AppEdition edition;
  final bool active;
  final VoidCallback onTap;

  const _EditionCard({
    required this.edition,
    required this.active,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edition.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      edition.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: active ? AppColors.success : AppColors.textMuted,
              ),
            ],
          ),
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
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final bool enabled;

  const _FeatureRow({
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Icon(
          enabled ? Icons.check_rounded : Icons.close_rounded,
          color: enabled ? AppColors.success : AppColors.textMuted,
        ),
      ],
    );
  }
}