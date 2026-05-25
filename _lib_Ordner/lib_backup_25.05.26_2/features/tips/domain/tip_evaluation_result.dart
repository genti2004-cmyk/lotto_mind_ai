import '../../draws/domain/draw_result.dart';
import '../../winnings/domain/lotto_win_value_model.dart';

enum LottoPlayKind {
  normal,
  fullSystem,
  vewSystem,
}

extension LottoPlayKindX on LottoPlayKind {
  String get label {
    switch (this) {
      case LottoPlayKind.normal:
        return 'Normal';
      case LottoPlayKind.fullSystem:
        return 'Vollsystem';
      case LottoPlayKind.vewSystem:
        return 'VEW';
    }
  }
}

class LottoPrizeClass {
  final int? classNumber;
  final String label;
  final bool isWin;

  const LottoPrizeClass._({
    required this.classNumber,
    required this.label,
    required this.isWin,
  });

  const LottoPrizeClass.noWin()
      : this._(
    classNumber: null,
    label: 'Kein Gewinn',
    isWin: false,
  );

  const LottoPrizeClass.win({
    required int classNumber,
    required String label,
  }) : this._(
    classNumber: classNumber,
    label: label,
    isWin: true,
  );

  double get estimatedPrizeEuro => LottoWinValueModel.lottoPrizeEuro(classNumber);

  String get estimatedPrizeLabel => LottoWinValueModel.formatEuro(estimatedPrizeEuro);

  static LottoPrizeClass fromHits({
    required int hits,
    required bool superHit,
  }) {
    if (hits == 6 && superHit) {
      return const LottoPrizeClass.win(
        classNumber: 1,
        label: 'Gewinnklasse 1 · 6 Richtige + Superzahl',
      );
    }
    if (hits == 6) {
      return const LottoPrizeClass.win(
        classNumber: 2,
        label: 'Gewinnklasse 2 · 6 Richtige',
      );
    }
    if (hits == 5 && superHit) {
      return const LottoPrizeClass.win(
        classNumber: 3,
        label: 'Gewinnklasse 3 · 5 Richtige + Superzahl',
      );
    }
    if (hits == 5) {
      return const LottoPrizeClass.win(
        classNumber: 4,
        label: 'Gewinnklasse 4 · 5 Richtige',
      );
    }
    if (hits == 4 && superHit) {
      return const LottoPrizeClass.win(
        classNumber: 5,
        label: 'Gewinnklasse 5 · 4 Richtige + Superzahl',
      );
    }
    if (hits == 4) {
      return const LottoPrizeClass.win(
        classNumber: 6,
        label: 'Gewinnklasse 6 · 4 Richtige',
      );
    }
    if (hits == 3 && superHit) {
      return const LottoPrizeClass.win(
        classNumber: 7,
        label: 'Gewinnklasse 7 · 3 Richtige + Superzahl',
      );
    }
    if (hits == 3) {
      return const LottoPrizeClass.win(
        classNumber: 8,
        label: 'Gewinnklasse 8 · 3 Richtige',
      );
    }
    if (hits == 2 && superHit) {
      return const LottoPrizeClass.win(
        classNumber: 9,
        label: 'Gewinnklasse 9 · 2 Richtige + Superzahl',
      );
    }
    return const LottoPrizeClass.noWin();
  }
}

class AdditionalLotteryEvaluation {
  final String name;
  final String? tipNumber;
  final String? drawNumber;
  final bool played;
  final bool exactMatch;
  final int matchedSuffixDigits;

  const AdditionalLotteryEvaluation({
    required this.name,
    required this.tipNumber,
    required this.drawNumber,
    required this.played,
    required this.exactMatch,
    required this.matchedSuffixDigits,
  });

  bool get hasResult => drawNumber != null && drawNumber!.isNotEmpty;

  double get estimatedPrizeEuro {
    if (!played || !hasResult || matchedSuffixDigits <= 0) return 0;
    final normalizedName = name.toLowerCase();
    if (normalizedName.contains('spiel')) {
      return LottoWinValueModel.spiel77PrizeEuro(matchedSuffixDigits);
    }
    if (normalizedName.contains('super')) {
      return LottoWinValueModel.super6PrizeEuro(matchedSuffixDigits);
    }
    return 0;
  }

  String get estimatedPrizeLabel => LottoWinValueModel.formatEuro(estimatedPrizeEuro);

  String get label {
    if (!played) return '$name nicht gespielt';
    if (!hasResult) return '$name: Ziehungsnummer fehlt';
    if (exactMatch) return '$name: Volltreffer';
    if (matchedSuffixDigits > 0) {
      return '$name: $matchedSuffixDigits Endziffer(n) richtig';
    }
    return '$name: kein Treffer';
  }
}

class TipRowEvaluation {
  final int rowIndex;
  final List<int> numbers;
  final List<int> drawNumbers;
  final List<int> matchedNumbers;
  final int? tipSuperNumber;
  final int? drawSuperNumber;
  final LottoPrizeClass prizeClass;

  const TipRowEvaluation({
    required this.rowIndex,
    required this.numbers,
    required this.drawNumbers,
    required this.matchedNumbers,
    required this.tipSuperNumber,
    required this.drawSuperNumber,
    required this.prizeClass,
  });

  int get hits => matchedNumbers.length;
  int get hitCount => hits;

  bool get superHit {
    final tip = tipSuperNumber;
    final draw = drawSuperNumber;
    return tip != null && draw != null && tip == draw;
  }

  bool get isWin => prizeClass.isWin;

  double get estimatedPrizeEuro => prizeClass.estimatedPrizeEuro;

  String get estimatedPrizeLabel => prizeClass.estimatedPrizeLabel;

  String get hitLabel {
    final base = hits == 1 ? '1 Treffer' : '$hits Treffer';
    return superHit ? '$base + Superzahl' : base;
  }

  String get shortLabel => prizeClass.isWin ? prizeClass.label : hitLabel;
}

class TipEvaluationResult {
  final String id;
  final DateTime evaluatedAt;
  final LottoPlayKind playKind;
  final DrawResult draw;
  final List<int> baseNumbers;
  final int? superNumber;
  final List<TipRowEvaluation> rows;
  final AdditionalLotteryEvaluation spiel77;
  final AdditionalLotteryEvaluation super6;

  const TipEvaluationResult({
    required this.id,
    required this.evaluatedAt,
    required this.playKind,
    required this.draw,
    required this.baseNumbers,
    required this.superNumber,
    required this.rows,
    required this.spiel77,
    required this.super6,
  });

  int get totalRows => rows.length;

  List<TipRowEvaluation> get winningRows =>
      rows.where((row) => row.isWin).toList(growable: false);

  bool get hasLottoWin => winningRows.isNotEmpty;

  bool get hasAdditionalWin => spiel77.estimatedPrizeEuro > 0 || super6.estimatedPrizeEuro > 0;

  bool get hasAnyWin => hasLottoWin || hasAdditionalWin;

  double get lottoEstimatedPrizeEuro => rows.fold<double>(
    0,
        (sum, row) => sum + row.estimatedPrizeEuro,
  );

  double get additionalEstimatedPrizeEuro =>
      spiel77.estimatedPrizeEuro + super6.estimatedPrizeEuro;

  double get totalEstimatedPrizeEuro =>
      lottoEstimatedPrizeEuro + additionalEstimatedPrizeEuro;

  double get estimatedStakeEuro =>
      totalRows * LottoWinValueModel.stakePerLottoRow +
          (spiel77.played ? LottoWinValueModel.spiel77Stake : 0) +
          (super6.played ? LottoWinValueModel.super6Stake : 0);

  double get estimatedNetEuro => totalEstimatedPrizeEuro - estimatedStakeEuro;

  String get totalEstimatedPrizeLabel =>
      LottoWinValueModel.formatEuro(totalEstimatedPrizeEuro);

  String get estimatedStakeLabel => LottoWinValueModel.formatEuro(estimatedStakeEuro);

  String get estimatedNetLabel => LottoWinValueModel.formatSignedEuro(estimatedNetEuro);

  TipRowEvaluation? get bestRow {
    if (rows.isEmpty) return null;
    final sorted = List<TipRowEvaluation>.from(rows)
      ..sort((a, b) {
        final aClass = a.prizeClass.classNumber ?? 99;
        final bClass = b.prizeClass.classNumber ?? 99;
        final classCompare = aClass.compareTo(bClass);
        if (classCompare != 0) return classCompare;
        final hitCompare = b.hits.compareTo(a.hits);
        if (hitCompare != 0) return hitCompare;
        if (a.superHit != b.superHit) return a.superHit ? -1 : 1;
        return a.rowIndex.compareTo(b.rowIndex);
      });
    return sorted.first;
  }

  int get bestHitCount => bestRow?.hits ?? 0;

  String get summaryLabel {
    final best = bestRow;
    if (best == null) return '${playKind.label}: keine Reihen';
    final prefix = totalRows == 1
        ? playKind.label
        : '${playKind.label} · $totalRows Reihen';
    if (best.isWin) return '$prefix · Beste Reihe: ${best.prizeClass.label} · ${best.estimatedPrizeLabel}';
    return '$prefix · Beste Reihe: ${best.hitLabel}';
  }
}
