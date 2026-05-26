enum AnalysisSignal {
  frequency,
  overdue,
  interval,
  pattern,
  hybrid,
}

extension AnalysisSignalLabel on AnalysisSignal {
  String get label {
    switch (this) {
      case AnalysisSignal.frequency:
        return 'Häufigkeit';
      case AnalysisSignal.overdue:
        return 'Rückstand';
      case AnalysisSignal.interval:
        return 'Intervall';
      case AnalysisSignal.pattern:
        return 'Muster';
      case AnalysisSignal.hybrid:
        return 'Hybrid';
    }
  }

  String get description {
    switch (this) {
      case AnalysisSignal.frequency:
        return 'Bewertet, wie oft eine Zahl im Analysefenster vorkam.';
      case AnalysisSignal.overdue:
        return 'Bewertet, wie lange eine Zahl nicht mehr gezogen wurde.';
      case AnalysisSignal.interval:
        return 'Vergleicht den aktuellen Abstand mit typischen historischen Abständen.';
      case AnalysisSignal.pattern:
        return 'Berücksichtigt einfache Wiederholungs- und Gruppenmuster.';
      case AnalysisSignal.hybrid:
        return 'Kombiniert Häufigkeit, Rückstand, Intervall und Muster zu einem Gesamtwert.';
    }
  }
}
