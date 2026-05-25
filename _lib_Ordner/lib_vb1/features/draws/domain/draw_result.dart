enum DrawType {
  wednesday,
  saturday,
  unknown,
}

extension DrawTypeX on DrawType {
  String get label {
    switch (this) {
      case DrawType.wednesday:
        return 'Mittwoch';
      case DrawType.saturday:
        return 'Samstag';
      case DrawType.unknown:
        return 'Unbekannt';
    }
  }

  String get storageKey {
    switch (this) {
      case DrawType.wednesday:
        return 'wednesday';
      case DrawType.saturday:
        return 'saturday';
      case DrawType.unknown:
        return 'unknown';
    }
  }
}

DrawType drawTypeFromStorageKey(String? value) {
  switch (value) {
    case 'wednesday':
      return DrawType.wednesday;
    case 'saturday':
      return DrawType.saturday;
    default:
      return DrawType.unknown;
  }
}

DrawType drawTypeFromDate(DateTime date) {
  if (date.weekday == DateTime.wednesday) return DrawType.wednesday;
  if (date.weekday == DateTime.saturday) return DrawType.saturday;
  return DrawType.unknown;
}

class DrawResult {
  final String id;
  final DateTime drawDate;
  final List<int> numbers;
  final int? superNumber;
  final String? spiel77;
  final String? super6;
  final DrawType drawType;

  DrawResult({
    required this.id,
    required this.drawDate,
    required this.numbers,
    this.superNumber,
    this.spiel77,
    this.super6,
    DrawType? drawType,
  }) : drawType = drawType ?? drawTypeFromDate(drawDate);

  DrawResult copyWith({
    String? id,
    DateTime? drawDate,
    List<int>? numbers,
    int? superNumber,
    bool clearSuperNumber = false,
    int? additionalNumber,
    bool clearAdditionalNumber = false,
    String? spiel77,
    bool clearSpiel77 = false,
    String? super6,
    bool clearSuper6 = false,
    DrawType? drawType,
  }) {
    return DrawResult(
      id: id ?? this.id,
      drawDate: drawDate ?? this.drawDate,
      numbers: numbers ?? this.numbers,
      superNumber: clearSuperNumber ? null : (superNumber ?? this.superNumber),
      spiel77: clearSpiel77 ? null : (spiel77 ?? this.spiel77),
      super6: clearSuper6 ? null : (super6 ?? this.super6),
      drawType: drawType ?? this.drawType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drawDate': drawDate.toIso8601String(),
      'numbers': numbers,
      'superNumber': superNumber,
      'spiel77': spiel77,
      'super6': super6,
      'drawType': drawType.storageKey,
    };
  }

  factory DrawResult.fromMap(Map<dynamic, dynamic> map) {
    int? toNullableInt(dynamic value) {
      return int.tryParse(value?.toString() ?? '');
    }

    String? toNullableString(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return DrawResult(
      id: map['id']?.toString() ?? '',
      drawDate:
      DateTime.tryParse(map['drawDate']?.toString() ?? '') ?? DateTime.now(),
      numbers: (map['numbers'] as List? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList(),
      superNumber: toNullableInt(map['superNumber']),
      spiel77: toNullableString(map['spiel77']),
      super6: toNullableString(map['super6']),
      drawType: drawTypeFromStorageKey(map['drawType']?.toString()),
    );
  }
}
