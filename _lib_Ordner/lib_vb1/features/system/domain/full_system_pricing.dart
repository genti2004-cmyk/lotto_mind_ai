import 'system_models.dart';

class PriceBreakdown {
  const PriceBreakdown({
    required this.baseAmount,
    required this.spiel77Amount,
    required this.super6Amount,
    required this.drawCount,
    required this.processingFee,
  });

  final double baseAmount;
  final double spiel77Amount;
  final double super6Amount;
  final int drawCount;
  final double processingFee;

  double get subtotalPerDraw => baseAmount + spiel77Amount + super6Amount;
  double get totalWithoutProcessing => subtotalPerDraw * drawCount;
  double get total => totalWithoutProcessing + processingFee;
}

class LottoSystemPricing {
  const LottoSystemPricing._();

  static const double lottoRowPrice = 1.20;
  static const double spiel77Price = 2.50;
  static const double super6Price = 1.25;

  /// WestLotto published full-system base prices per draw.
  static const Map<FullSystemType, double> fullSystemBasePrices = {
    FullSystemType.fs007: 8.40,
    FullSystemType.fs008: 33.60,
    FullSystemType.fs009: 100.80,
    FullSystemType.fs010: 252.00,
  };

  static double normalBasePrice({required int rows}) {
    return rows * lottoRowPrice;
  }

  static PriceBreakdown normalBreakdown({
    required int rows,
    required bool withSpiel77,
    required bool withSuper6,
    required int drawCount,
    required double processingFee,
  }) {
    return PriceBreakdown(
      baseAmount: normalBasePrice(rows: rows),
      spiel77Amount: withSpiel77 ? spiel77Price : 0,
      super6Amount: withSuper6 ? super6Price : 0,
      drawCount: drawCount,
      processingFee: processingFee,
    );
  }

  static PriceBreakdown fullBreakdown({
    required FullSystemType system,
    required bool withSpiel77,
    required bool withSuper6,
    required int drawCount,
    required double processingFee,
  }) {
    return PriceBreakdown(
      baseAmount: fullSystemBasePrices[system] ?? 0,
      spiel77Amount: withSpiel77 ? spiel77Price : 0,
      super6Amount: withSuper6 ? super6Price : 0,
      drawCount: drawCount,
      processingFee: processingFee,
    );
  }

  static PriceBreakdown vewBreakdown({
    required int rows,
    required bool withSpiel77,
    required bool withSuper6,
    required int drawCount,
    required double processingFee,
  }) {
    return PriceBreakdown(
      baseAmount: rows * lottoRowPrice,
      spiel77Amount: withSpiel77 ? spiel77Price : 0,
      super6Amount: withSuper6 ? super6Price : 0,
      drawCount: drawCount,
      processingFee: processingFee,
    );
  }

  /// Simple default approximation for the German ticket handling fee.
  static double defaultProcessingFee({required int drawCount}) {
    if (drawCount <= 1) return 0.50;
    if (drawCount == 2) return 0.80;
    return 0.50 + (drawCount - 1) * 0.30;
  }
}

const List<VewPreset> defaultVewPresets = [
  VewPreset(
    code: 'Intervall-8/12',
    name: 'Intervall Kompakt',
    stammzahlen: 8,
    reihen: 12,
    hinweis: 'Schnelles kompaktes Teilsystem für 8 Stammzahlen.',
  ),
  VewPreset(
    code: 'Intervall-9/18',
    name: 'Intervall Balance',
    stammzahlen: 9,
    reihen: 18,
    hinweis: 'Gute Balance aus Budget und Abdeckung.',
  ),
  VewPreset(
    code: 'Intervall-10/24',
    name: 'Intervall Plus',
    stammzahlen: 10,
    reihen: 24,
    hinweis: 'Mehr Abdeckung bei kontrolliertem Einsatz.',
  ),
];
