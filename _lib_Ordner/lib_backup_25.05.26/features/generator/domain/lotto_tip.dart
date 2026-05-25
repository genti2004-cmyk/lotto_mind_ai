class LottoTip {
  final String id;
  final DateTime createdAt;
  final List<int> numbers;
  final int? superNumber;
  final String source;
  final bool isFavorite;

  const LottoTip({
    required this.id,
    required this.createdAt,
    required this.numbers,
    required this.source,
    this.superNumber,
    this.isFavorite = false,
  });

  LottoTip copyWith({
    String? id,
    DateTime? createdAt,
    List<int>? numbers,
    int? superNumber,
    bool clearSuperNumber = false,
    String? source,
    bool? isFavorite,
  }) {
    return LottoTip(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      numbers: numbers ?? this.numbers,
      superNumber: clearSuperNumber ? null : (superNumber ?? this.superNumber),
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
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
    );
  }
}
