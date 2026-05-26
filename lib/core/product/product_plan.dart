import '../../features/settings/domain/app_edition.dart';

/// Beschreibt die geplante Produktlogik, ohne bereits eine Paywall zu erzwingen.
///
/// Diese Datei ist die zentrale Grundlage für Normal, Pro und Premium. Screens
/// können dieselben Daten nutzen, damit Funktionsumfang, Labels und spätere
/// Freischaltungen konsistent bleiben.
class ProductPlan {
  final AppEdition edition;
  final String title;
  final String shortDescription;
  final String audience;
  final List<String> included;
  final List<String> planned;

  const ProductPlan({
    required this.edition,
    required this.title,
    required this.shortDescription,
    required this.audience,
    required this.included,
    this.planned = const [],
  });

  List<String> get highlights => included;

  bool get isNormal => edition.isNormal;
  bool get isPro => edition.isPro;
  bool get isPremium => edition.isPremium;

  static const normal = ProductPlan(
    edition: AppEdition.free,
    title: 'Normal',
    shortDescription: 'Einfacher Einstieg für Ziehungen, Tipps und Grundprüfung.',
    audience: 'Für Nutzer, die schnell einen Tipp erzeugen und später prüfen möchten.',
    included: [
      'Ziehungen aktualisieren',
      'Basis-Tipp erstellen',
      'Meine Tipps speichern',
      'Grundauswertung nach Ziehung',
      'Letzte Ziehungen ansehen',
    ],
  );

  static const pro = ProductPlan(
    edition: AppEdition.pro,
    title: 'Pro',
    shortDescription: 'Mehr Kontrolle durch Analyse, Tracking und Systemtipps.',
    audience: 'Für Nutzer, die Strategien vergleichen und Tipps langfristig beobachten möchten.',
    included: [
      'Analyse nach Häufigkeit, Intervall und Rückstand',
      'Tracking Pro für gespeicherte Tipps',
      'Systemschein-Generator',
      'Erweiterter Ziehungsverlauf',
      'Favoriten und Beobachtungsliste',
    ],
    planned: [
      'Strategie-Bewertung über mehrere Wochen',
      'Detailliertere Statistik-Karten',
    ],
  );

  static const premium = ProductPlan(
    edition: AppEdition.future,
    title: 'Premium',
    shortDescription: 'Vollausbau mit Expertenmodellen, Export und Komfortfunktionen.',
    audience: 'Für Power-User, die maximale Transparenz, Backups und Expertenmodelle möchten.',
    included: [
      'Expertenmodelle und Strategievergleich',
      'Export Center und Wiederherstellung',
      'Premium-Regelprofile',
      'Erweiterte System- und Analyseoptionen',
    ],
    planned: [
      'Cloud-/Geräte-Sync vorbereitet',
      'Komfortfunktionen für Backups und Reports',
      'Premium-Auswertungsberichte',
    ],
  );

  static const all = [normal, pro, premium];

  static ProductPlan fromEdition(AppEdition edition) {
    switch (edition) {
      case AppEdition.free:
        return normal;
      case AppEdition.pro:
        return pro;
      case AppEdition.future:
        return premium;
    }
  }
}
