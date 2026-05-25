import '../../draws/domain/draw_result.dart';

class SmartVewRow {
  final List<int> numbers;
  final double score;

  const SmartVewRow({
    required this.numbers,
    required this.score,
  });
}

class SmartVewResult {
  final List<SmartVewRow> rows;

  const SmartVewResult({required this.rows});

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;
}

class SmartVewEngine {
  const SmartVewEngine();

  SmartVewResult rankRows({
    required List<List<int>> rows,
    required List<DrawResult> draws,
    int limit = 12,
  }) {
    if (rows.isEmpty) return const SmartVewResult(rows: []);

    final frequency = _frequency(draws);
    final pairFrequency = _pairFrequency(draws);

    final ranked = rows.map((row) {
      final clean = List<int>.from(row.where((n) => n >= 1 && n <= 49).toSet())..sort();
      return SmartVewRow(
        numbers: clean,
        score: _scoreRow(clean, frequency, pairFrequency),
      );
    }).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.numbers.join('-').compareTo(b.numbers.join('-'));
      });

    return SmartVewResult(rows: ranked.take(limit).toList());
  }

  Map<int, int> _frequency(List<DrawResult> draws) {
    final map = <int, int>{for (var i = 1; i <= 49; i++) i: 0};
    for (final draw in draws) {
      for (final n in draw.numbers) {
        if (n >= 1 && n <= 49) map[n] = (map[n] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<String, int> _pairFrequency(List<DrawResult> draws) {
    final map = <String, int>{};
    for (final draw in draws) {
      final nums = List<int>.from(draw.numbers.where((n) => n >= 1 && n <= 49).toSet())..sort();
      for (var i = 0; i < nums.length; i++) {
        for (var j = i + 1; j < nums.length; j++) {
          final key = '${nums[i]}-${nums[j]}';
          map[key] = (map[key] ?? 0) + 1;
        }
      }
    }
    return map;
  }

  double _scoreRow(
      List<int> row,
      Map<int, int> frequency,
      Map<String, int> pairFrequency,
      ) {
    var score = 0.0;

    for (final n in row) {
      score += (frequency[n] ?? 0) * 1.2;
    }

    for (var i = 0; i < row.length; i++) {
      for (var j = i + 1; j < row.length; j++) {
        final key = row[i] < row[j] ? '${row[i]}-${row[j]}' : '${row[j]}-${row[i]}';
        score += (pairFrequency[key] ?? 0) * 2.4;
      }
    }

    final low = row.where((n) => n <= 24).length;
    final odd = row.where((n) => n.isOdd).length;
    final endDigits = row.map((n) => n % 10).toSet().length;
    final spread = row.isEmpty ? 0 : row.last - row.first;

    if (low >= 2 && low <= 4) score += 8;
    if (odd >= 2 && odd <= 4) score += 8;
    if (endDigits >= 4) score += 5;
    if (spread >= 20 && spread <= 42) score += 5;
    score -= _consecutiveCount(row) * 4;

    return score;
  }

  int _consecutiveCount(List<int> row) {
    var count = 0;
    for (var i = 1; i < row.length; i++) {
      if (row[i] == row[i - 1] + 1) count++;
    }
    return count;
  }
}
