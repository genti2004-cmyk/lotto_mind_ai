import '../../generator/domain/lotto_tip.dart';
import 'draw_result.dart';
import 'tip_check_result.dart';

class DrawCheckerService {
  TipCheckResult checkTipAgainstDraw(
      LottoTip tip,
      DrawResult draw,
      ) {
    final matched = tip.numbers.where(draw.numbers.contains).toList()..sort();

    return TipCheckResult(
      tip: tip,
      draw: draw,
      matchedNumbers: matched,
    );
  }

  List<TipCheckResult> checkAllTipsAgainstDraw(
      List<LottoTip> tips,
      DrawResult draw,
      ) {
    return tips
        .map((tip) => checkTipAgainstDraw(tip, draw))
        .toList()
      ..sort((a, b) => b.hitCount.compareTo(a.hitCount));
  }
}