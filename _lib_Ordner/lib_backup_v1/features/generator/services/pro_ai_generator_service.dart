import 'dart:math';

/// AI Real Boost helper for the fallback analysis generator.
///
/// It intentionally avoids a pure "top six" strategy. The result is built from
/// trend, stable frequency, rebound/gap numbers and pair affinity, then balanced
/// by odd/even, low/high, sum and decade spread.
class ProAiGeneratorService {
  final Random _rng;

  ProAiGeneratorService({Random? random}) : _rng = random ?? Random();

  List<int> generate({
    required List<List<int>> draws,
    int count = 6,
  }) {
    if (count <= 0) return <int>[];

    final normalizedDraws = draws
        .map((draw) => draw.where((n) => n >= 1 && n <= 49).toSet().toList()..sort())
        .where((draw) => draw.length == 6)
        .toList();

    if (normalizedDraws.length < 6) return _randomUniqueNumbers(count);

    final recentWindow = min(18, normalizedDraws.length);
    final mediumWindow = min(52, normalizedDraws.length);
    final totalFrequency = _buildFrequency(normalizedDraws);
    final recentFrequency = _buildFrequency(normalizedDraws.take(recentWindow).toList());
    final mediumFrequency = _buildFrequency(normalizedDraws.take(mediumWindow).toList());
    final lastSeen = _buildLastSeenIndex(normalizedDraws);
    final pairAffinity = _buildPairAffinity(normalizedDraws.take(mediumWindow).toList());
    final ranking = _buildRanking(
      total: totalFrequency,
      recent: recentFrequency,
      medium: mediumFrequency,
      lastSeen: lastSeen,
      pairAffinity: pairAffinity,
    );

    final selected = <int>{};
    final top = ranking.take(20).toList();
    final trend = [...ranking]..sort((a, b) => b.trendScore.compareTo(a.trendScore));
    final rebound = [...ranking]..sort((a, b) => b.reboundScore.compareTo(a.reboundScore));
    final pair = [...ranking]..sort((a, b) => b.pairScore.compareTo(a.pairScore));

    _addWeighted(selected, top, 2);
    _addWeighted(selected, trend.take(16).toList(), 3);
    _addWeighted(selected, pair.take(18).toList(), 5);
    _addWeighted(selected, rebound.take(18).toList(), count);

    for (final item in ranking) {
      if (selected.length >= count) break;
      selected.add(item.number);
    }

    return _normalizeStructure(selected.toList(), ranking, count);
  }

  Map<int, int> _buildFrequency(List<List<int>> draws) {
    final map = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    for (final draw in draws) {
      for (final n in draw) {
        map[n] = (map[n] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<int, int> _buildLastSeenIndex(List<List<int>> draws) {
    final sentinel = draws.length + 99;
    final map = <int, int>{for (int number = 1; number <= 49; number++) number: sentinel};
    for (int i = 0; i < draws.length; i++) {
      for (final n in draws[i]) {
        if ((map[n] ?? sentinel) == sentinel) map[n] = i;
      }
    }
    return map;
  }

  Map<int, double> _buildPairAffinity(List<List<int>> draws) {
    final map = <int, double>{for (int i = 1; i <= 49; i++) i: 0};
    for (int rowIndex = 0; rowIndex < draws.length; rowIndex++) {
      final draw = draws[rowIndex];
      final weight = max(1, draws.length - rowIndex).toDouble();
      for (final n in draw) {
        map[n] = (map[n] ?? 0) + weight;
      }
    }
    final maxValue = max(1.0, map.values.fold<double>(0, max));
    return {for (final e in map.entries) e.key: (e.value / maxValue).clamp(0.0, 1.0).toDouble()};
  }

  List<_AiNumberScore> _buildRanking({
    required Map<int, int> total,
    required Map<int, int> recent,
    required Map<int, int> medium,
    required Map<int, int> lastSeen,
    required Map<int, double> pairAffinity,
  }) {
    final maxTotal = max(1, total.values.reduce(max));
    final maxRecent = max(1, recent.values.reduce(max));
    final maxMedium = max(1, medium.values.reduce(max));
    final ranking = <_AiNumberScore>[];

    for (int n = 1; n <= 49; n++) {
      final totalScore = (total[n] ?? 0) / maxTotal;
      final recentScore = (recent[n] ?? 0) / maxRecent;
      final mediumScore = (medium[n] ?? 0) / maxMedium;
      final trendScore = ((recentScore * 0.68) + (mediumScore * 0.32) - (totalScore * 0.18)).clamp(0.0, 1.0).toDouble();
      final reboundScore = _gapCurve((lastSeen[n] ?? 99).toDouble());
      final pairScore = pairAffinity[n] ?? 0;
      final balanceScore = (n >= 7 && n <= 43) ? 1.0 : 0.55;
      final score = (totalScore * 22) + (recentScore * 25) + (mediumScore * 18) + (trendScore * 15) + (reboundScore * 10) + (pairScore * 8) + (balanceScore * 2);
      ranking.add(_AiNumberScore(number: n, score: score, trendScore: trendScore, reboundScore: reboundScore, pairScore: pairScore));
    }

    ranking.sort((a, b) => b.score.compareTo(a.score));
    return ranking;
  }

  void _addWeighted(Set<int> target, List<_AiNumberScore> pool, int targetSize) {
    int guard = 0;
    while (target.length < targetSize && pool.isNotEmpty && guard < 100) {
      target.add(_weightedPick(pool).number);
      guard++;
    }
  }

  _AiNumberScore _weightedPick(List<_AiNumberScore> items) {
    final minScore = items.map((e) => e.score).reduce(min);
    final weights = items.map((e) => max(0.2, e.score - minScore + 1)).toList();
    final total = weights.fold<double>(0, (a, b) => a + b);
    var roll = _rng.nextDouble() * total;
    for (int i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return items[i];
    }
    return items.last;
  }

  List<int> _normalizeStructure(List<int> rawTip, List<_AiNumberScore> ranking, int count) {
    final result = rawTip.toSet().where((n) => n >= 1 && n <= 49).toList()..sort();
    for (final item in ranking) {
      if (result.length >= count) break;
      if (!result.contains(item.number)) result.add(item.number);
    }

    int guard = 0;
    while (result.length == 6 && !_isGoodStructure(result) && guard < 60) {
      guard++;
      final removeIndex = _weakestIndex(result);
      result.removeAt(removeIndex);
      for (final item in ranking.skip(_rng.nextInt(min(12, ranking.length)))) {
        if (!result.contains(item.number)) {
          result.add(item.number);
          break;
        }
      }
      result.sort();
    }

    while (result.length < count) {
      final n = _rng.nextInt(49) + 1;
      if (!result.contains(n)) result.add(n);
    }
    return result.take(count).toList()..sort();
  }

  bool _isGoodStructure(List<int> tip) {
    final even = tip.where((n) => n.isEven).length;
    final low = tip.where((n) => n <= 24).length;
    final sum = tip.fold<int>(0, (a, b) => a + b);
    final spread = tip.last - tip.first;
    final ends = tip.map((e) => e % 10).toSet().length;
    final decades = tip.map((e) => (e - 1) ~/ 10).toSet().length;
    return even >= 2 && even <= 4 && low >= 2 && low <= 4 && sum >= 100 && sum <= 185 && spread >= 20 && ends >= 4 && decades >= 4;
  }

  int _weakestIndex(List<int> tip) {
    final even = tip.where((n) => n.isEven).length;
    final low = tip.where((n) => n <= 24).length;
    if (even > 4) return tip.indexWhere((n) => n.isEven);
    if (even < 2) return tip.indexWhere((n) => n.isOdd);
    if (low > 4) return tip.indexWhere((n) => n <= 24);
    if (low < 2) return tip.indexWhere((n) => n >= 25);
    final sum = tip.fold<int>(0, (a, b) => a + b);
    if (sum > 185) return tip.indexOf(tip.reduce(max));
    if (sum < 100) return tip.indexOf(tip.reduce(min));
    return _rng.nextInt(tip.length);
  }

  double _gapCurve(double gap) {
    if (gap < 4) return (gap / 4).clamp(0.0, 1.0) * 0.55;
    if (gap <= 18) return 1.0;
    return (1.0 - ((gap - 18) / 35)).clamp(0.25, 1.0).toDouble();
  }

  List<int> _randomUniqueNumbers(int count) {
    final result = <int>{};
    while (result.length < count) {
      result.add(_rng.nextInt(49) + 1);
    }
    return result.toList()..sort();
  }
}

class _AiNumberScore {
  final int number;
  final double score;
  final double trendScore;
  final double reboundScore;
  final double pairScore;

  const _AiNumberScore({
    required this.number,
    required this.score,
    required this.trendScore,
    required this.reboundScore,
    required this.pairScore,
  });
}
