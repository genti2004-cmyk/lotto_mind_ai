import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../domain/app_edition.dart';

class ExportCenterScreen extends StatefulWidget {
  const ExportCenterScreen({super.key});

  @override
  State<ExportCenterScreen> createState() => _ExportCenterScreenState();
}

class _ExportCenterScreenState extends State<ExportCenterScreen> {
  bool _busy = false;

  Future<String> _writeBackupFile(BuildContext context) async {
    final payload = context.read<LottoAppState>().buildExportPayload();
    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${dir.path}/lotto_mind_ai_backup_$timestamp.json');

    await file.writeAsString(jsonText, flush: true);
    return file.path;
  }

  Future<void> _showExportJson(BuildContext context) async {
    final jsonText = const JsonEncoder.withIndent('  ')
        .convert(context.read<LottoAppState>().buildExportPayload());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Backup-Vorschau'),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBackup(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final path = await _writeBackupFile(context);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup gespeichert: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup konnte nicht gespeichert werden: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareBackup(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final path = await _writeBackupFile(context);
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Lotto Mind AI Backup',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup wurde vorbereitet und geteilt.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup konnte nicht geteilt werden: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final picked = result.files.single;

      String jsonText;
      if (picked.bytes != null) {
        jsonText = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        jsonText = await File(picked.path!).readAsString();
      } else {
        throw Exception('Datei konnte nicht gelesen werden.');
      }

      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Ungültiges Backup-Format.');
      }

      if (!context.mounted) return;
      await context.read<LottoAppState>().importBackupPayload(decoded);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup wurde erfolgreich importiert.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final gate = state.gate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Center'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const SectionTitle(
              title: 'Export Center',
              subtitle:
                  'Daten sichern, teilen und später wiederherstellen. Deine Daten bleiben lokal, bis du selbst exportierst oder teilst.',
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'Datenübersicht',
                    subtitle:
                        'Diese Daten können in einer Gesamtsicherung gesichert werden.',
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Edition', value: state.edition.label),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Exportstatus',
                    value: gate.canUseExportCenter ? 'Aktiv' : 'Vorbereitet',
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DataChip(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Ziehungen',
                        value: '${state.drawResults.length}',
                      ),
                      _DataChip(
                        icon: Icons.confirmation_number_rounded,
                        label: 'Meine Tipps',
                        value: '${state.savedTips.length}',
                      ),
                      _DataChip(
                        icon: Icons.rule_rounded,
                        label: 'Profile',
                        value: '${state.ruleProfiles.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _BlockHeader(
                    title: 'Was wird gesichert?',
                    subtitle:
                        'Die Gesamtsicherung ist für Gerätewechsel, Support und spätere Wiederherstellung vorbereitet.',
                  ),
                  SizedBox(height: 16),
                  _ExportTypeTile(
                    icon: Icons.event_available_rounded,
                    title: 'Ziehungen',
                    description:
                        'Importierte Mittwoch- und Samstag-Ziehungen inklusive Superzahl, Spiel 77 und SUPER 6.',
                    label: 'Normal',
                  ),
                  _ExportTypeTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Meine Tipps',
                    description:
                        'Gespeicherte Tipps mit Zielziehung, Zieldatum, Strategie und Auswertungsstatus.',
                    label: 'Normal',
                  ),
                  _ExportTypeTile(
                    icon: Icons.analytics_rounded,
                    title: 'Tracking & Analyse',
                    description:
                        'Tracking-Verlauf, Prüfungen, Strategievergleich und vorbereitete Analyseprofile.',
                    label: 'Pro',
                  ),
                  _ExportTypeTile(
                    icon: Icons.inventory_2_rounded,
                    title: 'Gesamtsicherung',
                    description:
                        'Ein JSON-Backup mit allen unterstützten lokalen App-Daten.',
                    label: 'Premium vorbereitet',
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
                    title: 'Backup erstellen',
                    subtitle:
                        'Erstelle eine Datei, teile sie oder prüfe vorab den Inhalt als Vorschau.',
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Backup-Vorschau anzeigen',
                    icon: Icons.visibility_rounded,
                    onPressed: _busy ? null : () => _showExportJson(context),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Gesamtsicherung speichern',
                    icon: Icons.save_alt_rounded,
                    onPressed: _busy ? null : () => _saveBackup(context),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Backup teilen',
                    icon: Icons.ios_share_rounded,
                    onPressed: _busy ? null : () => _shareBackup(context),
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
                    title: 'Backup wiederherstellen',
                    subtitle:
                        'Importiere nur Backups, die aus dieser App stammen. Vor dem Import am besten zuerst ein neues Backup erstellen.',
                  ),
                  const SizedBox(height: 14),
                  const _WarningBox(
                    text:
                        'Wiederherstellen kann vorhandene lokale Daten ergänzen oder ersetzen. Nutze diese Funktion bewusst und sichere vorher den aktuellen Stand.',
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _importBackup(context),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Backup-Datei importieren'),
                  ),
                ],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
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
            fontSize: 14,
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

class _DataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportTypeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String label;

  const _ExportTypeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SmallLabel(text: label),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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

class _SmallLabel extends StatelessWidget {
  final String text;

  const _SmallLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
