import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../../draws/domain/draw_data_status.dart';
import '../../draws/domain/draw_result.dart';
import '../../draws/presentation/draw_results_screen.dart';
import '../../generator/presentation/generator_screen.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../../tips/presentation/my_tips_screen.dart';
import 'package:lotto_mind_ai/core/utils/format_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final dataStatus = DrawDataStatus.fromDraws(state.drawResults);
    final latestWednesday = dataStatus.latestWednesday;
    final latestSaturday = dataStatus.latestSaturday;
    final latestDrawDate = dataStatus.latestDraw?.drawDate;
    final dataAgeDays = dataStatus.ageDays;
    final dataNeedsUpdate = dataStatus.needsUpdate;
    final tip = state.lastGeneratedTip;
    final superNumber = state.lastGeneratedSuperNumber;
    final hasTip = tip != null && tip.isNotEmpty;
    final hasDraws = state.drawResults.isNotEmpty;
    final tipsCount = state.savedTips.length;
    final hasSavedTips = tipsCount > 0;
    final hasSelectedDraw = state.selectedDrawForCheck != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            const _SimpleHeader(),
            const SizedBox(height: 14),
            _StatusCard(
              latestWednesday: latestWednesday,
              latestSaturday: latestSaturday,
              drawCount: state.drawResults.length,
            ),
            const SizedBox(height: 14),
            _DataFreshnessCard(
              latestDrawDate: latestDrawDate,
              dataAgeDays: dataAgeDays,
              dataNeedsUpdate: dataNeedsUpdate,
              hasWednesday: latestWednesday != null,
              hasSaturday: latestSaturday != null,
              dataStatus: dataStatus,
              onUpdateDraws: () => _open(context, const DrawResultsScreen()),
            ),
            const SizedBox(height: 14),
            _NextStepAssistantCard(
              hasDraws: hasDraws,
              hasSavedTips: hasSavedTips,
              hasSelectedDraw: hasSelectedDraw,
              dataNeedsUpdate: dataNeedsUpdate,
              tipsCount: tipsCount,
              onUpdateDraws: () => _open(context, const DrawResultsScreen()),
              onCreateTip: () => _open(context, const GeneratorScreen()),
              onOpenTips: () => _open(context, const MyTipsScreen()),
            ),
            const SizedBox(height: 14),
            _PrimaryActionGrid(
              onUpdateDraws: () => _open(context, const DrawResultsScreen()),
              onCreateTip: () => _open(context, const GeneratorScreen()),
              onOpenTips: () => _open(context, const MyTipsScreen()),
            ),
            const SizedBox(height: 14),
            _LastTipCard(
              hasTip: hasTip,
              tip: tip ?? const <int>[],
              superNumber: superNumber,
            ),
            const SizedBox(height: 14),
            _CompactInfoCard(state: state),
          ],
        ),
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LottoMind AI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ziehungen aktualisieren, Tipp erstellen und Ergebnisse klar prüfen.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final DrawResult? latestWednesday;
  final DrawResult? latestSaturday;
  final int drawCount;

  const _StatusCard({
    required this.latestWednesday,
    required this.latestSaturday,
    required this.drawCount,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Datenstatus',
      subtitle: 'So weißt du sofort, ob die Ziehungen aktuell sind.',
      child: Column(
        children: [
          _DrawStatusLine(
            label: 'Letzte Mittwoch-Ziehung',
            draw: latestWednesday,
          ),
          const SizedBox(height: 10),
          _DrawStatusLine(
            label: 'Letzte Samstag-Ziehung',
            draw: latestSaturday,
          ),
          const SizedBox(height: 10),
          _InfoLine(label: 'Gespeicherte Ziehungen', value: '$drawCount'),
        ],
      ),
    );
  }
}


class _DataFreshnessCard extends StatelessWidget {
  final DateTime? latestDrawDate;
  final int? dataAgeDays;
  final bool dataNeedsUpdate;
  final bool hasWednesday;
  final bool hasSaturday;
  final DrawDataStatus dataStatus;
  final VoidCallback onUpdateDraws;

  const _DataFreshnessCard({
    required this.latestDrawDate,
    required this.dataAgeDays,
    required this.dataNeedsUpdate,
    required this.hasWednesday,
    required this.hasSaturday,
    required this.dataStatus,
    required this.onUpdateDraws,
  });

  @override
  Widget build(BuildContext context) {
    final title = dataStatus.title;
    final subtitle = dataStatus.guidance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dataNeedsUpdate ? AppColors.warningSoft : AppColors.successSoft,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: dataNeedsUpdate
              ? AppColors.warning.withValues(alpha: 0.24)
              : AppColors.success.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                dataNeedsUpdate ? Icons.sync_problem_rounded : Icons.verified_rounded,
                color: dataNeedsUpdate ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(label: 'Mittwoch-Daten', value: hasWednesday ? 'vorhanden' : 'fehlen'),
          const SizedBox(height: 8),
          _InfoLine(label: 'Samstag-Daten', value: hasSaturday ? 'vorhanden' : 'fehlen'),
          const SizedBox(height: 8),
          _InfoLine(label: 'Pflichtdaten', value: dataStatus.coreDataLabel),
          const SizedBox(height: 8),
          _InfoLine(label: 'Zusatzlotterien', value: dataStatus.additionalDataLabel),
          if (dataNeedsUpdate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpdateDraws,
                icon: const Icon(Icons.update_rounded, size: 18),
                label: const Text('Ziehungen jetzt aktualisieren'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _NextStepAssistantCard extends StatelessWidget {
  final bool hasDraws;
  final bool hasSavedTips;
  final bool hasSelectedDraw;
  final bool dataNeedsUpdate;
  final int tipsCount;
  final VoidCallback onUpdateDraws;
  final VoidCallback onCreateTip;
  final VoidCallback onOpenTips;

  const _NextStepAssistantCard({
    required this.hasDraws,
    required this.hasSavedTips,
    required this.hasSelectedDraw,
    required this.dataNeedsUpdate,
    required this.tipsCount,
    required this.onUpdateDraws,
    required this.onCreateTip,
    required this.onOpenTips,
  });

  @override
  Widget build(BuildContext context) {
    final step = _nextStep;
    final steps = <_ChecklistStep>[
      _ChecklistStep(
        label: 'Ziehungen aktualisieren',
        done: hasDraws,
        help: hasDraws ? 'Daten sind vorhanden.' : 'Starte mit dem Import der letzten Ziehungen.',
      ),
      _ChecklistStep(
        label: 'Tipp speichern',
        done: hasSavedTips,
        help: hasSavedTips ? '$tipsCount Tipp${tipsCount == 1 ? '' : 's'} gespeichert.' : 'Erstelle danach einen Tipp und speichere ihn.',
      ),
      _ChecklistStep(
        label: 'Tipps prüfen',
        done: hasSelectedDraw && hasSavedTips,
        help: hasSelectedDraw ? 'Prüfziehung ist gewählt.' : 'Wähle eine Ziehung und prüfe passende Tipps.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assistant_direction_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start-Assistent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChecklistLine(step: item),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: step.onTap,
              icon: Icon(step.icon, size: 18),
              label: Text(step.buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _AssistantStep get _nextStep {
    if (!hasDraws) {
      return _AssistantStep(
        description: 'Es fehlen noch Ziehungen. Aktualisiere zuerst die Daten, damit Tipps und Prüfungen sinnvoll funktionieren.',
        buttonLabel: 'Ziehungen aktualisieren',
        icon: Icons.update_rounded,
        onTap: onUpdateDraws,
      );
    }

    if (dataNeedsUpdate) {
      return _AssistantStep(
        description: 'Die gespeicherten Ziehungen wirken nicht mehr ganz aktuell. Aktualisiere die Daten, bevor du neue Tipps bewertest.',
        buttonLabel: 'Daten aktualisieren',
        icon: Icons.sync_rounded,
        onTap: onUpdateDraws,
      );
    }

    if (!hasSavedTips) {
      return _AssistantStep(
        description: 'Die Ziehungen sind bereit. Erstelle jetzt einen Tipp und speichere ihn in „Meine Tipps“.',
        buttonLabel: 'Tipp erstellen',
        icon: Icons.casino_rounded,
        onTap: onCreateTip,
      );
    }

    return _AssistantStep(
      description: 'Du hast gespeicherte Tipps. Öffne „Meine Tipps“, prüfe passende Ziehungen und vergleiche später die Strategien.',
      buttonLabel: 'Meine Tipps öffnen',
      icon: Icons.fact_check_rounded,
      onTap: onOpenTips,
    );
  }
}

class _AssistantStep {
  final String description;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _AssistantStep({
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });
}

class _ChecklistStep {
  final String label;
  final bool done;
  final String help;

  const _ChecklistStep({
    required this.label,
    required this.done,
    required this.help,
  });
}

class _ChecklistLine extends StatelessWidget {
  final _ChecklistStep step;

  const _ChecklistLine({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          step.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: step.done ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.help,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionGrid extends StatelessWidget {
  final VoidCallback onUpdateDraws;
  final VoidCallback onCreateTip;
  final VoidCallback onOpenTips;

  const _PrimaryActionGrid({
    required this.onUpdateDraws,
    required this.onCreateTip,
    required this.onOpenTips,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Was möchtest du tun?',
      subtitle: 'Die drei wichtigsten Aktionen für normale Nutzer.',
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.update_rounded,
            title: 'Ziehungen aktualisieren',
            subtitle: 'Neue Mittwoch- und Samstag-Ziehungen laden und prüfen.',
            onTap: onUpdateDraws,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.casino_rounded,
            title: 'Neuen Tipp erstellen',
            subtitle: 'Tipp für die nächste passende Ziehung erzeugen.',
            onTap: onCreateTip,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.bookmarks_rounded,
            title: 'Meine Tipps prüfen',
            subtitle: 'Gespeicherte Tipps ansehen und gegen passende Ziehungen prüfen.',
            onTap: onOpenTips,
          ),
        ],
      ),
    );
  }
}

class _LastTipCard extends StatelessWidget {
  final bool hasTip;
  final List<int> tip;
  final int? superNumber;

  const _LastTipCard({
    required this.hasTip,
    required this.tip,
    required this.superNumber,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Letzter Tipp',
      subtitle: 'Der zuletzt erzeugte Tipp bleibt hier sichtbar.',
      child: !hasTip
          ? const Text(
              'Noch kein Tipp erstellt. Starte mit „Neuen Tipp erstellen“.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tip.map((n) => NumberBall(number: n)).toList(),
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  label: 'Superzahl',
                  value: superNumber?.toString() ?? '-',
                ),
              ],
            ),
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  final LottoAppState state;

  const _CompactInfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Analyse kurz erklärt',
      subtitle: 'Expertenwerte bleiben erreichbar, stehen aber nicht mehr im Vordergrund.',
      child: Column(
        children: [
          _InfoLine(label: 'Profil', value: state.analysisProfileLabel),
          const SizedBox(height: 8),
          _InfoLine(label: 'Analyse-Fenster', value: state.analysisWindowLabel),
          const SizedBox(height: 8),
          _InfoLine(label: 'Ziehungstag', value: state.analysisDrawFilterLabel),
        ],
      ),
    );
  }
}

class _DrawStatusLine extends StatelessWidget {
  final String label;
  final DrawResult? draw;

  const _DrawStatusLine({
    required this.label,
    required this.draw,
  });

  @override
  Widget build(BuildContext context) {
    final value = draw == null
        ? 'Noch keine Ziehung vorhanden'
        : '${_formatDate(draw!.drawDate)} • SZ ${draw!.superNumber?.toString() ?? '-'}';
    return _InfoLine(label: label, value: value);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatDate(DateTime date) => AppFormatUtils.date(date);
