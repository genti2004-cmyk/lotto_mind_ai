/// Strategien für die spätere klare Tipp-Erstellung und das spätere
/// Strategie-Tracking.
///
/// Diese Werte sind bewusst stabil und speicherbar, damit Tracking Pro später
/// vergleichen kann, welche Tipp-Methode langfristig welche Treffer liefert.
enum GeneratorStrategy {
  basis,
  analysis,
  signal,
  pro,
  system,
  frequency,
  interval,
  overdue,
  hybrid,
  manual,
  unknown,
}

extension GeneratorStrategyX on GeneratorStrategy {
  String get label {
    switch (this) {
      case GeneratorStrategy.basis:
        return 'Basis';
      case GeneratorStrategy.analysis:
        return 'Analyse';
      case GeneratorStrategy.signal:
        return 'Signal';
      case GeneratorStrategy.pro:
        return 'Pro';
      case GeneratorStrategy.system:
        return 'System';
      case GeneratorStrategy.frequency:
        return 'Häufigkeit';
      case GeneratorStrategy.interval:
        return 'Intervall';
      case GeneratorStrategy.overdue:
        return 'Rückstand';
      case GeneratorStrategy.hybrid:
        return 'Hybrid';
      case GeneratorStrategy.manual:
        return 'Manuell';
      case GeneratorStrategy.unknown:
        return 'Offen';
    }
  }

  String get trackingLabel => label;

  static GeneratorStrategy fromName(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return GeneratorStrategy.unknown;
    return GeneratorStrategy.values.firstWhere(
      (value) => value.name == text,
      orElse: () => GeneratorStrategy.unknown,
    );
  }

  /// Kompatibilität mit den alten `source`-Werten.
  static GeneratorStrategy fromSource(String? raw) {
    final source = raw?.toLowerCase().trim() ?? '';
    if (source.isEmpty) return GeneratorStrategy.unknown;
    if (source == 'manual') return GeneratorStrategy.manual;
    if (source == 'random') return GeneratorStrategy.basis;
    if (source == 'analysis') return GeneratorStrategy.analysis;
    if (source == 'signal') return GeneratorStrategy.signal;
    if (source == 'ai' || source == 'analysis_pro' || source == 'pro') {
      return GeneratorStrategy.pro;
    }
    if (source == 'tracking_pro') return GeneratorStrategy.pro;
    if (source.startsWith('system_') ||
        source.startsWith('voll_') ||
        source.startsWith('vew_')) {
      return GeneratorStrategy.system;
    }
    if (source.contains('hybrid')) return GeneratorStrategy.hybrid;
    if (source.contains('interval') || source.contains('intervall')) {
      return GeneratorStrategy.interval;
    }
    if (source.contains('overdue') || source.contains('rueckstand') || source.contains('rückstand')) {
      return GeneratorStrategy.overdue;
    }
    if (source.contains('frequency') || source.contains('haeufig') || source.contains('häufig')) {
      return GeneratorStrategy.frequency;
    }
    return GeneratorStrategy.unknown;
  }
}
