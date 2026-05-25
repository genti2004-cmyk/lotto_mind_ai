import 'package:flutter/material.dart';

import '../../provider/lotto_app_state.dart';

class AiLearningBoostControlCard extends StatelessWidget {
  final LottoAppState state;

  const AiLearningBoostControlCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final boostNumbers = state.aiLearningBoostNumbers;
    final isActive = state.aiLearningBoostEnabled;
    final trackedCount = state.aiLearningTrackedTipCount;
    final status = state.aiLearningBoostStatus;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_alt_rounded, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'AI Learning Boost',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                Switch.adaptive(
                  value: isActive,
                  onChanged: state.setAiLearningBoostEnabled,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Tracking-Basis: $trackedCount Tipps'),
            const SizedBox(height: 6),
            Text('Status: $status'),
            const SizedBox(height: 12),
            if (boostNumbers.isEmpty)
              const Text(
                'Noch keine Boost-Zahlen vorhanden. Speichere und prüfe zuerst Tipps im Tracking.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: boostNumbers.take(10).map((number) {
                  return Chip(label: Text(number.toString().padLeft(2, '0')));
                }).toList(),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.refreshAiLearningBoost,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Boost aktualisieren'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}