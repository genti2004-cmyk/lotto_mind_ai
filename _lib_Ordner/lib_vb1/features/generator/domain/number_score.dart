class NumberScore {
  const NumberScore({
    required this.number,
    required this.frequencyScore,
    required this.recencyScore,
    required this.trendScore,
    required this.reboundScore,
    required this.balanceScore,
    required this.pairScore,
    required this.totalScore,
  });

  final int number;
  final double frequencyScore;
  final double recencyScore;
  final double trendScore;
  final double reboundScore;
  final double balanceScore;
  final double pairScore;
  final double totalScore;

  String get shortReason {
    final reasons = <String>[];
    if (frequencyScore >= 0.65) reasons.add('häufig');
    if (trendScore >= 0.60) reasons.add('Trend');
    if (reboundScore >= 0.55) reasons.add('Rebound');
    if (pairScore >= 0.45) reasons.add('Paarbindung');
    if (reasons.isEmpty) reasons.add('Ausgleich');
    return reasons.join(' + ');
  }
}
