import '../../draws/domain/draw_result.dart';
import '../../winnings/domain/lotto_win_value_model.dart';

class MethodWinEvaluationResult {
  final String label;
  final int rowCount;
  final int drawCount;
  final double stakePerRow;
  final double totalStake;
  final double totalModelPrize;
  final double netModel;
  final double roiPercent;
  final int hit2;
  final int hit3;
  final int hit4;
  final int hit5;
  final int hit6;
  final int superNumberHits;
  final int bestHitCount;
  final DateTime? bestDrawDate;
  final List<int> bestRow;

  const MethodWinEvaluationResult({
    required this.label,
    required this.rowCount,
    required this.drawCount,
    required this.stakePerRow,
    required this.totalStake,
    required this.totalModelPrize,
    required this.netModel,
    required this.roiPercent,
    required this.hit2,
    required this.hit3,
    required this.hit4,
    required this.hit5,
    required this.hit6,
    required this.superNumberHits,
    required this.bestHitCount,
    required this.bestDrawDate,
    required this.bestRow,
  });

  bool get hasData => rowCount > 0 && drawCount > 0;

  int get weightedHitScore {
    return hit2 + (hit3 * 4) + (hit4 * 18) + (hit5 * 120) + (hit6 * 1200);
  }

  String get ratingLabel {
    if (!hasData) return 'Keine Daten';
    if (roiPercent >= -25) return 'Sehr stark';
    if (roiPercent >= -55) return 'Stark';
    if (roiPercent >= -80) return 'Solide';
    return 'Schwach';
  }
}

class MethodWinEvaluationService {
  const MethodWinEvaluationService();

  MethodWinEvaluationResult evaluate({
    required String label,
    required List<List<int>> rows,
    required List<DrawResult> draws,
    double stakePerRow = LottoWinValueModel.stakePerLottoRow,
    int? ticketSuperNumber,
  }) {
    final cleanRows = rows
        .map(_cleanRow)
        .where((row) => row.length == 6)
        .toList(growable: false);

    final cleanDraws = draws
        .where((draw) => draw.numbers.where((n) => n >= 1 && n <= 49).toSet().length >= 6)
        .toList(growable: false);

    if (cleanRows.isEmpty || cleanDraws.isEmpty) {
      return MethodWinEvaluationResult(
        label: label,
        rowCount: cleanRows.length,
        drawCount: cleanDraws.length,
        stakePerRow: stakePerRow,
        totalStake: 0,
        totalModelPrize: 0,
        netModel: 0,
        roiPercent: 0,
        hit2: 0,
        hit3: 0,
        hit4: 0,
        hit5: 0,
        hit6: 0,
        superNumberHits: 0,
        bestHitCount: 0,
        bestDrawDate: null,
        bestRow: const [],
      );
    }

    var totalPrize = 0.0;
    var hit2 = 0;
    var hit3 = 0;
    var hit4 = 0;
    var hit5 = 0;
    var hit6 = 0;
    var superHits = 0;
    var bestHit = 0;
    DateTime? bestDate;
    var bestRow = <int>[];

    for (final draw in cleanDraws) {
      final drawNumbers = draw.numbers.where((n) => n >= 1 && n <= 49).toSet();
      final superHit = ticketSuperNumber != null && draw.superNumber != null && ticketSuperNumber == draw.superNumber;

      for (final row in cleanRows) {
        final hits = row.where(drawNumbers.contains).length;
        if (hits == 2) hit2++;
        if (hits == 3) hit3++;
        if (hits == 4) hit4++;
        if (hits == 5) hit5++;
        if (hits == 6) hit6++;
        if (superHit && hits >= 2) superHits++;

        final prizeClass = _lottoPrizeClass(hits: hits, superHit: superHit);
        totalPrize += LottoWinValueModel.lottoPrizeEuro(prizeClass);

        if (hits > bestHit) {
          bestHit = hits;
          bestDate = draw.drawDate;
          bestRow = List<int>.from(row);
        }
      }
    }

    final totalStake = cleanRows.length * cleanDraws.length * stakePerRow;
    final net = totalPrize - totalStake;
    final roi = totalStake <= 0 ? 0.0 : (net / totalStake) * 100;

    return MethodWinEvaluationResult(
      label: label,
      rowCount: cleanRows.length,
      drawCount: cleanDraws.length,
      stakePerRow: stakePerRow,
      totalStake: totalStake,
      totalModelPrize: totalPrize,
      netModel: net,
      roiPercent: roi,
      hit2: hit2,
      hit3: hit3,
      hit4: hit4,
      hit5: hit5,
      hit6: hit6,
      superNumberHits: superHits,
      bestHitCount: bestHit,
      bestDrawDate: bestDate,
      bestRow: bestRow,
    );
  }

  int? _lottoPrizeClass({required int hits, required bool superHit}) {
    if (hits >= 6) return superHit ? 1 : 2;
    if (hits == 5) return superHit ? 3 : 4;
    if (hits == 4) return superHit ? 5 : 6;
    if (hits == 3) return superHit ? 7 : 8;
    if (hits == 2 && superHit) return 9;
    return null;
  }

  List<int> _cleanRow(List<int> row) {
    final result = row.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
    return result;
  }
}
