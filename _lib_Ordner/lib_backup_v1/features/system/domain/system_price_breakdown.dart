class SystemPriceBreakdown {
  final double lotto;
  final double spiel77;
  final double super6;
  final int drawCount;
  final double processingFee;
  final double total;

  const SystemPriceBreakdown({
    required this.lotto,
    required this.spiel77,
    required this.super6,
    this.drawCount = 1,
    required this.processingFee,
    required this.total,
  });

  double get subtotalPerDraw => lotto + spiel77 + super6;
}