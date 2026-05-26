import '../../draws/domain/draw_type.dart';
import '../../generator/domain/lotto_tip.dart';
import '../../generator/domain/generator_strategy.dart';

/// Central helper for saved-tip persistence and duplicate handling.
///
/// This service deliberately contains no UI state and no Hive dependency. The
/// AppState still owns when data is loaded/saved, while this class owns how
/// saved tips are parsed, normalized and updated.
class SavedTipService {
  const SavedTipService();

  List<LottoTip> parseTips(dynamic raw) {
    final tips = <LottoTip>[];
    if (raw is! List) return tips;

    for (final item in raw) {
      if (item is Map) {
        try {
          tips.add(LottoTip.fromMap(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Beschädigte Einträge überspringen, damit die App weiter startet.
        }
      }
    }

    return tips;
  }

  List<Map<String, dynamic>> toStorage(List<LottoTip> tips) {
    return tips.map((tip) => tip.toMap()).toList();
  }

  List<int>? normalizeNumbers(List<int> numbers) {
    final normalized = List<int>.from(numbers)
      ..removeWhere((number) => number < 1 || number > 49)
      ..sort();
    return normalized.length == 6 ? normalized : null;
  }

  int? normalizeSuperNumber(int? superNumber) {
    return superNumber != null && superNumber >= 0 && superNumber <= 9
        ? superNumber
        : null;
  }

  bool sameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool sameNullableDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == null && b == null;
    return sameCalendarDate(a, b);
  }

  bool containsDuplicate(
    List<LottoTip> tips, {
    required List<int> numbers,
    required int? superNumber,
    required DrawType targetDrawType,
    required DateTime? targetDrawDate,
    GeneratorStrategy? strategy,
  }) {
    final normalizedNumbers = normalizeNumbers(numbers);
    if (normalizedNumbers == null) return false;
    final key = normalizedNumbers.join('-');

    return tips.any((tip) {
      final tipNumbers = List<int>.from(tip.numbers)..sort();
      return tipNumbers.join('-') == key &&
          tip.superNumber == superNumber &&
          tip.targetDrawType == targetDrawType &&
          sameNullableDate(tip.targetDrawDate, targetDrawDate);
    });
  }

  LottoTip? createTipFromNumbers({
    required List<int> numbers,
    required String source,
    GeneratorStrategy? strategy,
    required DrawType targetDrawType,
    required DateTime? targetDrawDate,
    int? superNumber,
    String? id,
    DateTime? createdAt,
  }) {
    final normalizedNumbers = normalizeNumbers(numbers);
    if (normalizedNumbers == null) return null;

    return LottoTip(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: createdAt ?? DateTime.now(),
      numbers: normalizedNumbers,
      superNumber: normalizeSuperNumber(superNumber),
      source: source,
      strategy: strategy ?? GeneratorStrategyX.fromSource(source),
      targetDrawType: targetDrawType,
      targetDrawDate: targetDrawDate,
    );
  }

  int addSystemRows({
    required List<LottoTip> tips,
    required List<List<int>> rows,
    required String source,
    GeneratorStrategy? strategy,
    required DrawType targetDrawType,
    DateTime? targetDrawDate,
  }) {
    int added = 0;
    final now = DateTime.now();

    for (int i = 0; i < rows.length; i++) {
      final normalized = normalizeNumbers(rows[i]);
      if (normalized == null) continue;

      if (containsDuplicate(
        tips,
        numbers: normalized,
        superNumber: null,
        targetDrawType: targetDrawType,
        targetDrawDate: targetDrawDate,
      )) {
        continue;
      }

      tips.add(
        LottoTip(
          id: '${now.microsecondsSinceEpoch}_system_$i',
          createdAt: DateTime.now(),
          numbers: normalized,
          superNumber: null,
          source: source,
          strategy: strategy ?? GeneratorStrategy.system,
          targetDrawType: targetDrawType,
          targetDrawDate: targetDrawDate,
        ),
      );
      added++;
    }

    return added;
  }

  bool toggleFavorite(List<LottoTip> tips, String id) {
    final index = tips.indexWhere((tip) => tip.id == id);
    if (index == -1) return false;

    final current = tips[index];
    tips[index] = current.copyWith(isFavorite: !current.isFavorite);
    return true;
  }

  bool removeById(List<LottoTip> tips, String id) {
    final before = tips.length;
    tips.removeWhere((tip) => tip.id == id);
    return tips.length != before;
  }
}
