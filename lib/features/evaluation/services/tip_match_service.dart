import '../../draws/domain/draw_result.dart';
import '../../tips/domain/tip_evaluation_result.dart';

/// Zentrale Treffer- und Zusatzspiel-Berechnung.
///
/// Diese Klasse entlastet LottoAppState und hält die fachliche Logik
/// für Lottozahlen, Superzahl, Spiel 77 und SUPER 6 an einer Stelle.
class TipMatchService {
  const TipMatchService();

  TipRowEvaluation buildRowEvaluation({
    required int rowIndex,
    required List<int> numbers,
    required DrawResult draw,
    required int? tipSuperNumber,
  }) {
    final normalizedNumbers = normalizeLottoRow(numbers);
    final normalizedDraw = normalizeLottoRow(draw.numbers);
    final matched = normalizedNumbers
        .where((number) => normalizedDraw.contains(number))
        .toSet()
        .toList()
      ..sort();

    final drawSuper = draw.superNumber;
    final superHit = tipSuperNumber != null &&
        drawSuper != null &&
        tipSuperNumber == drawSuper;

    return TipRowEvaluation(
      rowIndex: rowIndex,
      numbers: normalizedNumbers,
      drawNumbers: normalizedDraw,
      matchedNumbers: matched,
      tipSuperNumber: tipSuperNumber,
      drawSuperNumber: drawSuper,
      prizeClass: LottoPrizeClass.fromHits(
        hits: matched.length,
        superHit: superHit,
      ),
    );
  }

  AdditionalLotteryEvaluation evaluateAdditionalLottery({
    required String name,
    required String? tipNumber,
    required String? drawNumber,
    required int expectedLength,
  }) {
    final tip = digitsOnly(tipNumber);
    final draw = digitsOnly(drawNumber);
    final played = tip.isNotEmpty;

    if (!played) {
      return AdditionalLotteryEvaluation(
        name: name,
        tipNumber: null,
        drawNumber: draw.isEmpty ? null : draw.padLeft(expectedLength, '0'),
        played: false,
        exactMatch: false,
        matchedSuffixDigits: 0,
      );
    }

    final normalizedTip = tip.padLeft(expectedLength, '0');
    final normalizedDraw = draw.isEmpty ? null : draw.padLeft(expectedLength, '0');

    return AdditionalLotteryEvaluation(
      name: name,
      tipNumber: normalizedTip,
      drawNumber: normalizedDraw,
      played: true,
      exactMatch: normalizedDraw != null && normalizedTip == normalizedDraw,
      matchedSuffixDigits: normalizedDraw == null
          ? 0
          : matchingSuffixDigits(normalizedTip, normalizedDraw),
    );
  }

  List<TipEvaluationResult> sortResults(List<TipEvaluationResult> results) {
    final sorted = List<TipEvaluationResult>.from(results)
      ..sort((a, b) {
        final aClass = a.bestRow?.prizeClass.classNumber ?? 99;
        final bClass = b.bestRow?.prizeClass.classNumber ?? 99;
        final classCompare = aClass.compareTo(bClass);
        if (classCompare != 0) return classCompare;
        final hitCompare = b.bestHitCount.compareTo(a.bestHitCount);
        if (hitCompare != 0) return hitCompare;
        return b.evaluatedAt.compareTo(a.evaluatedAt);
      });
    return sorted;
  }

  List<int> normalizeLottoRow(List<int> input) {
    final normalized = input
        .where((number) => number >= 1 && number <= 49)
        .toSet()
        .toList()
      ..sort();
    return normalized;
  }

  String digitsOnly(String? value) {
    return (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  }

  int matchingSuffixDigits(String a, String b) {
    final max = a.length < b.length ? a.length : b.length;
    var count = 0;
    for (var i = 1; i <= max; i++) {
      if (a[a.length - i] != b[b.length - i]) break;
      count++;
    }
    return count;
  }
}
