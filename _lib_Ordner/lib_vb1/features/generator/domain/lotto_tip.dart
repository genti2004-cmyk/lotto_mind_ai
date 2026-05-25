import '../../draws/domain/draw_result.dart';

class LottoTip {
  final String id;
  final DateTime createdAt;
  final List<int> numbers;
  final int? superNumber;
  final String source;
  final bool isFavorite;
  final DrawType targetDrawType;
  final DateTime? targetDrawDate;
  final String strategyName;
  final int strategyVersion;

  LottoTip({
    required this.id,
    required this.createdAt,
    required this.numbers,
    required this.source,
    this.superNumber,
    this.isFavorite = false,
    this.targetDrawType = DrawType.unknown,
    this.targetDrawDate,
    String? strategyName,
    this.strategyVersion = 1,
  }) : strategyName = strategyName ?? source;

  LottoTip copyWith({
    String? id,
    DateTime? createdAt,
    List<int>? numbers,
    int? superNumber,
    bool clearSuperNumber = false,
    String? source,
    bool? isFavorite,
    DrawType? targetDrawType,
    DateTime? targetDrawDate,
    bool clearTargetDrawDate = false,
    String? strategyName,
    int? strategyVersion,
  }) {
    return LottoTip(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      numbers: numbers ?? this.numbers,
      superNumber: clearSuperNumber ? null : (superNumber ?? this.superNumber),
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
      targetDrawType: targetDrawType ?? this.targetDrawType,
      targetDrawDate: clearTargetDrawDate ? null : (targetDrawDate ?? this.targetDrawDate),
      strategyName: strategyName ?? this.strategyName,
      strategyVersion: strategyVersion ?? this.strategyVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'numbers': numbers,
      'superNumber': superNumber,
      'source': source,
      'isFavorite': isFavorite,
      'targetDrawType': targetDrawType.storageKey,
      'targetDrawDate': targetDrawDate?.toIso8601String(),
      'strategyName': strategyName,
      'strategyVersion': strategyVersion,
    };
  }

  factory LottoTip.fromMap(Map<String, dynamic> map) {
    return LottoTip(
      id: map['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      numbers: (map['numbers'] as List? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 1 && e <= 49)
          .toList()
        ..sort(),
      superNumber: () {
        final raw = int.tryParse(map['superNumber']?.toString() ?? '');
        if (raw == null || raw < 0 || raw > 9) return null;
        return raw;
      }(),
      source: map['source']?.toString() ?? 'manual',
      isFavorite: map['isFavorite'] == true,
      targetDrawType: drawTypeFromStorageKey(map['targetDrawType']?.toString()),
      targetDrawDate: DateTime.tryParse(map['targetDrawDate']?.toString() ?? ''),
      strategyName: map['strategyName']?.toString() ?? map['source']?.toString() ?? 'manual',
      strategyVersion: int.tryParse(map['strategyVersion']?.toString() ?? '') ?? 1,
    );
  }
}
