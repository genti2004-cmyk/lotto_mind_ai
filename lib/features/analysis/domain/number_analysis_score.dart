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
    required this.averageInterval,
    required this.currentInterval,
    required this.intervalRatio,
  });

  final int number;
  final double frequencyScore;
  final double overdueScore;
  final double intervalScore;
  final double patternScore;
  final double hybridScore;
  final int? lastSeenDrawsAgo;
  final int hitCount;
  final double? averageInterval;
  final int? currentInterval;
  final double? intervalRatio;

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

  String get hybridPercentLabel => '${(hybridScore * 100).round()}%';

  String get intervalLabel {
    final average = averageInterval;
    final current = currentInterval;
    if (average == null || current == null || hitCount < 2) {
      return 'Intervall noch nicht belastbar';
    }
    return 'Ø ${average.toStringAsFixed(1)} Ziehungen · aktuell $current';
  }

  String get lastSeenLabel {
    if (lastSeenDrawsAgo == null) return 'im aktuellen Fenster nicht gesehen';
    if (lastSeenDrawsAgo == 0) return 'in der letzten Ziehung gesehen';
    if (lastSeenDrawsAgo == 1) return 'vor 1 Ziehung gesehen';
    return 'vor $lastSeenDrawsAgo Ziehungen gesehen';
  }

  List<String> get reasonBullets {
    final reasons = <String>[];

    if (frequencyScore >= 0.70) {
      reasons.add('überdurchschnittlich häufig im Analysefenster');
    } else if (frequencyScore <= 0.22 && hitCount > 0) {
      reasons.add('unterdurchschnittlich häufig im Analysefenster');
    }

    if (overdueScore >= 0.70) {
      reasons.add('erhöhter Rückstand');
    } else if (lastSeenDrawsAgo == 0) {
      reasons.add('sehr frisch gezogen');
    }

    if (intervalScore >= 0.72) {
      reasons.add('aktueller Abstand passt gut zum typischen Intervall');
    }

    if (patternScore >= 0.45) {
      reasons.add('Muster-/Nachbarschaftssignal');
    }

    if (hybridScore >= 0.60 && reasons.length >= 2) {
      reasons.add('mehrere Signale wirken zusammen');
    }

    if (reasons.isEmpty) {
      reasons.add('ausgewogener Hybrid-Score');
    }

    return reasons;
  }

  String get shortExplanation {
    final parts = reasonBullets.take(2).join(' · ');
    return '$parts · Hybrid $hybridPercentLabel · $lastSeenLabel';
  }
}
