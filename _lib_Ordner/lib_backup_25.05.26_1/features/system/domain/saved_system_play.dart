import 'package:lotto_mind_ai/features/winnings/domain/lotto_win_value_model.dart';

class SavedSystemPlay {
  const SavedSystemPlay({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.numbers,
    required this.rows,
    required this.pricePerRow,
    required this.superNumber,
    required this.losnummer,
    required this.spiel77,
    required this.super6,
    this.lastCheckedDrawId,
    this.lastCheckedAt,
    this.bestHits,
    this.winningRows,
    this.spiel77Matches,
    this.super6Matches,
    this.estimatedPrizeEuro,
    this.estimatedStakeEuro,
  });

  final String id;
  final DateTime createdAt;

  /// normal / full / vew
  final String type;

  /// Chosen number pool. Normal = 6 numbers, Full/VEW = 6-12 numbers.
  final List<int> numbers;

  /// Expanded rows that are checked against a draw.
  final List<List<int>> rows;

  final double pricePerRow;

  /// Superzahl is derived from the last digit of [losnummer].
  final int superNumber;

  /// Seven-digit ticket number used for Spiel 77. Super 6 = last six digits.
  final String losnummer;
  final String spiel77;
  final String super6;

  final String? lastCheckedDrawId;
  final DateTime? lastCheckedAt;
  final int? bestHits;
  final int? winningRows;
  final int? spiel77Matches;
  final int? super6Matches;
  final double? estimatedPrizeEuro;
  final double? estimatedStakeEuro;

  int get rowCount => rows.length;
  double get totalPrice => rowCount * pricePerRow;
  double get estimatedNetEuro => (estimatedPrizeEuro ?? 0) - (estimatedStakeEuro ?? totalPrice);
  double get estimatedRoiPercent => LottoWinValueModel.roiPercent(
    prize: estimatedPrizeEuro ?? 0,
    stake: estimatedStakeEuro ?? totalPrice,
  );
  String get estimatedRoiLabel => LottoWinValueModel.roiLabel(
    prize: estimatedPrizeEuro ?? 0,
    stake: estimatedStakeEuro ?? totalPrice,
  );
  String get estimatedPerformanceLabel => LottoWinValueModel.performanceLabel(
    prize: estimatedPrizeEuro ?? 0,
    stake: estimatedStakeEuro ?? totalPrice,
  );

  String get typeLabel {
    switch (type) {
      case 'normal':
        return 'Normalschein';
      case 'full':
        return 'Vollsystem';
      case 'vew':
        return 'VEW-System';
      default:
        return type;
    }
  }

  bool get hasEvaluation => lastCheckedAt != null;

  SavedSystemPlay copyWith({
    String? lastCheckedDrawId,
    DateTime? lastCheckedAt,
    int? bestHits,
    int? winningRows,
    int? spiel77Matches,
    int? super6Matches,
    double? estimatedPrizeEuro,
    double? estimatedStakeEuro,
  }) {
    return SavedSystemPlay(
      id: id,
      createdAt: createdAt,
      type: type,
      numbers: List<int>.from(numbers)..sort(),
      rows: rows.map((row) => List<int>.from(row)..sort()).toList(),
      pricePerRow: pricePerRow,
      superNumber: superNumber,
      losnummer: losnummer,
      spiel77: spiel77,
      super6: super6,
      lastCheckedDrawId: lastCheckedDrawId ?? this.lastCheckedDrawId,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      bestHits: bestHits ?? this.bestHits,
      winningRows: winningRows ?? this.winningRows,
      spiel77Matches: spiel77Matches ?? this.spiel77Matches,
      super6Matches: super6Matches ?? this.super6Matches,
      estimatedPrizeEuro: estimatedPrizeEuro ?? this.estimatedPrizeEuro,
      estimatedStakeEuro: estimatedStakeEuro ?? this.estimatedStakeEuro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'numbers': numbers,
      'rows': rows,
      'pricePerRow': pricePerRow,
      'superNumber': superNumber,
      'losnummer': losnummer,
      'spiel77': spiel77,
      'super6': super6,
      'lastCheckedDrawId': lastCheckedDrawId,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'bestHits': bestHits,
      'winningRows': winningRows,
      'spiel77Matches': spiel77Matches,
      'super6Matches': super6Matches,
      'estimatedPrizeEuro': estimatedPrizeEuro,
      'estimatedStakeEuro': estimatedStakeEuro,
    };
  }

  factory SavedSystemPlay.fromMap(Map<dynamic, dynamic> map) {
    List<int> parseInts(dynamic value) {
      final normalized = (value as List? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 1 && e <= 49)
          .toSet()
          .toList()
        ..sort();
      return normalized;
    }

    List<List<int>> parseRows(dynamic value) {
      return (value as List? ?? const [])
          .map((row) => parseInts(row))
          .where((row) => row.length == 6)
          .toList();
    }

    int? parseNullableInt(dynamic value) {
      return int.tryParse(value?.toString() ?? '');
    }

    double? parseNullableDouble(dynamic value) {
      return double.tryParse(value?.toString() ?? '');
    }

    String digits(String value, int length) {
      final raw = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (raw.isEmpty) return ''.padLeft(length, '0');
      if (raw.length >= length) return raw.substring(raw.length - length);
      return raw.padLeft(length, '0');
    }

    final rawLosnummer = map['losnummer']?.toString() ?? map['spiel77']?.toString() ?? '';
    final losnummer = digits(rawLosnummer, 7);
    final spiel77 = digits(map['spiel77']?.toString() ?? losnummer, 7);
    final super6 = digits(map['super6']?.toString() ?? losnummer.substring(1), 6);
    final superNumber = int.tryParse(
      map['superNumber']?.toString() ??
          (losnummer.isEmpty ? '0' : losnummer.substring(losnummer.length - 1)),
    ) ??
        0;

    return SavedSystemPlay(
      id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      type: map['type']?.toString() ?? 'normal',
      numbers: parseInts(map['numbers']),
      rows: parseRows(map['rows']),
      pricePerRow: double.tryParse(map['pricePerRow']?.toString() ?? '') ?? 1.20,
      superNumber: superNumber.clamp(0, 9).toInt(),
      losnummer: losnummer,
      spiel77: spiel77,
      super6: super6,
      lastCheckedDrawId: map['lastCheckedDrawId']?.toString(),
      lastCheckedAt: DateTime.tryParse(map['lastCheckedAt']?.toString() ?? ''),
      bestHits: parseNullableInt(map['bestHits']),
      winningRows: parseNullableInt(map['winningRows']),
      spiel77Matches: parseNullableInt(map['spiel77Matches']),
      super6Matches: parseNullableInt(map['super6Matches']),
      estimatedPrizeEuro: parseNullableDouble(map['estimatedPrizeEuro']),
      estimatedStakeEuro: parseNullableDouble(map['estimatedStakeEuro']),
    );
  }
}
