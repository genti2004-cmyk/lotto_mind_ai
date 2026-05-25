/// Eindeutiger Ziehungstyp für Lotto 6aus49.
///
/// Diese Trennung ist wichtig, damit Mittwoch-Tipps nicht versehentlich gegen
/// Samstag-Ziehungen ausgewertet werden und umgekehrt.
enum DrawType {
  wednesday,
  saturday,
  unknown,
}

extension DrawTypeX on DrawType {
  String get label {
    switch (this) {
      case DrawType.wednesday:
        return 'Mittwoch';
      case DrawType.saturday:
        return 'Samstag';
      case DrawType.unknown:
        return 'Unbekannt';
    }
  }

  static DrawType fromDate(DateTime date) {
    if (date.weekday == DateTime.wednesday) return DrawType.wednesday;
    if (date.weekday == DateTime.saturday) return DrawType.saturday;
    return DrawType.unknown;
  }
}
