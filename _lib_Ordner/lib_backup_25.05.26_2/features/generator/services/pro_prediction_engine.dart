import 'dart:math';

import '../../draws/domain/draw_result.dart';

class PredictionEngineResult {
  final List<int> primaryTip;
  final int? recommendedSuperNumber;
  final double overallScore;
  final double score3Plus;
  final List<PredictionCandidate> topCandidates;
  final List<String> reasons;

  const PredictionEngineResult({
    required this.primaryTip,
    required this.recommendedSuperNumber,
    required this.overallScore,
    required this.score3Plus,
    required this.topCandidates,
    required this.reasons,
  });

  factory PredictionEngineResult.empty() {
    return const PredictionEngineResult(
      primaryTip: [],
      recommendedSuperNumber: null,
      overallScore: 0,
      score3Plus: 0,
      topCandidates: [],
      reasons: ['Noch nicht genug Ziehungen für eine belastbare Prognose.'],
    );
  }
}

class PredictionCandidate {
  final List<int> tip;
  final double totalScore;
  final double score3Plus;
  final double pairScore;
  final double tripleScore;
  final double recencyScore;
  final double overdueScore;
  final double structureScore;
  final List<String> reasons;

  const PredictionCandidate({
    required this.tip,
    required this.totalScore,
    required this.score3Plus,
    required this.pairScore,
    required this.tripleScore,
    required this.recencyScore,
    required this.overdueScore,
    required this.structureScore,
    required this.reasons,
  });
}

class ProPredictionEngine {
  final Random _random;

  ProPredictionEngine({Random? random}) : _random = random ?? Random();

  PredictionEngineResult build({
    required List<DrawResult> draws,
    required String profileLabel,
    int candidateCount = 720,
  }) {
    final sortedRows = List<DrawResult>.from(draws)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    final normalizedDraws = sortedRows
        .map((d) => d.numbers.where((n) => n >= 1 && n <= 49).toSet().toList()..sort())
        .where((d) => d.length == 6)
        .toList();

    if (normalizedDraws.length < 12) {
      return PredictionEngineResult.empty();
    }

    final recentWindow = min(18, normalizedDraws.length);
    final mediumWindow = min(52, normalizedDraws.length);
    final longWindow = min(156, normalizedDraws.length);

    final frequency = _buildFrequency(normalizedDraws.take(longWindow).toList());
    final recencyFrequency = _buildFrequency(normalizedDraws.take(recentWindow).toList());
    final mediumFrequency = _buildFrequency(normalizedDraws.take(mediumWindow).toList());
    final lastSeen = _buildLastSeenIndex(normalizedDraws);
    final pairCounts = _buildPairCounts(normalizedDraws.take(longWindow).toList());
    final recentPairCounts = _buildPairCounts(normalizedDraws.take(mediumWindow).toList(), recencyWeighted: true);
    final tripleCounts = _buildTripleCounts(normalizedDraws.take(mediumWindow).toList());
    final repeatHistogram = _buildRepeatHistogram(normalizedDraws);
    final superNumber = _buildSuperNumberRecommendation(sortedRows);

    final ranking = _buildBaseRanking(
      freq: frequency,
      recency: recencyFrequency,
      medium: mediumFrequency,
      lastSeen: lastSeen,
      pairCounts: recentPairCounts,
      profileLabel: profileLabel,
    );

    final candidates = <PredictionCandidate>[];
    final seenCandidateKeys = <String>{};

    void addCandidate(List<int> rawTip) {
      final tip = _normalizeStructure(rawTip, ranking);
      if (tip.length != 6) return;
      final key = tip.join('-');
      if (!seenCandidateKeys.add(key)) return;
      candidates.add(
        _scoreTip(
          tip: tip,
          draws: normalizedDraws,
          pairCounts: pairCounts,
          recentPairCounts: recentPairCounts,
          tripleCounts: tripleCounts,
          freq: frequency,
          recency: recencyFrequency,
          medium: mediumFrequency,
          lastSeen: lastSeen,
          repeatHistogram: repeatHistogram,
          profileLabel: profileLabel,
        ),
      );
    }

    for (final seed in _deterministicSeeds(ranking)) {
      addCandidate(seed);
    }

    final effectiveCount = max(candidateCount, 720);
    for (int i = 0; i < effectiveCount; i++) {
      addCandidate(
        _buildCandidateTip(
          ranking: ranking,
          pairCounts: pairCounts,
          recentPairCounts: recentPairCounts,
          tripleCounts: tripleCounts,
          profileLabel: profileLabel,
          round: i,
        ),
      );
    }

    candidates.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    final topCandidates = _diversifyTopCandidates(candidates, maxCount: 24);
    if (topCandidates.isEmpty) return PredictionEngineResult.empty();

    final best = topCandidates.first;
    final reasons = <String>[
      'AI Real Boost: Score aus Rücktest, Paar-Dynamik, Trend, Gap und Struktur-Balance.',
      'Kandidaten werden diversifiziert, damit nicht nur fast gleiche Top-Zahlen entstehen.',
      'Superzahl-Empfehlung nutzt Häufigkeit, aktuelle Dynamik und Positions-Gap.',
      ...best.reasons.take(4),
    ];

    return PredictionEngineResult(
      primaryTip: best.tip,
      recommendedSuperNumber: superNumber,
      overallScore: best.totalScore,
      score3Plus: best.score3Plus,
      topCandidates: topCandidates,
      reasons: reasons,
    );
  }

  Map<int, int> _buildFrequency(List<List<int>> draws) {
    final map = {for (int i = 1; i <= 49; i++) i: 0};
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

  Map<String, int> _buildPairCounts(List<List<int>> draws, {bool recencyWeighted = false}) {
    final map = <String, int>{};
    for (int rowIndex = 0; rowIndex < draws.length; rowIndex++) {
      final draw = draws[rowIndex];
      final weight = recencyWeighted ? max(1, draws.length - rowIndex) : 1;
      for (int i = 0; i < draw.length; i++) {
        for (int j = i + 1; j < draw.length; j++) {
          final key = '${draw[i]}-${draw[j]}';
          map[key] = (map[key] ?? 0) + weight;
        }
      }
    }
    return map;
  }

  Map<String, int> _buildTripleCounts(List<List<int>> draws) {
    final map = <String, int>{};
    for (final draw in draws) {
      for (int i = 0; i < draw.length; i++) {
        for (int j = i + 1; j < draw.length; j++) {
          for (int k = j + 1; k < draw.length; k++) {
            final key = '${draw[i]}-${draw[j]}-${draw[k]}';
            map[key] = (map[key] ?? 0) + 1;
          }
        }
      }
    }
    return map;
  }

  Map<int, int> _buildRepeatHistogram(List<List<int>> draws) {
    final hist = {for (int i = 0; i <= 6; i++) i: 0};
    for (int i = 1; i < draws.length; i++) {
      final prev = draws[i - 1].toSet();
      final curr = draws[i].toSet();
      final overlap = curr.where(prev.contains).length;
      hist[overlap] = (hist[overlap] ?? 0) + 1;
    }
    return hist;
  }

  int? _buildSuperNumberRecommendation(List<DrawResult> draws) {
    if (draws.isEmpty) return null;
    final totalCounts = {for (int i = 0; i <= 9; i++) i: 0};
    final recentCounts = {for (int i = 0; i <= 9; i++) i: 0};
    final lastSeen = {for (int i = 0; i <= 9; i++) i: draws.length + 99};
    final recentWindow = min(18, draws.length);

    for (int i = 0; i < draws.length; i++) {
      final sn = draws[i].superNumber;
      if (sn == null || sn < 0 || sn > 9) continue;
      totalCounts[sn] = (totalCounts[sn] ?? 0) + 1;
      if (i < recentWindow) recentCounts[sn] = (recentCounts[sn] ?? 0) + 1;
      if (lastSeen[sn] == draws.length + 99) lastSeen[sn] = i;
    }

    final ranked = <MapEntry<int, double>>[];
    for (int n = 0; n <= 9; n++) {
      final total = (totalCounts[n] ?? 0).toDouble();
      final recent = (recentCounts[n] ?? 0).toDouble();
      final gap = (lastSeen[n] ?? draws.length).toDouble();
      ranked.add(MapEntry(n, (total * 0.9) + (recent * 3.2) + (_gapCurve(gap, 4, 18) * 5.5)));
    }
    ranked.sort((a, b) => b.value.compareTo(a.value));
    return ranked.first.key;
  }

  List<_RankedNumber> _buildBaseRanking({
    required Map<int, int> freq,
    required Map<int, int> recency,
    required Map<int, int> medium,
    required Map<int, int> lastSeen,
    required Map<String, int> pairCounts,
    required String profileLabel,
  }) {
    final aggressive = profileLabel.toLowerCase().contains('aggressiv');
    final defensive = profileLabel.toLowerCase().contains('defensiv');
    final maxFreq = max(1, freq.values.reduce(max));
    final maxRecent = max(1, recency.values.reduce(max));
    final maxMedium = max(1, medium.values.reduce(max));
    final ranked = <_RankedNumber>[];

    for (int number = 1; number <= 49; number++) {
      final totalScore = (freq[number] ?? 0) / maxFreq;
      final recentScore = (recency[number] ?? 0) / maxRecent;
      final mediumScore = (medium[number] ?? 0) / maxMedium;
      final gap = (lastSeen[number] ?? 99).toDouble();
      final gapScore = _gapCurve(gap, aggressive ? 5 : 4, defensive ? 14 : 20);
      final pairAffinity = _numberPairAffinity(number, pairCounts);
      final bandBalance = _singleNumberBalance(number);
      final trend = ((recentScore * 0.65) + (mediumScore * 0.35) - (totalScore * 0.25)).clamp(-0.35, 1.0);

      double score =
          (totalScore * (defensive ? 28 : 18)) +
              (recentScore * (aggressive ? 28 : 22)) +
              (mediumScore * 17) +
              (trend * 12) +
              (gapScore * (aggressive ? 13 : 9)) +
              (pairAffinity * 11) +
              (bandBalance * 4);

      if (defensive) score += totalScore * 12;
      if (aggressive) score += gapScore * 5;
      ranked.add(_RankedNumber(number: number, score: score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  List<List<int>> _deterministicSeeds(List<_RankedNumber> ranking) {
    final byNumber = {for (final r in ranking) r.number: r};
    final hot = ranking.take(14).map((e) => e.number).toList();
    final mid = ranking.skip(8).take(20).map((e) => e.number).toList();
    final spread = <int>[1, 8, 15, 22, 29, 36, 43]
        .map((start) => _bestInRange(byNumber, start, min(49, start + 6)))
        .whereType<int>()
        .toList();

    return <List<int>>[
      [...hot.take(6)],
      [...hot.take(3), ...mid.take(3)],
      [...spread.take(6)],
      [...hot.where((n) => n.isOdd).take(3), ...hot.where((n) => n.isEven).take(3)],
      [...hot.where((n) => n <= 24).take(3), ...hot.where((n) => n >= 25).take(3)],
    ];
  }

  int? _bestInRange(Map<int, _RankedNumber> byNumber, int start, int end) {
    _RankedNumber? best;
    for (int n = start; n <= end; n++) {
      final item = byNumber[n];
      if (item == null) continue;
      if (best == null || item.score > best.score) best = item;
    }
    return best?.number;
  }

  List<int> _buildCandidateTip({
    required List<_RankedNumber> ranking,
    required Map<String, int> pairCounts,
    required Map<String, int> recentPairCounts,
    required Map<String, int> tripleCounts,
    required String profileLabel,
    required int round,
  }) {
    final aggressive = profileLabel.toLowerCase().contains('aggressiv');
    final defensive = profileLabel.toLowerCase().contains('defensiv');
    final selected = <int>{};
    final topPool = ranking.take(22).toList();
    final widePool = ranking.take(36).toList();
    final reboundPool = ranking.skip(12).take(28).toList();

    final anchorSource = round % 4 == 0 ? widePool : topPool;
    while (selected.length < 2 && anchorSource.isNotEmpty) {
      selected.add(_weightedPick(anchorSource).number);
    }

    while (selected.length < 6) {
      final current = selected.toList()..sort();
      final source = selected.length < 4
          ? widePool
          : (aggressive ? reboundPool : widePool);
      final scored = <_RankedNumber>[];
      for (final item in source) {
        if (selected.contains(item.number)) continue;
        final probe = [...current, item.number]..sort();
        final pairStrength = _probePairStrength(probe, pairCounts);
        final recentPairStrength = _probePairStrength(probe, recentPairCounts);
        final tripleStrength = _probeTripleStrength(probe, tripleCounts);
        final structure = _rawStructureScore(probe);
        final score = item.score +
            (pairStrength * 1.6) +
            (recentPairStrength * 0.08) +
            (tripleStrength * 2.0) +
            (structure * (defensive ? 0.5 : 0.35)) +
            (_random.nextDouble() * (aggressive ? 8 : 5));
        scored.add(_RankedNumber(number: item.number, score: score));
      }
      if (scored.isEmpty) break;
      scored.sort((a, b) => b.score.compareTo(a.score));
      selected.add(_weightedPick(scored.take(12).toList()).number);
    }

    for (final item in ranking) {
      if (selected.length >= 6) break;
      selected.add(item.number);
    }
    return selected.toList()..sort();
  }

  _RankedNumber _weightedPick(List<_RankedNumber> items) {
    if (items.length == 1) return items.first;
    final minScore = items.map((e) => e.score).reduce(min);
    final weights = items.map((e) => max(0.1, e.score - minScore + 1.0)).toList();
    final total = weights.fold<double>(0, (a, b) => a + b);
    var roll = _random.nextDouble() * total;
    for (int i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return items[i];
    }
    return items.last;
  }

  double _probePairStrength(List<int> tip, Map<String, int> pairCounts) {
    if (tip.length < 2) return 0;
    double sum = 0;
    int count = 0;
    for (int i = 0; i < tip.length; i++) {
      for (int j = i + 1; j < tip.length; j++) {
        sum += (pairCounts['${tip[i]}-${tip[j]}'] ?? 0).toDouble();
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  double _probeTripleStrength(List<int> tip, Map<String, int> tripleCounts) {
    if (tip.length < 3) return 0;
    double sum = 0;
    int count = 0;
    for (int i = 0; i < tip.length; i++) {
      for (int j = i + 1; j < tip.length; j++) {
        for (int k = j + 1; k < tip.length; k++) {
          sum += (tripleCounts['${tip[i]}-${tip[j]}-${tip[k]}'] ?? 0).toDouble();
          count++;
        }
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  List<int> _normalizeStructure(List<int> rawTip, List<_RankedNumber> ranking) {
    final result = rawTip.toSet().where((n) => n >= 1 && n <= 49).toList()..sort();
    for (final item in ranking) {
      if (result.length >= 6) break;
      result.add(item.number);
      final unique = result.toSet().toList()..sort();
      result..clear()..addAll(unique);
    }

    int guard = 0;
    while (!_isGoodStructure(result) && guard < 80) {
      guard++;
      final weakestIndex = _weakestStructuralIndex(result);
      result.removeAt(weakestIndex);
      for (final item in ranking.skip(_random.nextInt(min(12, ranking.length)))) {
        if (!result.contains(item.number)) {
          result.add(item.number);
          break;
        }
      }
      result.sort();
      while (result.length < 6) {
        final n = ranking[_random.nextInt(min(30, ranking.length))].number;
        if (!result.contains(n)) result.add(n);
      }
      result.sort();
    }
    return result.take(6).toList()..sort();
  }

  bool _isGoodStructure(List<int> tip) {
    if (tip.length != 6) return false;
    final even = tip.where((n) => n.isEven).length;
    final low = tip.where((n) => n <= 24).length;
    final sum = tip.fold<int>(0, (a, b) => a + b);
    final spread = tip.last - tip.first;
    final endDigits = tip.map((e) => e % 10).toSet().length;
    final decades = tip.map((e) => (e - 1) ~/ 10).toSet().length;
    return even >= 2 && even <= 4 && low >= 2 && low <= 4 && sum >= 100 && sum <= 185 && spread >= 20 && spread <= 44 && endDigits >= 4 && decades >= 4;
  }

  int _weakestStructuralIndex(List<int> tip) {
    if (tip.isEmpty) return 0;
    final even = tip.where((n) => n.isEven).length;
    final low = tip.where((n) => n <= 24).length;
    if (even > 4) return tip.indexWhere((n) => n.isEven);
    if (even < 2) return tip.indexWhere((n) => n.isOdd);
    if (low > 4) return tip.indexWhere((n) => n <= 24);
    if (low < 2) return tip.indexWhere((n) => n >= 25);
    final sum = tip.fold<int>(0, (a, b) => a + b);
    if (sum > 185) return tip.indexOf(tip.reduce(max));
    if (sum < 100) return tip.indexOf(tip.reduce(min));
    return _random.nextInt(tip.length);
  }

  PredictionCandidate _scoreTip({
    required List<int> tip,
    required List<List<int>> draws,
    required Map<String, int> pairCounts,
    required Map<String, int> recentPairCounts,
    required Map<String, int> tripleCounts,
    required Map<int, int> freq,
    required Map<int, int> recency,
    required Map<int, int> medium,
    required Map<int, int> lastSeen,
    required Map<int, int> repeatHistogram,
    required String profileLabel,
  }) {
    final backtest = _backtestTip(tip, draws.take(min(156, draws.length)).toList());
    final recentBacktest = _backtestTip(tip, draws.take(min(52, draws.length)).toList());
    final score3Plus = _score3Plus(backtest, min(156, draws.length)) + (_score3Plus(recentBacktest, min(52, draws.length)) * 0.45);
    final pairScore = (_pairScore(tip, pairCounts) * 0.65) + (_pairScore(tip, recentPairCounts) * 0.012);
    final tripleScore = _tripleScore(tip, tripleCounts);
    final recencyScore = _recencyScore(tip, freq, recency, medium);
    final overdueScore = _overdueScore(tip, lastSeen, profileLabel);
    final structureScore = _structureScore(tip, repeatHistogram);
    final antiCrowdScore = _antiCrowdScore(tip);
    final duplicatePenalty = _duplicatePatternPenalty(tip);

    final totalScore =
        (score3Plus * 0.30) +
            (pairScore * 0.20) +
            (tripleScore * 0.11) +
            (recencyScore * 0.17) +
            (overdueScore * 0.10) +
            (structureScore * 0.10) +
            (antiCrowdScore * 0.02) -
            duplicatePenalty;

    return PredictionCandidate(
      tip: tip,
      totalScore: totalScore,
      score3Plus: score3Plus,
      pairScore: pairScore,
      tripleScore: tripleScore,
      recencyScore: recencyScore,
      overdueScore: overdueScore,
      structureScore: structureScore,
      reasons: [
        'Rücktest 3+: ${score3Plus.toStringAsFixed(1)}',
        'Paar-/Clusterfit: ${pairScore.toStringAsFixed(1)}',
        'Dreiermuster: ${tripleScore.toStringAsFixed(1)}',
        'Trend + Medium-Fenster: ${recencyScore.toStringAsFixed(1)}',
        'Gap/Rückkehr: ${overdueScore.toStringAsFixed(1)}',
        'Struktur-Balance: ${structureScore.toStringAsFixed(1)}',
      ],
    );
  }

  Map<int, int> _backtestTip(List<int> tip, List<List<int>> draws) {
    final hist = {for (int i = 0; i <= 6; i++) i: 0};
    final set = tip.toSet();
    for (final draw in draws) {
      final hits = draw.where(set.contains).length;
      hist[hits] = (hist[hits] ?? 0) + 1;
    }
    return hist;
  }

  double _score3Plus(Map<int, int> backtest, int totalDraws) {
    if (totalDraws <= 0) return 0;
    final weighted =
        ((backtest[2] ?? 0) * 0.45) +
            ((backtest[3] ?? 0) * 3.4) +
            ((backtest[4] ?? 0) * 7.6) +
            ((backtest[5] ?? 0) * 14.0) +
            ((backtest[6] ?? 0) * 25.0);
    return (weighted / totalDraws) * 12.0;
  }

  double _pairScore(List<int> tip, Map<String, int> pairCounts) => _probePairStrength(tip, pairCounts);

  double _tripleScore(List<int> tip, Map<String, int> tripleCounts) => _probeTripleStrength(tip, tripleCounts);

  double _recencyScore(List<int> tip, Map<int, int> freq, Map<int, int> recency, Map<int, int> medium) {
    final maxFreq = max(1, freq.values.reduce(max));
    final maxRecent = max(1, recency.values.reduce(max));
    final maxMedium = max(1, medium.values.reduce(max));
    double sum = 0;
    for (final n in tip) {
      final f = (freq[n] ?? 0) / maxFreq;
      final r = (recency[n] ?? 0) / maxRecent;
      final m = (medium[n] ?? 0) / maxMedium;
      sum += (r * 16) + (m * 11) + (f * 7) + (((r * 0.7 + m * 0.3) - f * 0.2) * 8);
    }
    return sum / tip.length;
  }

  double _overdueScore(List<int> tip, Map<int, int> lastSeen, String profileLabel) {
    final aggressive = profileLabel.toLowerCase().contains('aggressiv');
    double sum = 0;
    for (final n in tip) {
      final gap = (lastSeen[n] ?? 99).toDouble();
      sum += _gapCurve(gap, aggressive ? 5 : 4, aggressive ? 22 : 16) * 18;
    }
    return sum / tip.length;
  }

  double _structureScore(List<int> tip, Map<int, int> repeatHistogram) {
    return _rawStructureScore(tip) + (((repeatHistogram[1] ?? 0) >= (repeatHistogram[2] ?? 0)) ? 2 : 0);
  }

  double _rawStructureScore(List<int> tip) {
    if (tip.isEmpty) return 0;
    final sorted = [...tip]..sort();
    final even = sorted.where((n) => n.isEven).length;
    final low = sorted.where((n) => n <= 24).length;
    final sum = sorted.fold<int>(0, (a, b) => a + b);
    final spread = sorted.last - sorted.first;
    final endDigits = sorted.map((e) => e % 10).toSet().length;
    final decades = sorted.map((e) => (e - 1) ~/ 10).toSet().length;
    final consecutivePairs = _consecutivePairs(sorted);
    double score = 0;
    if (even >= 2 && even <= 4) score += 8;
    if (low >= 2 && low <= 4) score += 8;
    if (sum >= 100 && sum <= 185) score += 10;
    if (spread >= 20 && spread <= 44) score += 8;
    if (endDigits >= 4) score += 5;
    if (decades >= 4) score += 5;
    if (consecutivePairs <= 1) score += 3;
    return score;
  }

  int _consecutivePairs(List<int> sorted) {
    int count = 0;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) count++;
    }
    return count;
  }

  double _antiCrowdScore(List<int> tip) {
    // Leichte Streuung gegen reine Geburtstags-/Musterreihen, ohne gute Zahlen hart zu bestrafen.
    final under32 = tip.where((n) => n <= 31).length;
    final allSameEndBand = tip.map((n) => n % 10).toSet().length <= 3;
    double score = 10;
    if (under32 >= 5) score -= 4;
    if (allSameEndBand) score -= 3;
    if (_consecutivePairs([...tip]..sort()) >= 2) score -= 2;
    return score.clamp(0, 10).toDouble();
  }

  double _duplicatePatternPenalty(List<int> tip) {
    final sorted = [...tip]..sort();
    final sameDecadeMax = <int, int>{};
    for (final n in sorted) {
      final d = (n - 1) ~/ 10;
      sameDecadeMax[d] = (sameDecadeMax[d] ?? 0) + 1;
    }
    final maxDecade = sameDecadeMax.values.fold<int>(0, max);
    return maxDecade >= 4 ? 2.5 : 0;
  }

  double _gapCurve(double gap, double minGood, double maxGood) {
    if (gap < minGood) return (gap / minGood).clamp(0.0, 1.0) * 0.55;
    if (gap <= maxGood) return 1.0;
    final decay = 1.0 - ((gap - maxGood) / 35.0);
    return decay.clamp(0.25, 1.0).toDouble();
  }

  double _numberPairAffinity(int number, Map<String, int> pairCounts) {
    double sum = 0;
    int count = 0;
    for (int other = 1; other <= 49; other++) {
      if (other == number) continue;
      final a = min(number, other);
      final b = max(number, other);
      sum += (pairCounts['$a-$b'] ?? 0).toDouble();
      count++;
    }
    if (count == 0) return 0;
    return (sum / count / 8.0).clamp(0.0, 1.0).toDouble();
  }

  double _singleNumberBalance(int number) {
    if (number >= 8 && number <= 42) return 1;
    if (number >= 4 && number <= 46) return 0.75;
    return 0.45;
  }

  List<PredictionCandidate> _diversifyTopCandidates(List<PredictionCandidate> sorted, {required int maxCount}) {
    final selected = <PredictionCandidate>[];
    for (final candidate in sorted) {
      if (selected.length >= maxCount) break;
      final tooSimilar = selected.any((existing) {
        final overlap = candidate.tip.toSet().intersection(existing.tip.toSet()).length;
        return overlap >= 5;
      });
      if (!tooSimilar) selected.add(candidate);
    }
    if (selected.length < min(maxCount, 8)) {
      for (final candidate in sorted) {
        if (selected.length >= maxCount) break;
        if (!selected.any((e) => e.tip.join('-') == candidate.tip.join('-'))) selected.add(candidate);
      }
    }
    selected.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return selected;
  }
}

class _RankedNumber {
  final int number;
  final double score;
  const _RankedNumber({required this.number, required this.score});
}
