/// Modellwerte fuer Lotto Mind AI.
///
/// WICHTIG: Diese Werte sind bewusst als stabile App-Modellwerte definiert.
/// Offizielle LOTTO-Quoten aendern sich je Ziehung und werden hier nicht live
/// abgefragt. Fuer echte Auszahlung immer die offizielle Quotenliste pruefen.
class LottoWinValueModel {
  const LottoWinValueModel._();

  static const double stakePerLottoRow = 1.20;
  static const double spiel77Stake = 2.50;
  static const double super6Stake = 1.25;

  /// Stabile Modellwerte je Gewinnklasse Lotto 6aus49.
  /// GK 1 = 6 + Superzahl, GK 9 = 2 + Superzahl.
  static double lottoPrizeEuro(int? prizeClassNumber) {
    switch (prizeClassNumber) {
      case 1:
        return 8000000;
      case 2:
        return 1000000;
      case 3:
        return 12000;
      case 4:
        return 4000;
      case 5:
        return 200;
      case 6:
        return 50;
      case 7:
        return 25;
      case 8:
        return 12;
      case 9:
        return 6;
      default:
        return 0;
    }
  }

  static double spiel77PrizeEuro(int matchedSuffixDigits) {
    switch (matchedSuffixDigits) {
      case 7:
        return 1777777;
      case 6:
        return 77777;
      case 5:
        return 7777;
      case 4:
        return 777;
      case 3:
        return 77;
      case 2:
        return 17;
      case 1:
        return 5;
      default:
        return 0;
    }
  }

  static double super6PrizeEuro(int matchedSuffixDigits) {
    switch (matchedSuffixDigits) {
      case 6:
        return 100000;
      case 5:
        return 6666;
      case 4:
        return 666;
      case 3:
        return 66;
      case 2:
        return 6;
      case 1:
        return 2.50;
      default:
        return 0;
    }
  }

  static double netEuro({required double prize, required double stake}) => prize - stake;

  /// ROI in Prozent: 100% bedeutet Einsatz verdoppelt, -100% Totalverlust.
  static double roiPercent({required double prize, required double stake}) {
    if (stake <= 0) return prize > 0 ? 999.0 : 0.0;
    return ((prize - stake) / stake) * 100.0;
  }

  static String roiLabel({required double prize, required double stake}) {
    final roi = roiPercent(prize: prize, stake: stake);
    final prefix = roi > 0 ? '+' : '';
    return '$prefix${roi.toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  static String performanceLabel({required double prize, required double stake}) {
    final roi = roiPercent(prize: prize, stake: stake);
    if (prize <= 0) return 'Kein Gewinn';
    if (roi >= 250) return 'Sehr stark';
    if (roi >= 100) return 'Stark';
    if (roi >= 0) return 'Positiv';
    return 'Treffer ohne Kostendeckung';
  }

  static String efficiencyLabel({required int rows, required double stake, required double prize}) {
    if (rows <= 0) return 'Keine Reihen';
    final roi = roiPercent(prize: prize, stake: stake);
    if (roi >= 100) return 'Hohe Effizienz';
    if (roi >= 0) return 'Kostendeckend';
    if (prize > 0) return 'Teilgewinn';
    return 'Nicht getroffen';
  }

  static String formatEuro(double value) {
    final rounded = (value * 100).round() / 100;
    final fixed = rounded.toStringAsFixed(2).replaceAll('.', ',');
    final parts = fixed.split(',');
    final whole = parts[0];
    final decimals = parts[1];
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()},$decimals €';
  }

  static String formatSignedEuro(double value) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix${formatEuro(value)}';
  }
}
