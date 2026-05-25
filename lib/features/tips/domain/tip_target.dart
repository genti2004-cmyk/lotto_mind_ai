import '../../draws/domain/draw_type.dart';

/// Zielziehung eines Tipps.
///
/// Diese Klasse ist die Grundlage für die spätere saubere Auswertung:
/// Ein Tipp muss wissen, ob er für Mittwoch, Samstag oder ein konkretes Datum
/// gedacht war.
class TipTarget {
  final DrawType drawType;
  final DateTime? drawDate;

  const TipTarget({
    required this.drawType,
    this.drawDate,
  });

  String get label {
    final date = drawDate;
    if (date == null) return drawType.label;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '${drawType.label}, $day.$month.$year';
  }

  Map<String, dynamic> toMap() {
    return {
      'drawType': drawType.name,
      'drawDate': drawDate?.toIso8601String(),
    };
  }

  factory TipTarget.fromMap(Map<dynamic, dynamic>? map) {
    final rawType = map?['drawType']?.toString();
    final drawType = DrawType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => DrawType.unknown,
    );

    return TipTarget(
      drawType: drawType,
      drawDate: DateTime.tryParse(map?['drawDate']?.toString() ?? ''),
    );
  }
}
