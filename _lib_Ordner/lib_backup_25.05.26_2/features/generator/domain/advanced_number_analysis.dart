import '../../draws/domain/draw_result.dart';

class NumberAnalysis {
  final int number;
  final int totalCount;
  final int lastSeenIndex;
  final int currentGap;
  final double trendScore;
  final double returnScore;
  final double pairScore;
  final double tripleScore;
  final double rangeScore;
  final double totalScore;

  const NumberAnalysis({
    required this.number,
    required this.totalCount,
    required this.lastSeenIndex,
    required this.currentGap,
    required this.trendScore,
    required this.returnScore,
    required this.pairScore,
    required this.tripleScore,
    required this.rangeScore,
    required this.totalScore,
  });
}

class PairPattern {
  final List<int> pair;
  final int count;
  final double score;

  const PairPattern({
    required this.pair,
    required this.count,
    required this.score,
  });
}

class TriplePattern {
  final List<int> triple;
  final int count;
  final double score;

  const TriplePattern({
    required this.triple,
    required this.count,
    required this.score,
  });
}

class RangeGroupAnalysis {
  final String label;
  final int min;
  final int max;
  final int hitCount;
  final double averagePerDraw;
  final double share;

  const RangeGroupAnalysis({
    required this.label,
    required this.min,
    required this.max,
    required this.hitCount,
    required this.averagePerDraw,
    required this.share,
  });
}


class SmartNumberReason {
  final int number;
  final String label;
  final String description;
  final double score;
  final String badge;

  const SmartNumberReason({
    required this.number,
    required this.label,
    required this.description,
    required this.score,
    required this.badge,
  });
}

class SmartTipDetails {
  final List<int> numbers;
  final List<String> reasons;
  final List<SmartNumberReason> numberReasons;

  const SmartTipDetails({
    required this.numbers,
    required this.reasons,
    this.numberReasons = const [],
  });
}
class AdvancedNumberAnalysisService {
  const AdvancedNumberAnalysisService();

  List<NumberAnalysis> buildAdvancedAnalysis(List<DrawResult> draws) {
    if (draws.isEmpty) return [];

    final sortedDraws = List<DrawResult>.from(draws)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    final limitedDraws =
    sortedDraws.length > 140 ? sortedDraws.take(140).toList() : sortedDraws;

    final pairPatterns = buildPairPatterns(limitedDraws, top: 48);
    final triplePatterns = buildTriplePatterns(limitedDraws, top: 28);
    final rangeGroups = buildRangeGroups(limitedDraws);

    final totalCount = <int, int>{};
    final lastSeen = <int, int>{};
    final recentCount = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    final mediumCount = <int, int>{for (int i = 1; i <= 49; i++) i: 0};

    final recentWindow = limitedDraws.length >= 12 ? 12 : limitedDraws.length;
    final mediumWindow = limitedDraws.length >= 36 ? 36 : limitedDraws.length;

    for (int i = 0; i < limitedDraws.length; i++) {
      final numbers = _normalizedNumbers(limitedDraws[i]);
      for (final n in numbers) {
        totalCount[n] = (totalCount[n] ?? 0) + 1;
        lastSeen.putIfAbsent(n, () => i);
        if (i < recentWindow) recentCount[n] = (recentCount[n] ?? 0) + 1;
        if (i < mediumWindow) mediumCount[n] = (mediumCount[n] ?? 0) + 1;
      }
    }

    final rangeContribution = <int, double>{};
    for (final group in rangeGroups) {
      final weight = group.share * 8.0;
      for (int n = group.min; n <= group.max; n++) {
        rangeContribution[n] = (rangeContribution[n] ?? 0) + weight;
      }
    }

    final result = <NumberAnalysis>[];

    for (int n = 1; n <= 49; n++) {
      final count = totalCount[n] ?? 0;
      final lastIndex = lastSeen[n] ?? -1;
      final gap = lastIndex == -1 ? limitedDraws.length : lastIndex;
      final trend = _buildTrendScore(
        totalCount: count,
        recentCount: recentCount[n] ?? 0,
        mediumCount: mediumCount[n] ?? 0,
      );
      final returnScore = _buildReturnScore(gap);

      double pairScore = 0;
      for (final pair in pairPatterns) {
        if (pair.pair.contains(n)) pairScore += pair.count.toDouble();
      }

      double tripleScore = 0;
      for (final triple in triplePatterns) {
        if (triple.triple.contains(n)) {
          tripleScore += triple.count.toDouble() * 1.4;
        }
      }

      final rangeScore = rangeContribution[n] ?? 0.0;

      final totalScore = (count * 0.50) +
          (trend * 1.55) +
          (returnScore * 2.25) +
          (pairScore * 0.20) +
          (tripleScore * 0.17) +
          (rangeScore * 0.22);

      result.add(
        NumberAnalysis(
          number: n,
          totalCount: count,
          lastSeenIndex: lastIndex,
          currentGap: gap,
          trendScore: trend,
          returnScore: returnScore,
          pairScore: pairScore,
          tripleScore: tripleScore,
          rangeScore: rangeScore,
          totalScore: totalScore,
        ),
      );
    }

    result.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return result;
  }

  double _buildTrendScore({
    required int totalCount,
    required int recentCount,
    required int mediumCount,
  }) {
    final recentWeight = recentCount * 3.2;
    final mediumWeight = mediumCount * 1.6;
    final baselinePenalty = totalCount * 0.18;
    return recentWeight + mediumWeight - baselinePenalty;
  }

  double _buildReturnScore(int gap) {
    if (gap >= 24) return 3.6;
    if (gap >= 18) return 3.0;
    if (gap >= 12) return 2.2;
    if (gap >= 8) return 1.5;
    if (gap >= 4) return 0.8;
    return 0.0;
  }

  List<int> getTopNumbers(List<DrawResult> draws, {int count = 10}) {
    final analysis = buildAdvancedAnalysis(draws);
    return analysis.take(count).map((e) => e.number).toList();
  }

  List<int> buildSystem10Numbers(
      List<DrawResult> draws, {
        String profile = 'balanced',
      }) {
    final analysis = buildAdvancedAnalysis(draws);
    if (analysis.isEmpty) return const [];

    final selected = <int>[];

    void addUnique(Iterable<NumberAnalysis> items, int targetCount) {
      for (final item in items) {
        if (selected.length >= targetCount) break;
        if (!selected.contains(item.number)) selected.add(item.number);
      }
    }

    final byTotal = List<NumberAnalysis>.from(analysis)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final byTrend = List<NumberAnalysis>.from(analysis)
      ..sort((a, b) {
        final cmp = b.trendScore.compareTo(a.trendScore);
        return cmp != 0 ? cmp : b.totalScore.compareTo(a.totalScore);
      });
    final byReturn = List<NumberAnalysis>.from(analysis)
      ..sort((a, b) {
        final cmp = b.returnScore.compareTo(a.returnScore);
        return cmp != 0 ? cmp : b.currentGap.compareTo(a.currentGap);
      });
    final byPair = List<NumberAnalysis>.from(analysis)
      ..sort((a, b) {
        final cmp = b.pairScore.compareTo(a.pairScore);
        return cmp != 0 ? cmp : b.totalScore.compareTo(a.totalScore);
      });

    final normalizedProfile = profile.toLowerCase();
    if (normalizedProfile.contains('aggressiv')) {
      addUnique(byTrend, 4);
      addUnique(byReturn, 7);
      addUnique(byTotal, 9);
      addUnique(_rangeBalanceCandidates(analysis, selected), 10);
    } else if (normalizedProfile.contains('defensiv')) {
      addUnique(byTotal, 5);
      addUnique(byPair, 7);
      addUnique(byTrend, 9);
      addUnique(_rangeBalanceCandidates(analysis, selected), 10);
    } else {
      addUnique(byTotal, 4);
      addUnique(byTrend, 7);
      addUnique(byReturn, 9);
      addUnique(_rangeBalanceCandidates(analysis, selected), 10);
    }

    addUnique(byTotal, 10);
    return (selected.take(10).toList()..sort());
  }

  List<SmartNumberReason> buildSystem10Reasoning(
      List<DrawResult> draws, {
        String profile = 'balanced',
      }) {
    final analysis = buildAdvancedAnalysis(draws);
    if (analysis.isEmpty) return const [];
    final map = {for (final item in analysis) item.number: item};
    final numbers = buildSystem10Numbers(draws, profile: profile);
    return numbers
        .map((n) => _buildReason(map[n], contextLabel: 'System-10'))
        .whereType<SmartNumberReason>()
        .toList();
  }

  Iterable<NumberAnalysis> _rangeBalanceCandidates(
      List<NumberAnalysis> analysis,
      List<int> selected,
      ) {
    final selectedRanges = <int, int>{};
    for (final n in selected) {
      final r = _rangeIndex(n);
      selectedRanges[r] = (selectedRanges[r] ?? 0) + 1;
    }
    final candidates = List<NumberAnalysis>.from(analysis)
      ..sort((a, b) {
        final ar = selectedRanges[_rangeIndex(a.number)] ?? 0;
        final br = selectedRanges[_rangeIndex(b.number)] ?? 0;
        final cmp = ar.compareTo(br);
        return cmp != 0 ? cmp : b.totalScore.compareTo(a.totalScore);
      });
    return candidates;
  }

  int _rangeIndex(int n) {
    if (n <= 10) return 0;
    if (n <= 20) return 1;
    if (n <= 30) return 2;
    if (n <= 40) return 3;
    return 4;
  }
  List<PairPattern> buildPairPatterns(List<DrawResult> draws, {int top = 12}) {
    if (draws.isEmpty) return [];
    final limitedDraws = draws.length > 110 ? draws.take(110).toList() : draws;
    final pairMap = <String, int>{};
    for (final draw in limitedDraws) {
      final numbers = _normalizedNumbers(draw);
      if (numbers.length < 2) continue;
      for (int i = 0; i < numbers.length; i++) {
        for (int j = i + 1; j < numbers.length; j++) {
          final key = '${numbers[i]}-${numbers[j]}';
          pairMap[key] = (pairMap[key] ?? 0) + 1;
        }
      }
    }
    final result = pairMap.entries.map((entry) {
      final parts = entry.key.split('-').map(int.parse).toList()..sort();
      return PairPattern(pair: parts, count: entry.value, score: entry.value.toDouble());
    }).where((e) => e.pair.length == 2).toList();
    result.sort((a, b) => b.score.compareTo(a.score));
    return result.take(top).toList();
  }

  List<TriplePattern> buildTriplePatterns(List<DrawResult> draws, {int top = 10}) {
    if (draws.isEmpty) return [];
    final limitedDraws = draws.length > 80 ? draws.take(80).toList() : draws;
    final tripleMap = <String, int>{};
    for (final draw in limitedDraws) {
      final numbers = _normalizedNumbers(draw);
      if (numbers.length < 3) continue;
      for (int i = 0; i < numbers.length; i++) {
        for (int j = i + 1; j < numbers.length; j++) {
          for (int k = j + 1; k < numbers.length; k++) {
            final key = '${numbers[i]}-${numbers[j]}-${numbers[k]}';
            tripleMap[key] = (tripleMap[key] ?? 0) + 1;
          }
        }
      }
    }
    final result = tripleMap.entries.map((entry) {
      final parts = entry.key.split('-').map(int.parse).toList()..sort();
      return TriplePattern(triple: parts, count: entry.value, score: entry.value.toDouble());
    }).where((e) => e.triple.length == 3).toList();
    result.sort((a, b) => b.score.compareTo(a.score));
    return result.take(top).toList();
  }

  List<RangeGroupAnalysis> buildRangeGroups(List<DrawResult> draws) {
    if (draws.isEmpty) return const [];
    final groups = <({String label, int min, int max})>[
      (label: '1-10', min: 1, max: 10),
      (label: '11-20', min: 11, max: 20),
      (label: '21-30', min: 21, max: 30),
      (label: '31-40', min: 31, max: 40),
      (label: '41-49', min: 41, max: 49),
    ];
    int totalNumbers = 0;
    for (final draw in draws) {
      totalNumbers += _normalizedNumbers(draw).length;
    }
    if (totalNumbers <= 0) return const [];
    final result = <RangeGroupAnalysis>[];
    for (final group in groups) {
      int hitCount = 0;
      for (final draw in draws) {
        for (final n in _normalizedNumbers(draw)) {
          if (n >= group.min && n <= group.max) hitCount++;
        }
      }
      result.add(RangeGroupAnalysis(
        label: group.label,
        min: group.min,
        max: group.max,
        hitCount: hitCount,
        averagePerDraw: draws.isEmpty ? 0 : hitCount / draws.length,
        share: hitCount / totalNumbers,
      ));
    }
    result.sort((a, b) => b.share.compareTo(a.share));
    return result;
  }

  List<int> generateSmartTip(List<DrawResult> draws) => generateSmartTipDetails(draws).numbers;

  SmartTipDetails generateSmartTipDetails(List<DrawResult> draws) {
    final analysis = buildAdvancedAnalysis(draws);
    if (analysis.isEmpty) {
      return const SmartTipDetails(numbers: [], reasons: []);
    }

    final selected = <int>[];

    // 1) Zuerst starke Gesamt-Scores wählen, aber direkte Nachbarn begrenzen.
    for (final item in analysis.take(18)) {
      if (selected.length >= 6) break;
      final tooClose = selected.where((n) => (n - item.number).abs() <= 1).length >= 2;
      if (!selected.contains(item.number) && !tooClose) {
        selected.add(item.number);
      }
    }

    // 2) Danach Rebound-Kandidaten ergänzen, damit lange Pausen berücksichtigt werden.
    final rebound = List<NumberAnalysis>.from(analysis)
      ..sort((a, b) {
        final byGap = b.currentGap.compareTo(a.currentGap);
        if (byGap != 0) return byGap;
        return b.totalScore.compareTo(a.totalScore);
      });
    for (final item in rebound.take(18)) {
      if (selected.length >= 6) break;
      if (!selected.contains(item.number)) {
        selected.add(item.number);
      }
    }

    // 3) Sicherheits-Fallback: nach Score auffüllen.
    for (final item in analysis) {
      if (selected.length >= 6) break;
      if (!selected.contains(item.number)) selected.add(item.number);
    }

    selected.sort();

    final top = analysis.first;
    final bestPair = buildPairPatterns(draws, top: 1);
    final reasons = <String>[
      'Score basiert auf Häufigkeit, kurzem Trendfenster, Rückkehr-Chance, Paaren, Tripeln und Zahlenbereichen.',
      'Stärkster Einzel-Score: ${top.number} mit ${top.totalScore.toStringAsFixed(1)} Punkten.',
      if (bestPair.isNotEmpty)
        'Stärkstes Paar im Analysefenster: ${bestPair.first.pair.join(' / ')} (${bestPair.first.count}x).',
      'Direkte Nachbarhäufung wird begrenzt, damit der Tipp nicht nur aus einem Zahlencluster besteht.',
    ];

    final chosen = selected.take(6).toList()..sort();
    final analysisByNumber = {for (final item in analysis) item.number: item};
    final numberReasons = chosen
        .map((n) => _buildReason(analysisByNumber[n], contextLabel: 'AI-Tipp'))
        .whereType<SmartNumberReason>()
        .toList();

    return SmartTipDetails(
      numbers: chosen,
      reasons: reasons,
      numberReasons: numberReasons,
    );
  }

  SmartNumberReason? _buildReason(
      NumberAnalysis? item, {
        required String contextLabel,
      }) {
    if (item == null) return null;

    final signals = <String>[];
    String label;
    String badge;

    if (item.trendScore >= 8) {
      signals.add('Trend steigt');
    } else if (item.trendScore >= 4) {
      signals.add('stabiler Trend');
    }

    if (item.returnScore >= 3) {
      signals.add('Rebound');
    } else if (item.currentGap >= 10) {
      signals.add('lange Pause');
    }

    if (item.totalCount >= 8) {
      signals.add('häufig');
    }

    if (item.pairScore >= 4) {
      signals.add('Paarbindung');
    }

    if (item.tripleScore >= 3) {
      signals.add('Musterbindung');
    }

    if (signals.isEmpty) {
      signals.add('Ausgleichszahl');
    }

    if (signals.contains('Rebound') || signals.contains('lange Pause')) {
      label = 'Rückkehrer';
      badge = 'Rebound';
    } else if (signals.contains('Trend steigt') || signals.contains('stabiler Trend')) {
      label = 'Trendzahl';
      badge = 'Trend';
    } else if (signals.contains('Paarbindung') || signals.contains('Musterbindung')) {
      label = 'Kombination';
      badge = 'Muster';
    } else if (signals.contains('häufig')) {
      label = 'Stabil';
      badge = 'Hot';
    } else {
      label = 'Balance';
      badge = 'Ausgleich';
    }

    return SmartNumberReason(
      number: item.number,
      label: label,
      badge: badge,
      score: item.totalScore,
      description: '$contextLabel: ${signals.join(' • ')} · Score ${item.totalScore.toStringAsFixed(1)} · Pause ${item.currentGap}',
    );
  }
  List<int> _normalizedNumbers(DrawResult draw) {
    final unique = draw.numbers.toSet().toList()..sort();
    return unique.where((n) => n >= 1 && n <= 49).toList();
  }
}
