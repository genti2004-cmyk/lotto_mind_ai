enum AppEdition {
  free,
  pro,
  future,
}

extension AppEditionX on AppEdition {
  String get key {
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
        return 'Free';
      case AppEdition.pro:
        return 'Pro';
      case AppEdition.future:
        return 'Future';
    }
  }

  String get subtitle {
    switch (this) {
      case AppEdition.free:
        return 'Basisfunktionen für den Alltag';
      case AppEdition.pro:
        return 'Erweiterte Analyse und stärkere Werkzeuge';
      case AppEdition.future:
        return 'Vollausbau mit Pro- und Zukunftsfunktionen';
    }
  }

  String get description {
    switch (this) {
      case AppEdition.free:
        return 'Basisfunktionen';
      case AppEdition.pro:
        return 'Erweiterte Analyse und Systeme';
      case AppEdition.future:
        return 'Alle freigeschalteten Zukunftsfunktionen';
    }
  }

  static AppEdition fromKey(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'pro':
        return AppEdition.pro;
      case 'future':
        return AppEdition.future;
      case 'free':
      default:
        return AppEdition.free;
    }
  }
}