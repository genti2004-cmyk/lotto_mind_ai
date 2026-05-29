import 'dart:math';

import '../../draws/domain/draw_result.dart';
import '../../analysis/domain/number_analysis_score.dart';
import '../domain/analysis_rule_set.dart';
import '../domain/lotto_generator_service.dart';
import 'pro_prediction_engine.dart';

class GeneratedTipPayload {
  final List<int> numbers;
  final int? superNumber;

  const GeneratedTipPayload({
    required this.numbers,
    required this.superNumber,
  });

  bool get isValid => numbers.length == 6;
}

class GeneratedTipService {
  final Random _random;

  GeneratedTipService({Random? random}) : _random = random ?? Random();

  int generateRandomSuperNumber() {
    return _random.nextInt(10);
  }

  GeneratedTipPayload generateRandomTip(LottoGeneratorService generatorService) {
    return GeneratedTipPayload(
      numbers: generatorService.generateRandomTip(),
      superNumber: generateRandomSuperNumber(),
    );
  }

  GeneratedTipPayload generateAnalysisTip({
    required LottoGeneratorService generatorService,
    required PredictionEngineResult predictionResult,
    required AnalysisRuleSet rules,
    required List<DrawResult> historicalDraws,
  }) {
    if (predictionResult.primaryTip.length == 6) {
      return GeneratedTipPayload(
        numbers: _normalizeNumbers(predictionResult.primaryTip),
        superNumber: _normalizeSuperNumber(predictionResult.recommendedSuperNumber),
      );
    }

    return GeneratedTipPayload(
      numbers: generatorService.generateAnalysisTip(
        rules,
        historicalDraws: historicalDraws,
      ),
      superNumber: _normalizeSuperNumber(predictionResult.recommendedSuperNumber) ??
          generateRandomSuperNumber(),
    );
  }


  GeneratedTipPayload generateSignalTip({
    required List<NumberAnalysisScore> scores,
    int? recommendedSuperNumber,
  }) {
    // v47b: leichte Kandidatenbewertung mit hartem Sicherheitslimit.
    // Die schwere v47-Variante wurde verworfen, weil sie auf dem Gerät zu viel
    // im UI-Thread gerechnet hat. Diese Version bewertet nur wenige Kandidaten
    // aus den Top-Signalen und fällt bei Bedarf auf den einfachen Signal-Tipp
    // zurück.
    final rankedScores = scores
        .where((score) => score.number >= 1 && score.number <= 49)
        .toList()
      ..sort((a, b) {
        final byHybrid = b.hybridScore.compareTo(a.hybridScore);
        return byHybrid != 0 ? byHybrid : a.number.compareTo(b.number);
      });

    final fallbackNumbers = rankedScores
        .map((score) => score.number)
        .toSet()
        .take(6)
        .toList()
      ..sort();

    final candidates = _buildLightSignalCandidates(rankedScores);
    final bestCandidate = candidates.isEmpty
        ? fallbackNumbers
        : (candidates
              ..sort((a, b) =>
                  _candidateScore(b, rankedScores).compareTo(_candidateScore(a, rankedScores))))
            .first;

    final numbers = bestCandidate.length == 6 ? bestCandidate : fallbackNumbers;

    return GeneratedTipPayload(
      numbers: numbers,
      superNumber: _normalizeSuperNumber(recommendedSuperNumber) ??
          generateRandomSuperNumber(),
    );
  }

  List<List<int>> _buildLightSignalCandidates(List<NumberAnalysisScore> scores) {
    if (scores.length < 6) return const <List<int>>[];

    final pool = scores.take(14).map((score) => score.number).toList();
    final candidates = <List<int>>[];

    void addCandidate(Iterable<int> values) {
      if (candidates.length >= 12) return;
      final candidate = values
          .where((number) => number >= 1 && number <= 49)
          .toSet()
          .toList()
        ..sort();
      if (candidate.length != 6) return;
      final key = candidate.join(',');
      if (candidates.any((existing) => existing.join(',') == key)) return;
      candidates.add(candidate);
    }

    addCandidate(pool.take(6));
    addCandidate(pool.skip(1).take(6));
    addCandidate(pool.skip(2).take(6));

    final evenIndexed = <int>[];
    final oddIndexed = <int>[];
    for (var i = 0; i < pool.length; i++) {
      if (i.isEven) {
        evenIndexed.add(pool[i]);
      } else {
        oddIndexed.add(pool[i]);
      }
    }
    addCandidate([...evenIndexed.take(3), ...oddIndexed.take(3)]);

    final low = pool.where((number) => number <= 24).take(3);
    final high = pool.where((number) => number > 24).take(3);
    addCandidate([...low, ...high]);

    final byRange = <int>[];
    for (final range in const [(1, 10), (11, 20), (21, 30), (31, 40), (41, 49)]) {
      final picked = pool.where((number) => number >= range.$1 && number <= range.$2);
      if (picked.isNotEmpty) byRange.add(picked.first);
    }
    for (final number in pool) {
      if (byRange.length >= 6) break;
      if (!byRange.contains(number)) byRange.add(number);
    }
    addCandidate(byRange);

    // Wenige leichte Rotationen, hart begrenzt auf maximal 12 Kandidaten.
    for (var start = 0; start < 6 && candidates.length < 12; start++) {
      addCandidate(pool.skip(start).take(8).toList()..shuffle(_random));
    }

    return candidates;
  }

  double _candidateScore(
    List<int> candidate,
    List<NumberAnalysisScore> rankedScores,
  ) {
    if (candidate.length != 6) return -999;
    final scoreByNumber = {for (final score in rankedScores) score.number: score};
    final baseScore = candidate
            .map((number) => scoreByNumber[number]?.hybridScore ?? 0.0)
            .fold<double>(0.0, (sum, value) => sum + value) /
        candidate.length;

    final oddCount = candidate.where((number) => number.isOdd).length;
    final lowCount = candidate.where((number) => number <= 24).length;
    final rangePenalty = _rangePenalty(candidate);
    final clusterPenalty = _clusterPenalty(candidate);
    final regularPenalty = _regularGapPenalty(candidate);

    final oddBalance = 1.0 - ((oddCount - 3).abs() / 3).clamp(0.0, 1.0);
    final lowBalance = 1.0 - ((lowCount - 3).abs() / 3).clamp(0.0, 1.0);

    return baseScore * 0.72 +
        oddBalance * 0.08 +
        lowBalance * 0.08 -
        rangePenalty * 0.05 -
        clusterPenalty * 0.05 -
        regularPenalty * 0.02;
  }

  double _rangePenalty(List<int> numbers) {
    final rangeCounts = <int, int>{};
    for (final number in numbers) {
      final range = (number - 1) ~/ 10;
      rangeCounts[range] = (rangeCounts[range] ?? 0) + 1;
    }
    final maxInRange = rangeCounts.values.fold<int>(0, max);
    return maxInRange <= 2 ? 0.0 : (maxInRange - 2) / 4;
  }

  double _clusterPenalty(List<int> numbers) {
    final sorted = List<int>.from(numbers)..sort();
    var penalty = 0.0;
    for (var i = 0; i <= sorted.length - 3; i++) {
      if (sorted[i + 2] - sorted[i] <= 4) penalty += 0.5;
    }
    return penalty.clamp(0.0, 1.0).toDouble();
  }

  double _regularGapPenalty(List<int> numbers) {
    final sorted = List<int>.from(numbers)..sort();
    final gaps = <int>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      gaps.add(sorted[i + 1] - sorted[i]);
    }
    if (gaps.length < 5) return 0.0;
    final average = gaps.fold<int>(0, (sum, gap) => sum + gap) / gaps.length;
    final maxDeviation = gaps
        .map((gap) => (gap - average).abs())
        .fold<double>(0.0, max);
    return maxDeviation <= 1.2 ? 0.6 : 0.0;
  }

  GeneratedTipPayload fromNumbers(
    List<int> numbers, {
    int? recommendedSuperNumber,
    bool fallbackToRandomSuperNumber = true,
  }) {
    final normalizedSuperNumber = _normalizeSuperNumber(recommendedSuperNumber);
    return GeneratedTipPayload(
      numbers: _normalizeNumbers(numbers),
      superNumber: normalizedSuperNumber ??
          (fallbackToRandomSuperNumber ? generateRandomSuperNumber() : null),
    );
  }

  List<int> _normalizeNumbers(List<int> numbers) {
    return numbers.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
  }

  int? _normalizeSuperNumber(int? value) {
    if (value == null) return null;
    if (value < 0 || value > 9) return null;
    return value;
  }
}
