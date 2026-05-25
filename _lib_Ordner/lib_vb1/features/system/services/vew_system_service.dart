/// VEW PRO ENGINE fuer Lotto 6aus49.
///
/// Diese Engine erzeugt deterministische, reduzierte Systemreihen aus 7 bis 10
/// Basiszahlen. Der Fokus liegt nicht auf Zufall, sondern auf maximaler
/// Abdeckung von 3er- und 4er-Teilmengen innerhalb der gewaehlten Basiszahlen.
///
/// Wichtig:
/// - Vollsystem = alle 6er-Kombinationen.
/// - VEW = reduzierte Auswahl mit hoher Abdeckung, aber ohne Vollgarantie.
/// - Die Engine ist stabil/deterministisch: gleiche Basiszahlen ergeben gleiche Reihen.
class VewSystemService {
  const VewSystemService();

  /// Baut reduzierte VEW-Reihen aus 7 bis 10 Basiszahlen.
  ///
  /// Zielreihen:
  /// 7 Zahlen  -> 3 Reihen
  /// 8 Zahlen  -> 5 Reihen
  /// 9 Zahlen  -> 7 Reihen
  /// 10 Zahlen -> 10 Reihen
  List<List<int>> buildRows(List<int> numbers) {
    final pool = _normalize(numbers);
    if (pool.length < 6 || pool.length > 10) return const [];
    if (pool.length == 6) return [pool];

    final allRows = _combinations(pool, 6);
    final target = targetRows(pool.length);
    if (allRows.length <= target) return allRows;

    final allPairs = _tupleKeys(pool, 2);
    final allTriples = _tupleKeys(pool, 3);
    final allFours = _tupleKeys(pool, 4);

    final coveredPairs = <String>{};
    final coveredTriples = <String>{};
    final coveredFours = <String>{};
    final numberCoverage = <int, int>{for (final n in pool) n: 0};

    final selected = <List<int>>[];
    final usedRows = <String>{};

    // Startanker: erste Reihe moeglichst breit gestreut aus dem gesamten Pool.
    final anchor = _anchorRow(pool);
    selected.add(anchor);
    usedRows.add(_rowKey(anchor));
    _applyCoverage(
      row: anchor,
      numberCoverage: numberCoverage,
      coveredPairs: coveredPairs,
      coveredTriples: coveredTriples,
      coveredFours: coveredFours,
    );

    while (selected.length < target) {
      _VewCandidate? best;

      for (final row in allRows) {
        final key = _rowKey(row);
        if (usedRows.contains(key)) continue;

        final score = _scoreRow(
          row: row,
          pool: pool,
          selected: selected,
          numberCoverage: numberCoverage,
          coveredPairs: coveredPairs,
          coveredTriples: coveredTriples,
          coveredFours: coveredFours,
          allPairs: allPairs,
          allTriples: allTriples,
          allFours: allFours,
        );

        if (best == null || score > best.score ||
            (score == best.score && _rowKey(row).compareTo(_rowKey(best.row)) < 0)) {
          best = _VewCandidate(row: row, score: score);
        }
      }

      if (best == null) break;

      final row = List<int>.from(best.row)..sort();
      selected.add(row);
      usedRows.add(_rowKey(row));
      _applyCoverage(
        row: row,
        numberCoverage: numberCoverage,
        coveredPairs: coveredPairs,
        coveredTriples: coveredTriples,
        coveredFours: coveredFours,
      );
    }

    selected.sort((a, b) => _rowKey(a).compareTo(_rowKey(b)));
    return selected;
  }

  /// Vollsystem-Reihen zum Vergleich oder fuer Voll-Modus.
  List<List<int>> buildFullRows(List<int> numbers) {
    final pool = _normalize(numbers);
    if (pool.length < 6 || pool.length > 10) return const [];
    return _combinations(pool, 6);
  }

  /// Anzahl reduzierter VEW-Reihen.
  int targetRows(int selectedCount) {
    switch (selectedCount) {
      case 6:
        return 1;
      case 7:
        return 3;
      case 8:
        return 5;
      case 9:
        return 7;
      case 10:
        return 10;
      default:
        return 0;
    }
  }

  /// Anzahl Vollsystem-Reihen C(n, 6).
  int fullSystemRows(int selectedCount) {
    if (selectedCount < 6 || selectedCount > 10) return 0;
    return _binomial(selectedCount, 6);
  }

  /// Bericht fuer UI/Debug: zeigt, wie stark das VEW die Basiszahlen abdeckt.
  VewCoverageReport coverageReport(List<int> numbers) {
    final pool = _normalize(numbers);
    final rows = buildRows(pool);
    if (pool.length < 6 || rows.isEmpty) {
      return const VewCoverageReport.empty();
    }

    final allPairs = _tupleKeys(pool, 2);
    final allTriples = _tupleKeys(pool, 3);
    final allFours = _tupleKeys(pool, 4);
    final coveredPairs = <String>{};
    final coveredTriples = <String>{};
    final coveredFours = <String>{};

    for (final row in rows) {
      coveredPairs.addAll(_tupleKeys(row, 2));
      coveredTriples.addAll(_tupleKeys(row, 3));
      coveredFours.addAll(_tupleKeys(row, 4));
    }

    final fullRows = fullSystemRows(pool.length);
    final reduction = fullRows == 0 ? 0.0 : 1.0 - (rows.length / fullRows);

    return VewCoverageReport(
      selectedNumbers: pool.length,
      rows: rows.length,
      fullRows: fullRows,
      pairCoverage: _ratio(coveredPairs.length, allPairs.length),
      tripleCoverage: _ratio(coveredTriples.length, allTriples.length),
      fourCoverage: _ratio(coveredFours.length, allFours.length),
      reduction: reduction,
    );
  }

  List<int> _normalize(List<int> numbers) {
    return numbers.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
  }

  List<int> _anchorRow(List<int> pool) {
    // Gleichmaessig ueber den Pool verteilt: vermeidet einen schwachen Start.
    if (pool.length == 6) return List<int>.from(pool)..sort();
    final indexes = <int>{0, pool.length - 1};
    for (var i = 1; indexes.length < 6; i++) {
      final pos = ((pool.length - 1) * i / 5).round();
      indexes.add(pos.clamp(0, pool.length - 1));
      if (i > 20) break;
    }
    var fallback = 0;
    while (indexes.length < 6) {
      indexes.add(fallback);
      fallback++;
    }
    return indexes.map((i) => pool[i]).toList()..sort();
  }

  void _applyCoverage({
    required List<int> row,
    required Map<int, int> numberCoverage,
    required Set<String> coveredPairs,
    required Set<String> coveredTriples,
    required Set<String> coveredFours,
  }) {
    for (final n in row) {
      numberCoverage[n] = (numberCoverage[n] ?? 0) + 1;
    }
    coveredPairs.addAll(_tupleKeys(row, 2));
    coveredTriples.addAll(_tupleKeys(row, 3));
    coveredFours.addAll(_tupleKeys(row, 4));
  }

  double _scoreRow({
    required List<int> row,
    required List<int> pool,
    required List<List<int>> selected,
    required Map<int, int> numberCoverage,
    required Set<String> coveredPairs,
    required Set<String> coveredTriples,
    required Set<String> coveredFours,
    required Set<String> allPairs,
    required Set<String> allTriples,
    required Set<String> allFours,
  }) {
    final rowPairs = _tupleKeys(row, 2);
    final rowTriples = _tupleKeys(row, 3);
    final rowFours = _tupleKeys(row, 4);

    final newPairs = rowPairs.where((k) => !coveredPairs.contains(k)).length;
    final newTriples = rowTriples.where((k) => !coveredTriples.contains(k)).length;
    final newFours = rowFours.where((k) => !coveredFours.contains(k)).length;

    final lowCoveredBonus = row.fold<double>(
      0,
          (sum, n) => sum + (9 - (numberCoverage[n] ?? 0)).clamp(0, 9),
    );

    final overlapPenalty = selected.fold<double>(0, (sum, oldRow) {
      final overlap = row.where(oldRow.contains).length;
      if (overlap <= 3) return sum;
      return sum + ((overlap - 3) * 18.0);
    });

    final odd = row.where((n) => n.isOdd).length;
    final low = row.where((n) => n <= 24).length;
    final sum = row.fold<int>(0, (a, b) => a + b);
    final spread = row.last - row.first;

    var score = 0.0;

    // Kern der VEW PRO Engine: 3er-Abdeckung ist am wichtigsten,
    // 4er-Abdeckung kommt danach, Paare stabilisieren die Streuung.
    score += newTriples * 34.0;
    score += newFours * 16.0;
    score += newPairs * 4.5;
    score += lowCoveredBonus * 7.0;

    // Reihen sollen nicht alle gleich aussehen.
    score -= overlapPenalty;

    // Lotto-typische Balance-Regeln.
    if (odd >= 2 && odd <= 4) score += 18;
    if (low >= 2 && low <= 4) score += 18;
    if (spread >= 22 && spread <= 46) score += 12;
    if (sum >= 95 && sum <= 190) score += 12;

    // Spaetere Reihen priorisieren staerker noch offene 3er/4er.
    final progress = selected.length / targetRows(pool.length);
    score += newTriples * (12.0 * progress);
    score += newFours * (7.0 * progress);

    // Kleine deterministische Tiebreaker, damit gleiche Scores stabil bleiben.
    score += (allPairs.length - coveredPairs.length) * 0.001;
    score += (allTriples.length - coveredTriples.length) * 0.002;
    score += (allFours.length - coveredFours.length) * 0.003;

    return score;
  }

  List<List<int>> _combinations(List<int> numbers, int k) {
    final sorted = List<int>.from(numbers)..sort();
    final result = <List<int>>[];

    void build(int start, List<int> current) {
      if (current.length == k) {
        result.add(List<int>.from(current)..sort());
        return;
      }
      final remainingNeeded = k - current.length;
      for (var i = start; i <= sorted.length - remainingNeeded; i++) {
        current.add(sorted[i]);
        build(i + 1, current);
        current.removeLast();
      }
    }

    build(0, <int>[]);
    return result;
  }

  Set<String> _tupleKeys(List<int> numbers, int k) {
    final tuples = _combinations(numbers, k);
    return tuples.map((tuple) => tuple.join('-')).toSet();
  }

  int _binomial(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k == 0 || k == n) return 1;
    var result = 1;
    for (var i = 1; i <= k; i++) {
      result = (result * (n - i + 1)) ~/ i;
    }
    return result;
  }

  double _ratio(int part, int total) {
    if (total <= 0) return 0.0;
    return part / total;
  }

  String _rowKey(List<int> row) => (List<int>.from(row)..sort()).join('-');
}

class VewCoverageReport {
  final int selectedNumbers;
  final int rows;
  final int fullRows;
  final double pairCoverage;
  final double tripleCoverage;
  final double fourCoverage;
  final double reduction;

  const VewCoverageReport({
    required this.selectedNumbers,
    required this.rows,
    required this.fullRows,
    required this.pairCoverage,
    required this.tripleCoverage,
    required this.fourCoverage,
    required this.reduction,
  });

  const VewCoverageReport.empty()
      : selectedNumbers = 0,
        rows = 0,
        fullRows = 0,
        pairCoverage = 0,
        tripleCoverage = 0,
        fourCoverage = 0,
        reduction = 0;

  String get guaranteeLabel {
    if (tripleCoverage >= 0.98) return 'Sehr hohe 3er-Abdeckung';
    if (tripleCoverage >= 0.85) return 'Hohe 3er-Abdeckung';
    if (tripleCoverage >= 0.70) return 'Solide 3er-Abdeckung';
    return 'Reduzierte Abdeckung';
  }

  int get pairPercent => (pairCoverage * 100).round();
  int get triplePercent => (tripleCoverage * 100).round();
  int get fourPercent => (fourCoverage * 100).round();
  int get reductionPercent => (reduction * 100).round();
}

class _VewCandidate {
  const _VewCandidate({required this.row, required this.score});

  final List<int> row;
  final double score;
}
