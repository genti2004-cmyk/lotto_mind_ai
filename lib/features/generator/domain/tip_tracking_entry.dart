import '../../draws/domain/draw_result.dart';
import '../../winnings/domain/lotto_win_value_model.dart';
import 'lotto_tip.dart';
import 'generator_strategy.dart';

class TipTrackingEntry {
  final String id;
  final String tipId;
  final String drawId;
  final DateTime checkedAt;
  final DateTime drawDate;
  final List<int> tipNumbers;
  final List<int> drawNumbers;
  final List<int> matchedNumbers;
  final int? tipSuperNumber;
  final int? drawSuperNumber;
  final String tipSource;
  final GeneratorStrategy tipStrategy;

  const TipTrackingEntry({
    required this.id,
    required this.tipId,
    required this.drawId,
    required this.checkedAt,
    required this.drawDate,
    required this.tipNumbers,
    required this.drawNumbers,
    required this.matchedNumbers,
    required this.tipSuperNumber,
    required this.drawSuperNumber,
    required this.tipSource,
    this.tipStrategy = GeneratorStrategy.unknown,
  });

  int get hitCount => matchedNumbers.length;

  bool get superHit {
    final tip = tipSuperNumber;
    final draw = drawSuperNumber;
    return tip != null && draw != null && tip == draw;
  }

  String get hitLabel {
    final main = hitCount == 1 ? '1 Treffer' : '$hitCount Treffer';
    return superHit ? '$main + Superzahl' : main;
  }

  bool get isWinRelevant => hitCount >= 3 || (hitCount == 2 && superHit);

  int? get prizeClassNumber {
    if (hitCount == 6 && superHit) return 1;
    if (hitCount == 6) return 2;
    if (hitCount == 5 && superHit) return 3;
    if (hitCount == 5) return 4;
    if (hitCount == 4 && superHit) return 5;
    if (hitCount == 4) return 6;
    if (hitCount == 3 && superHit) return 7;
    if (hitCount == 3) return 8;
    if (hitCount == 2 && superHit) return 9;
    return null;
  }

  double get estimatedPrizeEuro =>
      LottoWinValueModel.lottoPrizeEuro(prizeClassNumber);

  String get estimatedPrizeLabel =>
      LottoWinValueModel.formatEuro(estimatedPrizeEuro);

  String get prizeClassLabel {
    switch (prizeClassNumber) {
      case 1:
        return 'GK 1 · 6 Richtige + Superzahl';
      case 2:
        return 'GK 2 · 6 Richtige';
      case 3:
        return 'GK 3 · 5 Richtige + Superzahl';
      case 4:
        return 'GK 4 · 5 Richtige';
      case 5:
        return 'GK 5 · 4 Richtige + Superzahl';
      case 6:
        return 'GK 6 · 4 Richtige';
      case 7:
        return 'GK 7 · 3 Richtige + Superzahl';
      case 8:
        return 'GK 8 · 3 Richtige';
      case 9:
        return 'GK 9 · 2 Richtige + Superzahl';
      default:
        return 'Keine Gewinnklasse';
    }
  }

  String get drawDateLabel {
    final d = drawDate;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  factory TipTrackingEntry.fromTipAndDraw({
    required LottoTip tip,
    required DrawResult draw,
    required List<int> matchedNumbers,
  }) {
    final normalizedTip = List<int>.from(tip.numbers)..sort();
    final normalizedDraw = List<int>.from(draw.numbers)..sort();
    final normalizedMatched = List<int>.from(matchedNumbers)..sort();
    return TipTrackingEntry(
      id: '${tip.id}_${draw.id}',
      tipId: tip.id,
      drawId: draw.id,
      checkedAt: DateTime.now(),
      drawDate: draw.drawDate,
      tipNumbers: normalizedTip,
      drawNumbers: normalizedDraw,
      matchedNumbers: normalizedMatched,
      tipSuperNumber: tip.superNumber,
      drawSuperNumber: draw.superNumber,
      tipSource: tip.source,
      tipStrategy: tip.strategy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipId': tipId,
      'drawId': drawId,
      'checkedAt': checkedAt.toIso8601String(),
      'drawDate': drawDate.toIso8601String(),
      'tipNumbers': tipNumbers,
      'drawNumbers': drawNumbers,
      'matchedNumbers': matchedNumbers,
      'tipSuperNumber': tipSuperNumber,
      'drawSuperNumber': drawSuperNumber,
      'tipSource': tipSource,
      'tipStrategy': tipStrategy.name,
    };
  }

  factory TipTrackingEntry.fromMap(Map<dynamic, dynamic> map) {
    List<int> parseNumbers(dynamic value) {
      return (value as List? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList()
        ..sort();
    }

    int? parseNullableInt(dynamic value) {
      final parsed = int.tryParse(value?.toString() ?? '');
      return parsed;
    }

    return TipTrackingEntry(
      id: map['id']?.toString() ?? '',
      tipId: map['tipId']?.toString() ?? '',
      drawId: map['drawId']?.toString() ?? '',
      checkedAt: DateTime.tryParse(map['checkedAt']?.toString() ?? '') ?? DateTime.now(),
      drawDate: DateTime.tryParse(map['drawDate']?.toString() ?? '') ?? DateTime.now(),
      tipNumbers: parseNumbers(map['tipNumbers']),
      drawNumbers: parseNumbers(map['drawNumbers']),
      matchedNumbers: parseNumbers(map['matchedNumbers']),
      tipSuperNumber: parseNullableInt(map['tipSuperNumber']),
      drawSuperNumber: parseNullableInt(map['drawSuperNumber']),
      tipSource: map['tipSource']?.toString() ?? 'manual',
      tipStrategy: GeneratorStrategyX.fromName(map['tipStrategy']?.toString()) == GeneratorStrategy.unknown
          ? GeneratorStrategyX.fromSource(map['tipSource']?.toString())
          : GeneratorStrategyX.fromName(map['tipStrategy']?.toString()),
    );
  }
}
