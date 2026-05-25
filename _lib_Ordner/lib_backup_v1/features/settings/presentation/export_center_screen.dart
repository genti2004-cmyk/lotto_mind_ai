import 'dart:convert';
import 'dart:io';
import '../domain/app_edition.dart';

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
    final file = File('${dir.path}/lotto_pro_analyzer_backup_$timestamp.json');

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
          title: const Text('Export Vorschau'),
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
        text: 'Lotto Pro Analyzer Backup',
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
              subtitle: 'Backup, Teilen und Wiederherstellen',
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    title: 'Exportstatus',
                    subtitle:
                    'Der aktuelle Zustand deiner lokalen Daten und Export-Funktionen.',
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Edition',
                    value: state.edition.label,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Export freigeschaltet',
                    value: gate.canUseExportCenter ? 'Ja' : 'Vorbereitet',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Tipps',
                    value: '${state.savedTips.length}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Ziehungen',
                    value: '${state.drawResults.length}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Rule Profiles',
                    value: '${state.ruleProfiles.length}',
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
                    title: 'Backup Aktionen',
                    subtitle:
                    'Kompletten App-Zustand als JSON ansehen, speichern, teilen und wieder importieren.',
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Export-Vorschau anzeigen',
                    icon: Icons.code_rounded,
                    onPressed: _busy ? null : () => _showExportJson(context),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Backup als Datei speichern',
                    icon: Icons.save_alt_rounded,
                    onPressed: _busy ? null : () => _saveBackup(context),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Backup teilen',
                    icon: Icons.ios_share_rounded,
                    onPressed: _busy ? null : () => _shareBackup(context),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _importBackup(context),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Backup importieren'),
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