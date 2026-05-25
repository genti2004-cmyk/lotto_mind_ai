class VewSystemResult {
  final List<int> bankNumbers;
  final List<int> systemNumbers;
  final List<List<int>> fullSystemRows;
  final List<List<int>> vewRows;
  final int targetVewRows;
  final double fullStake;
  final double vewStake;
  final double tripleCoveragePercent;
  final double pairCoveragePercent;

  const VewSystemResult({
    required this.bankNumbers,
    required this.systemNumbers,
    required this.fullSystemRows,
    required this.vewRows,
    required this.targetVewRows,
    required this.fullStake,
    required this.vewStake,
    required this.tripleCoveragePercent,
    required this.pairCoveragePercent,
  });

  int get fullRowCount => fullSystemRows.length;
  int get vewRowCount => vewRows.length;

  bool get hasRows => fullSystemRows.isNotEmpty || vewRows.isNotEmpty;

  String get efficiencyLabel {
    if (fullRowCount <= 0 || vewRowCount <= 0) return 'Keine Daten';
    final ratio = vewRowCount / fullRowCount;
    if (ratio <= 0.12) return 'Sehr hoch';
    if (ratio <= 0.25) return 'Hoch';
    if (ratio <= 0.45) return 'Mittel';
    return 'Basis';
  }

  String get smartVewLabel {
    if (vewRows.isEmpty) return 'Keine Reihen';
    if (tripleCoveragePercent >= 90 && pairCoveragePercent >= 95) {
      return 'Smart Intervall sehr stark';
    }
    if (tripleCoveragePercent >= 75 && pairCoveragePercent >= 90) {
      return 'Smart Intervall stark';
    }
    if (tripleCoveragePercent >= 55) return 'Smart Intervall solide';
    return 'Smart Intervall Basis';
  }
}

class VewSystemEngine {
  static const double defaultStakePerRow = 1.20;

  const VewSystemEngine();

  VewSystemResult generate({
    required List<int> bankNumbers,
    required List<int> systemNumbers,
    int? targetVewRows,
    double stakePerRow = defaultStakePerRow,
  }) {
    final banks = _cleanNumbers(bankNumbers).take(3).toList()..sort();
    final allNumbers = _cleanNumbers(<int>{...banks, ...systemNumbers}.toList())..sort();

    if (allNumbers.length < 6) {
      return VewSystemResult(
        bankNumbers: banks,
        systemNumbers: allNumbers,
        fullSystemRows: const [],
        vewRows: const [],
        targetVewRows: 0,
        fullStake: 0,
        vewStake: 0,
        tripleCoveragePercent: 0,
        pairCoveragePercent: 0,
      );
    }

    final effectiveBanks = banks.where(allNumbers.contains).take(5).toList();
    final flexibleNumbers = allNumbers.where((n) => !effectiveBanks.contains(n)).toList();
    final needFromFlexible = 6 - effectiveBanks.length;

    final fullRows = needFromFlexible <= 0
        ? <List<int>>[(effectiveBanks.take(6).toList()..sort())]
        : _combinations(flexibleNumbers, needFromFlexible)
        .map((combo) => (<int>[...effectiveBanks, ...combo]..sort()))
        .toList();

    final target = targetVewRows ?? _defaultVewTarget(allNumbers.length, effectiveBanks.length);
    final vewRows = _selectSmartVewRows(
      rows: fullRows,
      target: target,
      bankNumbers: effectiveBanks,
      systemNumbers: allNumbers,
    );

    final allTriples = _coverageKeys(allNumbers, 3);
    final allPairs = _coverageKeys(allNumbers, 2);
    final coveredTriples = _coveredKeys(vewRows, 3);
    final coveredPairs = _coveredKeys(vewRows, 2);

    return VewSystemResult(
      bankNumbers: effectiveBanks,
      systemNumbers: allNumbers,
      fullSystemRows: fullRows,
      vewRows: vewRows,
      targetVewRows: target,
      fullStake: fullRows.length * stakePerRow,
      vewStake: vewRows.length * stakePerRow,
      tripleCoveragePercent: _percent(coveredTriples.length, allTriples.length),
      pairCoveragePercent: _percent(coveredPairs.length, allPairs.length),
    );
  }

  List<int> _cleanNumbers(List<int> values) {
    return values.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
  }

  int _defaultVewTarget(int numberCount, int bankCount) {
    final effectiveCount = numberCount.clamp(6, 10);
    if (bankCount >= 2) {
      switch (effectiveCount) {
        case 7:
          return 3;
        case 8:
          return 5;
        case 9:
          return 7;
        default:
          return 10;
      }
    }

    switch (effectiveCount) {
      case 7:
        return 3;
      case 8:
        return 5;
      case 9:
        return 12;
      default:
        return 15;
    }
  }

  List<List<int>> _selectSmartVewRows({
    required List<List<int>> rows,
    required int target,
    required List<int> bankNumbers,
    required List<int> systemNumbers,
  }) {
    if (rows.length <= target) {
      return rows.map((r) => List<int>.from(r)..sort()).toList();
    }

    final selected = <List<int>>[];
    final coveredTriples = <String>{};
    final coveredPairs = <String>{};
    final usedNumbers = <int, int>{for (final n in systemNumbers) n: 0};
    final candidates = rows.map((r) => List<int>.from(r)..sort()).toList();

    while (selected.length < target && candidates.isNotEmpty) {
      candidates.sort((a, b) {
        final scoreA = _smartRowScore(
          row: a,
          coveredTriples: coveredTriples,
          coveredPairs: coveredPairs,
          usedNumbers: usedNumbers,
          bankNumbers: bankNumbers,
          systemNumbers: systemNumbers,
        );
        final scoreB = _smartRowScore(
          row: b,
          coveredTriples: coveredTriples,
          coveredPairs: coveredPairs,
          usedNumbers: usedNumbers,
          bankNumbers: bankNumbers,
          systemNumbers: systemNumbers,
        );
        if (scoreA != scoreB) return scoreB.compareTo(scoreA);
        return _rowKey(a).compareTo(_rowKey(b));
      });

      final best = candidates.removeAt(0);
      selected.add(best);
      coveredTriples.addAll(_coverageKeys(best, 3));
      coveredPairs.addAll(_coverageKeys(best, 2));
      for (final n in best) {
        usedNumbers[n] = (usedNumbers[n] ?? 0) + 1;
      }
    }

    selected.sort((a, b) => _rowKey(a).compareTo(_rowKey(b)));
    return selected;
  }

  int _smartRowScore({
    required List<int> row,
    required Set<String> coveredTriples,
    required Set<String> coveredPairs,
    required Map<int, int> usedNumbers,
    required List<int> bankNumbers,
    required List<int> systemNumbers,
  }) {
    final triples = _coverageKeys(row, 3).where((k) => !coveredTriples.contains(k)).length;
    final pairs = _coverageKeys(row, 2).where((k) => !coveredPairs.contains(k)).length;

    final lowCount = row.where((n) => n <= 24).length;
    final oddCount = row.where((n) => n.isOdd).length;
    final endDigits = row.map((n) => n % 10).toSet().length;
    final spread = row.last - row.first;
    final bankHits = row.where(bankNumbers.contains).length;

    final balanceBonus = (lowCount >= 2 && lowCount <= 4) ? 12 : -8;
    final oddEvenBonus = (oddCount >= 2 && oddCount <= 4) ? 10 : -6;
    final endDigitBonus = endDigits >= 4 ? 6 : -4;
    final spreadBonus = (spread >= 20 && spread <= 42) ? 6 : 0;
    final bankBonus = bankHits * 8;
    final consecutivePenalty = _consecutiveCount(row) * 5;
    final overusedPenalty = row.fold<int>(0, (sum, n) => sum + ((usedNumbers[n] ?? 0) * 3));

    return triples * 100 +
        pairs * 14 +
        balanceBonus +
        oddEvenBonus +
        endDigitBonus +
        spreadBonus +
        bankBonus -
        consecutivePenalty -
        overusedPenalty;
  }

  int _consecutiveCount(List<int> row) {
    var count = 0;
    final sorted = List<int>.from(row)..sort();
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) count++;
    }
    return count;
  }

  List<List<int>> _combinations(List<int> values, int k) {
    final clean = List<int>.from(values)..sort();
    final result = <List<int>>[];

    void walk(int start, List<int> current) {
      if (current.length == k) {
        result.add(List<int>.from(current));
        return;
      }
      final remainingSlots = k - current.length;
      for (var i = start; i <= clean.length - remainingSlots; i++) {
        current.add(clean[i]);
        walk(i + 1, current);
        current.removeLast();
      }
    }

    if (k <= 0) return const [[]];
    if (clean.length < k) return const [];
    walk(0, <int>[]);
    return result;
  }

  Set<String> _coverageKeys(List<int> numbers, int size) {
    final combos = _combinations(numbers, size);
    return combos.map(_rowKey).toSet();
  }

  Set<String> _coveredKeys(List<List<int>> rows, int size) {
    final result = <String>{};
    for (final row in rows) {
      result.addAll(_coverageKeys(row, size));
    }
    return result;
  }

  String _rowKey(List<int> row) => (List<int>.from(row)..sort()).join('-');

  double _percent(int value, int total) {
    if (total <= 0) return 0;
    return (value / total) * 100;
  }
}
