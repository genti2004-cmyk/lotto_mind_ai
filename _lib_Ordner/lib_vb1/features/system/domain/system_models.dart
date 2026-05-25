enum FullSystemType {
  fs007,
  fs008,
  fs009,
  fs010,
}

extension FullSystemTypeX on FullSystemType {
  int get selectedCount {
    switch (this) {
      case FullSystemType.fs007:
        return 7;
      case FullSystemType.fs008:
        return 8;
      case FullSystemType.fs009:
        return 9;
      case FullSystemType.fs010:
        return 10;
    }
  }

  String get label {
    switch (this) {
      case FullSystemType.fs007:
        return 'Vollsystem 007';
      case FullSystemType.fs008:
        return 'Vollsystem 008';
      case FullSystemType.fs009:
        return 'Vollsystem 009';
      case FullSystemType.fs010:
        return 'Vollsystem 010';
    }
  }

  String get title => label;

  String get subtitle {
    switch (this) {
      case FullSystemType.fs007:
        return '7 Zahlen, 7 Tippfelder, kompakter Einstieg.';
      case FullSystemType.fs008:
        return '8 Zahlen, 28 Tippfelder, gute Balance aus Abdeckung und Einsatz.';
      case FullSystemType.fs009:
        return '9 Zahlen, 84 Tippfelder, deutlich breitere Systemabdeckung.';
      case FullSystemType.fs010:
        return '10 Zahlen, 210 Tippfelder, maximale Abdeckung im Final-Pro-Bereich.';
    }
  }
}

class VewPreset {
  final String code;
  final String name;
  final int stammzahlen;
  final int reihen;
  final String hinweis;
  final int? guaranteeHits;

  const VewPreset({
    required this.code,
    required this.name,
    required this.stammzahlen,
    required this.reihen,
    required this.hinweis,
    this.guaranteeHits,
  });

  int get selectedCount => stammzahlen;
}
