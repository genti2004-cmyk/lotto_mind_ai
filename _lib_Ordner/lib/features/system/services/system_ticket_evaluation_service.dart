import 'dart:math';

import 'package:lotto_mind_ai/features/draws/domain/draw_result.dart';
import 'package:lotto_mind_ai/features/winnings/domain/lotto_win_value_model.dart';
import 'package:lotto_mind_ai/features/system/services/vew_system_service.dart';

class SystemTicketEvaluationService {
  const SystemTicketEvaluationService();

  static const int fullMaxNumbers = 10;
  static const int vewMaxNumbers = 10;

  static const VewSystemService _vewService = VewSystemService();

  List<List<int>> buildRows({
    required String type,
    required List<int> numbers,
  }) {
    final normalized = _normalize(numbers);
    if (type == 'normal') {
      return normalized.length == 6 ? [normalized] : const [];
    }
    if (type == 'full') {
      if (normalized.length < 6 || normalized.length > fullMaxNumbers) return const [];
      return _combinations(normalized, 6);
    }
    if (type == 'vew') {
      if (normalized.length < 6 || normalized.length > vewMaxNumbers) return const [];
      return _vewService.buildRows(normalized);
    }
    return const [];
  }

  SystemTicketEvaluation evaluate({
    required List<List<int>> rows,
    required DrawResult draw,
    required int superNumber,
    required String spiel77,
    required String super6,
  }) {
    final drawNumbers = draw.numbers.toSet();
    final drawSuper = draw.superNumber;
    final classCounts = <String, int>{};
    var bestHits = 0;
    var winningRows = 0;

    for (final row in rows) {
      final hits = row.where(drawNumbers.contains).length;
      bestHits = max(bestHits, hits);
      final superHit = drawSuper != null && superNumber == drawSuper;
      final label = _prizeClass(hits, superHit);
      if (label != null) {
        winningRows++;
        classCounts[label] = (classCounts[label] ?? 0) + 1;
      }
    }

    final spiel77Matches = _matchingTrailingDigits(spiel77, draw.spiel77 ?? '', expectedLength: 7);
    final super6Matches = _matchingTrailingDigits(super6, draw.super6 ?? '', expectedLength: 6);

    final lottoEstimatedPrizeEuro = classCounts.entries.fold<double>(
      0,
          (sum, entry) => sum + _estimatedPrizeForClassLabel(entry.key) * entry.value,
    );
    final spiel77EstimatedPrizeEuro = LottoWinValueModel.spiel77PrizeEuro(spiel77Matches);
    final super6EstimatedPrizeEuro = LottoWinValueModel.super6PrizeEuro(super6Matches);
    final totalEstimatedPrizeEuro = lottoEstimatedPrizeEuro + spiel77EstimatedPrizeEuro + super6EstimatedPrizeEuro;

    return SystemTicketEvaluation(
      rowsChecked: rows.length,
      winningRows: winningRows,
      bestHits: bestHits,
      classCounts: classCounts,
      spiel77Matches: spiel77Matches,
      super6Matches: super6Matches,
      spiel77Label: _optionalLabel('Spiel 77', spiel77Matches, 7, hasDrawValue: (draw.spiel77 ?? '').isNotEmpty),
      super6Label: _optionalLabel('Super 6', super6Matches, 6, hasDrawValue: (draw.super6 ?? '').isNotEmpty),
      lottoEstimatedPrizeEuro: lottoEstimatedPrizeEuro,
      spiel77EstimatedPrizeEuro: spiel77EstimatedPrizeEuro,
      super6EstimatedPrizeEuro: super6EstimatedPrizeEuro,
      totalEstimatedPrizeEuro: totalEstimatedPrizeEuro,
      estimatedStakeEuro: rows.length * LottoWinValueModel.stakePerLottoRow +
          (spiel77.isNotEmpty ? LottoWinValueModel.spiel77Stake : 0) +
          (super6.isNotEmpty ? LottoWinValueModel.super6Stake : 0),
    );
  }

  String? _prizeClass(int hits, bool superHit) {
    if (hits == 6 && superHit) return 'GK 1: 6 + SZ';
    if (hits == 6) return 'GK 2: 6 Richtige';
    if (hits == 5 && superHit) return 'GK 3: 5 + SZ';
    if (hits == 5) return 'GK 4: 5 Richtige';
    if (hits == 4 && superHit) return 'GK 5: 4 + SZ';
    if (hits == 4) return 'GK 6: 4 Richtige';
    if (hits == 3 && superHit) return 'GK 7: 3 + SZ';
    if (hits == 3) return 'GK 8: 3 Richtige';
    if (hits == 2 && superHit) return 'GK 9: 2 + SZ';
    return null;
  }


  double _estimatedPrizeForClassLabel(String label) {
    if (label.startsWith('GK 1')) return LottoWinValueModel.lottoPrizeEuro(1);
    if (label.startsWith('GK 2')) return LottoWinValueModel.lottoPrizeEuro(2);
    if (label.startsWith('GK 3')) return LottoWinValueModel.lottoPrizeEuro(3);
    if (label.startsWith('GK 4')) return LottoWinValueModel.lottoPrizeEuro(4);
    if (label.startsWith('GK 5')) return LottoWinValueModel.lottoPrizeEuro(5);
    if (label.startsWith('GK 6')) return LottoWinValueModel.lottoPrizeEuro(6);
    if (label.startsWith('GK 7')) return LottoWinValueModel.lottoPrizeEuro(7);
    if (label.startsWith('GK 8')) return LottoWinValueModel.lottoPrizeEuro(8);
    if (label.startsWith('GK 9')) return LottoWinValueModel.lottoPrizeEuro(9);
    return 0;
  }

  String _optionalLabel(String name, int matches, int max, {required bool hasDrawValue}) {
    if (!hasDrawValue) return '$name: keine Ergebnisnummer in der Ziehung';
    if (matches <= 0) return '$name: kein Treffer';
    if (matches >= max) return '$name: alle $max Endziffern richtig';
    return '$name: $matches Endziffer${matches == 1 ? '' : 'n'} richtig';
  }

  int _matchingTrailingDigits(String selected, String drawn, {required int expectedLength}) {
    final a = _digitsOnly(selected);
    final b = _digitsOnly(drawn);
    if (a.isEmpty || b.isEmpty) return 0;
    final left = a.padLeft(expectedLength, '0');
    final right = b.padLeft(expectedLength, '0');

    var matches = 0;
    for (var i = 1; i <= expectedLength; i++) {
      if (left[left.length - i] == right[right.length - i]) {
        matches++;
      } else {
        break;
      }
    }
    return matches;
  }

  List<int> _normalize(List<int> numbers) {
    return numbers.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
  }

  List<List<int>> _combinations(List<int> numbers, int k) {
    final result = <List<int>>[];

    void build(int start, List<int> current) {
      if (current.length == k) {
        result.add(List<int>.from(current)..sort());
        return;
      }
      final remainingNeeded = k - current.length;
      for (var i = start; i <= numbers.length - remainingNeeded; i++) {
        current.add(numbers[i]);
        build(i + 1, current);
        current.removeLast();
      }
    }

    build(0, <int>[]);
    return result;
  }

  List<List<int>> _buildVewRows(List<int> numbers) {
    final allRows = _combinations(numbers, 6);
    final target = _vewTargetRows(numbers.length);
    if (allRows.length <= target) return allRows;

    final selected = <List<int>>[];
    final coverage = <int, int>{for (final n in numbers) n: 0};

    while (selected.length < target) {
      _ScoredRow? best;
      for (final row in allRows) {
        if (selected.any((existing) => existing.join('-') == row.join('-'))) continue;
        final score = _scoreVewCandidate(row, coverage, numbers);
        if (best == null || score > best.score) {
          best = _ScoredRow(row: row, score: score);
        }
      }
      if (best == null) break;
      selected.add(best.row);
      for (final n in best.row) {
        coverage[n] = (coverage[n] ?? 0) + 1;
      }
    }

    return selected..sort((a, b) => a.join('-').compareTo(b.join('-')));
  }

  int _vewTargetRows(int selectedCount) {
    switch (selectedCount) {
      case 6:
        return 1;
      case 7:
        return 3;
      case 8:
        return 4;
      case 9:
        return 5;
      case 10:
        return 6;
      case 11:
        return 8;
      case 12:
        return 10;
      default:
        return max(1, selectedCount - 4);
    }
  }

  double _scoreVewCandidate(List<int> row, Map<int, int> coverage, List<int> pool) {
    final newCoverage = row.where((n) => coverage[n] == 0).length;
    final lowCoverageBonus = row.fold<double>(0, (sum, n) => sum + (6 - min(6, coverage[n] ?? 0)));
    final sum = row.fold<int>(0, (a, b) => a + b);
    final odd = row.where((n) => n.isOdd).length;
    final low = row.where((n) => n <= 24).length;
    final spread = row.last - row.first;

    var score = newCoverage * 100.0 + lowCoverageBonus * 8.0;
    if (odd >= 2 && odd <= 4) score += 5;
    if (low >= 2 && low <= 4) score += 5;
    if (spread >= 18) score += 3;
    if (sum >= 90 && sum <= 180) score += 4;
    score -= row.map((n) => (25 - n).abs()).fold<int>(0, (a, b) => a + b) * 0.03;
    score += pool.length * 0.01;
    return score;
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
}

class SystemTicketEvaluation {
  const SystemTicketEvaluation({
    required this.rowsChecked,
    required this.winningRows,
    required this.bestHits,
    required this.classCounts,
    required this.spiel77Matches,
    required this.super6Matches,
    required this.spiel77Label,
    required this.super6Label,
    required this.lottoEstimatedPrizeEuro,
    required this.spiel77EstimatedPrizeEuro,
    required this.super6EstimatedPrizeEuro,
    required this.totalEstimatedPrizeEuro,
    required this.estimatedStakeEuro,
  });

  final int rowsChecked;
  final int winningRows;
  final int bestHits;
  final Map<String, int> classCounts;
  final int spiel77Matches;
  final int super6Matches;
  final String spiel77Label;
  final String super6Label;
  final double lottoEstimatedPrizeEuro;
  final double spiel77EstimatedPrizeEuro;
  final double super6EstimatedPrizeEuro;
  final double totalEstimatedPrizeEuro;
  final double estimatedStakeEuro;

  double get estimatedNetEuro => totalEstimatedPrizeEuro - estimatedStakeEuro;
  double get roiPercent => LottoWinValueModel.roiPercent(
    prize: totalEstimatedPrizeEuro,
    stake: estimatedStakeEuro,
  );

  String get totalEstimatedPrizeLabel => LottoWinValueModel.formatEuro(totalEstimatedPrizeEuro);
  String get estimatedStakeLabel => LottoWinValueModel.formatEuro(estimatedStakeEuro);
  String get estimatedNetLabel => LottoWinValueModel.formatSignedEuro(estimatedNetEuro);
  String get roiLabel => LottoWinValueModel.roiLabel(
    prize: totalEstimatedPrizeEuro,
    stake: estimatedStakeEuro,
  );
  String get performanceLabel => LottoWinValueModel.performanceLabel(
    prize: totalEstimatedPrizeEuro,
    stake: estimatedStakeEuro,
  );
  String get efficiencyLabel => LottoWinValueModel.efficiencyLabel(
    rows: rowsChecked,
    prize: totalEstimatedPrizeEuro,
    stake: estimatedStakeEuro,
  );

  bool get hasAnyWin => winningRows > 0 || totalEstimatedPrizeEuro > 0;
}

class _ScoredRow {
  const _ScoredRow({required this.row, required this.score});
  final List<int> row;
  final double score;
}
