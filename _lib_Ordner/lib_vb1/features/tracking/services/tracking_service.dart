import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../draws/domain/draw_result.dart';
import '../../winnings/domain/lotto_win_value_model.dart';
import '../domain/tracked_tip.dart';

class TrackingStrategySummary {
  final TrackedTipType type;
  final int tipCount;
  final int checkCount;
  final double stake;
  final double prize;
  final int bestHits;
  final int winRows;

  const TrackingStrategySummary({
    required this.type,
    required this.tipCount,
    required this.checkCount,
    required this.stake,
    required this.prize,
    required this.bestHits,
    required this.winRows,
  });

  double get netValue => prize - stake;
  double get roiPercent => LottoWinValueModel.roiPercent(prize: prize, stake: stake);
  String get roiLabel => LottoWinValueModel.roiLabel(prize: prize, stake: stake);
  String get performanceLabel => LottoWinValueModel.performanceLabel(prize: prize, stake: stake);
}

class TrackingService {
  static const String boxName = 'tracking_pro_entries';

  Box<dynamic>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    if (!Hive.isBoxOpen(boxName)) {
      try {
        _box = await Hive.openBox<dynamic>(boxName);
        return;
      } on ArgumentError catch (error) {
        final message = error.toString();
        if (!message.contains('path') && !message.contains('Must not be null')) {
          rethrow;
        }

        await Hive.initFlutter();
        _box = await Hive.openBox<dynamic>(boxName);
        return;
      }
    }

    _box = Hive.box<dynamic>(boxName);
  }

  Future<List<TrackedTip>> loadTips() async {
    await init();
    final values = _box!.values;
    final tips = <TrackedTip>[];

    for (final value in values) {
      if (value is Map) {
        tips.add(TrackedTip.fromMap(value));
      }
    }

    tips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tips;
  }

  Future<void> saveTip(TrackedTip tip) async {
    await init();
    await _box!.put(tip.id, tip.toMap());
  }

  Future<void> saveTips(List<TrackedTip> tips) async {
    await init();
    for (final tip in tips) {
      await _box!.put(tip.id, tip.toMap());
    }
  }

  Future<void> deleteTip(String id) async {
    await init();
    await _box!.delete(id);
  }

  Future<void> clearChecks(String id) async {
    await init();
    final raw = _box!.get(id);
    if (raw is! Map) return;
    final tip = TrackedTip.fromMap(raw).copyWith(checks: const []);
    await _box!.put(id, tip.toMap());
  }

  TrackedTip createTip({
    required String title,
    required TrackedTipType type,
    required List<int> baseNumbers,
    required List<List<int>> rows,
    int? superNumber,
    String? spiel77,
    String? super6,
    double? stakePerDraw,
    String note = '',
  }) {
    final cleanBase = _cleanNumbers(baseNumbers, allowLength: null);
    final cleanRows = rows
        .map((row) => _cleanNumbers(row, allowLength: 6))
        .where((row) => row.length == 6)
        .toList();

    final normalizedRows = cleanRows.isNotEmpty
        ? cleanRows
        : cleanBase.length == 6
        ? [cleanBase]
        : <List<int>>[];

    final effectiveStake = stakePerDraw ??
        (normalizedRows.length * LottoWinValueModel.stakePerLottoRow) +
            (spiel77 == null ? 0 : LottoWinValueModel.spiel77Stake) +
            (super6 == null ? 0 : LottoWinValueModel.super6Stake);

    return TrackedTip(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? type.label : title.trim(),
      type: type,
      createdAt: DateTime.now(),
      baseNumbers: cleanBase,
      rows: normalizedRows,
      superNumber: superNumber,
      spiel77: spiel77,
      super6: super6,
      stakePerDraw: effectiveStake,
      note: note,
    );
  }

  TrackedTip evaluateAndAppend({
    required TrackedTip tip,
    required DrawResult draw,
  }) {
    final check = evaluate(tip: tip, draw: draw);
    final checks = List<TrackedTipCheck>.from(tip.checks);
    final existingIndex = checks.indexWhere((item) => item.drawId == check.drawId);

    if (existingIndex >= 0) {
      checks[existingIndex] = check;
    } else {
      checks.insert(0, check);
    }

    checks.sort((a, b) => b.drawDate.compareTo(a.drawDate));
    return tip.copyWith(checks: checks);
  }

  TrackedTip evaluateAgainstDraws({
    required TrackedTip tip,
    required List<DrawResult> draws,
    int? limit,
  }) {
    final safeDraws = List<DrawResult>.from(draws)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
    final selected = limit == null ? safeDraws : safeDraws.take(limit).toList();

    var current = tip;
    for (final draw in selected) {
      current = evaluateAndAppend(tip: current, draw: draw);
    }
    return current;
  }

  List<TrackedTip> evaluateAllAgainstDraws({
    required List<TrackedTip> tips,
    required List<DrawResult> draws,
    int? limit,
  }) {
    return tips
        .map(
          (tip) => evaluateAgainstDraws(
        tip: tip,
        draws: draws,
        limit: limit,
      ),
    )
        .toList();
  }

  List<TrackingStrategySummary> buildStrategySummaries(List<TrackedTip> tips) {
    final map = <TrackedTipType, List<TrackedTip>>{};
    for (final tip in tips) {
      map.putIfAbsent(tip.type, () => <TrackedTip>[]).add(tip);
    }

    final result = <TrackingStrategySummary>[];
    for (final entry in map.entries) {
      final groupedTips = entry.value;
      final checks = groupedTips.expand((tip) => tip.checks).toList();
      final stake = groupedTips.fold<double>(0, (sum, tip) => sum + tip.totalStake);
      final prize = groupedTips.fold<double>(0, (sum, tip) => sum + tip.totalPrize);
      final bestHits = checks.fold<int>(0, (best, check) => check.bestHits > best ? check.bestHits : best);
      final winRows = checks.fold<int>(0, (sum, check) => sum + check.winningRows);

      result.add(
        TrackingStrategySummary(
          type: entry.key,
          tipCount: groupedTips.length,
          checkCount: checks.length,
          stake: stake,
          prize: prize,
          bestHits: bestHits,
          winRows: winRows,
        ),
      );
    }

    result.sort((a, b) => b.roiPercent.compareTo(a.roiPercent));
    return result;
  }

  TrackedTipCheck evaluate({
    required TrackedTip tip,
    required DrawResult draw,
  }) {
    final drawSet = draw.numbers.toSet();
    final distribution = <int, int>{0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    var bestHits = 0;
    List<int> bestRow = const [];
    int? bestWinClass;
    var winningRows = 0;
    var prize = 0.0;

    for (final row in tip.rows) {
      final hits = row.where(drawSet.contains).length;
      distribution[hits] = (distribution[hits] ?? 0) + 1;
      final hasSuperNumber = tip.superNumber != null && draw.superNumber != null && tip.superNumber == draw.superNumber;
      final winClass = _lottoWinClass(hits: hits, superNumberHit: hasSuperNumber);
      final rowPrize = LottoWinValueModel.lottoPrizeEuro(winClass);

      if (rowPrize > 0) winningRows++;
      prize += rowPrize;

      final currentBestClass = bestWinClass ?? 99;
      if (hits > bestHits || (winClass != null && winClass < currentBestClass)) {
        bestHits = hits;
        bestRow = List<int>.from(row)..sort();
        bestWinClass = winClass;
      }
    }

    if (tip.spiel77 != null && draw.spiel77 != null) {
      prize += LottoWinValueModel.spiel77PrizeEuro(
        _matchingSuffixLength(tip.spiel77!, draw.spiel77!),
      );
    }

    if (tip.super6 != null && draw.super6 != null) {
      prize += LottoWinValueModel.super6PrizeEuro(
        _matchingSuffixLength(tip.super6!, draw.super6!),
      );
    }

    final stake = tip.stakePerDraw;
    final roi = LottoWinValueModel.roiPercent(prize: prize, stake: stake);

    return TrackedTipCheck(
      drawId: draw.id,
      drawDate: draw.drawDate,
      drawNumbers: List<int>.from(draw.numbers)..sort(),
      drawSuperNumber: draw.superNumber,
      bestHits: bestHits,
      bestWinClass: bestWinClass,
      winningRows: winningRows,
      hitDistribution: distribution,
      stake: stake,
      prize: prize,
      roiPercent: roi,
      bestRow: bestRow,
    );
  }

  int? _lottoWinClass({required int hits, required bool superNumberHit}) {
    if (hits == 6 && superNumberHit) return 1;
    if (hits == 6) return 2;
    if (hits == 5 && superNumberHit) return 3;
    if (hits == 5) return 4;
    if (hits == 4 && superNumberHit) return 5;
    if (hits == 4) return 6;
    if (hits == 3 && superNumberHit) return 7;
    if (hits == 3) return 8;
    if (hits == 2 && superNumberHit) return 9;
    return null;
  }

  int _matchingSuffixLength(String a, String b) {
    var count = 0;
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 1; i <= minLength; i++) {
      if (a[a.length - i] == b[b.length - i]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  List<int> _cleanNumbers(List<int> numbers, {required int? allowLength}) {
    final clean = numbers.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
    if (allowLength == null || clean.length <= allowLength) return clean;
    return clean.take(allowLength).toList()..sort();
  }
}
