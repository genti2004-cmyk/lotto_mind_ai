import 'dart:math';

import 'package:lotto_mind_ai/features/draws/domain/draw_result.dart';

class SystemWinCalculationService {
  const SystemWinCalculationService();

  static const int fullSystemMaxNumbers = 10;
  static const int vewSystemMaxNumbers = 12;

  List<List<int>> buildNormalRows(List<int> numbers) {
    final normalized = _normalize(numbers);
    if (normalized.length != 6) return const [];
    return [normalized];
  }

  List<List<int>> buildFullSystemRows(List<int> numbers) {
    final normalized = _normalize(numbers);
    if (normalized.length < 6 || normalized.length > fullSystemMaxNumbers) {
      return const [];
    }
    return _combinations(normalized, 6);
  }

  List<List<int>> buildVewSystemRows(List<int> numbers) {
    final normalized = _normalize(numbers);
    if (normalized.length < 6 || normalized.length > vewSystemMaxNumbers) {
      return const [];
    }

    final allRows = _combinations(normalized, 6);
    final target = _vewTargetRows(normalized.length);
    if (allRows.length <= target) return allRows;

    final scored = allRows
        .map((row) => _ScoredRow(row: row, score: _scoreVewRow(row, normalized)))
        .toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.row.join('-').compareTo(b.row.join('-'));
      });

    final selected = <List<int>>[];
    final coverage = <int, int>{for (final n in normalized) n: 0};

    for (final candidate in scored) {
      if (selected.length >= target) break;

      final weakCoverageBonus = candidate.row.where((n) => coverage[n] == 0).length;
      if (selected.length < normalized.length ~/ 2 || weakCoverageBonus > 0) {
        selected.add(candidate.row);
        for (final n in candidate.row) {
          coverage[n] = (coverage[n] ?? 0) + 1;
        }
      }
    }

    for (final candidate in scored) {
      if (selected.length >= target) break;
      if (!selected.any((row) => _sameRow(row, candidate.row))) {
        selected.add(candidate.row);
      }
    }

    return selected..sort((a, b) => a.join('-').compareTo(b.join('-')));
  }

  SystemWinSummary evaluate({
    required List<List<int>> rows,
    required DrawResult draw,
    required int selectedSuperNumber,
    required String selectedSpiel77,
    required String selectedSuper6,
  }) {
    final drawNumbers = draw.numbers.toSet();
    final drawSuper = draw.superNumber;

    final rowResults = rows.map((row) {
      final hits = row.where(drawNumbers.contains).length;
      final superHit = drawSuper != null && selectedSuperNumber == drawSuper;
      final prizeClass = _lottoPrizeClass(hits, superHit);
      return RowWinResult(
        row: List<int>.from(row)..sort(),
        hits: hits,
        superHit: superHit,
        prizeClass: prizeClass,
      );
    }).toList();

    final counts = <LottoPrizeClass, int>{};
    for (final result in rowResults) {
      if (result.prizeClass == LottoPrizeClass.none) continue;
      counts[result.prizeClass] = (counts[result.prizeClass] ?? 0) + 1;
    }

    rowResults.sort((a, b) {
      final byClass = a.prizeClass.rank.compareTo(b.prizeClass.rank);
      if (byClass != 0) return byClass;
      final byHits = b.hits.compareTo(a.hits);
      if (byHits != 0) return byHits;
      return a.row.join('-').compareTo(b.row.join('-'));
    });

    final spiel77Matches = _matchingTrailingDigits(
      selectedSpiel77,
      draw.spiel77 ?? '',
      expectedLength: 7,
    );
    final super6Matches = _matchingTrailingDigits(
      selectedSuper6,
      draw.super6 ?? '',
      expectedLength: 6,
    );

    return SystemWinSummary(
      rowsChecked: rows.length,
      rowResults: rowResults,
      lottoPrizeCounts: counts,
      bestHits: rowResults.isEmpty ? 0 : rowResults.map((e) => e.hits).reduce(max),
      bestPrizeClass: rowResults.isEmpty ? LottoPrizeClass.none : rowResults.first.prizeClass,
      spiel77TrailingMatches: spiel77Matches,
      super6TrailingMatches: super6Matches,
      spiel77PrizeLabel: _spiel77PrizeLabel(spiel77Matches),
      super6PrizeLabel: _super6PrizeLabel(super6Matches),
    );
  }

  LottoPrizeClass _lottoPrizeClass(int hits, bool superHit) {
    if (hits == 6 && superHit) return LottoPrizeClass.class1;
    if (hits == 6) return LottoPrizeClass.class2;
    if (hits == 5 && superHit) return LottoPrizeClass.class3;
    if (hits == 5) return LottoPrizeClass.class4;
    if (hits == 4 && superHit) return LottoPrizeClass.class5;
    if (hits == 4) return LottoPrizeClass.class6;
    if (hits == 3 && superHit) return LottoPrizeClass.class7;
    if (hits == 3) return LottoPrizeClass.class8;
    if (hits == 2 && superHit) return LottoPrizeClass.class9;
    return LottoPrizeClass.none;
  }

  int _matchingTrailingDigits(String selected, String drawn, {required int expectedLength}) {
    final a = _digitsOnly(selected).padLeft(expectedLength, '0');
    final b = _digitsOnly(drawn).padLeft(expectedLength, '0');
    if (a.length < expectedLength || b.length < expectedLength) return 0;

    var matches = 0;
    for (var i = 1; i <= expectedLength; i++) {
      if (a[a.length - i] == b[b.length - i]) {
        matches++;
      } else {
        break;
      }
    }
    return matches;
  }

  String _spiel77PrizeLabel(int matches) {
    if (matches <= 0) return 'kein Gewinn';
    if (matches == 7) return 'Spiel 77 Hauptgewinnklasse';
    return '$matches Endziffer${matches == 1 ? '' : 'n'} richtig';
  }

  String _super6PrizeLabel(int matches) {
    if (matches <= 0) return 'kein Gewinn';
    if (matches == 6) return 'SUPER 6 Höchstgewinnklasse';
    return '$matches Endziffer${matches == 1 ? '' : 'n'} richtig';
  }

  List<int> _normalize(List<int> input) {
    final normalized = input.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
    return normalized;
  }

  List<List<int>> _combinations(List<int> numbers, int k) {
    final result = <List<int>>[];

    void build(int start, List<int> current) {
      if (current.length == k) {
        result.add(List<int>.from(current)..sort());
        return;
      }
      for (var i = start; i < numbers.length; i++) {
        current.add(numbers[i]);
        build(i + 1, current);
        current.removeLast();
      }
    }

    build(0, <int>[]);
    return result;
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

  double _scoreVewRow(List<int> row, List<int> pool) {
    final sum = row.fold<int>(0, (a, b) => a + b);
    final oddCount = row.where((n) => n.isOdd).length;
    final lowCount = row.where((n) => n <= 24).length;
    final spread = row.last - row.first;
    final centerBias = row.map((n) => (25 - n).abs()).fold<int>(0, (a, b) => a + b);

    var score = 0.0;
    if (oddCount >= 2 && oddCount <= 4) score += 3;
    if (lowCount >= 2 && lowCount <= 4) score += 3;
    if (spread >= 18) score += 2;
    if (sum >= 90 && sum <= 180) score += 3;
    score += max(0, 30 - centerBias) * 0.05;

    final poolMiddle = pool[pool.length ~/ 2];
    final rowAverage = row.reduce((a, b) => a + b) / row.length;
    score += 5.0 - (rowAverage - poolMiddle).abs() * 0.1;
    return score;
  }

  bool _sameRow(List<int> a, List<int> b) => a.length == b.length && a.join('-') == b.join('-');

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
}

class SystemWinSummary {
  const SystemWinSummary({
    required this.rowsChecked,
    required this.rowResults,
    required this.lottoPrizeCounts,
    required this.bestHits,
    required this.bestPrizeClass,
    required this.spiel77TrailingMatches,
    required this.super6TrailingMatches,
    required this.spiel77PrizeLabel,
    required this.super6PrizeLabel,
  });

  final int rowsChecked;
  final List<RowWinResult> rowResults;
  final Map<LottoPrizeClass, int> lottoPrizeCounts;
  final int bestHits;
  final LottoPrizeClass bestPrizeClass;
  final int spiel77TrailingMatches;
  final int super6TrailingMatches;
  final String spiel77PrizeLabel;
  final String super6PrizeLabel;

  int get winningRows => lottoPrizeCounts.values.fold(0, (a, b) => a + b);
  bool get hasAnyWin => winningRows > 0 || spiel77TrailingMatches > 0 || super6TrailingMatches > 0;
}

class RowWinResult {
  const RowWinResult({
    required this.row,
    required this.hits,
    required this.superHit,
    required this.prizeClass,
  });

  final List<int> row;
  final int hits;
  final bool superHit;
  final LottoPrizeClass prizeClass;
}

enum LottoPrizeClass {
  class1,
  class2,
  class3,
  class4,
  class5,
  class6,
  class7,
  class8,
  class9,
  none,
}

extension LottoPrizeClassX on LottoPrizeClass {
  int get rank {
    switch (this) {
      case LottoPrizeClass.class1:
        return 1;
      case LottoPrizeClass.class2:
        return 2;
      case LottoPrizeClass.class3:
        return 3;
      case LottoPrizeClass.class4:
        return 4;
      case LottoPrizeClass.class5:
        return 5;
      case LottoPrizeClass.class6:
        return 6;
      case LottoPrizeClass.class7:
        return 7;
      case LottoPrizeClass.class8:
        return 8;
      case LottoPrizeClass.class9:
        return 9;
      case LottoPrizeClass.none:
        return 99;
    }
  }

  String get label {
    switch (this) {
      case LottoPrizeClass.class1:
        return 'GK 1: 6 + SZ';
      case LottoPrizeClass.class2:
        return 'GK 2: 6 Richtige';
      case LottoPrizeClass.class3:
        return 'GK 3: 5 + SZ';
      case LottoPrizeClass.class4:
        return 'GK 4: 5 Richtige';
      case LottoPrizeClass.class5:
        return 'GK 5: 4 + SZ';
      case LottoPrizeClass.class6:
        return 'GK 6: 4 Richtige';
      case LottoPrizeClass.class7:
        return 'GK 7: 3 + SZ';
      case LottoPrizeClass.class8:
        return 'GK 8: 3 Richtige';
      case LottoPrizeClass.class9:
        return 'GK 9: 2 + SZ';
      case LottoPrizeClass.none:
        return 'kein Gewinn';
    }
  }
}

class _ScoredRow {
  const _ScoredRow({required this.row, required this.score});
  final List<int> row;
  final double score;
}
