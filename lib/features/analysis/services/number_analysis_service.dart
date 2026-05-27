import 'dart:math' as math;

import '../../draws/domain/draw_result.dart';
import '../domain/analysis_signal.dart';
import '../domain/number_analysis_score.dart';

class NumberAnalysisService {
  const NumberAnalysisService();

  static const int _minNumber = 1;
  static const int _maxNumber = 49;
  static const int _numbersPerDraw = 6;

  List<NumberAnalysisScore> analyzeNumbers(List<DrawResult> draws) {
    final orderedDraws = List<DrawResult>.from(draws)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    if (orderedDraws.isEmpty) {
      return List.generate(
        _maxNumber,
        (index) => NumberAnalysisScore(
          number: index + 1,
          frequencyScore: 0,
          overdueScore: 0,
          intervalScore: 0,
          patternScore: 0,
          rangePatternScore: 0,
          hybridScore: 0,
          lastSeenDrawsAgo: null,
          hitCount: 0,
          averageInterval: null,
          currentInterval: null,
          intervalRatio: null,
        ),
      );
    }

    final totalDraws = orderedDraws.length;
    final expectedHits = math.max(1.0, totalDraws * (_numbersPerDraw / _maxNumber));
    final baselineInterval = _maxNumber / _numbersPerDraw;
    final hitsByNumber = <int, List<int>>{
      for (int number = _minNumber; number <= _maxNumber; number++) number: <int>[],
    };

    for (var drawIndex = 0; drawIndex < orderedDraws.length; drawIndex++) {
      final uniqueNumbers = orderedDraws[drawIndex]
          .numbers
          .where((number) => number >= _minNumber && number <= _maxNumber)
          .toSet();
      for (final number in uniqueNumbers) {
        hitsByNumber[number]!.add(drawIndex);
      }
    }

    final scores = <NumberAnalysisScore>[];
    for (var number = _minNumber; number <= _maxNumber; number++) {
      final hitIndexes = hitsByNumber[number] ?? const <int>[];
      final hitCount = hitIndexes.length;
      final lastSeen = hitIndexes.isEmpty ? null : hitIndexes.first;
      final averageInterval = _averageInterval(hitIndexes);
      final currentInterval = lastSeen == null ? null : lastSeen + 1;
      final expectedInterval = averageInterval ?? baselineInterval;
      final intervalRatio = currentInterval == null || expectedInterval <= 0
          ? null
          : currentInterval / expectedInterval;

      final frequencyScore = _frequencyScore(hitCount, expectedHits);
      final overdueScore = _overdueScore(
        currentInterval: currentInterval,
        averageInterval: averageInterval,
        baselineInterval: baselineInterval,
        totalDraws: totalDraws,
        hitCount: hitCount,
      );
      final intervalScore = _intervalScore(
        hitIndexes: hitIndexes,
        averageInterval: averageInterval,
        currentInterval: currentInterval,
        baselineInterval: baselineInterval,
      );
      final patternScore = _patternScore(number, orderedDraws);
      final rangePatternScore = _rangePatternScore(number, orderedDraws);
      final hybridScore = _hybridScore(
        frequencyScore: frequencyScore,
        overdueScore: overdueScore,
        intervalScore: intervalScore,
        patternScore: patternScore,
        rangePatternScore: rangePatternScore,
      );

      scores.add(
        NumberAnalysisScore(
          number: number,
          frequencyScore: frequencyScore,
          overdueScore: overdueScore,
          intervalScore: intervalScore,
          patternScore: patternScore,
          rangePatternScore: rangePatternScore,
          hybridScore: hybridScore,
          lastSeenDrawsAgo: lastSeen,
          hitCount: hitCount,
          averageInterval: averageInterval,
          currentInterval: currentInterval,
          intervalRatio: intervalRatio,
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
    if (signal == AnalysisSignal.hybrid && limit >= 6) {
      return _diversified(scores, limit: limit);
    }
    return scores.take(limit).toList();
  }

  double _frequencyScore(int hitCount, double expectedHits) {
    if (hitCount <= 0) return 0.0;
    final ratio = hitCount / expectedHits;
    return (ratio / 1.8).clamp(0.0, 1.0).toDouble();
  }

  double _overdueScore({
    required int? currentInterval,
    required double? averageInterval,
    required double baselineInterval,
    required int totalDraws,
    required int hitCount,
  }) {
    if (currentInterval == null) {
      // Zahlen ohne Treffer im Fenster sind auffällig, aber nicht automatisch Top-Kandidaten.
      return totalDraws >= baselineInterval ? 0.62 : 0.35;
    }
    final expectedInterval = averageInterval ?? baselineInterval;
    final ratio = currentInterval / expectedInterval;
    if (ratio <= 0.35) return 0.05;
    if (ratio <= 1.0) return (ratio * 0.55).clamp(0.0, 0.55).toDouble();
    return (0.55 + ((ratio - 1) / 1.8) * 0.45).clamp(0.0, 1.0).toDouble();
  }

  double _intervalScore({
    required List<int> hitIndexes,
    required double? averageInterval,
    required int? currentInterval,
    required double baselineInterval,
  }) {
    if (currentInterval == null) return 0.35;
    final expectedInterval = averageInterval ?? baselineInterval;
    if (expectedInterval <= 0) return 0.0;

    final ratio = currentInterval / expectedInterval;
    // Intervall-Signal ist am stärksten, wenn der aktuelle Abstand ungefähr
    // dem typischen Abstand entspricht. Stark überzogene Rückstände werden
    // separat über overdueScore bewertet und hier bewusst nicht doppelt belohnt.
    final distanceFromCycle = (ratio - 1.0).abs();
    final cycleFit = (1.0 - (distanceFromCycle / 1.35)).clamp(0.0, 1.0).toDouble();

    if (hitIndexes.length <= 1) {
      return (cycleFit * 0.65).clamp(0.0, 0.65).toDouble();
    }

    final consistency = _intervalConsistency(hitIndexes);
    return (cycleFit * 0.72 + consistency * 0.28).clamp(0.0, 1.0).toDouble();
  }

  double _patternScore(int number, List<DrawResult> draws) {
    if (draws.length < 3) return 0.0;

    var recentHits = 0;
    for (final draw in draws.take(math.min(6, draws.length))) {
      if (draw.numbers.contains(number)) recentHits++;
    }

    var neighborHits = 0;
    for (final draw in draws.take(math.min(12, draws.length))) {
      if (draw.numbers.contains(number - 1) || draw.numbers.contains(number + 1)) {
        neighborHits++;
      }
    }

    var sameDecadeHits = 0;
    final decadeStart = ((number - 1) ~/ 10) * 10 + 1;
    final decadeEnd = math.min(decadeStart + 9, _maxNumber);
    for (final draw in draws.take(math.min(12, draws.length))) {
      final countInDecade = draw.numbers
          .where((value) => value >= decadeStart && value <= decadeEnd)
          .length;
      if (countInDecade >= 2) sameDecadeHits++;
    }

    final recentScore = (recentHits / math.min(6, draws.length)).clamp(0.0, 1.0).toDouble();
    final neighborScore = (neighborHits / math.min(12, draws.length)).clamp(0.0, 1.0).toDouble();
    final decadeScore = (sameDecadeHits / math.min(12, draws.length)).clamp(0.0, 1.0).toDouble();
    return (recentScore * 0.40 + neighborScore * 0.35 + decadeScore * 0.25)
        .clamp(0.0, 1.0)
        .toDouble();
  }


  double _rangePatternScore(int number, List<DrawResult> draws) {
    if (draws.length < 6) return 0.45;

    // v38: Bereichsmuster 1–10 vs. 11–49.
    // Die Zahl 10 wird bewusst zur kleinen Gruppe gezählt, damit keine Zahl
    // aus der Bereichsanalyse herausfällt. Das Modell gleicht historische
    // Bereichsmuster nur weich aus und macht daraus keine harte Vorhersage.
    final isSmallNumber = number <= 10;
    final recentWindow = math.min(10, draws.length);
    final baselineWindow = math.min(52, draws.length);

    final recentSmallAverage = _averageSmallNumberCount(
      draws.take(recentWindow),
    );
    final baselineSmallAverage = _averageSmallNumberCount(
      draws.take(baselineWindow),
    );

    // Erwartungswert bei 6 aus 49 für Zahlen 1–10: ungefähr 1,22.
    final naturalSmallAverage = _numbersPerDraw * (10 / _maxNumber);
    final expectedSmallAverage = baselineSmallAverage > 0
        ? (baselineSmallAverage * 0.70 + naturalSmallAverage * 0.30)
        : naturalSmallAverage;

    final diff = expectedSmallAverage - recentSmallAverage;

    if (isSmallNumber) {
      // Kleine Zahlen bekommen ein weiches Plus, wenn sie im jüngeren Fenster
      // unterrepräsentiert waren. Bei Übergewicht wird der Score gedämpft.
      return (0.50 + diff * 0.20).clamp(0.0, 1.0).toDouble();
    }

    // Große Zahlen sind der Gegenpol. Wenn kleine Zahlen zuletzt deutlich
    // überrepräsentiert waren, bekommen größere Zahlen ein weiches Plus.
    return (0.50 - diff * 0.07).clamp(0.0, 1.0).toDouble();
  }

  double _averageSmallNumberCount(Iterable<DrawResult> draws) {
    final drawList = draws.toList();
    if (drawList.isEmpty) return 0.0;
    final total = drawList
        .map(
          (draw) => draw.numbers
              .where((number) => number >= _minNumber && number <= 10)
              .toSet()
              .length,
        )
        .fold<int>(0, (sum, value) => sum + value);
    return total / drawList.length;
  }

  double _hybridScore({
    required double frequencyScore,
    required double overdueScore,
    required double intervalScore,
    required double patternScore,
    required double rangePatternScore,
  }) {
    // v35: Das Hybrid-Signal soll ausgewogener sein.
    // Häufigkeit und Rückstand bleiben wichtig, werden aber nicht so stark
    // belohnt, dass ein einzelnes Extrem-Signal den kompletten Tipp dominiert.
    final rawScore =
        frequencyScore * 0.22 +
        overdueScore * 0.18 +
        intervalScore * 0.32 +
        patternScore * 0.18 +
        rangePatternScore * 0.10;

    final strongestSignal = [
      frequencyScore,
      overdueScore,
      intervalScore,
      patternScore,
      rangePatternScore,
    ].reduce(math.max);
    final weakestSignal = [
      frequencyScore,
      overdueScore,
      intervalScore,
      patternScore,
      rangePatternScore,
    ].reduce(math.min);
    final spread = strongestSignal - weakestSignal;

    // Kleine Stabilitätsbremse: extrem einseitige Zahlen bekommen keinen
    // massiven Bonus, ausgewogene Signale bleiben bevorzugt.
    final balancePenalty = spread > 0.72 ? 0.06 : 0.0;
    return (rawScore - balancePenalty).clamp(0.0, 1.0).toDouble();
  }

  double? _averageInterval(List<int> hitIndexes) {
    if (hitIndexes.length < 2) return null;
    final gaps = <int>[];
    for (var i = 0; i < hitIndexes.length - 1; i++) {
      gaps.add((hitIndexes[i + 1] - hitIndexes[i]).abs());
    }
    if (gaps.isEmpty) return null;
    return gaps.reduce((a, b) => a + b) / gaps.length;
  }

  double _intervalConsistency(List<int> hitIndexes) {
    if (hitIndexes.length < 3) return 0.45;
    final gaps = <int>[];
    for (var i = 0; i < hitIndexes.length - 1; i++) {
      gaps.add((hitIndexes[i + 1] - hitIndexes[i]).abs());
    }
    if (gaps.length < 2) return 0.45;
    final average = gaps.reduce((a, b) => a + b) / gaps.length;
    if (average <= 0) return 0.0;
    final variance = gaps
        .map((gap) => math.pow(gap - average, 2).toDouble())
        .reduce((a, b) => a + b) / gaps.length;
    final deviationRatio = math.sqrt(variance) / average;
    return (1.0 - deviationRatio).clamp(0.0, 1.0).toDouble();
  }

  List<NumberAnalysisScore> _diversified(
    List<NumberAnalysisScore> sortedScores, {
    required int limit,
  }) {
    final selected = <NumberAnalysisScore>[];
    final decadeCounts = <int, int>{};

    for (final score in sortedScores) {
      if (selected.length >= limit) break;
      if (!_canAddBalanced(score, selected, decadeCounts)) continue;
      selected.add(score);
      final decade = (score.number - 1) ~/ 10;
      decadeCounts[decade] = (decadeCounts[decade] ?? 0) + 1;
    }

    if (selected.length < limit) {
      for (final score in sortedScores) {
        if (selected.length >= limit) break;
        if (selected.any((item) => item.number == score.number)) continue;
        if (!_passesSoftBalance(score, selected)) continue;
        selected.add(score);
      }
    }

    if (selected.length < limit) {
      for (final score in sortedScores) {
        if (selected.length >= limit) break;
        if (selected.any((item) => item.number == score.number)) continue;
        selected.add(score);
      }
    }

    selected.sort((a, b) => a.number.compareTo(b.number));
    return selected.take(limit).toList();
  }

  bool _canAddBalanced(
    NumberAnalysisScore score,
    List<NumberAnalysisScore> selected,
    Map<int, int> decadeCounts,
  ) {
    final decade = (score.number - 1) ~/ 10;
    if ((decadeCounts[decade] ?? 0) >= 2) return false;

    final nearNeighbors = selected.where(
      (item) => (item.number - score.number).abs() <= 1,
    ).length;
    if (nearNeighbors >= 1) return false;

    return _passesSoftBalance(score, selected);
  }

  bool _passesSoftBalance(
    NumberAnalysisScore score,
    List<NumberAnalysisScore> selected,
  ) {
    final nextNumbers = [...selected.map((item) => item.number), score.number];
    final oddCount = nextNumbers.where((number) => number.isOdd).length;
    final lowCount = nextNumbers.where((number) => number <= 24).length;
    final freshCount = [
      ...selected.where((item) => item.lastSeenDrawsAgo == 0),
      if (score.lastSeenDrawsAgo == 0) score,
    ].length;

    // Bei sechs Zahlen soll keine Seite komplett dominieren. Bis zur vierten
    // Auswahl darf die Regel weich bleiben, danach wird stärker balanciert.
    if (nextNumbers.length >= 5) {
      if (oddCount > 4 || oddCount < nextNumbers.length - 4) return false;
      if (lowCount > 4 || lowCount < nextNumbers.length - 4) return false;
    }

    // Wiederholer aus der letzten Ziehung sind erlaubt, aber nicht als Cluster.
    if (freshCount > 2) return false;
    return true;
  }
}
