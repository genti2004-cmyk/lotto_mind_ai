import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lotto_mind_ai/features/settings/domain/app_edition.dart';

import '../../../core/constants/app_colors.dart';
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
              subtitle: 'Store-Status, Version und finale Freigabe-Checks',
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'App-Status',
                    subtitle: 'Die wichtigsten Produktdaten für den Release auf einen Blick.',
                  ),
                  const SizedBox(height: 14),
                  const _InfoRow(label: 'App-Name', value: 'Lotto Mind AI'),
                  const SizedBox(height: 10),
                  const _InfoRow(label: 'Release-Stufe', value: 'Final Pro / Store Ready'),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Edition', value: state.edition.label),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Gespeicherte Tipps', value: '${state.savedTips.length}'),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Gespeicherte Ziehungen', value: '${state.drawResults.length}'),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Regelprofile', value: '${state.ruleProfiles.length}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BlockHeader(
                    title: 'Release-Checkliste',
                    subtitle: 'Vor dem Upload in die Play Console einmal komplett abhaken.',
                  ),
                  SizedBox(height: 14),
                  _ReleaseLine('App startet stabil auf echtem Gerät'),
                  _ReleaseLine('Generator, Analyse und Meine Tipps laufen fehlerfrei'),
                  _ReleaseLine('Branding ist überall auf Lotto Mind AI umgestellt'),
                  _ReleaseLine('AAB statt APK für den Play-Upload vorbereitet'),
                  _ReleaseLine('Versionsnummer und versionCode wurden erhöht'),
                  _ReleaseLine('Datensicherheitsangaben und Datenschutzerklärung sind vorbereitet'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BlockHeader(
                    title: 'Finale Schritte vor Veröffentlichung',
                    subtitle: 'Diese Punkte solltest du direkt vor dem Release noch erledigen.',
                  ),
                  SizedBox(height: 14),
                  Text(
                    '1. App-Icon und Splash final prüfen'
                    '2. Build mit Release-Signatur als AAB erzeugen'
                    '3. Play App Signing aktivieren'
                    '4. Store-Eintrag, Screenshots und Datenschutzerklärung eintragen'
                    '5. Interne Testspur in der Play Console nutzen'
                    '6. Erst danach Produktions-Release freigeben',
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

class _BlockHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BlockHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.45)),
      ],
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
