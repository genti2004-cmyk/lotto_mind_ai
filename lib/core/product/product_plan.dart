import '../../features/settings/domain/app_edition.dart';

/// Beschreibt die geplante Produktlogik, ohne bereits eine Paywall zu erzwingen.
///
/// Diese Datei dient als stabile Grundlage für Normal, Pro und Premium.
/// Screens können später diese Daten verwenden, um Funktionen klar zu erklären.
class ProductPlan {
  final AppEdition edition;
  final List<String> highlights;

  const ProductPlan({
    required this.edition,
    required this.highlights,
  });

  static const normal = ProductPlan(
    edition: AppEdition.free,
    highlights: [
      'Ziehungen aktualisieren',
      'Einfache Tipp-Erstellung',
      'Meine Tipps speichern',
      'Grundauswertung nach Ziehung',
    ],
  );

  static const pro = ProductPlan(
    edition: AppEdition.pro,
    highlights: [
      'Erweiterte Statistiken',
      'Tracking Pro',
      'Systemgenerator',
      'Mehr Verlauf und Analysefenster',
    ],
  );

  static const premium = ProductPlan(
    edition: AppEdition.future,
    highlights: [
      'Expertenmodelle',
      'Strategievergleich',
      'Export Center',
      'Cloud-/Komfortfunktionen vorbereitet',
    ],
  );

  static const all = [normal, pro, premium];
}
