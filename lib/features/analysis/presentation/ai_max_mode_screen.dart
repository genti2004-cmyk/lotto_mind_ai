import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';

class AiMaxModeScreen extends StatelessWidget {
  const AiMaxModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final result = state.predictionEngineResult;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Expertenanalyse')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle(
            title: 'Expertenanalyse',
            subtitle: 'Auffällige Zahlen nach Häufigkeit, Intervall, Rückstand und Mustergewichtung.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modell-Empfehlung', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: result.primaryTip.map((n) => NumberBall(number: n)).toList()),
                const SizedBox(height: 12),
                Text('Superzahl: ${result.recommendedSuperNumber ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Gesamt-Score: ${result.overallScore.toStringAsFixed(1)}  •  3+ Potenzial: ${result.score3Plus.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...result.reasons.take(5).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $r', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Anzeige aktualisieren', icon: Icons.refresh_rounded, onPressed: () => context.read<LottoAppState>().notifyListeners()),
          const SizedBox(height: 20),
          const Text('Top Kandidaten', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...result.topCandidates.take(6).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final c = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(radius: 17, child: Text('${index + 1}')),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Kandidat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                      Text(c.totalScore.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ]),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: (c.tip).map((n) => NumberBall(number: n)).toList()),
                    const SizedBox(height: 12),
                    Text('3+: ${c.score3Plus.toStringAsFixed(1)}  •  Paar: ${c.pairScore.toStringAsFixed(1)}  •  Triple: ${c.tripleScore.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('Trend: ${c.recencyScore.toStringAsFixed(1)}  •  Gap: ${c.overdueScore.toStringAsFixed(1)}  •  Struktur: ${c.structureScore.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    ...c.reasons.take(4).map<Widget>((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $r', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    )),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Kandidat übernehmen',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        context.read<LottoAppState>().setGeneratedNumbers(c.tip, superNumber: result.recommendedSuperNumber);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kandidat ${index + 1} wurde übernommen.')));
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
