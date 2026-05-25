import '../../tracking/domain/tracked_tip.dart';

class AiLearningBoostResult {
  final List<int> boostedNumbers;

  const AiLearningBoostResult({required this.boostedNumbers});
}

class AiLearningBoostService {
  const AiLearningBoostService();

  AiLearningBoostResult buildBoost({required List<TrackedTip> tips}) {
    final frequency = <int, int>{};

    for (final tip in tips) {
      for (final n in tip.baseNumbers) {
        if (n >= 1 && n <= 49) {
          frequency[n] = (frequency[n] ?? 0) + 1;
        }
      }

      for (final row in tip.rows) {
        for (final n in row) {
          if (n >= 1 && n <= 49) {
            frequency[n] = (frequency[n] ?? 0) + 1;
          }
        }
      }
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) {
        final byFrequency = b.value.compareTo(a.value);
        if (byFrequency != 0) return byFrequency;
        return a.key.compareTo(b.key);
      });

    return AiLearningBoostResult(
      boostedNumbers: sorted.take(10).map((e) => e.key).toList(),
    );
  }
}
