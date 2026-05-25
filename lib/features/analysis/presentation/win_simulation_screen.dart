import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../../generator/provider/lotto_app_state.dart';

class WinSimulationScreen extends StatelessWidget {
  const WinSimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final currentTip = state.lastGeneratedTip;
    final currentSuper = state.lastGeneratedSuperNumber;
    final bestAiTip = state.bestAnalyzedTip;
    final bestAiSuper = state.recommendedSuperNumber;
    final currentRanges = state.currentTipRangeAnalysis;
    final bestAiRanges = state.bestAiTipRangeAnalysis;
    final bestCurrentWindow = state.bestCurrentTipWindow;
    final bestAiWindow = state.bestAiTipWindow;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gewinnsimulation € / ROI'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            _IntroCard(
              bestCurrentWindow: bestCurrentWindow,
              bestAiWindow: bestAiWindow,
            ),
            const SizedBox(height: 14),
            if (currentTip != null && currentTip.length == 6)
              _TipSection(
                title: 'Aktueller Tipp',
                subtitle:
                'Backtest für deinen zuletzt übernommenen oder generierten Tipp.',
                numbers: currentTip,
                superNumber: currentSuper,
                ranges: currentRanges,
              ),
            if (currentTip != null && currentTip.length == 6)
              const SizedBox(height: 14),
            if (bestAiTip.length == 6)
              _TipSection(
                title: 'Pro-Tipp',
                subtitle:
                'Zeitraum-Bewertung für den aktuell besten AI-Tipp.',
                numbers: bestAiTip,
                superNumber: bestAiSuper,
                ranges: bestAiRanges,
              ),
            if ((currentTip == null || currentTip.length != 6) &&
                bestAiTip.length != 6)
              const _EmptyState(),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final WinRangeEvaluation? bestCurrentWindow;
  final WinRangeEvaluation? bestAiWindow;

  const _IntroCard({
    required this.bestCurrentWindow,
    required this.bestAiWindow,
  });

  String _formatEuro(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$fixed €';
  }

  String _formatSignedEuro(double value) {
    final prefix = value >= 0 ? '+' : '-';
    final fixed = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return '$prefix$fixed €';
  }

  String _formatPercent(double value) {
    final prefix = value >= 0 ? '+' : '-';
    final fixed = value.abs().toStringAsFixed(1).replaceAll('.', ',');
    return '$prefix$fixed %';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
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
          const Text(
            'Backtest statt Zukunftsversprechen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dieser Screen zeigt dir, in welchen Zeitfenstern ein Tipp historisch eher 4er, 4+Superzahl oder besser erreicht hat. Die Euro-Werte und der ROI sind geschätzte Modellwerte, keine live offiziellen Quoten.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _TopWindowLine(
            label: 'Bester Zeitraum aktueller Tipp',
            value: bestCurrentWindow == null
                ? '-'
                : '${bestCurrentWindow!.label} • 4+SZ: ${bestCurrentWindow!.summary.hit4WithSuper} • ${_formatEuro(bestCurrentWindow!.summary.estimatedEuroTotal)} • ROI ${bestCurrentWindow!.summary.estimatedRoiPercent.toStringAsFixed(1).replaceAll('.', ',')}%',
          ),
          const SizedBox(height: 8),
          _TopWindowLine(
            label: 'Bester Zeitraum AI Pro Tipp',
            value: bestAiWindow == null
                ? '-'
                : '${bestAiWindow!.label} • 4+SZ: ${bestAiWindow!.summary.hit4WithSuper} • ${_formatEuro(bestAiWindow!.summary.estimatedEuroTotal)} • ROI ${bestAiWindow!.summary.estimatedRoiPercent.toStringAsFixed(1).replaceAll('.', ',')}%',
          ),
        ],
      ),
    );
  }
}

class _TopWindowLine extends StatelessWidget {
  final String label;
  final String value;

  const _TopWindowLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TipSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<int> numbers;
  final int? superNumber;
  final List<WinRangeEvaluation> ranges;

  const _TipSection({
    required this.title,
    required this.subtitle,
    required this.numbers,
    required this.superNumber,
    required this.ranges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
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
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers.map((n) => NumberBall(number: n)).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Superzahl: ${superNumber?.toString() ?? '-'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 14),
          ...ranges.map((range) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RangeCard(range: range),
          )),
        ],
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  final WinRangeEvaluation range;

  const _RangeCard({required this.range});

  String _formatEuro(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$fixed €';
  }

  String _formatSignedEuro(double value) {
    final prefix = value >= 0 ? '+' : '-';
    final fixed = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return '$prefix$fixed €';
  }

  String _formatPercent(double value) {
    final prefix = value >= 0 ? '+' : '-';
    final fixed = value.abs().toStringAsFixed(1).replaceAll('.', ',');
    return '$prefix$fixed %';
  }

  @override
  Widget build(BuildContext context) {
    final s = range.summary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            range.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(label: '3er', value: s.hit3),
              _StatChip(label: '4er', value: s.hit4),
              _StatChip(label: '4+SZ', value: s.hit4WithSuper),
              _StatChip(label: '5er', value: s.hit5),
              _StatChip(label: '5+SZ', value: s.hit5WithSuper),
              _StatChip(label: '6er', value: s.hit6),
              _StatChip(label: '6+SZ', value: s.hit6WithSuper),
              _StatChip(label: 'Score', value: s.weightedScore),
            ],
          ),
          const SizedBox(height: 12),
          _EuroLine(label: 'Geschätzter Modellwert', value: _formatEuro(s.estimatedEuroTotal)),
          const SizedBox(height: 6),
          _EuroLine(label: 'Modell-Einsatz', value: _formatEuro(s.estimatedStakeTotal)),
          const SizedBox(height: 6),
          _EuroLine(
            label: 'Netto',
            value: _formatSignedEuro(s.estimatedNetProfit),
            positive: s.estimatedNetProfit >= 0,
          ),
          const SizedBox(height: 6),
          _EuroLine(
            label: 'ROI',
            value: _formatPercent(s.estimatedRoiPercent),
            positive: s.estimatedRoiPercent >= 0,
          ),
          const SizedBox(height: 6),
          _EuroLine(label: 'Ø pro Ziehung', value: _formatEuro(s.estimatedEuroPerDraw)),
          const SizedBox(height: 10),
          Text(
            range.recommendation,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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

class _EuroLine extends StatelessWidget {
  final String label;
  final String value;
  final bool? positive;

  const _EuroLine({
    required this.label,
    required this.value,
    this.positive,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor;
    if (positive == null) {
      valueColor = AppColors.textPrimary;
    } else {
      valueColor = positive! ? Colors.green : Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 42,
            color: AppColors.primary,
          ),
          SizedBox(height: 12),
          Text(
            'Noch kein Tipp für die Gewinnsimulation verfügbar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Erzeuge zuerst einen Analyse- oder AI-Pro-Tipp und öffne dann diese Auswertung erneut.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
