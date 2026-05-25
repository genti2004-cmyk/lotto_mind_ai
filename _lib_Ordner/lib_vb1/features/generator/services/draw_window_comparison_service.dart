import '../../draws/domain/draw_result.dart';

class DrawWindowNumberScore {
  final int number;
  final int hits;
  final double score;

  const DrawWindowNumberScore({
    required this.number,
    required this.hits,
    required this.score,
  });
}

class DrawWindowSummary {
  final int requestedWindow;
  final int actualDrawCount;
  final List<DrawWindowNumberScore> topNumbers;
  final List<DrawWindowNumberScore> coldNumbers;

  const DrawWindowSummary({
    required this.requestedWindow,
    required this.actualDrawCount,
    required this.topNumbers,
    required this.coldNumbers,
  });

  List<int> get topNumberValues => topNumbers.map((e) => e.number).toList();
  List<int> get coldNumberValues => coldNumbers.map((e) => e.number).toList();
}

class DrawWindowComparisonResult {
  final List<DrawWindowSummary> summaries;

  const DrawWindowComparisonResult({required this.summaries});

  Map<int, List<int>> get windowTopNumbers => {
    for (final summary in summaries)
      summary.requestedWindow: summary.topNumberValues,
  };

  bool get isEmpty => summaries.isEmpty;
}

class DrawWindowComparisonService {
  const DrawWindowComparisonService();

  DrawWindowComparisonResult analyze(
      List<DrawResult> draws, {
        List<int> windows = const [5, 10, 15, 20, 26, 52],
        int numberLimit = 6,
      }) {
    if (draws.isEmpty) {
      return const DrawWindowComparisonResult(summaries: []);
    }

    final summaries = <DrawWindowSummary>[];

    for (final window in windows) {
      if (window <= 0) continue;

      final subset = draws.take(window).toList();
      final frequencies = <int, int>{
        for (int number = 1; number <= 49; number++) number: 0,
      };

      for (final draw in subset) {
        for (final number in draw.numbers) {
          if (number >= 1 && number <= 49) {
            frequencies[number] = (frequencies[number] ?? 0) + 1;
          }
        }
      }

      final allScores = frequencies.entries.map((entry) {
        return DrawWindowNumberScore(
          number: entry.key,
          hits: entry.value,
          score: subset.isEmpty ? 0 : entry.value / subset.length,
        );
      }).toList();

      final hot = [...allScores]
        ..sort((a, b) {
          final byHits = b.hits.compareTo(a.hits);
          if (byHits != 0) return byHits;
          return a.number.compareTo(b.number);
        });

      final cold = [...allScores]
        ..sort((a, b) {
          final byHits = a.hits.compareTo(b.hits);
          if (byHits != 0) return byHits;
          return a.number.compareTo(b.number);
        });

      summaries.add(
        DrawWindowSummary(
          requestedWindow: window,
          actualDrawCount: subset.length,
          topNumbers: hot.take(numberLimit).toList(),
          coldNumbers: cold.take(numberLimit).toList(),
        ),
      );
    }

    return DrawWindowComparisonResult(summaries: summaries);
  }
}
