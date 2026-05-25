import 'dart:math';

import '../domain/system_mode.dart';
import '../domain/system_ticket.dart';
import '../domain/vew_system_type.dart';

class SystemGeneratorService {
  /// Kombinationen erzeugen (n über k)
  List<List<int>> generateCombinations(List<int> numbers, int k) {
    final result = <List<int>>[];

    void combine(int start, List<int> current) {
      if (current.length == k) {
        result.add(List<int>.from(current)..sort());
        return;
      }

      for (int i = start; i < numbers.length; i++) {
        current.add(numbers[i]);
        combine(i + 1, current);
        current.removeLast();
      }
    }

    combine(0, <int>[]);
    return result;
  }

  /// Vollsystem: aus den gewählten Basiszahlen alle 6er-Reihen bilden
  SystemTicket generateFullSystem(List<int> baseNumbers) {
    final normalized = _normalizeNumbers(baseNumbers);

    if (normalized.length < 7) {
      throw Exception('Für Vollsystem bitte mindestens 7 Zahlen wählen.');
    }

    if (normalized.length > 10) {
      throw Exception('Für Vollsystem sind maximal 10 Zahlen vorgesehen.');
    }

    final rows = generateCombinations(normalized, 6);

    return SystemTicket(
      mode: SystemMode.full,
      baseNumbers: normalized,
      rows: rows,
      vewType: null,
    );
  }

  /// VEW: kompakte Reihen aus der Auswahl erzeugen
  ///
  /// Hinweis:
  /// Das ist eine stabile, app-taugliche VEW-Näherung für dein Projekt,
  /// keine offizielle proprietäre WestLotto-Matrix.
  SystemTicket generateVewSystem(List<int> baseNumbers, VewSystemType type) {
    final normalized = _normalizeNumbers(baseNumbers);

    if (normalized.length != type.selectedCount) {
      throw Exception(
        'Für ${type.label} müssen genau ${type.selectedCount} Zahlen gewählt werden.',
      );
    }

    final rows = _buildVewRows(normalized, type);

    return SystemTicket(
      mode: SystemMode.vew,
      baseNumbers: normalized,
      rows: rows,
      vewType: type,
    );
  }

  List<int> _normalizeNumbers(List<int> input) {
    final normalized = input.toSet().toList()..sort();

    for (final n in normalized) {
      if (n < 1 || n > 49) {
        throw Exception('Ungültige Zahl: $n. Erlaubt sind nur 1 bis 49.');
      }
    }

    return normalized;
  }

  List<List<int>> _buildVewRows(List<int> numbers, VewSystemType type) {
    final allRows = generateCombinations(numbers, 6);
    final targetRowCount = _targetRowCount(type);

    if (allRows.length <= targetRowCount) {
      return allRows;
    }

    final scored = allRows
        .map(
          (row) => _ScoredRow(
        row: row,
        score: _scoreRow(row, numbers),
      ),
    )
        .toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return _rowKey(a.row).compareTo(_rowKey(b.row));
      });

    final selected = <List<int>>[];
    final usedKeys = <String>{};

    for (final candidate in scored) {
      if (selected.length >= targetRowCount) break;

      final key = _rowKey(candidate.row);
      if (usedKeys.add(key)) {
        selected.add(candidate.row);
      }
    }

    return selected;
  }

  int _targetRowCount(VewSystemType type) {
    switch (type) {
      case VewSystemType.vew3:
        return 3;
      case VewSystemType.vew4:
        return 4;
      case VewSystemType.vew5:
        return 5;
      case VewSystemType.vew6:
        return 6;
      case VewSystemType.vew7_3:
        return 7;
      case VewSystemType.vew8_4:
        return 8;
      case VewSystemType.vew9_4:
        return 9;
      case VewSystemType.vew9_5:
        return 9;
      case VewSystemType.vew10_5:
        return 10;
    }
  }

  double _scoreRow(List<int> row, List<int> pool) {
    final sum = row.fold<int>(0, (a, b) => a + b);
    final oddCount = row.where((n) => n.isOdd).length;
    final lowCount = row.where((n) => n <= 24).length;
    final spread = row.last - row.first;
    final centerBias = row
        .map((n) => (25 - n).abs())
        .fold<int>(0, (a, b) => a + b);

    double score = 0;

    if (oddCount >= 2 && oddCount <= 4) score += 3.0;
    if (lowCount >= 2 && lowCount <= 4) score += 3.0;
    if (spread >= 18) score += 2.0;
    if (sum >= 90 && sum <= 180) score += 3.0;

    score += max(0, 30 - centerBias) * 0.05;

    final coverageBonus = _coverageBonus(row, pool);
    score += coverageBonus;

    return score;
  }

  double _coverageBonus(List<int> row, List<int> pool) {
    final poolMiddle = pool[pool.length ~/ 2];
    final rowAverage = row.reduce((a, b) => a + b) / row.length;
    return 5.0 - (rowAverage - poolMiddle).abs() * 0.1;
  }

  String _rowKey(List<int> row) => row.join('-');
}

class _ScoredRow {
  final List<int> row;
  final double score;

  const _ScoredRow({
    required this.row,
    required this.score,
  });
}