import 'package:flutter/material.dart';

import 'package:lotto_mind_ai/core/widgets/number_ball.dart';
import 'package:lotto_mind_ai/core/widgets/primary_button.dart';
import 'package:lotto_mind_ai/features/generator/presentation/widgets/generator_shared_widgets.dart';

class GeneratorRandomContent extends StatelessWidget {
  final List<int>? lastTip;
  final Future<void> Function() onGenerate;
  final Future<void> Function()? onSave;

  const GeneratorRandomContent({
    super.key,
    required this.lastTip,
    required this.onGenerate,
    required this.onSave,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimaryButton(
                  label: 'Zufallstipp erstellen',
                  icon: Icons.casino_rounded,
                  onPressed: onGenerate,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Aktuelle Reihe speichern',
                  icon: Icons.bookmark_add_rounded,
                  onPressed: onSave,
                ),
                const SizedBox(height: 10),
                GeneratorGlassPanel(
                  title: 'Letzte Zufallsreihe',
                  child: lastTip == null
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        'Noch keine Reihe erzeugt.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: lastTip!
                            .map((number) => NumberBall(number: number))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GeneratorValueChip(
                              label: 'Summe',
                              value: lastTip!
                                  .fold<int>(0, (a, b) => a + b)
                                  .toString(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GeneratorValueChip(
                              label: 'Gerade',
                              value: lastTip!
                                  .where((n) => n.isEven)
                                  .length
                                  .toString(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GeneratorValueChip(
                              label: 'Niedrig',
                              value: lastTip!
                                  .where((n) => n <= 24)
                                  .length
                                  .toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
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