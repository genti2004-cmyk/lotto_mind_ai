class PriceBreakdown {
  const PriceBreakdown({
    required this.baseFieldCount,
    required this.additionalFieldCount,
    required this.totalFieldCount,
    required this.pricePerField,
    required this.totalPrice,
    required this.basePrice,
    required this.additionalPrice,
    this.note,
  });

  final int baseFieldCount;
  final int additionalFieldCount;
  final int totalFieldCount;

  final double pricePerField;
  final double totalPrice;
  final double basePrice;
  final double additionalPrice;

  final String? note;

  String get totalPriceLabel => '${totalPrice.toStringAsFixed(2)} €';
}