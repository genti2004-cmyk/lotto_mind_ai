import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/number_ball.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
import '../../draws/domain/draw_result.dart';
import '../domain/analysis_signal.dart';
import '../domain/number_analysis_score.dart';
import '../services/number_analysis_service.dart';
import '../../generator/provider/lotto_app_state.dart';
import 'ai_max_mode_screen.dart';
import 'win_simulation_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final summary = state.analysisSummary;
    final aiSummary = state.analysisAiSummary;
    final proSummary = state.analysisProSummary;
    const signalService = NumberAnalysisService();
    final frequencyScores = signalService.topBySignal(
      state.analysisDrawResults,
      AnalysisSignal.frequency,
      limit: 6,
    );
    final overdueScores = signalService.topBySignal(
      state.analysisDrawResults,
      AnalysisSignal.overdue,
      limit: 6,
    );
    final intervalScores = signalService.topBySignal(
      state.analysisDrawResults,
      AnalysisSignal.interval,
      limit: 6,
    );
    final hybridScores = signalService.topBySignal(
      state.analysisDrawResults,
      AnalysisSignal.hybrid,
      limit: 6,
    );
    final rangeScores = signalService.analyzeNumbers(state.analysisDrawResults)
      ..sort((a, b) {
        final byScore = b.rangePatternScore.compareTo(a.rangePatternScore);
        return byScore != 0 ? byScore : a.number.compareTo(b.number);
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            SectionTitle(
              title: 'Analyse',
              subtitle:
              'Häufigkeit, Intervalle, Rückstände und Muster getrennt für Mittwoch und Samstag.',
              trailing: _TopBadge(label: state.analysisStrengthLabel),
            ),
            const SizedBox(height: 18),
            _HeroCard(state: state),
            const SizedBox(height: 14),
            _QuickActionsCard(
              onAiMax: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiMaxModeScreen()),
                );
              },
              onSimulation: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WinSimulationScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _FilterCard(state: state),
            const SizedBox(height: 14),
            _OverviewGrid(
              drawCount: summary.drawCount,
              averageSum: summary.averageSum,
              averageEven: summary.averageEven,
              averageLow: summary.averageLow,
              averageSpread: summary.averageSpread,
            ),
            const SizedBox(height: 14),
            _SignalModelCard(
              frequencyScores: frequencyScores,
              overdueScores: overdueScores,
              intervalScores: intervalScores,
              hybridScores: hybridScores,
              rangeScores: rangeScores.take(6).toList(),
            ),
            const SizedBox(height: 14),
            _AiInsightCard(
              aiSummary: aiSummary,
              proSummary: proSummary,
              onApplyTip: proSummary.bestTip.length == 6
                  ? () {
                context.read<LottoAppState>().setGeneratedNumbers(
                  proSummary.bestTip,
                  superNumber: state.recommendedSuperNumber,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pro-Tipp wurde in den Generator übernommen.'),
                  ),
                );
              }
                  : null,
            ),
            const SizedBox(height: 14),
            _PatternBoard(summary: summary, proSummary: proSummary),
            const SizedBox(height: 14),
            _DrawDayPanel(
              title: 'Mittwoch',
              subtitle: 'Eigene Trendbewertung für die Mittwoch-Ziehungen.',
              draws: state.wednesdayDrawResults,
            ),
            const SizedBox(height: 14),
            _DrawDayPanel(
              title: 'Samstag',
              subtitle: 'Eigene Trendbewertung für die Samstag-Ziehungen.',
              draws: state.saturdayDrawResults,
            ),
          ],
        ),
      ),
    );
  }
}


class _SignalModelCard extends StatelessWidget {
  const _SignalModelCard({
    required this.frequencyScores,
    required this.overdueScores,
    required this.intervalScores,
    required this.hybridScores,
    required this.rangeScores,
  });

  final List<NumberAnalysisScore> frequencyScores;
  final List<NumberAnalysisScore> overdueScores;
  final List<NumberAnalysisScore> intervalScores;
  final List<NumberAnalysisScore> hybridScores;
  final List<NumberAnalysisScore> rangeScores;

  bool get _hasScores => hybridScores.isNotEmpty &&
      hybridScores.any((score) => score.hybridScore > 0 || score.hitCount > 0);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signalmodell',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Die Analyse zeigt getrennt, welche Zahlen nach Häufigkeit, Rückstand, Intervall und Hybrid-Score aktuell auffällig sind. Das ist eine Bewertung historischer Muster, keine sichere Vorhersage.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (!_hasScores)
            const Text(
              'Noch nicht genug Ziehungen für eine belastbare Signalübersicht.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            _SignalTopRow(
              title: 'Häufigkeit',
              subtitle: 'kam im Analysefenster überdurchschnittlich oft vor',
              icon: Icons.bar_chart_rounded,
              scores: frequencyScores,
              signal: AnalysisSignal.frequency,
            ),
            const SizedBox(height: 12),
            _SignalTopRow(
              title: 'Rückstand',
              subtitle: 'liegt aktuell länger zurück als üblich',
              icon: Icons.history_toggle_off_rounded,
              scores: overdueScores,
              signal: AnalysisSignal.overdue,
            ),
            const SizedBox(height: 12),
            _SignalTopRow(
              title: 'Intervall',
              subtitle: 'aktueller Abstand passt zum typischen Zahlenzyklus',
              icon: Icons.timeline_rounded,
              scores: intervalScores,
              signal: AnalysisSignal.interval,
            ),
            const SizedBox(height: 12),
            _RangePatternRow(scores: rangeScores),
            const SizedBox(height: 12),
            const _SpacingPatternInfoRow(),
            const SizedBox(height: 12),
            _SignalTopRow(
              title: 'Hybrid',
              subtitle: 'kombiniert Häufigkeit, Rückstand, Intervall, Muster, Bereichsverteilung und Streuung',
              icon: Icons.auto_awesome_rounded,
              scores: hybridScores,
              signal: AnalysisSignal.hybrid,
              highlighted: true,
            ),
            const SizedBox(height: 14),
            const _SignalLegend(),
          ],
        ],
      ),
    );
  }
}

class _SignalTopRow extends StatelessWidget {
  const _SignalTopRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.scores,
    required this.signal,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<NumberAnalysisScore> scores;
  final AnalysisSignal signal;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final topScores = scores.take(6).toList();
    final top = topScores.isEmpty ? null : topScores.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.infoSoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? AppColors.primary.withValues(alpha: 0.28) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: highlighted ? Colors.white : AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (top != null) ...[
                const SizedBox(width: 8),
                _SignalScoreBadge(value: top.scoreFor(signal)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (topScores.isEmpty)
            const Text(
              'Keine Daten im aktuellen Analysefenster.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topScores
                  .map(
                    (score) => _SignalNumberPill(
                      score: score,
                      signal: signal,
                      highlighted: highlighted,
                    ),
                  )
                  .toList(),
            ),
          if (top != null) ...[
            const SizedBox(height: 10),
            Text(
              'Top: ${top.number} · ${top.shortExplanation}',
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _RangePatternRow extends StatelessWidget {
  const _RangePatternRow({required this.scores});

  final List<NumberAnalysisScore> scores;

  @override
  Widget build(BuildContext context) {
    final topScores = scores.take(6).toList();
    final top = topScores.isEmpty ? null : topScores.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bereichsmuster',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'bewertet die Zahlenblöcke 1–10, 11–20, 21–30, 31–40 und 41–49',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (top != null) ...[
                const SizedBox(width: 8),
                _SignalScoreBadge(value: top.rangePatternScore),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (topScores.isEmpty)
            const Text(
              'Keine Daten im aktuellen Analysefenster.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topScores
                  .map((score) => _RangeNumberPill(score: score))
                  .toList(),
            ),
          if (top != null) ...[
            const SizedBox(height: 10),
            Text(
              'Top: ${top.number} · ${top.rangePatternLabel} · Bereich ${((top.rangePatternScore * 100).round()).clamp(0, 100)}%',
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpacingPatternInfoRow extends StatelessWidget {
  const _SpacingPatternInfoRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scatter_plot_rounded, size: 18, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Abstandsmuster',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Signal-Tipps werden zusätzlich auf Streuung geprüft: enge 3er-Cluster, sehr gleichmäßige Lücken und zu kleine Gesamtspanne werden sanft vermieden.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeNumberPill extends StatelessWidget {
  const _RangeNumberPill({required this.score});

  final NumberAnalysisScore score;

  @override
  Widget build(BuildContext context) {
    final percent = (score.rangePatternScore * 100).round().clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NumberBall(number: score.number, size: 30),
          const SizedBox(width: 7),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalNumberPill extends StatelessWidget {
  const _SignalNumberPill({
    required this.score,
    required this.signal,
    required this.highlighted,
  });

  final NumberAnalysisScore score;
  final AnalysisSignal signal;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final percent = (score.scoreFor(signal) * 100).round().clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NumberBall(
            number: score.number,
            size: 30,
            highlighted: highlighted,
          ),
          const SizedBox(width: 7),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalScoreBadge extends StatelessWidget {
  const _SignalScoreBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${(value * 100).round().clamp(0, 100)}%',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SignalLegend extends StatelessWidget {
  const _SignalLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _SignalChip(label: 'Häufigkeit'),
        _SignalChip(label: 'Rückstand'),
        _SignalChip(label: 'Intervall'),
        _SignalChip(label: 'Muster'),
        _SignalChip(label: 'Bereich 1–10'),
        _SignalChip(label: '11–20'),
        _SignalChip(label: '21–30'),
        _SignalChip(label: '31–40'),
        _SignalChip(label: '41–49'),
        _SignalChip(label: 'Hybrid'),
      ],
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});

  final LottoAppState state;

  @override
  Widget build(BuildContext context) {
    final total = state.drawResults.length;
    final active = state.analysisDrawResults.length;
    final ratio = total == 0 ? 0 : ((active / total) * 100).round();

    return Container(
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
            color: Color(0x332563EB),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysefenster aktiv',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Muster-Auswertung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            state.analysisWindowLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Filter: ${state.analysisFilterLabel} • Profil: ${state.analysisProfileLabel} • $active aktive Ziehungen',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: total == 0 ? 0 : active / total,
              backgroundColor: Colors.white.withOpacity(0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Aktives Fenster',
                  value: '$ratio%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Gesamtbasis',
                  value: '$total Ziehungen',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.onAiMax, required this.onSimulation});

  final VoidCallback onAiMax;
  final VoidCallback onSimulation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schnellaktionen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Öffne die Expertenanalyse oder prüfe im Rücktest, wie frühere Tipps abgeschnitten hätten.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Expertenanalyse',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: onAiMax,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Rücktest',
                  icon: Icons.query_stats_rounded,
                  onTap: onSimulation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            const Text(
              'Rücktest',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.state});

  final LottoAppState state;

  @override
  Widget build(BuildContext context) {
    final activeCount = state.analysisDrawResults.length;
    final maxCount = state.maxAnalysisDrawCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysefenster steuern',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lege fest, welche Ziehungen in die aktuelle Analyse einfließen und mit welchem Profil die Gewichtung bewertet wird.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const _SubLabel('Ziehungsfilter'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ChoiceChipButton(
                label: 'Beide',
                selected: state.analysisDrawFilter == AnalysisDrawFilter.all,
                onTap: () => context
                    .read<LottoAppState>()
                    .setAnalysisDrawFilter(AnalysisDrawFilter.all),
              ),
              _ChoiceChipButton(
                label: 'Mittwoch',
                selected:
                state.analysisDrawFilter == AnalysisDrawFilter.wednesday,
                onTap: () => context
                    .read<LottoAppState>()
                    .setAnalysisDrawFilter(AnalysisDrawFilter.wednesday),
              ),
              _ChoiceChipButton(
                label: 'Samstag',
                selected:
                state.analysisDrawFilter == AnalysisDrawFilter.saturday,
                onTap: () => context
                    .read<LottoAppState>()
                    .setAnalysisDrawFilter(AnalysisDrawFilter.saturday),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SubLabel('Analyseprofil'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ChoiceChipButton(
                label: 'Defensiv',
                selected: state.analysisProfile == AnalysisProfile.defensive,
                onTap: () => context
                    .read<LottoAppState>()
                    .setAnalysisProfile(AnalysisProfile.defensive),
              ),
              _ChoiceChipButton(
                label: 'Mittel',
                selected: state.analysisProfile == AnalysisProfile.balanced,
                onTap: () => context
                    .read<LottoAppState>()
                    .setAnalysisProfile(AnalysisProfile.balanced),
              ),
              _ChoiceChipButton(
                label: 'Aggressiv',
                selected: state.analysisProfile == AnalysisProfile.aggressive,
                onTap: () => context
                    .read<LottoAppState>()
                    .setAnalysisProfile(AnalysisProfile.aggressive),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const _SubLabel('Analyse-Ziehungen'),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<LottoAppState>().setAnalysisToAllHistory(),
                child: const Text(
                  'Alles',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$activeCount von $maxCount Ziehungen aktiv',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Der Analyse-Zeitraum wird zentral im Generator/AI-Bereich gesteuert. Diese Analyse-Seite zeigt nur den aktuell aktiven Zeitraum an.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _RangeHint(
                  label: 'Aktiver Zeitraum',
                  value: state.analysisWindowLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RangeHint(
                  label: 'Konfidenz',
                  value: state.analysisStrengthLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          )
              : null,
          color: selected ? null : AppColors.surfaceSoft,
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
          boxShadow: selected
              ? const [
            BoxShadow(
              color: Color(0x1A2563EB),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _RangeHint extends StatelessWidget {
  const _RangeHint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.drawCount,
    required this.averageSum,
    required this.averageEven,
    required this.averageLow,
    required this.averageSpread,
  });

  final int drawCount;
  final double averageSum;
  final double averageEven;
  final double averageLow;
  final double averageSpread;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.28,
      children: [
        _MetricTile(
          label: 'Ziehungen aktiv',
          value: '$drawCount',
          icon: Icons.calendar_month_rounded,
        ),
        _MetricTile(
          label: 'Ø Summe',
          value: averageSum.toStringAsFixed(1).replaceAll('.', ','),
          icon: Icons.functions_rounded,
        ),
        _MetricTile(
          label: 'Ø Gerade',
          value: averageEven.toStringAsFixed(1).replaceAll('.', ','),
          icon: Icons.view_week_rounded,
        ),
        _MetricTile(
          label: 'Ø Niedrig (1–24)',
          value: averageLow.toStringAsFixed(1).replaceAll('.', ','),
          icon: Icons.south_west_rounded,
        ),
        _MetricTile(
          label: 'Ø Spannweite',
          value: averageSpread.toStringAsFixed(1).replaceAll('.', ','),
          icon: Icons.swap_horiz_rounded,
        ),
        _MetricTile(
          label: 'Modus',
          value: 'Live',
          icon: Icons.bolt_rounded,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.aiSummary,
    required this.proSummary,
    required this.onApplyTip,
  });

  final AnalysisAiSummary aiSummary;
  final AnalysisProSummary proSummary;
  final VoidCallback? onApplyTip;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aiSummary.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Konfidenz: ${aiSummary.confidence}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            aiSummary.reasoning,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _NumberBallRow(
            title: 'Empfohlene Zahlen',
            numbers: aiSummary.recommendedNumbers,
            highlighted: true,
          ),
          const SizedBox(height: 14),
          _NumberBallRow(
            title: 'Vorsicht bei',
            numbers: aiSummary.avoidNumbers,
            highlighted: false,
          ),
          if (proSummary.bestTip.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pro-Kombination',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: proSummary.bestTip
                        .map((number) => NumberBall(number: number, highlighted: true))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    proSummary.strategy,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'In Generator übernehmen',
                    icon: Icons.north_east_rounded,
                    onPressed: onApplyTip,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberBallRow extends StatelessWidget {
  const _NumberBallRow({
    required this.title,
    required this.numbers,
    required this.highlighted,
  });

  final String title;
  final List<int> numbers;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (numbers.isEmpty)
          const Text(
            'Noch keine ausreichende Datenbasis.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers
                .map((number) => NumberBall(number: number, highlighted: highlighted))
                .toList(),
          ),
      ],
    );
  }
}

class _PatternBoard extends StatelessWidget {
  const _PatternBoard({required this.summary, required this.proSummary});

  final AnalysisSummary summary;
  final AnalysisProSummary proSummary;

  @override
  Widget build(BuildContext context) {
    final repeats0 = summary.repeatHistogram[0] ?? 0;
    final repeats1 = summary.repeatHistogram[1] ?? 0;
    final repeats2 = (summary.repeatHistogram[2] ?? 0) +
        (summary.repeatHistogram[3] ?? 0) +
        (summary.repeatHistogram[4] ?? 0) +
        (summary.repeatHistogram[5] ?? 0) +
        (summary.repeatHistogram[6] ?? 0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Musterboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Wiederholungen, starke Paare und Bewegungsrichtung der Zahlen im aktuellen Fenster.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RepeatTile(
                  label: '0 Wiederholungen',
                  value: '$repeats0',
                  softColor: AppColors.successSoft,
                  accent: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RepeatTile(
                  label: '1 Wiederholung',
                  value: '$repeats1',
                  softColor: AppColors.infoSoft,
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RepeatTile(
                  label: '2+ Wiederholungen',
                  value: '$repeats2',
                  softColor: AppColors.warningSoft,
                  accent: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PatternLine(
            label: 'Stärkstes Paar',
            value: summary.strongPairs.isEmpty
                ? '-'
                : '${summary.strongPairs.first.pair.join(' / ')}  •  ${summary.strongPairs.first.count}x',
          ),
          const SizedBox(height: 8),
          _PatternLine(
            label: 'Trend nach oben',
            value: proSummary.trendingUp.isEmpty
                ? '-'
                : proSummary.trendingUp.take(4).map((e) => e.number).join(', '),
          ),
          const SizedBox(height: 8),
          _PatternLine(
            label: 'Trend nach unten',
            value: proSummary.trendingDown.isEmpty
                ? '-'
                : proSummary.trendingDown.take(4).map((e) => e.number).join(', '),
          ),
          const SizedBox(height: 8),
          _PatternLine(
            label: 'Rebound-Kandidaten',
            value: proSummary.reboundNumbers.isEmpty
                ? '-'
                : proSummary.reboundNumbers.take(4).map((e) => e.number).join(', '),
          ),
        ],
      ),
    );
  }
}

class _RepeatTile extends StatelessWidget {
  const _RepeatTile({
    required this.label,
    required this.value,
    required this.softColor,
    required this.accent,
  });

  final String label;
  final String value;
  final Color softColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternLine extends StatelessWidget {
  const _PatternLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawDayPanel extends StatelessWidget {
  const _DrawDayPanel({
    required this.title,
    required this.subtitle,
    required this.draws,
  });

  final String title;
  final String subtitle;
  final List<DrawResult> draws;

  @override
  Widget build(BuildContext context) {
    final stats = _DayStats.fromDraws(draws);

    return AppCard(
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
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniDayMetric(label: 'Ziehungen', value: '${draws.length}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniDayMetric(label: 'Top-Paar', value: stats.topPairLabel),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _NumberBallRow(
            title: 'Starke Zahlen',
            numbers: stats.topNumbers,
            highlighted: true,
          ),
          const SizedBox(height: 14),
          _NumberBallRow(
            title: 'Zurückhaltende Zahlen',
            numbers: stats.lowNumbers,
            highlighted: false,
          ),
          const SizedBox(height: 14),
          _PatternLine(
            label: 'Ø Summe',
            value: stats.averageSum,
          ),
          const SizedBox(height: 8),
          _PatternLine(
            label: 'Ø Gerade',
            value: stats.averageEven,
          ),
          const SizedBox(height: 8),
          _PatternLine(
            label: 'Ø Niedrig (1–24)',
            value: stats.averageLow,
          ),
        ],
      ),
    );
  }
}

class _MiniDayMetric extends StatelessWidget {
  const _MiniDayMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
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

class _DayStats {
  const _DayStats({
    required this.topNumbers,
    required this.lowNumbers,
    required this.topPairLabel,
    required this.averageSum,
    required this.averageEven,
    required this.averageLow,
  });

  final List<int> topNumbers;
  final List<int> lowNumbers;
  final String topPairLabel;
  final String averageSum;
  final String averageEven;
  final String averageLow;

  factory _DayStats.fromDraws(List<DrawResult> draws) {
    if (draws.isEmpty) {
      return const _DayStats(
        topNumbers: [],
        lowNumbers: [],
        topPairLabel: '-',
        averageSum: '-',
        averageEven: '-',
        averageLow: '-',
      );
    }

    final numberCounts = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    final pairCounts = <String, int>{};

    int totalSum = 0;
    int totalEven = 0;
    int totalLow = 0;

    for (final draw in draws) {
      final sorted = List<int>.from(draw.numbers)..sort();
      totalSum += sorted.fold<int>(0, (sum, value) => sum + value);
      totalEven += sorted.where((n) => n.isEven).length;
      totalLow += sorted.where((n) => n <= 24).length;

      for (final number in sorted) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }

      for (int i = 0; i < sorted.length; i++) {
        for (int j = i + 1; j < sorted.length; j++) {
          final key = '${sorted[i]}-${sorted[j]}';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    final sortedHigh = numberCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final sortedLow = numberCounts.entries.toList()
      ..sort((a, b) {
        final byCount = a.value.compareTo(b.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    final topPair = pairCounts.entries.isEmpty
        ? null
        : (pairCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      }))
        .first;

    return _DayStats(
      topNumbers: sortedHigh.take(6).map((e) => e.key).toList(),
      lowNumbers: sortedLow.take(6).map((e) => e.key).toList(),
      topPairLabel: topPair == null ? '-' : '${topPair.key} (${topPair.value})',
      averageSum: (totalSum / draws.length).toStringAsFixed(1).replaceAll('.', ','),
      averageEven: (totalEven / draws.length).toStringAsFixed(1).replaceAll('.', ','),
      averageLow: (totalLow / draws.length).toStringAsFixed(1).replaceAll('.', ','),
    );
  }
}
