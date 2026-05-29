import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../domain/draw_data_status.dart';
import '../domain/draw_result.dart';
import '../domain/draw_type.dart';
import '../domain/tip_check_result.dart';
import 'package:lotto_mind_ai/core/utils/format_utils.dart';

class DrawResultsScreen extends StatefulWidget {
  const DrawResultsScreen({super.key});

  @override
  State<DrawResultsScreen> createState() => _DrawResultsScreenState();
}

class _DrawResultsScreenState extends State<DrawResultsScreen> {
  final _dateController = TextEditingController();
  final _superNumberController = TextEditingController();
  final _spiel77Controller = TextEditingController();
  final _super6Controller = TextEditingController();

  late final List<TextEditingController> _numberControllers;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
    '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    _numberControllers = List.generate(6, (_) => TextEditingController());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _superNumberController.dispose();
    _spiel77Controller.dispose();
    _super6Controller.dispose();
    for (final c in _numberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? _parseDate(String input) {
    final parts = input.split('.');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  List<int>? _parseNumbers() {
    final values = _numberControllers
        .map((e) => int.tryParse(e.text.trim()))
        .whereType<int>()
        .toList();

    if (values.length != 6) return null;
    if (values.any((n) => n < 1 || n > 49)) return null;
    if (values.toSet().length != 6) return null;

    values.sort();
    return values;
  }

  int? _parseNullableNumber(
      TextEditingController controller, {
        int min = 0,
        int max = 49,
      }) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;

    final value = int.tryParse(raw);
    if (value == null || value < min || value > max) return null;

    return value;
  }

  String? _parseDigitString(TextEditingController controller, int length) {
    final digits = controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != length) return null;
    return digits;
  }

  Future<void> _saveDraw() async {
    final date = _parseDate(_dateController.text.trim());
    final numbers = _parseNumbers();
    final superNumber = _parseNullableNumber(
      _superNumberController,
      min: 0,
      max: 9,
    );
    final spiel77 = _parseDigitString(_spiel77Controller, 7);
    final super6 = _parseDigitString(_super6Controller, 6);

    if (date == null || numbers == null) {
      _snack(
        'Bitte gültiges Datum und 6 unterschiedliche Zahlen von 1 bis 49 eingeben.',
      );
      return;
    }

    if (_superNumberController.text.trim().isNotEmpty && superNumber == null) {
      _snack('Superzahl muss eine Ziffer von 0 bis 9 sein.');
      return;
    }

    if (_spiel77Controller.text.trim().isNotEmpty && spiel77 == null) {
      _snack('Spiel 77 muss genau 7 Ziffern haben.');
      return;
    }

    if (_super6Controller.text.trim().isNotEmpty && super6 == null) {
      _snack('SUPER 6 muss genau 6 Ziffern haben.');
      return;
    }

    await context.read<LottoAppState>().addDrawResult(
      drawDate: date,
      numbers: numbers,
      superNumber: superNumber,
      spiel77: spiel77,
      super6: super6,
    );

    for (final c in _numberControllers) {
      c.clear();
    }
    _superNumberController.clear();
    _spiel77Controller.clear();
    _super6Controller.clear();

    if (!mounted) return;
    _snack('Ziehung wurde gespeichert.');
  }

  Future<void> _runImport(Future<int> Function() action) async {
    try {
      final count = await action();
      if (!mounted) return;

      final state = context.read<LottoAppState>();
      final message = state.lastImportMessage ?? '$count Ziehungen importiert.';
      _snack(message);
    } catch (e) {
      if (!mounted) return;
      _snack('Import fehlgeschlagen: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final selectedDraw = state.selectedDrawForCheck;
    final results = state.latestCheckResults;
    final dataStatus = DrawDataStatus.fromDraws(state.drawResults);
    final latestDraw = dataStatus.latestDraw;
    final latestWednesday = dataStatus.latestWednesday;
    final latestSaturday = dataStatus.latestSaturday;
    final wednesdayCount = state.drawResults
        .where((draw) => DrawTypeX.fromDate(draw.drawDate) == DrawType.wednesday)
        .length;
    final saturdayCount = state.drawResults
        .where((draw) => DrawTypeX.fromDate(draw.drawDate) == DrawType.saturday)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const SectionTitle(
              title: 'Ziehungen',
              subtitle:
              'Lottozahlen aktualisieren, kontrollieren und als Grundlage für deine Tipps nutzen',
            ),
            const SizedBox(height: 20),

            _HeroCard(
              totalDraws: state.drawResults.length,
              latestDraw: latestDraw,
              latestWednesday: latestWednesday,
              latestSaturday: latestSaturday,
              wednesdayCount: wednesdayCount,
              saturdayCount: saturdayCount,
              isImporting: state.isImporting,
              progress: state.importProgress,
              progressLabel: state.importCurrentYear == null
                  ? (state.importLabel ?? 'Import läuft')
                  : 'Jahr ${state.importCurrentYear} • ${state.importProcessedYears}/${state.importTotalYears}',
            ),

            const SizedBox(height: 18),

            _DataQualityCard(
              latestDraw: latestDraw,
              latestWednesday: latestWednesday,
              latestSaturday: latestSaturday,
              totalDraws: state.drawResults.length,
              lastImportMessage: state.lastImportMessage,
              dataStatus: dataStatus,
            ),

            const SizedBox(height: 18),

            if (latestDraw != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _LatestDrawCard(draw: latestDraw),
              ),

            _Panel(
              title: 'Daten aktualisieren',
              subtitle:
              'Echte Lottozahlen und Superzahl zuerst. Zusatzlotterien nur, wenn sie sicher verfügbar sind.',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Daten aktualisieren',
                          icon: Icons.flash_on_rounded,
                          onPressed: state.isImporting
                              ? null
                              : () => _runImport(
                                    () => context
                                        .read<LottoAppState>()
                                        .autoImportLatestDraws(
                                          enrichAdditionalGames: false,
                                        ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Zusatzdaten prüfen',
                          icon: Icons.sync_rounded,
                          onPressed: state.isImporting
                              ? null
                              : () => _runImport(
                                    () => context
                                        .read<LottoAppState>()
                                        .autoImportLatestDraws(
                                          enrichAdditionalGames: true,
                                        ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daten aktualisieren lädt Lottozahlen + Superzahl stabil über das JSON-Archiv. Spiel 77 / SUPER 6 sind optionale Zusatzdaten und werden nur ergänzt, wenn sie sicher gefunden werden.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Mittwoch-Verlauf',
                          icon: Icons.history_rounded,
                          onPressed: state.isImporting
                              ? null
                              : () => _runImport(
                                () => context
                                .read<LottoAppState>()
                                .importHistoricalWednesdaySince2000(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Samstag-Verlauf',
                          icon: Icons.history_rounded,
                          onPressed: state.isImporting
                              ? null
                              : () => _runImport(
                                () => context
                                .read<LottoAppState>()
                                .importHistoricalSaturdaySince1955(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.isImporting) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: state.importProgress,
                        minHeight: 10,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.importCurrentYear == null
                          ? (state.importLabel ?? 'Suche läuft… bitte kurz warten.')
                          : 'Jahr ${state.importCurrentYear} • ${state.importProcessedYears}/${state.importTotalYears}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Der Import ist gesperrt, bis die aktuelle Suche fertig ist. Zusatzdaten sind optional und werden nicht erzwungen.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            _Panel(
              title: 'Ziehung manuell ergänzen',
              subtitle:
              'Für einzelne Ziehungen Zahlen, Superzahl, Spiel 77 und SUPER 6 eintragen',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InputField(
                    controller: _dateController,
                    labelText: 'Ziehungsdatum',
                    hintText: 'TT.MM.JJJJ',
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 74,
                        child: _InputField(
                          controller: _numberControllers[index],
                          labelText: '${index + 1}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  _InputField(
                    controller: _superNumberController,
                    labelText: 'Superzahl',
                    hintText: '0–9',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: _spiel77Controller,
                          labelText: 'Spiel 77',
                          hintText: '7 Ziffern',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InputField(
                          controller: _super6Controller,
                          labelText: 'SUPER 6',
                          hintText: '6 Ziffern',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Ziehung speichern',
                    icon: Icons.save_rounded,
                    onPressed: _saveDraw,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _Panel(
              title: 'Gespeicherte Ziehungen',
              subtitle: 'Nach Datum sortiert. Mittwoch und Samstag sind klar gekennzeichnet.',
              child: state.drawResults.isEmpty
                  ? const _EmptyText('Keine Ziehungen vorhanden.')
                  : Column(
                children: state.drawResults.take(30).map((draw) {
                  final selected = selectedDraw?.id == draw.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DrawTile(
                      draw: draw,
                      selected: selected,
                      onSelect: () {
                        context.read<LottoAppState>().selectDrawAndCheck(draw.id);
                      },
                      onDelete: () async {
                        await context.read<LottoAppState>().removeDrawResult(draw.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            _Panel(
              title: 'Prüfung mit ausgewählter Ziehung',
              subtitle: 'Wähle eine Ziehung aus der Liste, um passende gespeicherte Tipps zu prüfen.',
              child: selectedDraw == null
                  ? const _EmptyText('Bitte zuerst eine Ziehung auswählen.')
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DrawTile(
                    draw: selectedDraw,
                    selected: true,
                    onSelect: () {},
                  ),
                  const SizedBox(height: 14),
                  if (results.isEmpty)
                    const _EmptyText('Keine Prüfergebnisse vorhanden.')
                  else
                    ...results.take(20).map(
                          (result) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CheckResultTile(result: result),
                      ),
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


class _DataQualityCard extends StatelessWidget {
  final DrawResult? latestDraw;
  final DrawResult? latestWednesday;
  final DrawResult? latestSaturday;
  final int totalDraws;
  final String? lastImportMessage;
  final DrawDataStatus dataStatus;

  const _DataQualityCard({
    required this.latestDraw,
    required this.latestWednesday,
    required this.latestSaturday,
    required this.totalDraws,
    required this.lastImportMessage,
    required this.dataStatus,
  });

  @override
  Widget build(BuildContext context) {
    final ageDays = dataStatus.ageDays;
    final statusText = dataStatus.title;
    final statusColor = dataStatus.hasCurrentCoreData
        ? AppColors.success
        : AppColors.warning;

    return _Panel(
      title: 'Datenqualität',
      subtitle: 'Prüft, ob die gespeicherten Ziehungen für Analyse und Generator brauchbar sind.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: statusColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QualityRow(
            label: 'Importquelle',
            value: 'JSON-Archiv für Pflichtdaten, Zusatzdaten optional',
          ),
          const SizedBox(height: 8),
          _QualityRow(
            label: 'Neueste Ziehung',
            value: latestDraw == null
                ? '-'
                : '${_drawTypeLabel(latestDraw!.drawDate)} • ${_formatDate(latestDraw!.drawDate)}',
          ),
          const SizedBox(height: 8),
          _QualityRow(
            label: 'Alter der Daten',
            value: ageDays == null ? '-' : '$ageDays Tage',
          ),
          const SizedBox(height: 8),
          _QualityRow(
            label: 'Mittwoch/Samstag vorhanden',
            value: dataStatus.hasBothDrawDays ? 'Ja' : 'Bitte aktualisieren',
          ),
          const SizedBox(height: 8),
          _QualityRow(
            label: 'Gespeicherte Ziehungen',
            value: '$totalDraws',
          ),
          const SizedBox(height: 8),
          _QualityRow(
            label: 'Pflichtdaten',
            value: dataStatus.coreDataLabel,
          ),
          const SizedBox(height: 8),
          _QualityRow(
            label: 'Zusatzlotterien',
            value: dataStatus.additionalDataLabel,
          ),
          if (lastImportMessage != null && lastImportMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              lastImportMessage!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Hinweis: Die App arbeitet mit echten Ziehungsdaten. Fehlende Spiel 77 / SUPER 6 Werte werden ehrlich als nicht verfügbar angezeigt und nicht künstlich ergänzt.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  final String label;
  final String value;

  const _QualityRow({required this.label, required this.value});

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
              fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int totalDraws;
  final DrawResult? latestDraw;
  final DrawResult? latestWednesday;
  final DrawResult? latestSaturday;
  final int wednesdayCount;
  final int saturdayCount;
  final bool isImporting;
  final double progress;
  final String progressLabel;

  const _HeroCard({
    required this.totalDraws,
    required this.latestDraw,
    required this.latestWednesday,
    required this.latestSaturday,
    required this.wednesdayCount,
    required this.saturdayCount,
    required this.isImporting,
    required this.progress,
    required this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Datenstatus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Ziehungen im Überblick',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            latestDraw == null
                ? 'Noch keine Ziehungen gespeichert.'
                : 'Letzte gespeicherte Ziehung: ${_drawTypeLabel(latestDraw!.drawDate)} • ${_formatDate(latestDraw!.drawDate)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Mittwoch',
                  value: latestWednesday == null
                      ? '-'
                      : _formatDateShort(latestWednesday!.drawDate),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Samstag',
                  value: latestSaturday == null
                      ? '-'
                      : _formatDateShort(latestSaturday!.drawDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Gesamt',
                  value: '$totalDraws',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Mi/Sa',
                  value: '$wednesdayCount/$saturdayCount',
                ),
              ),
            ],
          ),
          if (isImporting) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progressLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestDrawCard extends StatelessWidget {
  final DrawResult draw;

  const _LatestDrawCard({required this.draw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Letzte gespeicherte Ziehung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_drawTypeLabel(draw.drawDate)} • ${_formatDate(draw.drawDate)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: draw.numbers.map((n) => NumberBall(number: n)).toList(),
          ),
          const SizedBox(height: 14),
          _InfoGrid(
            superNumber: draw.superNumber?.toString() ?? 'nicht verfügbar',
            spiel77: _formatOptionalGame(draw.spiel77),
            super6: _formatOptionalGame(draw.super6),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextAlign textAlign;

  const _InputField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: textAlign,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _DrawTile extends StatelessWidget {
  final DrawResult draw;
  final bool selected;
  final VoidCallback onSelect;
  final Future<void> Function()? onDelete;

  const _DrawTile({
    required this.draw,
    this.selected = false,
    required this.onSelect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSoft : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_drawTypeLabel(draw.drawDate)} • ${_formatDate(draw.drawDate)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: draw.numbers.map((n) => NumberBall(number: n)).toList(),
            ),
            const SizedBox(height: 12),
            _InfoGrid(
              superNumber: draw.superNumber?.toString() ?? '-',
              spiel77: draw.spiel77 ?? '-',
              super6: draw.super6 ?? '-',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final String superNumber;
  final String spiel77;
  final String super6;

  const _InfoGrid({
    required this.superNumber,
    required this.spiel77,
    required this.super6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExtraBox(
          label: 'Superzahl',
          value: superNumber,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ExtraBox(
                label: 'Spiel 77',
                value: spiel77,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ExtraBox(
                label: 'SUPER 6',
                value: super6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExtraBox extends StatelessWidget {
  final String label;
  final String value;

  const _ExtraBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckResultTile extends StatelessWidget {
  final TipCheckResult result;

  const _CheckResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.tip.numbers.join(' • '),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.hitCount} Richtige',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.tip.numbers.map((n) {
              final matched = result.matchedNumbers.contains(n);
              return NumberBall(number: n, highlighted: matched);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}


String _formatOptionalGame(String? value) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty) return 'nicht verfügbar';
  return clean;
}

String _additionalQualityLabel(DrawResult? latestDraw) {
  if (latestDraw == null) return 'nicht verfügbar';
  final hasSpiel77 = latestDraw.spiel77 != null && latestDraw.spiel77!.trim().isNotEmpty;
  final hasSuper6 = latestDraw.super6 != null && latestDraw.super6!.trim().isNotEmpty;
  if (hasSpiel77 && hasSuper6) return 'vorhanden';
  if (hasSpiel77 || hasSuper6) return 'teilweise verfügbar';
  return 'nicht verfügbar';
}

String _formatDate(DateTime value) => AppFormatUtils.date(value);
String _formatDateShort(DateTime value) => AppFormatUtils.dateShort(value);

String _drawTypeLabel(DateTime date) {
  return DrawTypeX.fromDate(date).label;
}

DrawResult? _latestDrawForType(List<DrawResult> draws, DrawType type) {
  for (final draw in draws) {
    if (DrawTypeX.fromDate(draw.drawDate) == type) return draw;
  }
  return null;
}
