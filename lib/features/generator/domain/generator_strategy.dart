/// Strategien für die spätere klare Tipp-Erstellung.
///
/// Noch nicht jede Strategie muss sofort vollständig implementiert sein. Wichtig
/// ist, dass jeder gespeicherte Tipp künftig nachvollziehbar speichern kann,
/// nach welchem Modell er erzeugt wurde.
enum GeneratorStrategy {
  basis,
  frequency,
  interval,
  overdue,
  hybrid,
  system,
}

extension GeneratorStrategyX on GeneratorStrategy {
  String get label {
    switch (this) {
      case GeneratorStrategy.basis:
        return 'Basis';
      case GeneratorStrategy.frequency:
        return 'Häufigkeit';
      case GeneratorStrategy.interval:
        return 'Intervall';
      case GeneratorStrategy.overdue:
        return 'Rückstand';
      case GeneratorStrategy.hybrid:
        return 'Hybrid';
      case GeneratorStrategy.system:
        return 'System';
    }
  }
}
