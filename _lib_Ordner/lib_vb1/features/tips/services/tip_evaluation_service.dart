import '../../draws/domain/draw_result.dart';
import '../../generator/domain/lotto_tip.dart';
import '../../system/domain/system_mode.dart';
import '../../system/domain/system_ticket.dart';
import '../domain/tip_evaluation_result.dart';

class TipEvaluationService {
  const TipEvaluationService();

  TipEvaluationResult evaluateNormalTip({
    required LottoTip tip,
    required DrawResult draw,
    String? spiel77TipNumber,
    String? super6TipNumber,
  }) {
    final numbers = _normalizeLottoNumbers(tip.numbers);
    final row = _evaluateRow(
      rowIndex: 1,
      numbers: numbers,
      draw: draw,
      tipSuperNumber: tip.superNumber,
    );

    return TipEvaluationResult(
      id: '${tip.id}_${draw.id}_${DateTime.now().millisecondsSinceEpoch}',
      evaluatedAt: DateTime.now(),
      playKind: LottoPlayKind.normal,
      draw: draw,
      baseNumbers: numbers,
      superNumber: tip.superNumber,
      rows: [row],
      spiel77: evaluateAdditionalLottery(
        name: 'Spiel 77',
        tipNumber: spiel77TipNumber,
        drawNumber: draw.spiel77,
        expectedLength: 7,
      ),
      super6: evaluateAdditionalLottery(
        name: 'Super 6',
        tipNumber: super6TipNumber,
        drawNumber: draw.super6,
        expectedLength: 6,
      ),
    );
  }

  TipEvaluationResult evaluateSystemTicket({
    required SystemTicket ticket,
    required DrawResult draw,
    String? spiel77TipNumber,
    String? super6TipNumber,
  }) {
    final kind = _kindFromSystemMode(ticket.mode);
    final rows = ticket.rows.isEmpty
        ? <List<int>>[_normalizeLottoNumbers(ticket.baseNumbers)]
        : ticket.rows.map(_normalizeLottoNumbers).toList(growable: false);

    final evaluatedRows = <TipRowEvaluation>[];
    for (var i = 0; i < rows.length; i++) {
      evaluatedRows.add(
        _evaluateRow(
          rowIndex: i + 1,
          numbers: rows[i],
          draw: draw,
          tipSuperNumber: ticket.superNumber,
        ),
      );
    }

    return TipEvaluationResult(
      id: '${ticket.mode.name}_${draw.id}_${DateTime.now().millisecondsSinceEpoch}',
      evaluatedAt: DateTime.now(),
      playKind: kind,
      draw: draw,
      baseNumbers: _normalizeLottoNumbers(ticket.baseNumbers),
      superNumber: ticket.superNumber,
      rows: evaluatedRows,
      spiel77: evaluateAdditionalLottery(
        name: 'Spiel 77',
        tipNumber: ticket.withSpiel77 ? spiel77TipNumber : null,
        drawNumber: draw.spiel77,
        expectedLength: 7,
      ),
      super6: evaluateAdditionalLottery(
        name: 'Super 6',
        tipNumber: ticket.withSuper6 ? super6TipNumber : null,
        drawNumber: draw.super6,
        expectedLength: 6,
      ),
    );
  }

  List<TipEvaluationResult> evaluateNormalTipsAgainstDraw({
    required List<LottoTip> tips,
    required DrawResult draw,
  }) {
    final results = tips
        .map((tip) => evaluateNormalTip(tip: tip, draw: draw))
        .toList(growable: false);

    return _sortResults(results);
  }

  AdditionalLotteryEvaluation evaluateAdditionalLottery({
    required String name,
    required String? tipNumber,
    required String? drawNumber,
    required int expectedLength,
  }) {
    final tip = _digitsOnly(tipNumber);
    final draw = _digitsOnly(drawNumber);
    final played = tip.isNotEmpty;

    if (!played) {
      return AdditionalLotteryEvaluation(
        name: name,
        tipNumber: null,
        drawNumber: draw.isEmpty ? null : draw,
        played: false,
        exactMatch: false,
        matchedSuffixDigits: 0,
      );
    }

    final normalizedTip = tip.padLeft(expectedLength, '0');
    final normalizedDraw = draw.isEmpty ? null : draw.padLeft(expectedLength, '0');
    final exact = normalizedDraw != null && normalizedTip == normalizedDraw;

    return AdditionalLotteryEvaluation(
      name: name,
      tipNumber: normalizedTip,
      drawNumber: normalizedDraw,
      played: true,
      exactMatch: exact,
      matchedSuffixDigits: normalizedDraw == null
          ? 0
          : _matchingSuffixLength(normalizedTip, normalizedDraw),
    );
  }

  TipRowEvaluation _evaluateRow({
    required int rowIndex,
    required List<int> numbers,
    required DrawResult draw,
    required int? tipSuperNumber,
  }) {
    final normalizedNumbers = _normalizeLottoNumbers(numbers);
    final normalizedDraw = _normalizeLottoNumbers(draw.numbers);
    final matched = normalizedNumbers
        .where((number) => normalizedDraw.contains(number))
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

  LottoPlayKind _kindFromSystemMode(SystemMode mode) {
    switch (mode) {
      case SystemMode.normal:
        return LottoPlayKind.normal;
      case SystemMode.full:
        return LottoPlayKind.fullSystem;
      case SystemMode.vew:
        return LottoPlayKind.vewSystem;
    }
  }

  List<TipEvaluationResult> _sortResults(List<TipEvaluationResult> results) {
    final sorted = List<TipEvaluationResult>.from(results)
      ..sort((a, b) {
        final aBestClass = a.bestRow?.prizeClass.classNumber ?? 99;
        final bBestClass = b.bestRow?.prizeClass.classNumber ?? 99;
        final classCompare = aBestClass.compareTo(bBestClass);
        if (classCompare != 0) return classCompare;
        final hitCompare = b.bestHitCount.compareTo(a.bestHitCount);
        if (hitCompare != 0) return hitCompare;
        return b.evaluatedAt.compareTo(a.evaluatedAt);
      });
    return sorted;
  }

  List<int> _normalizeLottoNumbers(List<int> input) {
    final normalized = input
        .where((number) => number >= 1 && number <= 49)
        .toSet()
        .toList()
      ..sort();
    return normalized;
  }

  String _digitsOnly(String? value) {
    return (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  }

  int _matchingSuffixLength(String a, String b) {
    final max = a.length < b.length ? a.length : b.length;
    var count = 0;
    for (var i = 1; i <= max; i++) {
      if (a[a.length - i] != b[b.length - i]) break;
      count++;
    }
    return count;
  }
}
