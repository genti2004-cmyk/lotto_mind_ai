import '../../draws/domain/draw_result.dart';
import '../domain/analysis_signal.dart';
import '../domain/number_analysis_score.dart';

class NumberAnalysisService {
  const NumberAnalysisService();

  List<NumberAnalysisScore> analyzeNumbers(List<DrawResult> draws) {
    final orderedDraws = List<DrawResult>.from(draws)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    if (orderedDraws.isEmpty) {
      return List.generate(
        49,
        (index) => NumberAnalysisScore(
          number: index + 1,
          frequencyScore: 0,
          overdueScore: 0,
          intervalScore: 0,
          patternScore: 0,
          hybridScore: 0,
          lastSeenDrawsAgo: null,
          hitCount: 0,
        ),
      );
    }

    final totalDraws = orderedDraws.length;
    final hitsByNumber = <int, List<int>>{
      for (int number = 1; number <= 49; number++) number: <int>[],
    };

    for (var drawIndex = 0; drawIndex < orderedDraws.length; drawIndex++) {
      final uniqueNumbers = orderedDraws[drawIndex]
          .numbers
          .where((number) => number >= 1 && number <= 49)
          .toSet();
      for (final number in uniqueNumbers) {
        hitsByNumber[number]!.add(drawIndex);
      }
    }

    final scores = <NumberAnalysisScore>[];
    for (var number = 1; number <= 49; number++) {
      final hitIndexes = hitsByNumber[number] ?? const <int>[];
      final hitCount = hitIndexes.length;
      final lastSeen = hitIndexes.isEmpty ? null : hitIndexes.first;

      final frequencyScore = hitCount / totalDraws;
      final overdueScore = lastSeen == null
          ? 1.0
          : (lastSeen / totalDraws).clamp(0.0, 1.0).toDouble();
      final intervalScore = _intervalScore(hitIndexes, totalDraws);
      final patternScore = _patternScore(number, orderedDraws);
      final hybridScore = (
        frequencyScore * 0.30 +
        overdueScore * 0.25 +
        intervalScore * 0.30 +
        patternScore * 0.15
      ).clamp(0.0, 1.0).toDouble();

      scores.add(
        NumberAnalysisScore(
          number: number,
          frequencyScore: frequencyScore,
          overdueScore: overdueScore,
          intervalScore: intervalScore,
          patternScore: patternScore,
          hybridScore: hybridScore,
          lastSeenDrawsAgo: lastSeen,
          hitCount: hitCount,
        ),
      );
    }

    scores.sort((a, b) {
      final byScore = b.hybridScore.compareTo(a.hybridScore);
      return byScore != 0 ? byScore : a.number.compareTo(b.number);
    });
    return scores;
  }

  List<NumberAnalysisScore> topBySignal(
    List<DrawResult> draws,
    AnalysisSignal signal, {
    int limit = 6,
  }) {
    final scores = analyzeNumbers(draws);
    scores.sort((a, b) {
      final byScore = b.scoreFor(signal).compareTo(a.scoreFor(signal));
      return byScore != 0 ? byScore : a.number.compareTo(b.number);
    });
    return scores.take(limit).toList();
  }

  double _intervalScore(List<int> hitIndexes, int totalDraws) {
    if (hitIndexes.isEmpty) return 0.85;
    if (hitIndexes.length == 1) {
      return ((hitIndexes.first + 1) / totalDraws).clamp(0.0, 1.0).toDouble();
    }

    final gaps = <int>[];
    for (var i = 0; i < hitIndexes.length - 1; i++) {
      gaps.add((hitIndexes[i + 1] - hitIndexes[i]).abs());
    }
    if (gaps.isEmpty) return 0.0;

    final averageGap = gaps.reduce((a, b) => a + b) / gaps.length;
    final currentGap = hitIndexes.first + 1;
    if (averageGap <= 0) return 0.0;

    final ratio = currentGap / averageGap;
    if (ratio <= 1) return (ratio * 0.55).clamp(0.0, 0.55).toDouble();
    return (0.55 + ((ratio - 1) / 3) * 0.45).clamp(0.0, 1.0).toDouble();
  }

  double _patternScore(int number, List<DrawResult> draws) {
    if (draws.length < 3) return 0.0;

    var recentHits = 0;
    for (final draw in draws.take(5)) {
      if (draw.numbers.contains(number)) recentHits++;
    }

    var neighborHits = 0;
    for (final draw in draws.take(10)) {
      if (draw.numbers.contains(number - 1) || draw.numbers.contains(number + 1)) {
        neighborHits++;
      }
    }

    final recentScore = (recentHits / 5).clamp(0.0, 1.0).toDouble();
    final neighborScore = (neighborHits / 10).clamp(0.0, 1.0).toDouble();
    return (recentScore * 0.55 + neighborScore * 0.45).clamp(0.0, 1.0).toDouble();
  }
}
