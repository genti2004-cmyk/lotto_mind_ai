import '../../draws/domain/draw_type.dart';
import 'generator_strategy.dart';

class LottoTip {
  final String id;
  final DateTime createdAt;
  final List<int> numbers;
  final int? superNumber;
  final String source;
  final GeneratorStrategy strategy;
  final DrawType targetDrawType;
  final DateTime? targetDrawDate;
  final bool isFavorite;

  LottoTip({
    required this.id,
    required this.createdAt,
    required this.numbers,
    required this.source,
    GeneratorStrategy? strategy,
    this.superNumber,
    this.targetDrawType = DrawType.unknown,
    this.targetDrawDate,
    this.isFavorite = false,
  }) : strategy = strategy ?? GeneratorStrategyX.fromSource(source);

  LottoTip copyWith({
    String? id,
    DateTime? createdAt,
    List<int>? numbers,
    int? superNumber,
    bool clearSuperNumber = false,
    String? source,
    GeneratorStrategy? strategy,
    DrawType? targetDrawType,
    DateTime? targetDrawDate,
    bool clearTargetDrawDate = false,
    bool? isFavorite,
  }) {
    return LottoTip(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      numbers: numbers ?? this.numbers,
      superNumber: clearSuperNumber ? null : (superNumber ?? this.superNumber),
      source: source ?? this.source,
      strategy: strategy ?? this.strategy,
      targetDrawType: targetDrawType ?? this.targetDrawType,
      targetDrawDate: clearTargetDrawDate ? null : (targetDrawDate ?? this.targetDrawDate),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }



  String get targetLabel {
    final typeLabel = targetDrawType.label;
    final date = targetDrawDate;
    if (targetDrawType == DrawType.unknown && date == null) {
      return 'Zielziehung offen';
    }
    if (date == null) return 'Ziel: $typeLabel';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return 'Ziel: $typeLabel, $day.$month.$year';
  }

  String get strategyLabel => strategy.label;

  static DrawType _drawTypeFromRaw(dynamic raw) {
    final text = raw?.toString() ?? '';
    return DrawType.values.firstWhere(
      (value) => value.name == text,
      orElse: () => DrawType.unknown,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'numbers': numbers,
      'superNumber': superNumber,
      'source': source,
      'strategy': strategy.name,
      'targetDrawType': targetDrawType.name,
      'targetDrawDate': targetDrawDate?.toIso8601String(),
      'isFavorite': isFavorite,
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
      strategy: GeneratorStrategyX.fromName(map['strategy']?.toString()) == GeneratorStrategy.unknown
          ? GeneratorStrategyX.fromSource(map['source']?.toString())
          : GeneratorStrategyX.fromName(map['strategy']?.toString()),
      targetDrawType: _drawTypeFromRaw(map['targetDrawType']),
      targetDrawDate: DateTime.tryParse(map['targetDrawDate']?.toString() ?? ''),
      isFavorite: map['isFavorite'] == true,
    );
  }
}
