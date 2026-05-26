import 'analysis_signal.dart';

class NumberAnalysisScore {
  const NumberAnalysisScore({
    required this.number,
    required this.frequencyScore,
    required this.overdueScore,
    required this.intervalScore,
    required this.patternScore,
    required this.hybridScore,
    required this.lastSeenDrawsAgo,
    required this.hitCount,
  });

  final int number;
  final double frequencyScore;
  final double overdueScore;
  final double intervalScore;
  final double patternScore;
  final double hybridScore;
  final int? lastSeenDrawsAgo;
  final int hitCount;

  double scoreFor(AnalysisSignal signal) {
    switch (signal) {
      case AnalysisSignal.frequency:
        return frequencyScore;
      case AnalysisSignal.overdue:
        return overdueScore;
      case AnalysisSignal.interval:
        return intervalScore;
      case AnalysisSignal.pattern:
        return patternScore;
      case AnalysisSignal.hybrid:
        return hybridScore;
    }
  }

  String get mainReason {
    final signals = <MapEntry<String, double>>[
      MapEntry('Häufigkeit', frequencyScore),
      MapEntry('Rückstand', overdueScore),
      MapEntry('Intervall', intervalScore),
      MapEntry('Muster', patternScore),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final best = signals.first;
    if (best.value <= 0) return 'keine Auffälligkeit';
    return best.key;
  }
}
