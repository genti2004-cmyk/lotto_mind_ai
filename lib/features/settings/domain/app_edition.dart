/// Produktstufe der App.
///
/// Hinweis zur Abwärtskompatibilität:
/// Die Enum-Werte `free` und `future` bleiben absichtlich erhalten, damit
/// bereits gespeicherte lokale Einstellungen und vorhandene Code-Stellen nicht
/// brechen. Im UI werden sie ab jetzt als `Normal` und `Premium` bezeichnet.
enum AppEdition {
  /// Öffentlich: Normal
  free,

  /// Öffentlich: Pro
  pro,

  /// Öffentlich: Premium
  future,
}

extension AppEditionX on AppEdition {
  bool get isNormal => this == AppEdition.free;
  bool get isPro => this == AppEdition.pro;
  bool get isPremium => this == AppEdition.future;

  String get key {
    switch (this) {
      case AppEdition.free:
        return 'normal';
      case AppEdition.pro:
        return 'pro';
      case AppEdition.future:
        return 'premium';
    }
  }

  /// Alte Keys bleiben lesbar, damit bestehende Installationen nicht kaputtgehen.
  String get legacyKey {
    switch (this) {
      case AppEdition.free:
        return 'free';
      case AppEdition.pro:
        return 'pro';
      case AppEdition.future:
        return 'future';
    }
  }

  String get label {
    switch (this) {
      case AppEdition.free:
        return 'Normal';
      case AppEdition.pro:
        return 'Pro';
      case AppEdition.future:
        return 'Premium';
    }
  }

  String get subtitle {
    switch (this) {
      case AppEdition.free:
        return 'Einfache Tipps, Ziehungen und Grundauswertung';
      case AppEdition.pro:
        return 'Erweiterte Analysen, Tracking und mehr Verlauf';
      case AppEdition.future:
        return 'Vollausbau mit Expertenmodellen, Export und Komfortfunktionen';
    }
  }

  String get description {
    switch (this) {
      case AppEdition.free:
        return 'Basisfunktionen für normale Nutzer';
      case AppEdition.pro:
        return 'Erweiterte Analyse- und Trackingfunktionen';
      case AppEdition.future:
        return 'Alle Premium- und Expertenfunktionen';
    }
  }

  static AppEdition fromKey(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'pro':
        return AppEdition.pro;
      case 'premium':
      case 'future':
        return AppEdition.future;
      case 'normal':
      case 'free':
      default:
        return AppEdition.free;
    }
  }
}
