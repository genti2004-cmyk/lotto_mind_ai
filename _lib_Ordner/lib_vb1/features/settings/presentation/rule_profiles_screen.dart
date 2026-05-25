import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';

class RuleProfilesScreen extends StatelessWidget {
  const RuleProfilesScreen({super.key});

  Future<void> _showCreateDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Regelprofil speichern'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Profilname',
              hintText: 'z. B. Smart Profil Stark',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                await context
                    .read<LottoAppState>()
                    .saveCurrentRulesAsProfile(name);

                if (!context.mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Regelprofil gespeichert.')),
                );
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final profiles = state.ruleProfiles;
    final canUseProfiles = state.gate.canUseRuleProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Profiles'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const SectionTitle(
              title: 'Regelprofile',
              subtitle: 'Mehrere Analyse-Profile lokal speichern und laden',
            ),
            const SizedBox(height: 20),
            if (!canUseProfiles)
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BlockHeader(
                      title: 'Nicht freigeschaltet',
                      subtitle:
                      'Rule Profiles sind für die Future-Stufe vorbereitet.',
                    ),
                  ],
                ),
              )
            else ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BlockHeader(
                      title: 'Aktive Regeln sichern',
                      subtitle:
                      'Speichere den aktuellen Analyse-Regelsatz als wiederverwendbares Profil.',
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Aktuelle Regeln als Profil speichern',
                      icon: Icons.save_rounded,
                      onPressed: () => _showCreateDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (profiles.isEmpty)
                const AppCard(
                  child: Text(
                    'Noch keine Regelprofile gespeichert.',
                    style: TextStyle(fontSize: 15),
                  ),
                )
              else
                ...profiles.map(
                      (profile) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Profil laden',
                                onPressed: () async {
                                  await context
                                      .read<LottoAppState>()
                                      .applyRuleProfile(profile.id);

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Regelprofil geladen.'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.upload_rounded),
                              ),
                              IconButton(
                                tooltip: 'Profil löschen',
                                onPressed: () async {
                                  await context
                                      .read<LottoAppState>()
                                      .deleteRuleProfile(profile.id);

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Regelprofil gelöscht.'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Gerade Zahlen',
                            value:
                            '${profile.rules.minEven} bis ${profile.rules.maxEven}',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Niedrige Zahlen',
                            value:
                            '${profile.rules.minLowNumbers} bis ${profile.rules.maxLowNumbers}',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Summenbereich',
                            value:
                            '${profile.rules.minSum} bis ${profile.rules.maxSum}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
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
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
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
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}