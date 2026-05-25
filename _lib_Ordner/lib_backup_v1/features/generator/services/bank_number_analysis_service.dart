import '../../draws/domain/draw_result.dart';

class BankNumberAnalysisResult {
  final List<BankNumberScore> singleScores;
  final List<BankPairScore> pairScores;

  const BankNumberAnalysisResult({
    required this.singleScores,
    required this.pairScores,
  });

  List<int> get bestSingleNumbers => singleScores.map((e) => e.number).toList();
  List<List<int>> get bestPairs => pairScores.map((e) => e.numbers).toList();

  bool get isEmpty => singleScores.isEmpty && pairScores.isEmpty;
}

class BankNumberScore {
  final int number;
  final int hits;
  final double score;

  const BankNumberScore({
    required this.number,
    required this.hits,
    required this.score,
  });
}

class BankPairScore {
  final int first;
  final int second;
  final int hits;
  final double score;

  const BankPairScore({
    required this.first,
    required this.second,
    required this.hits,
    required this.score,
  });

  List<int> get numbers => [first, second];
}

class BankNumberAnalysisService {
  const BankNumberAnalysisService();

  BankNumberAnalysisResult analyze(List<DrawResult> draws) {
    if (draws.isEmpty) {
      return const BankNumberAnalysisResult(
        singleScores: [],
        pairScores: [],
      );
    }

    final singleFrequency = <int, int>{
      for (int number = 1; number <= 49; number++) number: 0,
    };

    final pairFrequency = <String, int>{};

    for (final draw in draws) {
      final numbers = draw.numbers
          .where((n) => n >= 1 && n <= 49)
          .toSet()
          .toList()
        ..sort();

      for (final number in numbers) {
        singleFrequency[number] = (singleFrequency[number] ?? 0) + 1;
      }

      for (int i = 0; i < numbers.length; i++) {
        for (int j = i + 1; j < numbers.length; j++) {
          final key = _pairKey(numbers[i], numbers[j]);
          pairFrequency[key] = (pairFrequency[key] ?? 0) + 1;
        }
      }
    }

    final singleScores = singleFrequency.entries.map((entry) {
      return BankNumberScore(
        number: entry.key,
        hits: entry.value,
        score: entry.value / draws.length,
      );
    }).toList()
      ..sort((a, b) {
        final byHits = b.hits.compareTo(a.hits);
        if (byHits != 0) return byHits;
        return a.number.compareTo(b.number);
      });

    final pairScores = pairFrequency.entries.map((entry) {
      final parts = entry.key.split('-');
      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);
      return BankPairScore(
        first: first,
        second: second,
        hits: entry.value,
        score: entry.value / draws.length,
      );
    }).toList()
      ..sort((a, b) {
        final byHits = b.hits.compareTo(a.hits);
        if (byHits != 0) return byHits;
        final byFirst = a.first.compareTo(b.first);
        if (byFirst != 0) return byFirst;
        return a.second.compareTo(b.second);
      });

    return BankNumberAnalysisResult(
      singleScores: singleScores,
      pairScores: pairScores,
    );
  }

  String _pairKey(int a, int b) {
    final first = a < b ? a : b;
    final second = a < b ? b : a;
    return '$first-$second';
  }
}
