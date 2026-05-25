import '../../generator/domain/lotto_tip.dart';
import 'draw_result.dart';

class TipCheckResult {
  final LottoTip tip;
  final DrawResult draw;
  final List<int> matchedNumbers;

  const TipCheckResult({
    required this.tip,
    required this.draw,
    required this.matchedNumbers,
  });

  int get hitCount => matchedNumbers.length;

  String get hitLabel {
    switch (hitCount) {
      case 0:
        return '0 Treffer';
      case 1:
        return '1 Treffer';
      default:
        return '$hitCount Treffer';
    }
  }
}