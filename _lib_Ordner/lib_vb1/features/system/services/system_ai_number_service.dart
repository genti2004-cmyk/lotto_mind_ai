import 'dart:math';

import 'package:lotto_mind_ai/features/draws/domain/draw_result.dart';

/// AI-basierte Pool-Erzeugung fuer Lotto-Systeme.
///
/// Ziel:
/// - Normal bleibt 6 Zahlen.
/// - Vollsystem und VEW nutzen 7 bis 10 Basiszahlen.
/// - Die Auswahl respektiert den aktuellen Analysefilter, weil der Screen
///   [analysisDrawResults] uebergibt.
class SystemAiNumberService {
  SystemAiNumberService({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<int> generateSystemNumbers({
    required List<DrawResult> draws,
    required int count,
    required String mode,
  }) {
    final target = count.clamp(6, 10).toInt();
    if (draws.isEmpty) return _randomNumbers(target);

    final frequency = <int, int>{for (var n = 1; n <= 49; n++) n: 0};
    final lastSeen = <int, int>{for (var n = 1; n <= 49; n++) n: 9999};
    final pairScore = <int, int>{for (var n = 1; n <= 49; n++) n: 0};

    final source = draws.take(260).toList();
    for (var index = 0; index < source.length; index++) {
      final nums = source[index].numbers
          .where((n) => n >= 1 && n <= 49)
          .toSet()
          .toList()
        ..sort();
      for (final n in nums) {
        frequency[n] = (frequency[n] ?? 0) + 1;
        if ((lastSeen[n] ?? 9999) == 9999) lastSeen[n] = index;
      }
      for (var i = 0; i < nums.length; i++) {
        for (var j = i + 1; j < nums.length; j++) {
          pairScore[nums[i]] = (pairScore[nums[i]] ?? 0) + 1;
          pairScore[nums[j]] = (pairScore[nums[j]] ?? 0) + 1;
        }
      }
    }

    final hot = _rankNumbers(
      frequency: frequency,
      lastSeen: lastSeen,
      pairScore: pairScore,
      hotWeight: 1.0,
      coldWeight: 0.12,
      pairWeight: 0.20,
    );
    final cold = _rankNumbers(
      frequency: frequency,
      lastSeen: lastSeen,
      pairScore: pairScore,
      hotWeight: 0.10,
      coldWeight: 1.0,
      pairWeight: 0.10,
    );
    final balanced = _rankNumbers(
      frequency: frequency,
      lastSeen: lastSeen,
      pairScore: pairScore,
      hotWeight: 0.72,
      coldWeight: 0.42,
      pairWeight: 0.24,
    );

    final selected = <int>{};
    final normalizedMode = mode.toLowerCase().trim();

    if (normalizedMode.contains('trend') || normalizedMode.contains('hot')) {
      selected.addAll(hot.take((target * 0.65).round()));
      selected.addAll(balanced.where((n) => !selected.contains(n)).take(target - selected.length));
    } else if (normalizedMode.contains('rebound') || normalizedMode.contains('cold')) {
      selected.addAll(cold.take((target * 0.45).round()));
      selected.addAll(balanced.where((n) => !selected.contains(n)).take(target - selected.length));
    } else if (normalizedMode.contains('jackpot')) {
      selected.addAll(balanced.take((target * 0.55).round()));
      while (selected.length < target) {
        final candidate = 1 + _random.nextInt(49);
        if (_isGoodSpread([...selected, candidate])) selected.add(candidate);
      }
    } else {
      selected.addAll(balanced.take((target * 0.70).round()));
      selected.addAll(cold.where((n) => !selected.contains(n)).take(1));
      selected.addAll(hot.where((n) => !selected.contains(n)).take(target - selected.length));
    }

    for (final n in balanced) {
      if (selected.length >= target) break;
      selected.add(n);
    }
    while (selected.length < target) {
      selected.add(1 + _random.nextInt(49));
    }

    return selected.take(target).toList()..sort();
  }

  List<int> _rankNumbers({
    required Map<int, int> frequency,
    required Map<int, int> lastSeen,
    required Map<int, int> pairScore,
    required double hotWeight,
    required double coldWeight,
    required double pairWeight,
  }) {
    final maxFreq = max(1, frequency.values.fold<int>(0, max));
    final maxPair = max(1, pairScore.values.fold<int>(0, max));

    final scored = List<int>.generate(49, (i) => i + 1);
    scored.sort((a, b) {
      final scoreA = _score(
        number: a,
        frequency: frequency,
        lastSeen: lastSeen,
        pairScore: pairScore,
        maxFreq: maxFreq,
        maxPair: maxPair,
        hotWeight: hotWeight,
        coldWeight: coldWeight,
        pairWeight: pairWeight,
      );
      final scoreB = _score(
        number: b,
        frequency: frequency,
        lastSeen: lastSeen,
        pairScore: pairScore,
        maxFreq: maxFreq,
        maxPair: maxPair,
        hotWeight: hotWeight,
        coldWeight: coldWeight,
        pairWeight: pairWeight,
      );
      final byScore = scoreB.compareTo(scoreA);
      if (byScore != 0) return byScore;
      return a.compareTo(b);
    });
    return scored;
  }

  double _score({
    required int number,
    required Map<int, int> frequency,
    required Map<int, int> lastSeen,
    required Map<int, int> pairScore,
    required int maxFreq,
    required int maxPair,
    required double hotWeight,
    required double coldWeight,
    required double pairWeight,
  }) {
    final hot = (frequency[number] ?? 0) / maxFreq;
    final cold = min(lastSeen[number] ?? 9999, 52) / 52.0;
    final pair = (pairScore[number] ?? 0) / maxPair;
    final centerPenalty = (25 - number).abs() * 0.002;
    return hot * hotWeight + cold * coldWeight + pair * pairWeight - centerPenalty;
  }

  bool _isGoodSpread(List<int> numbers) {
    if (numbers.length <= 2) return true;
    final sorted = numbers.toSet().toList()..sort();
    final low = sorted.where((n) => n <= 24).length;
    final odd = sorted.where((n) => n.isOdd).length;
    return low >= 1 && odd >= 1;
  }

  List<int> _randomNumbers(int count) {
    final result = <int>{};
    while (result.length < count) {
      result.add(1 + _random.nextInt(49));
    }
    return result.toList()..sort();
  }
}
