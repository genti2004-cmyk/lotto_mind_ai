enum TrackedTipType {
  normal,
  ai,
  fullSystem,
  vew,
  smartVew,
  custom,
}

extension TrackedTipTypeLabel on TrackedTipType {
  String get label {
    switch (this) {
      case TrackedTipType.normal:
        return 'Normal';
      case TrackedTipType.ai:
        return 'AI';
      case TrackedTipType.fullSystem:
        return 'Vollsystem';
      case TrackedTipType.vew:
        return 'Intervall';
      case TrackedTipType.smartVew:
        return 'Smart Intervall';
      case TrackedTipType.custom:
        return 'Eigener Tipp';
    }
  }
}

class TrackedTip {
  final String id;
  final String title;
  final TrackedTipType type;
  final DateTime createdAt;
  final List<int> baseNumbers;
  final List<List<int>> rows;
  final int? superNumber;
  final String? spiel77;
  final String? super6;
  final double stakePerDraw;
  final String note;
  final List<TrackedTipCheck> checks;

  const TrackedTip({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.baseNumbers,
    required this.rows,
    this.superNumber,
    this.spiel77,
    this.super6,
    required this.stakePerDraw,
    this.note = '',
    this.checks = const [],
  });

  int get rowCount => rows.length;
  double get totalStake => checks.fold(0.0, (sum, check) => sum + check.stake);
  double get totalPrize => checks.fold(0.0, (sum, check) => sum + check.prize);
  double get netValue => totalPrize - totalStake;

  double get roiPercent {
    if (totalStake <= 0) return totalPrize > 0 ? 999.0 : 0.0;
    return ((totalPrize - totalStake) / totalStake) * 100.0;
  }

  TrackedTip copyWith({
    String? id,
    String? title,
    TrackedTipType? type,
    DateTime? createdAt,
    List<int>? baseNumbers,
    List<List<int>>? rows,
    int? superNumber,
    bool clearSuperNumber = false,
    String? spiel77,
    bool clearSpiel77 = false,
    String? super6,
    bool clearSuper6 = false,
    double? stakePerDraw,
    String? note,
    List<TrackedTipCheck>? checks,
  }) {
    return TrackedTip(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      baseNumbers: baseNumbers ?? this.baseNumbers,
      rows: rows ?? this.rows,
      superNumber: clearSuperNumber ? null : (superNumber ?? this.superNumber),
      spiel77: clearSpiel77 ? null : (spiel77 ?? this.spiel77),
      super6: clearSuper6 ? null : (super6 ?? this.super6),
      stakePerDraw: stakePerDraw ?? this.stakePerDraw,
      note: note ?? this.note,
      checks: checks ?? this.checks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'baseNumbers': baseNumbers,
      'rows': rows,
      'superNumber': superNumber,
      'spiel77': spiel77,
      'super6': super6,
      'stakePerDraw': stakePerDraw,
      'note': note,
      'checks': checks.map((e) => e.toMap()).toList(),
    };
  }

  factory TrackedTip.fromMap(Map<dynamic, dynamic> map) {
    List<int> parseIntList(dynamic value) {
      return (value as List? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 1 && e <= 49)
          .toList()
        ..sort();
    }

    List<List<int>> parseRows(dynamic value) {
      return (value as List? ?? const [])
          .map((row) => parseIntList(row))
          .where((row) => row.length == 6)
          .toList();
    }

    final parsedType = TrackedTipType.values.firstWhere(
          (type) => type.name == map['type']?.toString(),
      orElse: () => TrackedTipType.custom,
    );

    final baseNumbers = parseIntList(map['baseNumbers']);
    final rows = parseRows(map['rows']);

    return TrackedTip(
      id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? 'Gespeicherter Tipp',
      type: parsedType,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      baseNumbers: baseNumbers,
      rows: rows.isEmpty && baseNumbers.length == 6 ? [baseNumbers] : rows,
      superNumber: int.tryParse(map['superNumber']?.toString() ?? ''),
      spiel77: _nullableText(map['spiel77']),
      super6: _nullableText(map['super6']),
      stakePerDraw: double.tryParse(map['stakePerDraw']?.toString() ?? '') ?? 0.0,
      note: map['note']?.toString() ?? '',
      checks: (map['checks'] as List? ?? const [])
          .whereType<Map>()
          .map(TrackedTipCheck.fromMap)
          .toList(),
    );
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class TrackedTipCheck {
  final String drawId;
  final DateTime drawDate;
  final List<int> drawNumbers;
  final int? drawSuperNumber;
  final int bestHits;
  final int? bestWinClass;
  final int winningRows;
  final Map<int, int> hitDistribution;
  final double stake;
  final double prize;
  final double roiPercent;
  final List<int> bestRow;

  const TrackedTipCheck({
    required this.drawId,
    required this.drawDate,
    required this.drawNumbers,
    this.drawSuperNumber,
    required this.bestHits,
    this.bestWinClass,
    required this.winningRows,
    required this.hitDistribution,
    required this.stake,
    required this.prize,
    required this.roiPercent,
    required this.bestRow,
  });

  double get netValue => prize - stake;

  Map<String, dynamic> toMap() {
    return {
      'drawId': drawId,
      'drawDate': drawDate.toIso8601String(),
      'drawNumbers': drawNumbers,
      'drawSuperNumber': drawSuperNumber,
      'bestHits': bestHits,
      'bestWinClass': bestWinClass,
      'winningRows': winningRows,
      'hitDistribution': hitDistribution.map((key, value) => MapEntry(key.toString(), value)),
      'stake': stake,
      'prize': prize,
      'roiPercent': roiPercent,
      'bestRow': bestRow,
    };
  }

  factory TrackedTipCheck.fromMap(Map<dynamic, dynamic> map) {
    List<int> parseIntList(dynamic value) {
      return (value as List? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList()
        ..sort();
    }

    final distribution = <int, int>{};
    final rawDistribution = map['hitDistribution'];
    if (rawDistribution is Map) {
      rawDistribution.forEach((key, value) {
        final parsedKey = int.tryParse(key.toString());
        final parsedValue = int.tryParse(value.toString()) ?? 0;
        if (parsedKey != null) distribution[parsedKey] = parsedValue;
      });
    }

    return TrackedTipCheck(
      drawId: map['drawId']?.toString() ?? '',
      drawDate: DateTime.tryParse(map['drawDate']?.toString() ?? '') ?? DateTime.now(),
      drawNumbers: parseIntList(map['drawNumbers']),
      drawSuperNumber: int.tryParse(map['drawSuperNumber']?.toString() ?? ''),
      bestHits: int.tryParse(map['bestHits']?.toString() ?? '') ?? 0,
      bestWinClass: int.tryParse(map['bestWinClass']?.toString() ?? ''),
      winningRows: int.tryParse(map['winningRows']?.toString() ?? '') ?? 0,
      hitDistribution: distribution,
      stake: double.tryParse(map['stake']?.toString() ?? '') ?? 0.0,
      prize: double.tryParse(map['prize']?.toString() ?? '') ?? 0.0,
      roiPercent: double.tryParse(map['roiPercent']?.toString() ?? '') ?? 0.0,
      bestRow: parseIntList(map['bestRow']),
    );
  }
}
