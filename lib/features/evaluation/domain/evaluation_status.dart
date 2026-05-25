/// Status einer Tippauswertung.
///
/// Ziel: Nutzer sollen klar erkennen, ob ein Tipp schon ausgewertet werden kann
/// oder ob die passende Ziehung noch fehlt.
enum EvaluationStatus {
  waitingForDraw,
  ready,
  evaluated,
  skippedWrongDrawType,
  invalidLegacyTip,
}

extension EvaluationStatusX on EvaluationStatus {
  String get label {
    switch (this) {
      case EvaluationStatus.waitingForDraw:
        return 'Wartet auf Ziehung';
      case EvaluationStatus.ready:
        return 'Bereit zur Auswertung';
      case EvaluationStatus.evaluated:
        return 'Ausgewertet';
      case EvaluationStatus.skippedWrongDrawType:
        return 'Nicht passende Ziehung';
      case EvaluationStatus.invalidLegacyTip:
        return 'Alter Tipp ohne Zielziehung';
    }
  }
}
