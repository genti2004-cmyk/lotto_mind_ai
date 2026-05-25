import '../../draws/domain/draw_result.dart';

class CombinationPartnerScore {
  final int number;
  final int hits;
  final double score;

  const CombinationPartnerScore({
    required this.number,
    required this.hits,
    required this.score,
  });
}

class CombinationRankingResult {
  final List<int> baseNumbers;
  final List<CombinationPartnerScore> partners;
  final int matchedDrawCount;

  const CombinationRankingResult({
    required this.baseNumbers,
    required this.partners,
    required this.matchedDrawCount,
  });

  List<int> get bestPartners => partners.map((e) => e.number).toList();
  bool get isEmpty => partners.isEmpty;
}

class CombinationRankingService {
  const CombinationRankingService();

  CombinationRankingResult findBestPartners(
      List<DrawResult> draws, {
        required List<int> baseNumbers,
        int limit = 12,
      }) {
    final cleanBase = baseNumbers
        .where((n) => n >= 1 && n <= 49)
        .toSet()
        .toList()
      ..sort();

    if (draws.isEmpty || cleanBase.isEmpty) {
      return CombinationRankingResult(
        baseNumbers: cleanBase,
        partners: const [],
        matchedDrawCount: 0,
      );
    }

    final partnerFrequency = <int, int>{
      for (int number = 1; number <= 49; number++) number: 0,
    };

    int matchedDrawCount = 0;

    for (final draw in draws) {
      final numbers = draw.numbers
          .where((n) => n >= 1 && n <= 49)
          .toSet();

      final containsAllBase = cleanBase.every(numbers.contains);
      if (!containsAllBase) continue;

      matchedDrawCount++;

      for (final number in numbers) {
        if (!cleanBase.contains(number)) {
          partnerFrequency[number] = (partnerFrequency[number] ?? 0) + 1;
        }
      }
    }

    final partners = partnerFrequency.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
      return CombinationPartnerScore(
        number: entry.key,
        hits: entry.value,
        score: matchedDrawCount == 0 ? 0 : entry.value / matchedDrawCount,
      );
    }).toList()
      ..sort((a, b) {
        final byHits = b.hits.compareTo(a.hits);
        if (byHits != 0) return byHits;
        return a.number.compareTo(b.number);
      });

    return CombinationRankingResult(
      baseNumbers: cleanBase,
      partners: partners.take(limit).toList(),
      matchedDrawCount: matchedDrawCount,
    );
  }

  List<int> findBestPartnerNumbers(
      List<DrawResult> draws,
      int baseNumber, {
        int limit = 12,
      }) {
    return findBestPartners(
      draws,
      baseNumbers: [baseNumber],
      limit: limit,
    ).bestPartners;
  }
}
