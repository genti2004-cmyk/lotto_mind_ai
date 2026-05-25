class AnalysisRuleSet {
  final List<int> preferredNumbers;
  final List<int> excludedNumbers;
  final List<int> requiredNumbers;
  final List<int> allowedEndDigits;
  final List<int> blockedEndDigits;

  final int minEven;
  final int maxEven;
  final int minLowNumbers;
  final int maxLowNumbers;
  final int minSum;
  final int maxSum;

  final int maxSameEndDigitCount;
  final int minDistinctEndDigits;
  final int maxConsecutiveNumbers;
  final int minSpread;

  final int minGroup1to9;
  final int maxGroup1to9;
  final int minGroup10to19;
  final int maxGroup10to19;
  final int minGroup20to29;
  final int maxGroup20to29;
  final int minGroup30to39;
  final int maxGroup30to39;
  final int minGroup40to49;
  final int maxGroup40to49;

  final int maxRepeatFromLastDraw;
  final int maxRepeatFromLast3Draws;
  final int maxRepeatFromLast5Draws;

  final bool preferHotNumbers;
  final bool avoidHotNumbers;
  final bool preferColdNumbers;
  final bool avoidColdNumbers;
  final int hotNumberWindow;
  final int coldNumberWindow;
  final int maxHotNumbersInTip;
  final int maxColdNumbersInTip;

  final String analysisMode;

  const AnalysisRuleSet({
    required this.preferredNumbers,
    required this.excludedNumbers,
    required this.requiredNumbers,
    required this.allowedEndDigits,
    required this.blockedEndDigits,
    required this.minEven,
    required this.maxEven,
    required this.minLowNumbers,
    required this.maxLowNumbers,
    required this.minSum,
    required this.maxSum,
    required this.maxSameEndDigitCount,
    required this.minDistinctEndDigits,
    required this.maxConsecutiveNumbers,
    required this.minSpread,
    required this.minGroup1to9,
    required this.maxGroup1to9,
    required this.minGroup10to19,
    required this.maxGroup10to19,
    required this.minGroup20to29,
    required this.maxGroup20to29,
    required this.minGroup30to39,
    required this.maxGroup30to39,
    required this.minGroup40to49,
    required this.maxGroup40to49,
    required this.maxRepeatFromLastDraw,
    required this.maxRepeatFromLast3Draws,
    required this.maxRepeatFromLast5Draws,
    required this.preferHotNumbers,
    required this.avoidHotNumbers,
    required this.preferColdNumbers,
    required this.avoidColdNumbers,
    required this.hotNumberWindow,
    required this.coldNumberWindow,
    required this.maxHotNumbersInTip,
    required this.maxColdNumbersInTip,
    required this.analysisMode,
  });

  factory AnalysisRuleSet.initial() {
    return const AnalysisRuleSet(
      preferredNumbers: [],
      excludedNumbers: [],
      requiredNumbers: [],
      allowedEndDigits: [],
      blockedEndDigits: [],
      minEven: 2,
      maxEven: 4,
      minLowNumbers: 2,
      maxLowNumbers: 4,
      minSum: 100,
      maxSum: 200,
      maxSameEndDigitCount: 2,
      minDistinctEndDigits: 4,
      maxConsecutiveNumbers: 2,
      minSpread: 20,
      minGroup1to9: 0,
      maxGroup1to9: 3,
      minGroup10to19: 0,
      maxGroup10to19: 3,
      minGroup20to29: 0,
      maxGroup20to29: 3,
      minGroup30to39: 0,
      maxGroup30to39: 3,
      minGroup40to49: 0,
      maxGroup40to49: 3,
      maxRepeatFromLastDraw: 2,
      maxRepeatFromLast3Draws: 4,
      maxRepeatFromLast5Draws: 5,
      preferHotNumbers: false,
      avoidHotNumbers: false,
      preferColdNumbers: false,
      avoidColdNumbers: false,
      hotNumberWindow: 20,
      coldNumberWindow: 20,
      maxHotNumbersInTip: 4,
      maxColdNumbersInTip: 4,
      analysisMode: 'combined',
    );
  }

  AnalysisRuleSet copyWith({
    List<int>? preferredNumbers,
    List<int>? excludedNumbers,
    List<int>? requiredNumbers,
    List<int>? allowedEndDigits,
    List<int>? blockedEndDigits,
    int? minEven,
    int? maxEven,
    int? minLowNumbers,
    int? maxLowNumbers,
    int? minSum,
    int? maxSum,
    int? maxSameEndDigitCount,
    int? minDistinctEndDigits,
    int? maxConsecutiveNumbers,
    int? minSpread,
    int? minGroup1to9,
    int? maxGroup1to9,
    int? minGroup10to19,
    int? maxGroup10to19,
    int? minGroup20to29,
    int? maxGroup20to29,
    int? minGroup30to39,
    int? maxGroup30to39,
    int? minGroup40to49,
    int? maxGroup40to49,
    int? maxRepeatFromLastDraw,
    int? maxRepeatFromLast3Draws,
    int? maxRepeatFromLast5Draws,
    bool? preferHotNumbers,
    bool? avoidHotNumbers,
    bool? preferColdNumbers,
    bool? avoidColdNumbers,
    int? hotNumberWindow,
    int? coldNumberWindow,
    int? maxHotNumbersInTip,
    int? maxColdNumbersInTip,
    String? analysisMode,
  }) {
    return AnalysisRuleSet(
      preferredNumbers: preferredNumbers ?? this.preferredNumbers,
      excludedNumbers: excludedNumbers ?? this.excludedNumbers,
      requiredNumbers: requiredNumbers ?? this.requiredNumbers,
      allowedEndDigits: allowedEndDigits ?? this.allowedEndDigits,
      blockedEndDigits: blockedEndDigits ?? this.blockedEndDigits,
      minEven: minEven ?? this.minEven,
      maxEven: maxEven ?? this.maxEven,
      minLowNumbers: minLowNumbers ?? this.minLowNumbers,
      maxLowNumbers: maxLowNumbers ?? this.maxLowNumbers,
      minSum: minSum ?? this.minSum,
      maxSum: maxSum ?? this.maxSum,
      maxSameEndDigitCount:
      maxSameEndDigitCount ?? this.maxSameEndDigitCount,
      minDistinctEndDigits:
      minDistinctEndDigits ?? this.minDistinctEndDigits,
      maxConsecutiveNumbers:
      maxConsecutiveNumbers ?? this.maxConsecutiveNumbers,
      minSpread: minSpread ?? this.minSpread,
      minGroup1to9: minGroup1to9 ?? this.minGroup1to9,
      maxGroup1to9: maxGroup1to9 ?? this.maxGroup1to9,
      minGroup10to19: minGroup10to19 ?? this.minGroup10to19,
      maxGroup10to19: maxGroup10to19 ?? this.maxGroup10to19,
      minGroup20to29: minGroup20to29 ?? this.minGroup20to29,
      maxGroup20to29: maxGroup20to29 ?? this.maxGroup20to29,
      minGroup30to39: minGroup30to39 ?? this.minGroup30to39,
      maxGroup30to39: maxGroup30to39 ?? this.maxGroup30to39,
      minGroup40to49: minGroup40to49 ?? this.minGroup40to49,
      maxGroup40to49: maxGroup40to49 ?? this.maxGroup40to49,
      maxRepeatFromLastDraw:
      maxRepeatFromLastDraw ?? this.maxRepeatFromLastDraw,
      maxRepeatFromLast3Draws:
      maxRepeatFromLast3Draws ?? this.maxRepeatFromLast3Draws,
      maxRepeatFromLast5Draws:
      maxRepeatFromLast5Draws ?? this.maxRepeatFromLast5Draws,
      preferHotNumbers: preferHotNumbers ?? this.preferHotNumbers,
      avoidHotNumbers: avoidHotNumbers ?? this.avoidHotNumbers,
      preferColdNumbers: preferColdNumbers ?? this.preferColdNumbers,
      avoidColdNumbers: avoidColdNumbers ?? this.avoidColdNumbers,
      hotNumberWindow: hotNumberWindow ?? this.hotNumberWindow,
      coldNumberWindow: coldNumberWindow ?? this.coldNumberWindow,
      maxHotNumbersInTip: maxHotNumbersInTip ?? this.maxHotNumbersInTip,
      maxColdNumbersInTip: maxColdNumbersInTip ?? this.maxColdNumbersInTip,
      analysisMode: analysisMode ?? this.analysisMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredNumbers': preferredNumbers,
      'excludedNumbers': excludedNumbers,
      'requiredNumbers': requiredNumbers,
      'allowedEndDigits': allowedEndDigits,
      'blockedEndDigits': blockedEndDigits,
      'minEven': minEven,
      'maxEven': maxEven,
      'minLowNumbers': minLowNumbers,
      'maxLowNumbers': maxLowNumbers,
      'minSum': minSum,
      'maxSum': maxSum,
      'maxSameEndDigitCount': maxSameEndDigitCount,
      'minDistinctEndDigits': minDistinctEndDigits,
      'maxConsecutiveNumbers': maxConsecutiveNumbers,
      'minSpread': minSpread,
      'minGroup1to9': minGroup1to9,
      'maxGroup1to9': maxGroup1to9,
      'minGroup10to19': minGroup10to19,
      'maxGroup10to19': maxGroup10to19,
      'minGroup20to29': minGroup20to29,
      'maxGroup20to29': maxGroup20to29,
      'minGroup30to39': minGroup30to39,
      'maxGroup30to39': maxGroup30to39,
      'minGroup40to49': minGroup40to49,
      'maxGroup40to49': maxGroup40to49,
      'maxRepeatFromLastDraw': maxRepeatFromLastDraw,
      'maxRepeatFromLast3Draws': maxRepeatFromLast3Draws,
      'maxRepeatFromLast5Draws': maxRepeatFromLast5Draws,
      'preferHotNumbers': preferHotNumbers,
      'avoidHotNumbers': avoidHotNumbers,
      'preferColdNumbers': preferColdNumbers,
      'avoidColdNumbers': avoidColdNumbers,
      'hotNumberWindow': hotNumberWindow,
      'coldNumberWindow': coldNumberWindow,
      'maxHotNumbersInTip': maxHotNumbersInTip,
      'maxColdNumbersInTip': maxColdNumbersInTip,
      'analysisMode': analysisMode,
    };
  }

  factory AnalysisRuleSet.fromMap(Map<String, dynamic> map) {
    List<int> toIntList(dynamic value) {
      if (value is! List) return <int>[];
      return value
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 0)
          .toList();
    }

    int toInt(dynamic value, int fallback) =>
        int.tryParse(value?.toString() ?? '') ?? fallback;

    bool toBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      return fallback;
    }

    return AnalysisRuleSet(
      preferredNumbers: toIntList(map['preferredNumbers']),
      excludedNumbers: toIntList(map['excludedNumbers']),
      requiredNumbers: toIntList(map['requiredNumbers']),
      allowedEndDigits: toIntList(map['allowedEndDigits']),
      blockedEndDigits: toIntList(map['blockedEndDigits']),
      minEven: toInt(map['minEven'], 2),
      maxEven: toInt(map['maxEven'], 4),
      minLowNumbers: toInt(map['minLowNumbers'], 2),
      maxLowNumbers: toInt(map['maxLowNumbers'], 4),
      minSum: toInt(map['minSum'], 100),
      maxSum: toInt(map['maxSum'], 200),
      maxSameEndDigitCount: toInt(map['maxSameEndDigitCount'], 2),
      minDistinctEndDigits: toInt(map['minDistinctEndDigits'], 4),
      maxConsecutiveNumbers: toInt(map['maxConsecutiveNumbers'], 2),
      minSpread: toInt(map['minSpread'], 20),
      minGroup1to9: toInt(map['minGroup1to9'], 0),
      maxGroup1to9: toInt(map['maxGroup1to9'], 3),
      minGroup10to19: toInt(map['minGroup10to19'], 0),
      maxGroup10to19: toInt(map['maxGroup10to19'], 3),
      minGroup20to29: toInt(map['minGroup20to29'], 0),
      maxGroup20to29: toInt(map['maxGroup20to29'], 3),
      minGroup30to39: toInt(map['minGroup30to39'], 0),
      maxGroup30to39: toInt(map['maxGroup30to39'], 3),
      minGroup40to49: toInt(map['minGroup40to49'], 0),
      maxGroup40to49: toInt(map['maxGroup40to49'], 3),
      maxRepeatFromLastDraw: toInt(map['maxRepeatFromLastDraw'], 2),
      maxRepeatFromLast3Draws: toInt(map['maxRepeatFromLast3Draws'], 4),
      maxRepeatFromLast5Draws: toInt(map['maxRepeatFromLast5Draws'], 5),
      preferHotNumbers: toBool(map['preferHotNumbers'], false),
      avoidHotNumbers: toBool(map['avoidHotNumbers'], false),
      preferColdNumbers: toBool(map['preferColdNumbers'], false),
      avoidColdNumbers: toBool(map['avoidColdNumbers'], false),
      hotNumberWindow: toInt(map['hotNumberWindow'], 20),
      coldNumberWindow: toInt(map['coldNumberWindow'], 20),
      maxHotNumbersInTip: toInt(map['maxHotNumbersInTip'], 4),
      maxColdNumbersInTip: toInt(map['maxColdNumbersInTip'], 4),
      analysisMode: map['analysisMode']?.toString() ?? 'combined',
    );
  }
}
