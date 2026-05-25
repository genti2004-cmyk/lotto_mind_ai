import '../domain/draw_result.dart';

/// Kleine, reine Hilfsklasse fuer Ziehungsverlauf und Import-Merge.
///
/// Ziel: Der Provider bleibt fuer UI-State verantwortlich, diese Klasse fuer
/// Datumsschluessel, Bereinigung, Duplikate und Merge-Regeln.
class DrawHistoryService {
  const DrawHistoryService._();

  static String drawDateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static bool sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int mergeImportedDraws(
    List<DrawResult> target,
    List<DrawResult> importedDraws,
  ) {
    int inserted = 0;

    for (final imported in importedDraws) {
      final index = target.indexWhere(
        (draw) => sameDate(draw.drawDate, imported.drawDate),
      );

      if (index == -1) {
        target.add(imported);
        inserted++;
      } else {
        target[index] = mergeDrawMetadata(target[index], imported);
      }
    }

    normalizeDrawHistory(target);
    return inserted;
  }

  static void normalizeDrawHistory(List<DrawResult> draws) {
    final byDate = <String, DrawResult>{};

    for (final draw in draws) {
      final normalized = sanitizeDrawResult(draw);
      if (normalized == null) continue;

      final key = drawDateKey(normalized.drawDate);
      final current = byDate[key];
      byDate[key] = current == null
          ? normalized
          : mergeDrawMetadata(current, normalized);
    }

    draws
      ..clear()
      ..addAll(byDate.values);

    draws.sort((a, b) => b.drawDate.compareTo(a.drawDate));
  }

  static DrawResult? sanitizeDrawResult(DrawResult draw) {
    final numbers = sanitizeNumbers(draw.numbers);
    if (numbers.length != 6) return null;

    final drawDate = DateTime(
      draw.drawDate.year,
      draw.drawDate.month,
      draw.drawDate.day,
    );

    if (drawDate.weekday != DateTime.wednesday &&
        drawDate.weekday != DateTime.saturday) {
      return null;
    }

    final superNumber = draw.superNumber != null &&
            draw.superNumber! >= 0 &&
            draw.superNumber! <= 9
        ? draw.superNumber
        : null;

    return DrawResult(
      id: draw.id.isNotEmpty
          ? draw.id
          : '${drawDate.toIso8601String()}-${numbers.join('-')}',
      drawDate: drawDate,
      numbers: numbers,
      superNumber: superNumber,
      spiel77: normalizeFixedDigitText(draw.spiel77, 7),
      super6: normalizeFixedDigitText(draw.super6, 6),
    );
  }

  static DrawResult mergeDrawMetadata(DrawResult current, DrawResult incoming) {
    // Frische Import-Daten sind fuer dieses Datum massgeblich.
    // Wichtig: Wenn der Import KEINE Superzahl findet, darf eine frueher falsch
    // gespeicherte "6" nicht weiterleben. Deshalb wird Superzahl bewusst auch
    // auf null gesetzt. Spiel 77 / SUPER 6 bleiben dagegen erhalten, wenn die
    // neue Quelle sie nicht liefert.
    return current.copyWith(
      superNumber: incoming.superNumber,
      clearSuperNumber: incoming.superNumber == null,
      spiel77: incoming.spiel77 ?? current.spiel77,
      super6: incoming.super6 ?? current.super6,
    );
  }

  static DrawResult replaceManualDraw(DrawResult current, DrawResult incoming) {
    // Manuelle Eingabe ist eine bewusste Korrektur fuer dieses Datum.
    // Wenn das Superzahl-Feld leer bleibt, wird eine alte/falsche Superzahl
    // geloescht statt behalten. Spiel 77 / SUPER 6 bleiben erhalten, wenn leer.
    return DrawResult(
      id: current.id.isNotEmpty ? current.id : incoming.id,
      drawDate: DateTime(
        incoming.drawDate.year,
        incoming.drawDate.month,
        incoming.drawDate.day,
      ),
      numbers: sanitizeNumbers(incoming.numbers),
      superNumber: incoming.superNumber,
      spiel77: incoming.spiel77 ?? current.spiel77,
      super6: incoming.super6 ?? current.super6,
    );
  }

  static List<int> sanitizeNumbers(List<int> input) {
    final clean = input.where((e) => e >= 1 && e <= 49).toSet().toList()
      ..sort();
    return clean;
  }

  static String? normalizeFixedDigitText(String? value, int length) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != length) return null;
    return digits;
  }
}
