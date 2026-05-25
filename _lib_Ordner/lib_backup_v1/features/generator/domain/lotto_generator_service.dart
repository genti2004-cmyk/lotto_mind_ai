import 'dart:math';

import '../../../core/constants/lotto_constants.dart';
import '../../draws/domain/draw_result.dart';
import 'advanced_number_analysis.dart';
import 'analysis_rule_set.dart';
import 'package:lotto_mind_ai/features/generator/services/pro_ai_generator_service.dart';

class LottoGeneratorService {
  final Random _random = Random();
  final AdvancedNumberAnalysisService _advancedAnalysisService =
  const AdvancedNumberAnalysisService();
  final ProAiGeneratorService _proAiGeneratorService = ProAiGeneratorService();

  String? _lastGeneratedAnalysisKey;

  List<int> generateRandomTip() {
    final values = <int>{};

    while (values.length < LottoConstants.numbersPerTip) {
      values.add(
        LottoConstants.minNumber +
            _random.nextInt(
              LottoConstants.maxNumber - LottoConstants.minNumber + 1,
            ),
      );
    }

    final result = values.toList()..sort();
    return result;
  }

  List<int> generateAnalysisTip(
      AnalysisRuleSet rules, {
        List<DrawResult> historicalDraws = const [],
        int maxAttempts = 30000,
      }) {
    final filteredHistory = _filterHistoricalDraws(
      historicalDraws,
      rules.analysisMode,
    );

    if (filteredHistory.isEmpty) {
      return generateRandomTip();
    }

    final advanced = _advancedAnalysisService.buildAdvancedAnalysis(
      filteredHistory,
    );
    final ranking = _buildCandidateRanking(
      filteredHistory,
      rules,
      advancedAnalysis: advanced,
    );

    final exactCandidates = <_TipCandidate>[];
    final approximateCandidates = <_TipCandidate>[];

    void registerCandidate(List<int> rawTip) {
      final tip = List<int>.from(rawTip.toSet().where((n) => n >= 1 && n <= 49))
        ..sort();

      if (tip.length != LottoConstants.numbersPerTip) return;

      final penalty = _penaltyScore(tip, rules, filteredHistory);
      final candidate = _TipCandidate(tip, penalty);

      if (_matchesRules(tip, rules, filteredHistory)) {
        exactCandidates.add(candidate);
      } else {
        approximateCandidates.add(candidate);
      }
    }

    final proAiTip = _proAiGeneratorService.generate(
      draws: filteredHistory.map((d) => d.numbers).toList(),
      count: LottoConstants.numbersPerTip,
    );
    registerCandidate(_normalizeTip(proAiTip, ranking));

    registerCandidate(
      _buildGuidedTip(
        ranking,
        rules,
        filteredHistory,
        strategy: _inferProfile(rules),
      ),
    );

    final strategyOrder = <_AnalysisProfile>{
      _inferProfile(rules),
      _AnalysisProfile.balanced,
      _AnalysisProfile.defensive,
      _AnalysisProfile.aggressive,
    }.toList();

    for (final strategy in strategyOrder) {
      for (int i = 0; i < maxAttempts; i++) {
        final tip = _buildGuidedTip(
          ranking,
          rules,
          filteredHistory,
          strategy: strategy,
        );
        registerCandidate(tip);
        if (exactCandidates.isNotEmpty && exactCandidates.length >= 24) {
          break;
        }
      }
      if (exactCandidates.isNotEmpty && exactCandidates.length >= 24) {
        break;
      }
    }

    if (exactCandidates.isNotEmpty) {
      exactCandidates.sort((a, b) => a.penalty.compareTo(b.penalty));
      final result = _pickVariedCandidate(
        exactCandidates,
        takeCount: 10,
      );
      _lastGeneratedAnalysisKey = result.join('-');
      return result;
    }

    if (approximateCandidates.isNotEmpty) {
      approximateCandidates.sort((a, b) => a.penalty.compareTo(b.penalty));
      final result = _pickVariedCandidate(
        approximateCandidates,
        takeCount: 12,
      );
      _lastGeneratedAnalysisKey = result.join('-');
      return result;
    }

    return generateRandomTip();
  }

  List<int> _pickVariedCandidate(
      List<_TipCandidate> candidates, {
        required int takeCount,
      }) {
    final pool = candidates.take(takeCount).toList();

    if (pool.isEmpty) {
      return generateRandomTip();
    }

    if (_lastGeneratedAnalysisKey != null && pool.length > 1) {
      pool.removeWhere((c) => c.tip.join('-') == _lastGeneratedAnalysisKey);
    }

    final effectivePool = pool.isEmpty ? candidates.take(takeCount).toList() : pool;
    return effectivePool[_random.nextInt(effectivePool.length)].tip;
  }

  List<int> generateSystemBaseNumbers(
      int systemSize, {
        required AnalysisRuleSet rules,
        List<DrawResult> historicalDraws = const [],
        List<int> manualNumbers = const [],
        int maxAttempts = 400,
      }) {
    if (systemSize < 7 || systemSize > 16) {
      throw Exception('Systemgröße muss zwischen 7 und 16 liegen.');
    }

    final selected = manualNumbers
        .where((n) => n >= 1 && n <= 49)
        .where((n) => !rules.excludedNumbers.contains(n))
        .toSet()
        .toList()
      ..sort();

    if (selected.length > systemSize) {
      throw Exception(
        'Zu viele manuell gewählte Zahlen für System $systemSize.',
      );
    }

    for (final number in rules.requiredNumbers) {
      if (number < 1 || number > 49) continue;
      if (rules.excludedNumbers.contains(number)) continue;
      if (!selected.contains(number)) {
        selected.add(number);
      }
    }

    if (selected.length > systemSize) {
      throw Exception(
        'Pflichtzahlen und manuelle Auswahl überschreiten System $systemSize.',
      );
    }

    final filteredHistory = _filterHistoricalDraws(
      historicalDraws,
      rules.analysisMode,
    );
    final advanced = _advancedAnalysisService.buildAdvancedAnalysis(
      filteredHistory,
    );
    final ranking = _buildCandidateRanking(
      filteredHistory,
      rules,
      advancedAnalysis: advanced,
    );

    for (final number in ranking) {
      if (selected.length >= systemSize) break;
      if (rules.excludedNumbers.contains(number)) continue;
      if (!selected.contains(number)) {
        selected.add(number);
      }
    }

    int attempts = 0;
    while (selected.length < systemSize && attempts < maxAttempts) {
      final n = 1 + _random.nextInt(49);
      if (!rules.excludedNumbers.contains(n) && !selected.contains(n)) {
        selected.add(n);
      }
      attempts++;
    }

    if (selected.length < systemSize) {
      throw Exception('Systemzahlen konnten nicht vollständig erstellt werden.');
    }

    selected.sort();
    return selected.take(systemSize).toList();
  }

  List<List<int>> buildSystemRows(List<int> baseNumbers) {
    final normalized = baseNumbers.toSet().toList()..sort();

    if (normalized.length < 6) {
      throw Exception('Für ein System werden mindestens 6 Basiszahlen benötigt.');
    }

    final result = <List<int>>[];
    final current = <int>[];

    void backtrack(int start) {
      if (current.length == 6) {
        result.add(List<int>.from(current));
        return;
      }

      for (int i = start; i < normalized.length; i++) {
        current.add(normalized[i]);
        backtrack(i + 1);
        current.removeLast();
      }
    }

    backtrack(0);
    return result;
  }

  List<List<int>> buildVewSystemRows(List<int> baseNumbers) {
    final normalized = baseNumbers.toSet().toList()..sort();

    if (normalized.length < 7) {
      throw Exception('VEW benötigt mindestens 7 Basiszahlen.');
    }

    final rows = <List<int>>[];
    final n = normalized.length;

    void addRow(List<int> row) {
      final sorted = row.toSet().toList()..sort();
      if (sorted.length != 6) return;

      final key = sorted.join('-');
      final exists = rows.any((r) => r.join('-') == key);
      if (!exists) {
        rows.add(sorted);
      }
    }

    if (n == 7) {
      for (int skip = 0; skip < n; skip++) {
        addRow([
          for (int i = 0; i < n; i++)
            if (i != skip) normalized[i],
        ]);
      }
      return rows;
    }

    if (n == 8) {
      for (int start = 0; start < n; start++) {
        addRow([
          normalized[start % n],
          normalized[(start + 1) % n],
          normalized[(start + 2) % n],
          normalized[(start + 3) % n],
          normalized[(start + 4) % n],
          normalized[(start + 5) % n],
        ]);
      }

      addRow([
        normalized[0],
        normalized[1],
        normalized[2],
        normalized[5],
        normalized[6],
        normalized[7],
      ]);

      addRow([
        normalized[0],
        normalized[2],
        normalized[3],
        normalized[4],
        normalized[6],
        normalized[7],
      ]);

      return rows;
    }

    for (int start = 0; start < n; start++) {
      addRow([
        normalized[start % n],
        normalized[(start + 1) % n],
        normalized[(start + 2) % n],
        normalized[(start + 3) % n],
        normalized[(start + 4) % n],
        normalized[(start + 5) % n],
      ]);
    }

    for (int start = 0; start < n; start += 2) {
      addRow([
        normalized[start % n],
        normalized[(start + 2) % n],
        normalized[(start + 4) % n],
        normalized[(start + 5) % n],
        normalized[(start + 7) % n],
        normalized[(start + 8) % n],
      ]);
    }

    final mid = n ~/ 2;
    addRow([
      normalized.first,
      normalized[(mid - 1).clamp(0, n - 1)],
      normalized[mid.clamp(0, n - 1)],
      normalized[(mid + 1).clamp(0, n - 1)],
      normalized[(n - 2).clamp(0, n - 1)],
      normalized.last,
    ]);

    return rows;
  }

  List<int> _buildGuidedTip(
      List<int> ranking,
      AnalysisRuleSet rules,
      List<DrawResult> filteredHistory, {
        required _AnalysisProfile strategy,
      }) {
    final hotSet = _hotNumbers(filteredHistory, rules.hotNumberWindow);
    final coldSet = _coldNumbers(filteredHistory, rules.coldNumberWindow);
    final latestDraw = filteredHistory.isEmpty
        ? <int>{}
        : filteredHistory.first.numbers.toSet();
    final last3 = filteredHistory.take(3).expand((d) => d.numbers).toSet();

    int hotTarget;
    int coldTarget;
    int reboundTarget;
    switch (strategy) {
      case _AnalysisProfile.defensive:
        hotTarget = 1;
        coldTarget = 0;
        reboundTarget = 1;
        break;
      case _AnalysisProfile.aggressive:
        hotTarget = min(3, rules.maxHotNumbersInTip);
        coldTarget = min(2, rules.maxColdNumbersInTip);
        reboundTarget = 2;
        break;
      case _AnalysisProfile.balanced:
        hotTarget = min(2, rules.maxHotNumbersInTip);
        coldTarget = min(1, rules.maxColdNumbersInTip);
        reboundTarget = 1;
        break;
    }

    final selected = <int>[];

    void addIfAllowed(int n) {
      if (selected.length >= LottoConstants.numbersPerTip) return;
      if (n < 1 || n > 49) return;
      if (selected.contains(n)) return;
      if (rules.excludedNumbers.contains(n)) return;
      selected.add(n);
    }

    for (final n in rules.requiredNumbers) {
      addIfAllowed(n);
    }

    final preferred = ranking.where((n) => rules.preferredNumbers.contains(n)).toList();
    for (final n in preferred) {
      addIfAllowed(n);
    }

    if (hotTarget > 0) {
      final hotPool = ranking.where((n) => hotSet.contains(n)).toList();
      _shuffleInPlace(hotPool);
      for (final n in hotPool) {
        if (selected.where((x) => hotSet.contains(x)).length >= hotTarget) {
          break;
        }
        addIfAllowed(n);
      }
    }

    if (coldTarget > 0) {
      final coldPool = ranking.where((n) => coldSet.contains(n)).toList();
      _shuffleInPlace(coldPool);
      for (final n in coldPool) {
        if (selected.where((x) => coldSet.contains(x)).length >= coldTarget) {
          break;
        }
        addIfAllowed(n);
      }
    }

    if (reboundTarget > 0) {
      final reboundPool = ranking
          .where((n) => !latestDraw.contains(n) && last3.contains(n))
          .toList();
      _shuffleInPlace(reboundPool);
      for (final n in reboundPool) {
        if (selected.length >= LottoConstants.numbersPerTip) break;
        addIfAllowed(n);
      }
    }

    final remaining = List<int>.from(ranking);
    _shuffleTopBand(remaining, 14);
    for (final n in remaining) {
      if (selected.length >= LottoConstants.numbersPerTip) break;
      addIfAllowed(n);
    }

    while (selected.length < LottoConstants.numbersPerTip) {
      addIfAllowed(1 + _random.nextInt(49));
    }

    return _normalizeTip(selected, ranking);
  }

  List<int> _normalizeTip(List<int> input, List<int> ranking) {
    final result = input.toSet().toList()..sort();

    while (result.length > LottoConstants.numbersPerTip) {
      result.removeLast();
    }

    for (final number in ranking) {
      if (result.length >= LottoConstants.numbersPerTip) break;
      if (!result.contains(number)) {
        result.add(number);
      }
    }

    while (result.length < LottoConstants.numbersPerTip) {
      final n = 1 + _random.nextInt(49);
      if (!result.contains(n)) {
        result.add(n);
      }
    }

    result.sort();
    return result;
  }

  double _penaltyScore(
      List<int> tip,
      AnalysisRuleSet rules,
      List<DrawResult> filteredHistory,
      ) {
    double penalty = 0.0;

    final evenCount = tip.where((n) => n.isEven).length;
    final lowCount = tip.where((n) => n <= 24).length;
    final sum = tip.fold<int>(0, (a, b) => a + b);

    penalty += _rangePenalty(evenCount, rules.minEven, rules.maxEven) * 8.0;
    penalty += _rangePenalty(lowCount, rules.minLowNumbers, rules.maxLowNumbers) * 8.0;
    penalty += _rangePenalty(sum, rules.minSum, rules.maxSum) * 0.35;

    final endDigits = tip.map((n) => n % 10).toList();
    final endDigitCounts = <int, int>{};
    for (final digit in endDigits) {
      endDigitCounts[digit] = (endDigitCounts[digit] ?? 0) + 1;
    }

    if (rules.allowedEndDigits.isNotEmpty) {
      penalty += tip.where((n) => !rules.allowedEndDigits.contains(n % 10)).length * 6.0;
    }
    penalty += tip.where((n) => rules.blockedEndDigits.contains(n % 10)).length * 8.0;
    penalty += endDigitCounts.values
        .where((c) => c > rules.maxSameEndDigitCount)
        .fold<int>(0, (a, b) => a + (b - rules.maxSameEndDigitCount)) *
        5.0;

    if (endDigitCounts.keys.length < rules.minDistinctEndDigits) {
      penalty += (rules.minDistinctEndDigits - endDigitCounts.keys.length) * 6.0;
    }

    final consecutiveRun = _maxConsecutiveRun(tip);
    if (consecutiveRun > rules.maxConsecutiveNumbers) {
      penalty += (consecutiveRun - rules.maxConsecutiveNumbers) * 6.0;
    }

    final spread = tip.last - tip.first;
    if (spread < rules.minSpread) {
      penalty += (rules.minSpread - spread) * 1.5;
    }

    penalty += _groupPenalty(tip, 1, 9, rules.minGroup1to9, rules.maxGroup1to9);
    penalty += _groupPenalty(tip, 10, 19, rules.minGroup10to19, rules.maxGroup10to19);
    penalty += _groupPenalty(tip, 20, 29, rules.minGroup20to29, rules.maxGroup20to29);
    penalty += _groupPenalty(tip, 30, 39, rules.minGroup30to39, rules.maxGroup30to39);
    penalty += _groupPenalty(tip, 40, 49, rules.minGroup40to49, rules.maxGroup40to49);

    penalty += tip.where((n) => rules.excludedNumbers.contains(n)).length * 12.0;
    penalty += rules.requiredNumbers.where((n) => !tip.contains(n)).length * 10.0;
    if (rules.preferredNumbers.isNotEmpty &&
        tip.where((n) => rules.preferredNumbers.contains(n)).isEmpty) {
      penalty += 6.0;
    }

    if (filteredHistory.isNotEmpty) {
      final last1 = filteredHistory.take(1).expand((d) => d.numbers).toSet();
      final last3 = filteredHistory.take(3).expand((d) => d.numbers).toSet();
      final last5 = filteredHistory.take(5).expand((d) => d.numbers).toSet();

      penalty += _limitPenalty(
        tip.where(last1.contains).length,
        rules.maxRepeatFromLastDraw,
      ) *
          7.0;
      penalty += _limitPenalty(
        tip.where(last3.contains).length,
        rules.maxRepeatFromLast3Draws,
      ) *
          5.0;
      penalty += _limitPenalty(
        tip.where(last5.contains).length,
        rules.maxRepeatFromLast5Draws,
      ) *
          4.0;

      final hotSet = _hotNumbers(filteredHistory, rules.hotNumberWindow);
      final coldSet = _coldNumbers(filteredHistory, rules.coldNumberWindow);

      final hotCount = tip.where(hotSet.contains).length;
      final coldCount = tip.where(coldSet.contains).length;

      penalty += _limitPenalty(hotCount, rules.maxHotNumbersInTip) * 4.0;
      penalty += _limitPenalty(coldCount, rules.maxColdNumbersInTip) * 4.0;

      if (rules.preferHotNumbers && hotCount == 0) penalty += 5.0;
      if (rules.preferColdNumbers && coldCount == 0) penalty += 5.0;
      if (rules.avoidHotNumbers && hotCount > 0) penalty += hotCount * 4.0;
      if (rules.avoidColdNumbers && coldCount > 0) penalty += coldCount * 4.0;
    }

    return penalty;
  }

  bool _matchesRules(
      List<int> tip,
      AnalysisRuleSet rules,
      List<DrawResult> historicalDraws,
      ) {
    return _penaltyScore(tip, rules, historicalDraws) == 0.0;
  }

  List<int> _buildCandidateRanking(
      List<DrawResult> draws,
      AnalysisRuleSet rules, {
        List<NumberAnalysis> advancedAnalysis = const [],
      }) {
    final frequency = _buildFrequency(draws);
    final gaps = <int, int>{};
    for (int n = 1; n <= 49; n++) {
      gaps[n] = _drawGap(draws, n);
    }

    final advancedMap = <int, NumberAnalysis>{
      for (final item in advancedAnalysis) item.number: item,
    };

    final hotSet = _hotNumbers(draws, rules.hotNumberWindow);
    final coldSet = _coldNumbers(draws, rules.coldNumberWindow);
    final latestDraw = draws.isEmpty ? <int>{} : draws.first.numbers.toSet();
    final recentPool = draws.take(min(10, draws.length)).toList();
    final recentFreq = _buildFrequency(recentPool);

    final scored = <_NumberScore>[];
    for (int n = 1; n <= 49; n++) {
      double score = 0.0;
      final pref = rules.preferredNumbers.contains(n) ? 1.0 : 0.0;
      final req = rules.requiredNumbers.contains(n) ? 1.0 : 0.0;
      final freq = (frequency[n] ?? 0).toDouble();
      final recent = (recentFreq[n] ?? 0).toDouble();
      final gap = (gaps[n] ?? draws.length + 1).toDouble();
      final adv = advancedMap[n];

      score += req * 200.0;
      score += pref * 120.0;
      score += freq * 7.0;
      score += recent * 11.0;
      score += max(0, 12 - gap) * 0.9;

      if (adv != null) {
        score += adv.totalScore * 4.0;
        score += adv.trendScore * 2.5;
        score += adv.returnScore * 3.5;
        score += adv.pairScore * 0.4;
        score += adv.tripleScore * 0.35;
      }

      if (hotSet.contains(n)) score += 8.0;
      if (coldSet.contains(n)) score += rules.preferColdNumbers ? 6.0 : 1.0;
      if (latestDraw.contains(n)) score -= 5.0;
      if (rules.avoidHotNumbers && hotSet.contains(n)) score -= 12.0;
      if (rules.avoidColdNumbers && coldSet.contains(n)) score -= 12.0;

      if (rules.excludedNumbers.contains(n)) {
        score = -999999.0;
      }

      scored.add(_NumberScore(number: n, score: score));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.number.compareTo(b.number);
    });

    return scored.map((e) => e.number).toList();
  }

  List<DrawResult> _filterHistoricalDraws(
      List<DrawResult> draws,
      String analysisMode,
      ) {
    final sorted = List<DrawResult>.from(draws)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    switch (analysisMode) {
      case 'wednesday':
        return sorted.where((d) => d.drawDate.weekday == DateTime.wednesday).toList();
      case 'saturday':
        return sorted.where((d) => d.drawDate.weekday == DateTime.saturday).toList();
      default:
        return sorted;
    }
  }

  Set<int> _hotNumbers(List<DrawResult> draws, int window) {
    final freq = _buildFrequency(draws.take(window).toList());
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toSet();
  }

  Set<int> _coldNumbers(List<DrawResult> draws, int window) {
    final freq = _buildFrequency(draws.take(window).toList());
    final sorted = freq.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(10).map((e) => e.key).toSet();
  }

  Map<int, int> _buildFrequency(List<DrawResult> draws) {
    final map = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    for (final draw in draws) {
      for (final n in draw.numbers) {
        map[n] = (map[n] ?? 0) + 1;
      }
    }
    return map;
  }

  int _drawGap(List<DrawResult> draws, int number) {
    for (int i = 0; i < draws.length; i++) {
      if (draws[i].numbers.contains(number)) {
        return i;
      }
    }
    return draws.length + 1;
  }

  int _maxConsecutiveRun(List<int> values) {
    if (values.isEmpty) return 0;

    int maxRun = 1;
    int currentRun = 1;

    for (int i = 1; i < values.length; i++) {
      if (values[i] == values[i - 1] + 1) {
        currentRun++;
        if (currentRun > maxRun) maxRun = currentRun;
      } else {
        currentRun = 1;
      }
    }

    return maxRun;
  }

  double _rangePenalty(int value, int min, int max) {
    if (value < min) return (min - value).toDouble();
    if (value > max) return (value - max).toDouble();
    return 0.0;
  }

  double _limitPenalty(int value, int max) {
    if (value <= max) return 0.0;
    return (value - max).toDouble();
  }

  double _groupPenalty(List<int> tip, int start, int end, int min, int max) {
    final count = tip.where((n) => n >= start && n <= end).length;
    return _rangePenalty(count, min, max) * 2.0;
  }

  _AnalysisProfile _inferProfile(AnalysisRuleSet rules) {
    if (rules.avoidHotNumbers ||
        rules.maxConsecutiveNumbers <= 1 ||
        rules.maxRepeatFromLastDraw <= 1) {
      return _AnalysisProfile.defensive;
    }

    if (rules.preferHotNumbers ||
        rules.preferColdNumbers ||
        rules.maxConsecutiveNumbers >= 3 ||
        rules.maxHotNumbersInTip >= 5) {
      return _AnalysisProfile.aggressive;
    }

    return _AnalysisProfile.balanced;
  }

  void _shuffleInPlace(List<int> values) {
    for (int i = values.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = values[i];
      values[i] = values[j];
      values[j] = tmp;
    }
  }

  void _shuffleTopBand(List<int> values, int bandSize) {
    final upper = bandSize.clamp(0, values.length);
    final top = values.take(upper).toList();
    final rest = values.skip(upper).toList();
    _shuffleInPlace(top);
    values
      ..clear()
      ..addAll(top)
      ..addAll(rest);
  }

  // 🔥 JACKPOT MODE
  List<int> generateJackpotNumbers(List<DrawResult> draws) {
    if (draws.isEmpty) {
      return generateRandomTip();
    }

    final frequency = _buildFrequency(draws);
    final allNumbers = List<int>.generate(49, (i) => i + 1);

    allNumbers.sort((a, b) {
      final byFreq = (frequency[a] ?? 0).compareTo(frequency[b] ?? 0);
      if (byFreq != 0) return byFreq;
      return a.compareTo(b);
    });

    final rarePool = allNumbers.take(25).toList();
    final selected = <int>{};

    while (selected.length < 6) {
      selected.add(rarePool[_random.nextInt(rarePool.length)]);
    }

    return _forceJackpotSpread(selected.toList());
  }

  // 🔥 JACKPOT PRO
  List<int> generateJackpotProNumbers(
      List<DrawResult> draws, {
        required String profileLabel,
      }) {
    if (draws.length < 12) {
      return generateJackpotNumbers(draws);
    }

    final frequency = _buildFrequency(draws);

    final scored = <_NumberScore>[];
    for (int n = 1; n <= 49; n++) {
      final freq = (frequency[n] ?? 0).toDouble();
      final gap = _drawGap(draws, n).toDouble();

      final score = (gap * 2.2) - (freq * 4.2);
      scored.add(_NumberScore(number: n, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final pool = scored.take(22).map((e) => e.number).toList();

    final selected = <int>[];
    for (final n in pool) {
      if (selected.length >= 6) break;
      if (selected.any((x) => (x - n).abs() <= 1)) continue;
      selected.add(n);
    }

    while (selected.length < 6) {
      final n = pool[_random.nextInt(pool.length)];
      if (!selected.contains(n)) {
        selected.add(n);
      }
    }

    return _forceJackpotSpread(selected);
  }

  List<int> _forceJackpotSpread(List<int> input) {
    final tip = input.toSet().where((n) => n >= 1 && n <= 49).toList()..sort();

    while (tip.length < 6) {
      final n = 1 + _random.nextInt(49);
      if (!tip.contains(n)) {
        tip.add(n);
      }
    }

    int guard = 0;
    while (guard < 100) {
      guard++;
      final spread = tip.last - tip.first;
      final even = tip.where((n) => n.isEven).length;
      final low = tip.where((n) => n <= 24).length;
      final sum = tip.fold<int>(0, (a, b) => a + b);

      final okSpread = spread >= 24;
      final okEven = even >= 2 && even <= 4;
      final okLow = low >= 2 && low <= 4;
      final okSum = sum >= 85 && sum <= 205;

      if (okSpread && okEven && okLow && okSum) {
        break;
      }

      tip.removeAt(_random.nextInt(tip.length));
      final candidate = 1 + _random.nextInt(49);
      if (!tip.contains(candidate)) {
        tip.add(candidate);
      }
      tip.sort();
    }

    return tip.take(6).toList()..sort();
  }

}
enum _AnalysisProfile {
  defensive,
  balanced,
  aggressive,
}

class _TipCandidate {
  final List<int> tip;
  final double penalty;

  const _TipCandidate(this.tip, this.penalty);
}

class _NumberScore {
  final int number;
  final double score;

  const _NumberScore({
    required this.number,
    required this.score,
  });
}
