import 'dart:math';

import '../../draws/domain/draw_result.dart';
import 'number_score.dart';

enum SmartPredictionProfile {
  defensive,
  balanced,
  aggressive,
}

class SmartPredictionEngine {
  const SmartPredictionEngine();

  List<NumberScore> scoreNumbers({
    required List<DrawResult> draws,
    SmartPredictionProfile profile = SmartPredictionProfile.balanced,
  }) {
    final sorted = _sortedDraws(draws);
    if (sorted.isEmpty) return _fallbackScores(profile);

    final recentWindow = min(18, sorted.length);
    final mediumWindow = min(60, sorted.length);
    final recent = sorted.take(recentWindow).toList();
    final medium = sorted.take(mediumWindow).toList();

    final totalCounts = <int, int>{for (var n = 1; n <= 49; n++) n: 0};
    final recentCounts = <int, int>{for (var n = 1; n <= 49; n++) n: 0};
    final mediumCounts = <int, int>{for (var n = 1; n <= 49; n++) n: 0};
    final lastSeenIndex = <int, int>{for (var n = 1; n <= 49; n++) n: sorted.length + 8};

    for (var i = 0; i < sorted.length; i++) {
      for (final n in _numbers(sorted[i])) {
        totalCounts[n] = (totalCounts[n] ?? 0) + 1;
        lastSeenIndex[n] = min(lastSeenIndex[n] ?? sorted.length + 8, i);
      }
    }

    for (final draw in recent) {
      for (final n in _numbers(draw)) {
        recentCounts[n] = (recentCounts[n] ?? 0) + 1;
      }
    }

    for (final draw in medium) {
      for (final n in _numbers(draw)) {
        mediumCounts[n] = (mediumCounts[n] ?? 0) + 1;
      }
    }

    final pairAffinity = _pairAffinity(sorted.take(min(80, sorted.length)).toList());
    final maxTotal = max(1, totalCounts.values.fold<int>(0, max));
    final maxRecent = max(1, recentCounts.values.fold<int>(0, max));
    final maxMedium = max(1, mediumCounts.values.fold<int>(0, max));
    final maxPair = max(1, pairAffinity.values.fold<int>(0, max));

    final weights = _weights(profile);
    final scores = <NumberScore>[];

    for (var n = 1; n <= 49; n++) {
      final frequencyScore = (totalCounts[n] ?? 0) / maxTotal;
      final recentScore = (recentCounts[n] ?? 0) / maxRecent;
      final mediumScore = (mediumCounts[n] ?? 0) / maxMedium;
      final trendScore = ((recentScore * 0.65) + (mediumScore * 0.35)).clamp(0.0, 1.0);

      final gap = lastSeenIndex[n] ?? sorted.length + 8;
      final expectedGap = max(4.0, sorted.length / 8.2);
      final reboundScore = (gap / (expectedGap * 2.2)).clamp(0.0, 1.0);
      final recencyScore = (1.0 / (gap + 1)).clamp(0.0, 1.0);
      final balanceScore = _balanceScore(n);
      final pairScore = ((pairAffinity[n] ?? 0) / maxPair).clamp(0.0, 1.0);

      final total =
          (frequencyScore * weights.frequency) +
              (recencyScore * weights.recency) +
              (trendScore * weights.trend) +
              (reboundScore * weights.rebound) +
              (balanceScore * weights.balance) +
              (pairScore * weights.pair);

      scores.add(
        NumberScore(
          number: n,
          frequencyScore: frequencyScore,
          recencyScore: recencyScore,
          trendScore: trendScore,
          reboundScore: reboundScore,
          balanceScore: balanceScore,
          pairScore: pairScore,
          totalScore: total,
        ),
      );
    }

    scores.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return scores;
  }

  List<int> generateMainNumbers({
    required List<DrawResult> draws,
    SmartPredictionProfile profile = SmartPredictionProfile.balanced,
    int count = 6,
  }) {
    final scores = scoreNumbers(draws: draws, profile: profile);
    return _pickBalanced(scores, count: count);
  }

  /// System-10: bewusst nicht nur Top-10.
  /// Mischung: 4 Stärke, 3 Trend, 2 Rebound, 1 Ausgleich.
  List<int> generateSystemNumbers({
    required List<DrawResult> draws,
    SmartPredictionProfile profile = SmartPredictionProfile.balanced,
    int count = 10,
  }) {
    final scores = scoreNumbers(draws: draws, profile: profile);
    if (scores.isEmpty) return const <int>[];

    final byTotal = [...scores]..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final byTrend = [...scores]..sort((a, b) => b.trendScore.compareTo(a.trendScore));
    final byRebound = [...scores]..sort((a, b) => b.reboundScore.compareTo(a.reboundScore));
    final byBalance = [...scores]..sort((a, b) => b.balanceScore.compareTo(a.balanceScore));

    final selected = <int>{};

    void addFrom(List<NumberScore> source, int amount) {
      for (final item in source) {
        if (selected.length >= count) break;
        if (selected.length >= amount) break;
        selected.add(item.number);
      }
    }

    void addUntil(List<NumberScore> source, int targetSize) {
      for (final item in source) {
        if (selected.length >= min(targetSize, count)) break;
        selected.add(item.number);
      }
    }

    addUntil(byTotal, 4);   // 4 starke Zahlen
    addUntil(byTrend, 7);   // +3 Trendzahlen
    addUntil(byRebound, 9); // +2 Rückkehrer
    addUntil(byBalance, 10); // +1 Ausgleichszahl
    addUntil(byTotal, count);

    final result = selected.take(count).toList()..sort();
    return result;
  }

  List<String> explainNumbers({
    required List<int> numbers,
    required List<DrawResult> draws,
    SmartPredictionProfile profile = SmartPredictionProfile.balanced,
  }) {
    final byNumber = {
      for (final score in scoreNumbers(draws: draws, profile: profile)) score.number: score,
    };

    return numbers.map((number) {
      final score = byNumber[number];
      if (score == null) return '$number: Ausgleichszahl im Profil';
      return '$number: ${score.shortReason}';
    }).toList();
  }

  int generateSuperNumber({
    required List<DrawResult> draws,
    int fallback = 0,
  }) {
    final counts = List<int>.filled(10, 0);
    for (final draw in _sortedDraws(draws)) {
      final value = draw.superNumber;
      if (value != null && value >= 0 && value <= 9) counts[value]++;
    }
    return _bestDigit(counts, fallback: fallback.clamp(0, 9));
  }

  String generateDigitSequence({
    required List<DrawResult> draws,
    required int length,
    required String? Function(DrawResult draw) extract,
    required String fallbackSeed,
  }) {
    final fallback = _normalizeDigits(fallbackSeed, length);
    final matrix = List.generate(length, (_) => List<int>.filled(10, 0));
    var usableRows = 0;

    for (final draw in _sortedDraws(draws)) {
      final digits = _normalizeDigits(extract(draw) ?? '', length, allowShort: false);
      if (digits.length != length) continue;
      usableRows++;
      for (var i = 0; i < length; i++) {
        final digit = int.tryParse(digits[i]);
        if (digit != null && digit >= 0 && digit <= 9) matrix[i][digit]++;
      }
    }

    if (usableRows == 0) return fallback;

    final buffer = StringBuffer();
    for (var pos = 0; pos < length; pos++) {
      buffer.write(_bestDigit(matrix[pos], fallback: int.tryParse(fallback[pos]) ?? 0));
    }
    return buffer.toString();
  }

  List<int> _pickBalanced(List<NumberScore> scores, {required int count}) {
    final selected = <int>{};
    final high = scores.where((s) => s.number >= 25).toList();
    final low = scores.where((s) => s.number <= 24).toList();
    final odd = scores.where((s) => s.number.isOdd).toList();
    final even = scores.where((s) => s.number.isEven).toList();

    void addBest(List<NumberScore> source, int target) {
      for (final item in source) {
        if (selected.length >= target) break;
        selected.add(item.number);
      }
    }

    addBest(scores, min(count, 2));
    addBest(low, min(count, 3));
    addBest(high, min(count, 4));
    addBest(odd, min(count, 5));
    addBest(even, count);
    addBest(scores, count);

    final result = selected.take(count).toList()..sort();
    return result;
  }

  List<DrawResult> _sortedDraws(List<DrawResult> draws) {
    return List<DrawResult>.from(draws)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
  }

  List<int> _numbers(DrawResult draw) {
    return draw.numbers.where((n) => n >= 1 && n <= 49).toSet().toList();
  }

  Map<int, int> _pairAffinity(List<DrawResult> draws) {
    final result = <int, int>{for (var n = 1; n <= 49; n++) n: 0};
    for (final draw in draws) {
      final nums = _numbers(draw);
      for (final n in nums) {
        result[n] = (result[n] ?? 0) + max(0, nums.length - 1);
      }
    }
    return result;
  }

  double _balanceScore(int n) {
    final centerDistance = (25 - n).abs() / 24.0;
    final centerScore = (1.0 - centerDistance).clamp(0.0, 1.0);
    final endDigit = n % 10;
    final digitBalance = (endDigit == 0 || endDigit == 9) ? 0.65 : 1.0;
    return ((centerScore * 0.65) + (digitBalance * 0.35)).clamp(0.0, 1.0);
  }

  int _bestDigit(List<int> counts, {required int fallback}) {
    var best = fallback.clamp(0, 9);
    for (var i = 0; i < counts.length; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return best;
  }

  String _normalizeDigits(String input, int length, {bool allowShort = true}) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= length) return digits.substring(0, length);
    if (!allowShort) return '';
    if (digits.isEmpty) return ''.padLeft(length, '0');
    return digits.padRight(length, digits[digits.length - 1]);
  }

  List<NumberScore> _fallbackScores(SmartPredictionProfile profile) {
    final weights = _weights(profile);
    return List.generate(49, (index) {
      final number = index + 1;
      final balance = _balanceScore(number);
      final total = (balance * weights.balance) + ((1.0 - (number / 60.0)) * 0.15);
      return NumberScore(
        number: number,
        frequencyScore: 0,
        recencyScore: 0,
        trendScore: 0,
        reboundScore: 0,
        balanceScore: balance,
        pairScore: 0,
        totalScore: total,
      );
    })..sort((a, b) => b.totalScore.compareTo(a.totalScore));
  }

  _ScoreWeights _weights(SmartPredictionProfile profile) {
    switch (profile) {
      case SmartPredictionProfile.defensive:
        return const _ScoreWeights(
          frequency: 0.34,
          recency: 0.16,
          trend: 0.18,
          rebound: 0.08,
          balance: 0.16,
          pair: 0.08,
        );
      case SmartPredictionProfile.aggressive:
        return const _ScoreWeights(
          frequency: 0.18,
          recency: 0.08,
          trend: 0.24,
          rebound: 0.26,
          balance: 0.08,
          pair: 0.16,
        );
      case SmartPredictionProfile.balanced:
        return const _ScoreWeights(
          frequency: 0.24,
          recency: 0.12,
          trend: 0.22,
          rebound: 0.16,
          balance: 0.12,
          pair: 0.14,
        );
    }
  }
}

class _ScoreWeights {
  const _ScoreWeights({
    required this.frequency,
    required this.recency,
    required this.trend,
    required this.rebound,
    required this.balance,
    required this.pair,
  });

  final double frequency;
  final double recency;
  final double trend;
  final double rebound;
  final double balance;
  final double pair;
}
