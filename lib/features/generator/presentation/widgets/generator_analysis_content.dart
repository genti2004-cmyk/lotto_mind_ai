import 'package:flutter/material.dart';

import 'package:lotto_mind_ai/core/constants/app_colors.dart';
import 'package:lotto_mind_ai/core/widgets/number_ball.dart';
import 'package:lotto_mind_ai/core/widgets/primary_button.dart';
import 'package:lotto_mind_ai/features/generator/presentation/widgets/generator_shared_widgets.dart';
import 'package:lotto_mind_ai/features/generator/provider/lotto_app_state.dart';

class GeneratorAnalysisContent extends StatelessWidget {
  final LottoAppState appState;
  final AnalysisAiSummary ai;
  final AnalysisProSummary pro;
  final List<MultiAiTipSuggestion> multiAi;
  final Future<void> Function() onGenerate;
  final Future<void> Function()? onApplyBest;

  const GeneratorAnalysisContent({
    super.key,
    required this.appState,
    required this.ai,
    required this.pro,
    required this.multiAi,
    required this.onGenerate,
    required this.onApplyBest,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Analyse-Reihe',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: onGenerate,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Bester Tipp',
                  icon: Icons.psychology_alt_rounded,
                  onPressed: onApplyBest,
                ),
                const SizedBox(height: 10),
                GeneratorGlassPanel(
                  title: 'Analysefenster',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GeneratorStatLine(
                        label: 'Fenster',
                        value: appState.analysisWindowLabel,
                      ),
                      const SizedBox(height: 5),
                      GeneratorStatLine(
                        label: 'Modus',
                        value: appState.drawModeDescription,
                      ),
                      const SizedBox(height: 5),
                      GeneratorStatLine(
                        label: 'Qualität',
                        value: appState.analysisStrengthLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GeneratorGlassPanel(
                  title: 'Modell-Auswertung',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ai.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GeneratorStatLine(
                        label: 'Empfohlene 3',
                        value: ai.recommendedNumbers.isEmpty
                            ? '-'
                            : ai.recommendedNumbers.join('  •  '),
                      ),
                      const SizedBox(height: 5),
                      GeneratorStatLine(
                        label: 'Eher meiden',
                        value: ai.avoidNumbers.isEmpty
                            ? '-'
                            : ai.avoidNumbers.join('  •  '),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ai.reasoning,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GeneratorGlassPanel(
                  title: 'Premium-Empfehlung',
                  child: pro.bestTip.isEmpty
                      ? const Text(
                    'Noch zu wenige Ziehungen vorhanden.',
                    style: TextStyle(fontSize: 12),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pro.bestTip
                            .map((number) => NumberBall(number: number))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      GeneratorStatLine(
                        label: 'Strategie',
                        value: pro.strategy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GeneratorGlassPanel(
                  title: 'Strategie-Mix',
                  child: multiAi.isEmpty
                      ? const Text(
                    'Noch nicht genug Daten für den Strategie-Mix.',
                    style: TextStyle(fontSize: 12),
                  )
                      : Column(
                    children: multiAi.take(3).map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GeneratorMultiAiCompactCard(
                          title: suggestion.title,
                          subtitle: suggestion.subtitle,
                          numbers: suggestion.numbers,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}