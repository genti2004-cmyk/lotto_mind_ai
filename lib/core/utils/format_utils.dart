class AppFormatUtils {
  const AppFormatUtils._();

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  static String dateShort(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.';
  }

  static String dateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${date(value)} • $hour:$minute';
  }

  static String decimal(num value, {int fractionDigits = 1}) {
    return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
  }

  static String euro(double value) {
    return '${decimal(value, fractionDigits: 2)} €';
  }

  static String signedEuro(double value) {
    final prefix = value >= 0 ? '+' : '-';
    return '$prefix${euro(value.abs())}';
  }

  static String percent(double value, {int fractionDigits = 1}) {
    return '${decimal(value, fractionDigits: fractionDigits)} %';
  }

  static String signedPercent(double value, {int fractionDigits = 1}) {
    final prefix = value >= 0 ? '+' : '-';
    return '$prefix${percent(value.abs(), fractionDigits: fractionDigits)}';
  }
}
