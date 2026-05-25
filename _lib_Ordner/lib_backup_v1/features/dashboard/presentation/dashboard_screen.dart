import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../../draws/presentation/draw_results_screen.dart';
import '../../generator/presentation/generator_screen.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../../tracking/domain/tracked_tip.dart';
import '../../tracking/services/tracking_service.dart';
import '../../system/presentation/system_generator_screen.dart';
import '../../tips/presentation/my_tips_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final tip = state.lastGeneratedTip;
    final superNumber = state.lastGeneratedSuperNumber;
    final lastSimulation = state.bestCurrentTipWindow?.summary;
    final hasTip = tip != null && tip.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            const _DashboardHeader(),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  title: 'Profil',
                  value: state.analysisProfileLabel,
                  icon: Icons.psychology_alt_rounded,
                ),
                _MetricCard(
                  title: 'Ziehungen',
                  value: '${state.analysisDrawCount}',
                  icon: Icons.dataset_rounded,
                ),
                _MetricCard(
                  title: 'Qualität',
                  value: state.analysisStrengthLabel,
                  icon: Icons.insights_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DashboardProPanel(state: state),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Heute',
              subtitle: 'Dein letzter Tipp und die aktuelle Ausgangslage.',
              child: !hasTip
                  ? const Text(
                'Noch kein Tipp erstellt. Starte über den Generator und erstelle deinen ersten Tipp.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Letzter Tipp',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  if (lastSimulation != null) ...[
                    const SizedBox(height: 12),
                    _SummaryPills(simulation: lastSimulation),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Schnellzugriff',
              subtitle: 'Die wichtigsten Wege ohne Umwege.',
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.casino_rounded,
                    title: 'Generator starten',
                    subtitle: 'Normal, AI, Jackpot und System-Modus öffnen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GeneratorScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.grid_view_rounded,
                    title: 'System spielen',
                    subtitle: 'Intervall und Vollsystem erzeugen, prüfen und abgeben',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SystemGeneratorScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.bookmarks_rounded,
                    title: 'Meine Tipps',
                    subtitle: 'Gespeicherte Tipps, Spielschein und WestLotto',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyTipsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.fact_check_rounded,
                    title: 'Ziehungen & Prüfung',
                    subtitle: 'Ziehungen ansehen und Tipps prüfen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DrawResultsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'AI Status',
              subtitle: 'Deine aktuelle Analyse-Konfiguration auf einen Blick.',
              child: Column(
                children: [
                  _InfoLine(label: 'Profil', value: state.analysisProfileLabel),
                  const SizedBox(height: 8),
                  _InfoLine(label: 'Analyse-Fenster', value: state.analysisWindowLabel),
                  const SizedBox(height: 8),
                  _InfoLine(label: 'Ziehungstag', value: state.analysisDrawFilterLabel),
                  const SizedBox(height: 8),
                  _InfoLine(label: 'Qualität', value: state.analysisStrengthLabel),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'System Status',
              subtitle: 'Systembereich kompakt zusammengefasst.',
              child: Column(
                children: [
                  _InfoLine(label: 'Systemart', value: state.systemPlayTypeLabel),
                  const SizedBox(height: 8),
                  _InfoLine(label: 'Systemgröße', value: '${state.selectedSystemSize}'),
                  const SizedBox(height: 8),
                  _InfoLine(label: 'Basiszahlen', value: '${state.systemBaseNumbers.length}'),
                  const SizedBox(height: 8),
                  _InfoLine(label: 'Reihen', value: '${state.systemRows.length}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
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
                'Dein intelligenter Lotto-Assistent für Generator, Systeme, Tipps und PDF-Export.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _DashboardProPanel extends StatefulWidget {
  final LottoAppState state;

  const _DashboardProPanel({required this.state});

  @override
  State<_DashboardProPanel> createState() => _DashboardProPanelState();
}

class _DashboardProPanelState extends State<_DashboardProPanel> {
  late Future<List<TrackingStrategySummary>> _future;
  final TrackingService _trackingService = TrackingService();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TrackingStrategySummary>> _load() async {
    final tips = await _trackingService.loadTips();
    if (tips.isEmpty) return const <TrackingStrategySummary>[];

    final draws = widget.state.drawResults;
    final evaluated = draws.isEmpty
        ? tips
        : _trackingService.evaluateAllAgainstDraws(
      tips: tips,
      draws: draws,
      limit: 52,
    );

    return _trackingService.buildStrategySummaries(evaluated);
  }

  String _money(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  String _percent(double value) {
    return '${value.toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Performance Dashboard',
      subtitle: 'Tracking-Auswertung der letzten 52 Ziehungen nach Strategie.',
      child: FutureBuilder<List<TrackingStrategySummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Text(
              'Tracking-Auswertung konnte nicht geladen werden: ${snapshot.error}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            );
          }

          final summaries = snapshot.data ?? const <TrackingStrategySummary>[];
          if (summaries.isEmpty) {
            return const Text(
              'Noch keine geprüften Tracking-Daten vorhanden. Speichere Tipps im Tracking und prüfe sie gegen Ziehungen.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            );
          }

          final totalTips = summaries.fold<int>(0, (sum, item) => sum + item.tipCount);
          final totalChecks = summaries.fold<int>(0, (sum, item) => sum + item.checkCount);
          final totalStake = summaries.fold<double>(0, (sum, item) => sum + item.stake);
          final totalPrize = summaries.fold<double>(0, (sum, item) => sum + item.prize);
          final totalNet = totalPrize - totalStake;
          final totalRoi = totalStake <= 0 ? 0.0 : (totalNet / totalStake) * 100.0;
          final best = summaries.first;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(label: 'Tipps', value: '$totalTips'),
                  _Pill(label: 'Checks', value: '$totalChecks'),
                  _Pill(label: 'Einsatz', value: _money(totalStake)),
                  _Pill(label: 'Gewinn', value: _money(totalPrize)),
                  _Pill(label: 'Netto', value: _money(totalNet)),
                  _Pill(label: 'ROI', value: _percent(totalRoi)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
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
                    const Text(
                      'Beste Strategie',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      best.type.label,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${best.performanceLabel} • ROI ${_percent(best.roiPercent)} • bester Treffer ${best.bestHits} Richtige',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...summaries.take(5).map(
                    (summary) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StrategyPerformanceRow(
                    title: summary.type.label,
                    subtitle: '${summary.tipCount} Tipps • ${summary.checkCount} Checks • ${summary.winRows} Gewinnreihen',
                    roi: _percent(summary.roiPercent),
                    net: _money(summary.netValue),
                    bestHits: summary.bestHits,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StrategyPerformanceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String roi;
  final String net;
  final int bestHits;

  const _StrategyPerformanceRow({
    required this.title,
    required this.subtitle,
    required this.roi,
    required this.net,
    required this.bestHits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '$bestHits',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                roi,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                net,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
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
        if (constraints.maxWidth < 260) {
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

class _SummaryPills extends StatelessWidget {
  final dynamic simulation;

  const _SummaryPills({
    required this.simulation,
  });

  num _numValue(String field, [num fallback = 0]) {
    try {
      final dynamic value;
      switch (field) {
        case 'weightedScore':
          value = simulation.weightedScore;
          break;
        case 'estimatedEuroTotalValue':
          value = simulation.estimatedEuroTotalValue;
          break;
        case 'hit3':
          value = simulation.hit3;
          break;
        case 'hit4':
          value = simulation.hit4;
          break;
        case 'hit5':
          value = simulation.hit5;
          break;
        case 'hit6':
          value = simulation.hit6;
          break;
        default:
          value = fallback;
      }
      return value is num ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final euro = _numValue('estimatedEuroTotalValue', 0).toDouble();
    final score = _numValue('weightedScore', 0).toDouble();
    final hit3 = _numValue('hit3', 0).toInt();
    final hit4 = _numValue('hit4', 0).toInt();
    final hit5 = _numValue('hit5', 0).toInt();
    final hit6 = _numValue('hit6', 0).toInt();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(label: 'Wert', value: '${euro.toStringAsFixed(2).replaceAll('.', ',')} €'),
        _Pill(label: 'Score', value: score.toStringAsFixed(1)),
        _Pill(label: '3er', value: '$hit3'),
        _Pill(label: '4er', value: '$hit4'),
        _Pill(label: '5er', value: '$hit5'),
        _Pill(label: '6er', value: '$hit6'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
