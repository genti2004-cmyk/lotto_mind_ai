import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../domain/advanced_number_analysis.dart';
import '../domain/tip_tracking_entry.dart';

import '../../draws/domain/draw_checker_service.dart';
import '../../draws/domain/draw_result.dart';
import '../../draws/domain/draw_type.dart';
import '../../draws/domain/tip_check_result.dart';
import '../../draws/services/lotto_results_import_service.dart';
import '../../draws/services/draw_history_service.dart';
import '../../settings/domain/app_edition.dart';
import '../../settings/domain/feature_gate.dart';
import '../../settings/domain/rule_profile.dart';
import '../../tips/domain/tip_evaluation_result.dart';
import '../../tips/services/saved_tip_service.dart';
import '../../evaluation/services/tip_match_service.dart';
import '../domain/analysis_rule_set.dart';
import '../domain/lotto_generator_service.dart';
import '../domain/lotto_tip.dart';
import '../domain/generator_strategy.dart';
import '../services/pro_prediction_engine.dart';
import '../services/ai_master_mode_service.dart';
import '../services/ai_learning_boost_service.dart' as ai_boost;
import '../services/generated_tip_service.dart';
import '../../tracking/services/tracking_service.dart';
import '../../analysis/domain/analysis_signal.dart';
import '../../analysis/domain/number_analysis_score.dart';
import '../../analysis/services/number_analysis_service.dart';
import 'package:lotto_mind_ai/core/storage/app_storage_keys.dart';
import 'package:lotto_mind_ai/core/utils/format_utils.dart';

enum DrawMode {
  combined,
  wednesday,
  saturday,
}
enum AnalysisDrawFilter {
  all,
  wednesday,
  saturday,
}

enum AnalysisProfile {
  defensive,
  balanced,
  aggressive,
}

enum SystemPlayType {
  full,
  vew,
}

class AnalysisNumberStat {
  final int number;
  final int count;

  const AnalysisNumberStat({
    required this.number,
    required this.count,
  });
}

class AnalysisEndDigitStat {
  final int digit;
  final int count;

  const AnalysisEndDigitStat({
    required this.digit,
    required this.count,
  });
}

class AnalysisPairStat {
  final List<int> pair;
  final int count;

  const AnalysisPairStat({
    required this.pair,
    required this.count,
  });
}

class AnalysisSummary {
  final int drawCount;
  final double averageSum;
  final double averageEven;
  final double averageLow;
  final double averageSpread;
  final double averageRepeatFromPrevious;
  final List<AnalysisNumberStat> hotNumbers;
  final List<AnalysisNumberStat> coldNumbers;
  final List<AnalysisEndDigitStat> strongEndDigits;
  final List<AnalysisPairStat> strongPairs;
  final Map<int, int> repeatHistogram;

  const AnalysisSummary({
    required this.drawCount,
    required this.averageSum,
    required this.averageEven,
    required this.averageLow,
    required this.averageSpread,
    required this.averageRepeatFromPrevious,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.strongEndDigits,
    required this.strongPairs,
    required this.repeatHistogram,
  });

  factory AnalysisSummary.empty() {
    return const AnalysisSummary(
      drawCount: 0,
      averageSum: 0,
      averageEven: 0,
      averageLow: 0,
      averageSpread: 0,
      averageRepeatFromPrevious: 0,
      hotNumbers: [],
      coldNumbers: [],
      strongEndDigits: [],
      strongPairs: [],
      repeatHistogram: {},
    );
  }
}

class AnalysisAiSummary {
  final String title;
  final String confidence;
  final List<int> recommendedNumbers;
  final List<int> avoidNumbers;
  final String reasoning;

  const AnalysisAiSummary({
    required this.title,
    required this.confidence,
    required this.recommendedNumbers,
    required this.avoidNumbers,
    required this.reasoning,
  });

  factory AnalysisAiSummary.empty() {
    return const AnalysisAiSummary(
      title: 'Keine AI-Auswertung',
      confidence: 'Niedrig',
      recommendedNumbers: [],
      avoidNumbers: [],
      reasoning: 'Noch nicht genug Ziehungen im gewählten Analysefenster.',
    );
  }
}

class AnalysisScoreStat {
  final int number;
  final double score;
  final int totalCount;
  final int recentCount;
  final int olderCount;

  const AnalysisScoreStat({
    required this.number,
    required this.score,
    required this.totalCount,
    required this.recentCount,
    required this.olderCount,
  });
}

class AnalysisProSummary {
  final List<int> bestTip;
  final List<AnalysisNumberStat> trendingUp;
  final List<AnalysisNumberStat> trendingDown;
  final List<AnalysisNumberStat> reboundNumbers;
  final List<AnalysisScoreStat> topScores;
  final String strategy;

  const AnalysisProSummary({
    required this.bestTip,
    required this.trendingUp,
    required this.trendingDown,
    required this.reboundNumbers,
    required this.topScores,
    required this.strategy,
  });

  factory AnalysisProSummary.empty() {
    return const AnalysisProSummary(
      bestTip: [],
      trendingUp: [],
      trendingDown: [],
      reboundNumbers: [],
      topScores: [],
      strategy: 'Noch nicht genug Daten für eine Pro-Analyse.',
    );
  }
}



class MultiAiTipSuggestion {
  final String id;
  final String title;
  final String subtitle;
  final List<int> numbers;
  final String riskLabel;
  final String reasoning;

  const MultiAiTipSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.numbers,
    required this.riskLabel,
    required this.reasoning,
  });
}

class TipSimulationSummary {
  final Map<int, int> hitDistribution;
  final int totalDraws;

  const TipSimulationSummary({
    required this.hitDistribution,
    required this.totalDraws,
  });

  int getHitCount(int hits) => hitDistribution[hits] ?? 0;
}

class SystemAiRowScore {
  final List<int> row;
  final double score;
  final String label;
  final double roi;
  final double estimatedEuro;
  final int hit4Chance;
  final int hit3Base;
  final bool optimized;

  const SystemAiRowScore({
    required this.row,
    required this.score,
    required this.label,
    required this.roi,
    required this.estimatedEuro,
    required this.hit4Chance,
    required this.hit3Base,
    this.optimized = false,
  });
}

class WinClassSimulationSummary {
  final int totalDraws;
  final int hit2;
  final int hit3;
  final int hit4;
  final int hit4WithSuper;
  final int hit5;
  final int hit5WithSuper;
  final int hit6;
  final int hit6WithSuper;
  final int? superNumber;

  static const double estimatedPrizeClass8 = 6.00; // 3 Richtige
  static const double estimatedPrizeClass7 = 19.00; // 4 Richtige
  static const double estimatedPrizeClass6 = 48.00; // 4 + Superzahl
  static const double estimatedPrizeClass5 = 3200.00; // 5 Richtige
  static const double estimatedPrizeClass4 = 10000.00; // 5 + Superzahl
  static const double estimatedPrizeClass3 = 100000.00; // 6 Richtige
  static const double estimatedPrizeClass2 = 2500000.00; // 6 + Superzahl

  const WinClassSimulationSummary({
    required this.totalDraws,
    required this.hit2,
    required this.hit3,
    required this.hit4,
    required this.hit4WithSuper,
    required this.hit5,
    required this.hit5WithSuper,
    required this.hit6,
    required this.hit6WithSuper,
    required this.superNumber,
  });

  double get hit4WithSuperRate =>
      totalDraws <= 0 ? 0.0 : hit4WithSuper / totalDraws;

  double get hit4OrBetterRate =>
      totalDraws <= 0 ? 0.0 : (hit4 + hit4WithSuper + hit5 + hit5WithSuper + hit6 + hit6WithSuper) / totalDraws;

  int get weightedScore =>
      (hit3 * 2) +
          (hit4 * 8) +
          (hit4WithSuper * 14) +
          (hit5 * 30) +
          (hit5WithSuper * 40) +
          (hit6 * 80) +
          (hit6WithSuper * 100);

  double get estimatedEuroTotal =>
      (hit3 * estimatedPrizeClass8) +
          (hit4 * estimatedPrizeClass7) +
          (hit4WithSuper * estimatedPrizeClass6) +
          (hit5 * estimatedPrizeClass5) +
          (hit5WithSuper * estimatedPrizeClass4) +
          (hit6 * estimatedPrizeClass3) +
          (hit6WithSuper * estimatedPrizeClass2);

  double get estimatedEuroPerDraw =>
      totalDraws <= 0 ? 0.0 : estimatedEuroTotal / totalDraws;

  static const double modelStakePerDraw = 1.20;

  double get estimatedEuroPerTip =>
      totalDraws <= 0 ? 0.0 : estimatedEuroTotal / totalDraws;

  double get estimatedStakeTotal => totalDraws * modelStakePerDraw;

  double get estimatedNetProfit => estimatedEuroTotal - estimatedStakeTotal;

  double get estimatedRoiPercent =>
      estimatedStakeTotal <= 0 ? 0.0 : (estimatedNetProfit / estimatedStakeTotal) * 100.0;

}

class WinRangeEvaluation {
  final String label;
  final int drawCount;
  final WinClassSimulationSummary summary;
  final String recommendation;

  const WinRangeEvaluation({
    required this.label,
    required this.drawCount,
    required this.summary,
    required this.recommendation,
  });
}

class LottoAppState extends ChangeNotifier {
  static const TipMatchService _tipMatchService = TipMatchService();
  static const SavedTipService _savedTipService = SavedTipService();

  final double _stakePerTip = 1.20;   // ✅ HIER rein
  double get stakePerTip => _stakePerTip;

  static const String _boxName = AppStorageBoxes.appState;
  static const String _drawHistoryBoxName = AppStorageBoxes.drawHistory;
  static const String _savedTipsKey = 'saved_tips';
  static const String _lastGeneratedTipKey = 'last_generated_tip';
  static const String _lastGeneratedSuperNumberKey = 'last_generated_super_number';
  static const String _lastGeneratedStrategyKey = 'last_generated_strategy';
  static const String _drawResultsKey = 'draw_results';
  static const String _selectedDrawIdKey = 'selected_draw_id';
  static const String _rulesKey = 'rules';
  static const String _editionKey = 'app_edition';
  static const String _ruleProfilesKey = 'rule_profiles';
  static const String _drawModeKey = 'draw_mode';
  static const String _analysisStartOffsetKey = 'analysis_start_offset';
  static const String _analysisEndOffsetKey = 'analysis_end_offset';
  static const String _selectedSystemSizeKey = 'selected_system_size';
  static const String _systemBaseNumbersKey = 'system_base_numbers';
  static const String _systemRowsKey = 'system_rows';
  static const String _manualSystemNumbersKey = 'manual_system_numbers';
  static const String _systemPlayTypeKey = 'system_play_type';
  static const String _analysisDrawFilterKey = 'analysis_draw_filter';
  static const String _analysisDrawCountKey = 'analysis_draw_count';
  static const String _analysisProfileKey = 'analysis_profile';
  static const String _aiMasterModeKey = 'ai_master_mode';
  static const String _tipTrackingEntriesKey = 'tip_tracking_entries';

  AnalysisDrawFilter _analysisDrawFilter = AnalysisDrawFilter.all;
  int _analysisDrawCount = 52;
  AnalysisProfile _analysisProfile = AnalysisProfile.balanced;
  AiMasterMode _aiMasterMode = AiMasterMode.off;

  AnalysisDrawFilter get analysisDrawFilter => _analysisDrawFilter;

  int get analysisDrawCount => _analysisDrawCount;

  AnalysisProfile get analysisProfile => _analysisProfile;

  AiMasterMode get aiMasterMode => _aiMasterMode;

  bool get aiLearningBoostEnabled => _aiLearningBoostEnabled;
  List<int> get aiLearningBoostNumbers => List<int>.unmodifiable(_aiLearningBoostNumbers);
  int get aiLearningTrackedTipCount => _aiLearningTrackedTipCount;
  String get aiLearningBoostStatus => _aiLearningBoostStatus;

  bool get isAiMasterModeEnabled => _aiMasterMode != AiMasterMode.off;

  final LottoGeneratorService _generatorService = LottoGeneratorService();
  final GeneratedTipService _generatedTipService = GeneratedTipService();
  final NumberAnalysisService _numberAnalysisService = const NumberAnalysisService();
  final DrawCheckerService _drawCheckerService = DrawCheckerService();
  final LottoResultsImportService _importService = LottoResultsImportService();
  final AiMasterModeService _aiMasterModeService = const AiMasterModeService();

  bool _aiLearningBoostEnabled = true;
  List<int> _aiLearningBoostNumbers = <int>[];
  int _aiLearningTrackedTipCount = 0;
  String _aiLearningBoostStatus = 'nicht geladen';

  final AdvancedNumberAnalysisService _advancedAnalysisService =
  const AdvancedNumberAnalysisService();

  // AI MAX ENGINE

  final ProPredictionEngine _predictionEngine = ProPredictionEngine();

  PredictionEngineResult get predictionEngineResult {
    return _predictionEngine.build(
      draws: analysisDrawResults,
      profileLabel: analysisProfileLabel,
    );
  }


  AiMasterRecommendation get aiMasterRecommendation {
    return _aiMasterModeService.recommend(
      mode: _aiMasterMode,
      availableDrawCount: maxAnalysisDrawCount,
      currentDrawCount: _analysisDrawCount,
    );
  }

  String get aiMasterModeLabel {
    switch (_aiMasterMode) {
      case AiMasterMode.off:
        return 'Aus';
      case AiMasterMode.autoBalanced:
        return 'Master Auto';
      case AiMasterMode.trend:
        return 'Trend Boost';
      case AiMasterMode.rebound:
        return 'Rebound';
      case AiMasterMode.jackpot:
        return 'Jackpot Range';
    }
  }

  List<int> get bestAnalyzedTip {
    final result = predictionEngineResult;
    if (result.primaryTip.length == 6) {
      return result.primaryTip;
    }
    return analysisProSummary.bestTip;
  }

  int? get recommendedSuperNumber {
    return predictionEngineResult.recommendedSuperNumber;
  }

  List<NumberAnalysis> buildAdvancedAnalysis() {
    return _advancedAnalysisService.buildAdvancedAnalysis(analysisDrawResults);
  }

  List<int> getTopNumbers({int count = 10}) {
    return _advancedAnalysisService.getTopNumbers(
      analysisDrawResults,
      count: count,
    );
  }

  List<int> generateSmartTip() {
    return _advancedAnalysisService.generateSmartTip(analysisDrawResults);
  }

  List<PairPattern> get pairPatterns {
    return _advancedAnalysisService.buildPairPatterns(
      analysisDrawResults,
      top: 12,
    );
  }

  List<TriplePattern> get triplePatterns {
    return _advancedAnalysisService.buildTriplePatterns(
      analysisDrawResults,
      top: 10,
    );
  }

  List<RangeGroupAnalysis> get rangeGroups {
    return _advancedAnalysisService.buildRangeGroups(analysisDrawResults);
  }

  SmartTipDetails get smartTipDetails {
    return _advancedAnalysisService.generateSmartTipDetails(
      analysisDrawResults,
    );
  }


  List<NumberAnalysisScore> signalScores({
    AnalysisSignal signal = AnalysisSignal.hybrid,
    int limit = 6,
  }) {
    return _numberAnalysisService.topBySignal(
      analysisDrawResults,
      signal,
      limit: limit,
    );
  }

  List<int> get signalTipNumbers {
    return signalScores(limit: 6).map((score) => score.number).toList()..sort();
  }

  AnalysisRuleSet _rules = AnalysisRuleSet.initial();
  AppEdition _edition = AppEdition.free;
  DrawMode _drawMode = DrawMode.combined;
  int _analysisStartOffset = 0;
  int _analysisEndOffset = 0;

  List<int>? _lastGeneratedTip;
  int? _lastGeneratedSuperNumber;
  GeneratorStrategy _lastGeneratedStrategy = GeneratorStrategy.unknown;
  int _selectedSystemSize = 7;
  SystemPlayType _systemPlayType = SystemPlayType.full;
  List<int> _systemBaseNumbers = [];
  List<List<int>> _systemRows = [];
  List<int> _manualSystemNumbers = [];
  final List<LottoTip> _savedTips = [];
  final List<DrawResult> _drawResults = [];
  final List<RuleProfile> _ruleProfiles = [];
  final List<TipTrackingEntry> _tipTrackingEntries = [];

  DrawResult? _selectedDrawForCheck;
  List<TipCheckResult> _latestCheckResults = [];
  List<TipEvaluationResult> _tipEvaluationResults = [];

  bool _isImporting = false;
  String? _lastImportMessage;

  int? _importCurrentYear;
  int _importProcessedYears = 0;
  int _importTotalYears = 0;
  String? _importLabel;

  AnalysisRuleSet get rules => _rules;

  AppEdition get edition => _edition;

  FeatureGate get gate => FeatureGate(_edition);

  DrawMode get drawMode => _drawMode;

  List<int>? get lastGeneratedTip => _lastGeneratedTip;

  int? get lastGeneratedSuperNumber => _lastGeneratedSuperNumber;

  GeneratorStrategy get lastGeneratedStrategy => _lastGeneratedStrategy;

  int get selectedSystemSize => _selectedSystemSize;

  SystemPlayType get systemPlayType => _systemPlayType;

  String get systemPlayTypeLabel =>
      _systemPlayType == SystemPlayType.full ? 'Voll' : 'Intervall';

  List<int> get systemBaseNumbers => List.unmodifiable(_systemBaseNumbers);

  List<List<int>> get systemRows => List.unmodifiable(_systemRows);

  List<int> get manualSystemNumbers => List.unmodifiable(_manualSystemNumbers);

  bool get hasSystemRows => _systemRows.isNotEmpty;

  List<List<int>> get generatedSystemRows => List.unmodifiable(_systemRows);

  List<SystemAiRowScore> get systemAiRowScores => _buildSystemAiRowScores();

  List<List<int>> get systemAiTopRows =>
      systemAiRowScores.take(3).map((e) => List<int>.from(e.row)).toList();

  List<SystemAiRowScore> get optimizedSystemAiRows =>
      _optimizeSystemRows(systemAiRowScores);

  String get systemAiSummary {
    if (_systemRows.isEmpty) return 'Noch keine Systemreihen generiert.';
    final top = systemAiRowScores;
    if (top.isEmpty) return 'Noch keine AI-Bewertung verfügbar.';
    final best = top.first;
    return 'AI Top-Reihe: ${best.row.join(" - ")} • Score ${best.score.toStringAsFixed(1)} • ROI ${best.roi.toStringAsFixed(1)}%';
  }
  String get aiModeLabel => 'Normal';

  String get optimizedSystemAiSummary {
    final optimized = optimizedSystemAiRows;
    if (optimized.isEmpty) return 'Noch kein optimiertes System verfügbar.';
    final saved = _systemRows.length - optimized.length;
    return 'AI optimiert: ${optimized.length} Reihen statt ${_systemRows.length} • ${saved > 0 ? "$saved Reihen weniger" : "volle Auswahl"}';
  }

  int get remainingManualSystemSlots =>
      (_selectedSystemSize - _manualSystemNumbers.length).clamp(0, 16);

  List<LottoTip> get savedTips => List.unmodifiable(_savedTips);

  List<RuleProfile> get ruleProfiles => List.unmodifiable(_ruleProfiles);

  List<List<int>> get analysisDrawNumbers {
    return analysisDrawResults.map((d) => d.numbers).toList();
  }

  List<LottoTip> get favoriteTips {
    if (!gate.canUseFavorites) return const [];
    return _savedTips.where((tip) => tip.isFavorite).toList();
  }

  List<LottoTip> get regularTips {
    if (!gate.canUseFavorites) return List.unmodifiable(_savedTips);
    return _savedTips.where((tip) => !tip.isFavorite).toList();
  }

  List<TipTrackingEntry> get tipTrackingEntries =>
      List.unmodifiable(_tipTrackingEntries);

  List<TipTrackingEntry> get recentTipTrackingEntries {
    final entries = List<TipTrackingEntry>.from(_tipTrackingEntries)
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
    return entries.take(10).toList();
  }

  Map<int, int> get tipTrackingHitDistribution {
    final distribution = <int, int>{for (var i = 0; i <= 6; i++) i: 0};
    for (final entry in _tipTrackingEntries) {
      distribution[entry.hitCount] = (distribution[entry.hitCount] ?? 0) + 1;
    }
    return distribution;
  }

  int get bestTrackedHitCount {
    if (_tipTrackingEntries.isEmpty) return 0;
    return _tipTrackingEntries
        .map((entry) => entry.hitCount)
        .reduce((a, b) => a > b ? a : b);
  }

  double get averageTrackedHits {
    if (_tipTrackingEntries.isEmpty) return 0;
    final total = _tipTrackingEntries.fold<int>(
      0,
          (sum, entry) => sum + entry.hitCount,
    );
    return total / _tipTrackingEntries.length;
  }

  String get tipTrackingSummary {
    if (_tipTrackingEntries.isEmpty) {
      return 'Noch kein Treffer-Verlauf vorhanden.';
    }
    final best = bestTrackedHitCount;
    final average = averageTrackedHits.toStringAsFixed(1);
    return 'Bester Treffer: $best • Durchschnitt: $average • ${_tipTrackingEntries.length} Prüfungen';
  }

  List<DrawResult> get drawResults => List.unmodifiable(_drawResults);

  List<DrawResult> get wednesdayDrawResults =>
      _drawResults
          .where((d) => d.drawDate.weekday == DateTime.wednesday)
          .toList()
        ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

  List<DrawResult> get saturdayDrawResults =>
      _drawResults
          .where((d) => d.drawDate.weekday == DateTime.saturday)
          .toList()
        ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

  List<DrawResult> get filteredDrawResults {
    switch (_drawMode) {
      case DrawMode.wednesday:
        return wednesdayDrawResults;
      case DrawMode.saturday:
        return saturdayDrawResults;
      case DrawMode.combined:
        return List<DrawResult>.from(_drawResults)
          ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
    }
  }

  bool _matchesAnalysisFilter(DrawResult draw) {
    switch (_analysisDrawFilter) {
      case AnalysisDrawFilter.all:
        return true;
      case AnalysisDrawFilter.wednesday:
        return draw.drawDate.weekday == DateTime.wednesday;
      case AnalysisDrawFilter.saturday:
        return draw.drawDate.weekday == DateTime.saturday;
    }
  }

  List<DrawResult> get analysisBaseDrawResults {
    final sorted = List<DrawResult>.from(drawResults)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    return sorted.where(_matchesAnalysisFilter).toList();
  }

  int get maxAnalysisDrawCount {
    final count = analysisBaseDrawResults.length;
    return count <= 0 ? 1 : count;
  }

  String get analysisFilterLabel {
    switch (_analysisDrawFilter) {
      case AnalysisDrawFilter.all:
        return 'Beide';
      case AnalysisDrawFilter.wednesday:
        return 'Mittwoch';
      case AnalysisDrawFilter.saturday:
        return 'Samstag';
    }
  }
  String get analysisDrawFilterLabel {
    switch (analysisDrawFilter) {
      case AnalysisDrawFilter.all:
        return 'Alle';
      case AnalysisDrawFilter.wednesday:
        return 'Mittwoch';
      case AnalysisDrawFilter.saturday:
        return 'Samstag';
    }
  }
  String get analysisProfileLabel {
    switch (_analysisProfile) {
      case AnalysisProfile.defensive:
        return 'Defensiv';
      case AnalysisProfile.balanced:
        return 'Mittel';
      case AnalysisProfile.aggressive:
        return 'Aggressiv';
    }
  }

  void setAnalysisDrawFilter(AnalysisDrawFilter value) {
    if (_analysisDrawFilter == value) return;

    _analysisDrawFilter = value;

    final maxCount = maxAnalysisDrawCount;
    if (_analysisDrawCount > maxCount) {
      _analysisDrawCount = maxCount;
    }
    if (_analysisDrawCount < 1) {
      _analysisDrawCount = 1;
    }

    _saveToStorage();
    notifyListeners();
  }

  void setAnalysisDrawCount(int value) {
    final clamped = value.clamp(1, maxAnalysisDrawCount);
    if (_analysisDrawCount == clamped) return;
    _analysisDrawCount = clamped;
    _saveToStorage();
    notifyListeners();
  }

  void setAnalysisProfile(AnalysisProfile value) {
    if (_analysisProfile == value) return;
    _analysisProfile = value;
    _applyAnalysisProfilePreset();
    _saveToStorage();
    notifyListeners();
  }


  Future<void> setAiMasterMode(AiMasterMode mode) async {
    if (_aiMasterMode == mode) return;
    _aiMasterMode = mode;
    if (_aiMasterMode != AiMasterMode.off) {
      _applyAiMasterRecommendation();
    }
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> applyAiMasterModeNow() async {
    if (_aiMasterMode == AiMasterMode.off) return;
    _applyAiMasterRecommendation();
    await _saveToStorage();
    notifyListeners();
  }


  void setAiLearningBoostEnabled(bool value) {
    if (_aiLearningBoostEnabled == value) return;
    _aiLearningBoostEnabled = value;
    notifyListeners();
  }

  Future<void> refreshAiLearningBoost() async {
    try {
      final tips = await TrackingService().loadTips();
      _aiLearningTrackedTipCount = tips.length;

      if (tips.isEmpty) {
        _aiLearningBoostNumbers = <int>[];
        _aiLearningBoostStatus = 'keine Tracking-Daten';
        notifyListeners();
        return;
      }

      final result = ai_boost.AiLearningBoostService().buildBoost(tips: tips);
      _aiLearningBoostNumbers = result.boostedNumbers;
      _aiLearningBoostStatus = _aiLearningBoostNumbers.isEmpty
          ? 'keine Boost-Zahlen'
          : 'aktiv (${_aiLearningBoostNumbers.length} Zahlen)';
    } catch (e) {
      _aiLearningBoostNumbers = <int>[];
      _aiLearningBoostStatus = 'Fehler: $e';
    }

    notifyListeners();
  }

  void _applyAiMasterRecommendation() {
    final recommendation = aiMasterRecommendation;
    _analysisDrawCount = recommendation.drawCount.clamp(1, maxAnalysisDrawCount);
    switch (recommendation.profileTarget) {
      case AiMasterProfileTarget.defensive:
        _analysisProfile = AnalysisProfile.defensive;
        break;
      case AiMasterProfileTarget.balanced:
        _analysisProfile = AnalysisProfile.balanced;
        break;
      case AiMasterProfileTarget.aggressive:
        _analysisProfile = AnalysisProfile.aggressive;
        break;
    }
    _applyAnalysisProfilePreset();
  }

  AiMasterMode _aiMasterModeFromKey(String? raw) {
    switch (raw) {
      case 'auto_balanced':
        return AiMasterMode.autoBalanced;
      case 'trend':
        return AiMasterMode.trend;
      case 'rebound':
        return AiMasterMode.rebound;
      case 'jackpot':
        return AiMasterMode.jackpot;
      case 'off':
      default:
        return AiMasterMode.off;
    }
  }

  String _aiMasterModeKeyValue(AiMasterMode mode) {
    switch (mode) {
      case AiMasterMode.off:
        return 'off';
      case AiMasterMode.autoBalanced:
        return 'auto_balanced';
      case AiMasterMode.trend:
        return 'trend';
      case AiMasterMode.rebound:
        return 'rebound';
      case AiMasterMode.jackpot:
        return 'jackpot';
    }
  }

  void setAnalysisToAllHistory() {
    _analysisDrawCount = maxAnalysisDrawCount;
    notifyListeners();
  }

  void setAnalysisToRecent52() {
    final target = maxAnalysisDrawCount >= 52 ? 52 : maxAnalysisDrawCount;
    _analysisDrawCount = target < 1 ? 1 : target;
    notifyListeners();
  }

  void _applyAnalysisProfilePreset() {
    switch (_analysisProfile) {
      case AnalysisProfile.defensive:
        _rules = _rules.copyWith(
          minEven: 2,
          maxEven: 4,
          minLowNumbers: 2,
          maxLowNumbers: 4,
          minSum: 110,
          maxSum: 185,
          maxSameEndDigitCount: 2,
          minDistinctEndDigits: 4,
          maxConsecutiveNumbers: 1,
          minSpread: 24,
          maxRepeatFromLastDraw: 1,
          maxRepeatFromLast3Draws: 3,
          maxRepeatFromLast5Draws: 4,
          preferHotNumbers: false,
          avoidHotNumbers: true,
          preferColdNumbers: false,
          avoidColdNumbers: false,
          maxHotNumbersInTip: 2,
          maxColdNumbersInTip: 3,
        );
        break;
      case AnalysisProfile.balanced:
        _rules = _rules.copyWith(
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
          maxRepeatFromLastDraw: 2,
          maxRepeatFromLast3Draws: 4,
          maxRepeatFromLast5Draws: 5,
          preferHotNumbers: false,
          avoidHotNumbers: false,
          preferColdNumbers: false,
          avoidColdNumbers: false,
          maxHotNumbersInTip: 4,
          maxColdNumbersInTip: 4,
        );
        break;
      case AnalysisProfile.aggressive:
        _rules = _rules.copyWith(
          minEven: 1,
          maxEven: 5,
          minLowNumbers: 1,
          maxLowNumbers: 5,
          minSum: 90,
          maxSum: 220,
          maxSameEndDigitCount: 3,
          minDistinctEndDigits: 3,
          maxConsecutiveNumbers: 3,
          minSpread: 16,
          maxRepeatFromLastDraw: 2,
          maxRepeatFromLast3Draws: 5,
          maxRepeatFromLast5Draws: 6,
          preferHotNumbers: true,
          avoidHotNumbers: false,
          preferColdNumbers: true,
          avoidColdNumbers: false,
          maxHotNumbersInTip: 5,
          maxColdNumbersInTip: 5,
        );
        break;
    }
  }

  AnalysisDrawFilter _analysisDrawFilterFromKey(String? raw) {
    switch (raw) {
      case 'wednesday':
        return AnalysisDrawFilter.wednesday;
      case 'saturday':
        return AnalysisDrawFilter.saturday;
      case 'all':
      default:
        return AnalysisDrawFilter.all;
    }
  }

  String _analysisDrawFilterKeyValue(AnalysisDrawFilter value) {
    switch (value) {
      case AnalysisDrawFilter.wednesday:
        return 'wednesday';
      case AnalysisDrawFilter.saturday:
        return 'saturday';
      case AnalysisDrawFilter.all:
        return 'all';
    }
  }

  AnalysisProfile _analysisProfileFromKey(String? raw) {
    switch (raw) {
      case 'defensive':
        return AnalysisProfile.defensive;
      case 'aggressive':
        return AnalysisProfile.aggressive;
      case 'balanced':
      default:
        return AnalysisProfile.balanced;
    }
  }

  String _analysisProfileKeyValue(AnalysisProfile profile) {
    switch (profile) {
      case AnalysisProfile.defensive:
        return 'defensive';
      case AnalysisProfile.balanced:
        return 'balanced';
      case AnalysisProfile.aggressive:
        return 'aggressive';
    }
  }

  String _analysisFilterModeLabel() {
    switch (_analysisDrawFilter) {
      case AnalysisDrawFilter.all:
        return 'combined';
      case AnalysisDrawFilter.wednesday:
        return 'wednesday';
      case AnalysisDrawFilter.saturday:
        return 'saturday';
    }
  }

  DrawResult? get selectedDrawForCheck => _selectedDrawForCheck;

  List<TipCheckResult> get latestCheckResults =>
      List.unmodifiable(_latestCheckResults);

  bool get isImporting => _isImporting;

  String? get lastImportMessage => _lastImportMessage;

  int? get importCurrentYear => _importCurrentYear;

  int get importProcessedYears => _importProcessedYears;

  int get importTotalYears => _importTotalYears;

  String? get importLabel => _importLabel;

  double get importProgress {
    if (_importTotalYears <= 0) return 0;
    return _importProcessedYears / _importTotalYears;
  }

  String get drawModeLabel {
    switch (_drawMode) {
      case DrawMode.combined:
        return 'Alle';
      case DrawMode.wednesday:
        return 'Mittwoch';
      case DrawMode.saturday:
        return 'Samstag';
    }
  }

  String get drawModeDescription {
    switch (_drawMode) {
      case DrawMode.combined:
        return 'Kombinierte Analyse aus Mittwoch und Samstag';
      case DrawMode.wednesday:
        return 'Nur Mittwoch-Ziehungen';
      case DrawMode.saturday:
        return 'Nur Samstag-Ziehungen';
    }
  }

  int get analysisStartOffset => _analysisStartOffset;

  int get analysisEndOffset => _analysisEndOffset;

  int get analysisMaxOffset {
    final length = filteredDrawResults.length;
    if (length <= 1) return 0;
    return length - 1;
  }

  DateTime? get analysisStartDate {
    final draws = filteredDrawResults;
    if (draws.isEmpty) return null;
    final index = _analysisStartOffset.clamp(0, draws.length - 1);
    return draws[index].drawDate;
  }

  DateTime? get analysisEndDate {
    final draws = filteredDrawResults;
    if (draws.isEmpty) return null;
    final index = _analysisEndOffset.clamp(0, draws.length - 1);
    return draws[index].drawDate;
  }

  List<DrawResult> get analysisDrawResults {
    final filtered = analysisBaseDrawResults;
    if (filtered.isEmpty) return const [];

    final safeCount = _analysisDrawCount.clamp(1, filtered.length);
    return filtered.take(safeCount).toList();
  }

  AnalysisSummary get analysisSummary {
    return _buildAnalysisSummary(analysisDrawResults);
  }

  String get analysisWindowLabel {
    final draws = analysisDrawResults;
    if (draws.isEmpty) {
      return 'Keine Ziehungen ausgewählt';
    }

    final sorted = List<DrawResult>.from(draws)
      ..sort((a, b) => a.drawDate.compareTo(b.drawDate));

    final oldest = sorted.first.drawDate;
    final newest = sorted.last.drawDate;
    return '${_formatDate(oldest)} bis ${_formatDate(newest)}';
  }

  String get analysisStrengthLabel {
    final count = analysisDrawResults.length;
    if (count >= 150) return 'Sehr stark';
    if (count >= 80) return 'Stark';
    if (count >= 30) return 'Mittel';
    if (count >= 10) return 'Begrenzt';
    return 'Zu wenig Daten';
  }


  AnalysisAiSummary get analysisAiSummary {
    final summary = analysisSummary;
    if (summary.drawCount < 8) {
      return AnalysisAiSummary.empty();
    }

    final recommended = summary.hotNumbers
        .take(3)
        .map((e) => e.number)
        .toList();
    final avoid = summary.coldNumbers.take(3).map((e) => e.number).toList();
    final pairText = summary.strongPairs.isEmpty
        ? 'keine dominanten Paare'
        : summary.strongPairs.first.pair.join('/');
    final repeat0 = summary.repeatHistogram[0] ?? 0;
    final repeat1 = summary.repeatHistogram[1] ?? 0;
    final repeat2plus = (summary.repeatHistogram[2] ?? 0) +
        (summary.repeatHistogram[3] ?? 0) +
        (summary.repeatHistogram[4] ?? 0) +
        (summary.repeatHistogram[5] ?? 0) +
        (summary.repeatHistogram[6] ?? 0);

    String title;
    if (summary.drawCount >= 100) {
      title = 'AI-Auswertung: starke Datenbasis';
    } else if (summary.drawCount >= 40) {
      title = 'AI-Auswertung: gute Datenbasis';
    } else {
      title = 'AI-Auswertung: mittlere Datenbasis';
    }

    final confidence = analysisStrengthLabel;
    final reasoning =
        'Im gewählten Zeitraum dominieren die Zahlen ${recommended.join(
        ', ')}. '
        'Schwache Zahlen sind ${avoid.join(', ')}. '
        'Das stärkste Musterpaar ist $pairText. '
        'Wiederholungen von 0 bis 1 Zahl zur Vorziehung treten häufiger auf als 2+ Wiederholungen '
        '($repeat0 / $repeat1 / $repeat2plus).';

    return AnalysisAiSummary(
      title: title,
      confidence: confidence,
      recommendedNumbers: recommended,
      avoidNumbers: avoid,
      reasoning: reasoning,
    );
  }

  AnalysisProSummary get analysisProSummary {
    return _buildAnalysisProSummary(analysisDrawResults);
  }

  List<MultiAiTipSuggestion> get multiAiSuggestions {
    return _buildMultiAiSuggestions(analysisDrawResults);
  }

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }


  Future<Box> _openDrawHistoryBox() async {
    if (Hive.isBoxOpen(_drawHistoryBoxName)) {
      return Hive.box(_drawHistoryBoxName);
    }
    return Hive.openBox(_drawHistoryBoxName);
  }

  Future<List<DrawResult>> _loadDrawHistoryBox() async {
    final drawBox = await _openDrawHistoryBox();
    final loaded = <DrawResult>[];

    for (final value in drawBox.values) {
      if (value is Map) {
        try {
          loaded.add(DrawResult.fromMap(Map<dynamic, dynamic>.from(value)));
        } catch (_) {
          // beschädigte Einträge überspringen
        }
      }
    }

    return loaded;
  }

  Future<void> _saveDrawHistoryBox() async {
    final drawBox = await _openDrawHistoryBox();
    await drawBox.clear();

    for (final draw in _drawResults) {
      await drawBox.put(DrawHistoryService.drawDateKey(draw.drawDate), draw.toMap());
    }
  }

  Future<void> loadFromStorage() async {
    final box = await _openBox();

    _edition = AppEditionX.fromKey(box.get(_editionKey)?.toString());

    final rawDrawMode = box.get(_drawModeKey)?.toString();
    _drawMode = _drawModeFromKey(rawDrawMode);

    final rawAnalysisDrawFilter = box.get(_analysisDrawFilterKey)?.toString();
    _analysisDrawFilter = _analysisDrawFilterFromKey(rawAnalysisDrawFilter);

    final rawAnalysisDrawCount = box.get(_analysisDrawCountKey);
    _analysisDrawCount =
        int.tryParse(rawAnalysisDrawCount?.toString() ?? '') ?? 52;

    final rawAnalysisProfile = box.get(_analysisProfileKey)?.toString();
    _analysisProfile = _analysisProfileFromKey(rawAnalysisProfile);

    final rawAiMasterMode = box.get(_aiMasterModeKey)?.toString();
    _aiMasterMode = _aiMasterModeFromKey(rawAiMasterMode);

    final rawRules = box.get(_rulesKey);
    if (rawRules is Map) {
      _rules = AnalysisRuleSet.fromMap(Map<String, dynamic>.from(rawRules));
    } else {
      _rules = AnalysisRuleSet.initial();
    }

    final rawProfiles = box.get(_ruleProfilesKey);
    _ruleProfiles.clear();
    if (rawProfiles is List) {
      for (final item in rawProfiles) {
        if (item is Map) {
          _ruleProfiles.add(
            RuleProfile.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawSavedTips = box.get(_savedTipsKey);
    _savedTips
      ..clear()
      ..addAll(_savedTipService.parseTips(rawSavedTips));

    final rawLastTip = box.get(_lastGeneratedTipKey);
    if (rawLastTip is List) {
      final parsed = rawLastTip
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
      _lastGeneratedTip = parsed.isEmpty ? null : parsed;
    } else {
      _lastGeneratedTip = null;
    }

    final rawLastSuperNumber = box.get(_lastGeneratedSuperNumberKey);
    final parsedLastSuperNumber =
    int.tryParse(rawLastSuperNumber?.toString() ?? '');
    _lastGeneratedSuperNumber =
    (parsedLastSuperNumber != null &&
        parsedLastSuperNumber >= 0 &&
        parsedLastSuperNumber <= 9)
        ? parsedLastSuperNumber
        : null;

    _lastGeneratedStrategy = GeneratorStrategyX.fromName(
      box.get(_lastGeneratedStrategyKey)?.toString(),
    );

    final rawSelectedSystemSize = box.get(_selectedSystemSizeKey);
    _selectedSystemSize =
        int.tryParse(rawSelectedSystemSize?.toString() ?? '') ?? 7;
    if (_selectedSystemSize < 7 || _selectedSystemSize > 16) {
      _selectedSystemSize = 7;
    }

    final rawSystemPlayType = box.get(_systemPlayTypeKey)?.toString();
    _systemPlayType =
    rawSystemPlayType == 'vew' ? SystemPlayType.vew : SystemPlayType.full;

    final rawSystemBaseNumbers = box.get(_systemBaseNumbersKey);
    _systemBaseNumbers = [];
    if (rawSystemBaseNumbers is List) {
      _systemBaseNumbers = rawSystemBaseNumbers
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 1 && e <= 49)
          .toSet()
          .toList()
        ..sort();
    }

    final rawSystemRows = box.get(_systemRowsKey);
    _systemRows = [];
    if (rawSystemRows is List) {
      for (final row in rawSystemRows) {
        if (row is List) {
          final parsedRow = row
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e >= 1 && e <= 49)
              .toSet()
              .toList()
            ..sort();
          if (parsedRow.length == 6) {
            _systemRows.add(parsedRow);
          }
        }
      }
    }

    final rawManualSystemNumbers = box.get(_manualSystemNumbersKey);
    _manualSystemNumbers = [];
    if (rawManualSystemNumbers is List) {
      _manualSystemNumbers = rawManualSystemNumbers
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 1 && e <= 49)
          .toSet()
          .toList()
        ..sort();
      if (_manualSystemNumbers.length > _selectedSystemSize) {
        _manualSystemNumbers =
            _manualSystemNumbers.take(_selectedSystemSize).toList();
      }
    }

    final rawDraws = box.get(_drawResultsKey);
    _drawResults.clear();
    if (rawDraws is List) {
      for (final item in rawDraws) {
        if (item is Map) {
          try {
            _drawResults.add(DrawResult.fromMap(Map<dynamic, dynamic>.from(item)));
          } catch (_) {
            // beschädigte Einträge überspringen
          }
        }
      }
    }

    final dedicatedDraws = await _loadDrawHistoryBox();
    if (dedicatedDraws.length > _drawResults.length) {
      _drawResults
        ..clear()
        ..addAll(dedicatedDraws);
    }

    _normalizeDrawHistory();
    if (_drawResults.isNotEmpty) {
      // alte Listen-Speicherung und neue Draw-Box synchron halten
      await box.put(_drawResultsKey, _drawResults.map((draw) => draw.toMap()).toList());
      await _saveDrawHistoryBox();
    }

    final rawTipTrackingEntries = box.get(_tipTrackingEntriesKey);
    _tipTrackingEntries.clear();
    if (rawTipTrackingEntries is List) {
      for (final item in rawTipTrackingEntries) {
        if (item is Map) {
          _tipTrackingEntries.add(
            TipTrackingEntry.fromMap(Map<dynamic, dynamic>.from(item)),
          );
        }
      }
    }

    final selectedDrawId = box.get(_selectedDrawIdKey)?.toString();

    final rawAnalysisStart = box.get(_analysisStartOffsetKey);
    final rawAnalysisEnd = box.get(_analysisEndOffsetKey);
    _analysisStartOffset =
        int.tryParse(rawAnalysisStart?.toString() ?? '') ?? 0;
    _analysisEndOffset =
        int.tryParse(rawAnalysisEnd?.toString() ?? '') ?? analysisMaxOffset;

    if (selectedDrawId != null && selectedDrawId.isNotEmpty) {
      try {
        _selectedDrawForCheck =
            _drawResults.firstWhere((draw) => draw.id == selectedDrawId);
      } catch (_) {
        _selectedDrawForCheck = null;
      }
    } else {
      _selectedDrawForCheck = null;
    }

    _ensureSelectedDrawMatchesMode();
    _normalizeAnalysisWindow(notify: false);
    if (_analysisDrawCount > maxAnalysisDrawCount) {
      _analysisDrawCount = maxAnalysisDrawCount;
    }
    if (_analysisDrawCount < 1) {
      _analysisDrawCount = 1;
    }
    if (_aiMasterMode != AiMasterMode.off) {
      _applyAiMasterRecommendation();
    }
    _applyAnalysisProfilePreset();
    _rebuildCheckResults(notify: false);
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final box = await _openBox();

    await box.put(_editionKey, _edition.key);
    await box.put(_drawModeKey, _drawModeKeyValue(_drawMode));
    await box.put(_analysisDrawFilterKey,
        _analysisDrawFilterKeyValue(_analysisDrawFilter));
    await box.put(_analysisDrawCountKey, _analysisDrawCount);
    await box.put(
        _analysisProfileKey, _analysisProfileKeyValue(_analysisProfile));
    await box.put(_aiMasterModeKey, _aiMasterModeKeyValue(_aiMasterMode));
    await box.put(_rulesKey, _rules.toMap());
    await box.put(
      _ruleProfilesKey,
      _ruleProfiles.map((profile) => profile.toMap()).toList(),
    );
    await box.put(
      _savedTipsKey,
      _savedTipService.toStorage(_savedTips),
    );
    await box.put(
      _tipTrackingEntriesKey,
      _tipTrackingEntries.map((entry) => entry.toMap()).toList(),
    );
    await box.put(_lastGeneratedTipKey, _lastGeneratedTip ?? <int>[]);
    await box.put(_lastGeneratedSuperNumberKey, _lastGeneratedSuperNumber);
    await box.put(_lastGeneratedStrategyKey, _lastGeneratedStrategy.name);
    await box.put(
      _drawResultsKey,
      _drawResults.map((draw) => draw.toMap()).toList(),
    );
    await _saveDrawHistoryBox();
    await box.put(_selectedDrawIdKey, _selectedDrawForCheck?.id ?? '');
    await box.put(_analysisStartOffsetKey, _analysisStartOffset);
    await box.put(_analysisEndOffsetKey, _analysisEndOffset);
    await box.put(_selectedSystemSizeKey, _selectedSystemSize);
    await box.put(
      _systemPlayTypeKey,
      _systemPlayType == SystemPlayType.full ? 'full' : 'vew',
    );
    await box.put(_systemBaseNumbersKey, _systemBaseNumbers);
    await box.put(_systemRowsKey, _systemRows);
    await box.put(_manualSystemNumbersKey, _manualSystemNumbers);
  }

  Future<void> setEdition(AppEdition value) async {
    _edition = value;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> setDrawMode(DrawMode mode) async {
    if (_drawMode == mode) return;

    _drawMode = mode;
    _ensureSelectedDrawMatchesMode();
    _normalizeAnalysisWindow(notify: false);
    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
  }

  void updateAnalysisWindowLive({
    required int startOffset,
    required int endOffset,
  }) {
    _analysisStartOffset = startOffset;
    _analysisEndOffset = endOffset;
    _normalizeAnalysisWindow(notify: false);
    notifyListeners();
  }

  Future<void> setAnalysisWindow({
    required int startOffset,
    required int endOffset,
  }) async {
    updateAnalysisWindowLive(
      startOffset: startOffset,
      endOffset: endOffset,
    );
    await _saveToStorage();
  }

  Future<void> persistAnalysisWindow() async {
    await _saveToStorage();
  }

  Future<void> resetAnalysisWindow() async {
    final maxOffset = analysisMaxOffset;
    _analysisStartOffset = 0;
    _analysisEndOffset = maxOffset;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> saveCurrentRulesAsProfile(String name) async {
    if (!gate.canUseRuleProfiles) return;

    _ruleProfiles.insert(
      0,
      RuleProfile(
        id: DateTime
            .now()
            .microsecondsSinceEpoch
            .toString(),
        name: name,
        createdAt: DateTime.now(),
        rules: _rules,
      ),
    );

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> applyRuleProfile(String profileId) async {
    final index = _ruleProfiles.indexWhere((profile) =>
    profile.id == profileId);
    if (index == -1) return;

    _rules = _ruleProfiles[index].rules;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> deleteRuleProfile(String profileId) async {
    _ruleProfiles.removeWhere((profile) => profile.id == profileId);
    await _saveToStorage();
    notifyListeners();
  }

  Map<String, dynamic> buildExportPayload() {
    return {
      'schemaVersion': 1,
      'appEdition': _edition.key,
      'drawMode': _drawModeKeyValue(_drawMode),
      'exportedAt': DateTime.now().toIso8601String(),
      'rules': _rules.toMap(),
      'ruleProfiles': _ruleProfiles.map((e) => e.toMap()).toList(),
      'savedTips': _savedTipService.toStorage(_savedTips),
      'drawResults': _drawResults.map((e) => e.toMap()).toList(),
      'selectedDrawId': _selectedDrawForCheck?.id,
      'meta': {
        'tipsCount': _savedTips.length,
        'drawsCount': _drawResults.length,
        'profilesCount': _ruleProfiles.length,
        'drawMode': _drawModeKeyValue(_drawMode),
      },
    };
  }

  Future<void> importBackupPayload(Map<String, dynamic> payload) async {
    final schemaVersion = payload['schemaVersion'];
    if (schemaVersion != 1) {
      throw Exception('Nicht unterstützte Backup-Version.');
    }

    if (payload['rules'] == null ||
        payload['savedTips'] == null ||
        payload['drawResults'] == null ||
        payload['ruleProfiles'] == null) {
      throw Exception('Backup ist unvollständig.');
    }

    _edition = AppEditionX.fromKey(payload['appEdition']?.toString());
    _drawMode = _drawModeFromKey(payload['drawMode']?.toString());

    final rawRules = payload['rules'];
    if (rawRules is Map) {
      _rules = AnalysisRuleSet.fromMap(Map<String, dynamic>.from(rawRules));
    } else {
      throw Exception('Ungültige Regeln im Backup.');
    }

    _ruleProfiles.clear();
    final rawProfiles = payload['ruleProfiles'];
    if (rawProfiles is! List) {
      throw Exception('Ungültige Rule Profiles im Backup.');
    }
    for (final item in rawProfiles) {
      if (item is! Map) {
        throw Exception('Ungültiger Rule-Profile-Eintrag im Backup.');
      }
      _ruleProfiles.add(RuleProfile.fromMap(Map<String, dynamic>.from(item)));
    }

    final rawTips = payload['savedTips'];
    if (rawTips is! List) {
      throw Exception('Ungültige Tipps im Backup.');
    }
    _savedTips
      ..clear()
      ..addAll(_savedTipService.parseTips(rawTips));

    _drawResults.clear();
    final rawDraws = payload['drawResults'];
    if (rawDraws is! List) {
      throw Exception('Ungültige Ziehungen im Backup.');
    }
    for (final item in rawDraws) {
      if (item is! Map) {
        throw Exception('Ungültiger Ziehungs-Eintrag im Backup.');
      }
      _drawResults.add(DrawResult.fromMap(Map<String, dynamic>.from(item)));
    }

    _normalizeDrawHistory();

    final selectedDrawId = payload['selectedDrawId']?.toString();
    if (selectedDrawId != null && selectedDrawId.isNotEmpty) {
      try {
        _selectedDrawForCheck =
            _drawResults.firstWhere((draw) => draw.id == selectedDrawId);
      } catch (_) {
        _selectedDrawForCheck =
        _drawResults.isEmpty ? null : _drawResults.first;
      }
    } else {
      _selectedDrawForCheck = _drawResults.isEmpty ? null : _drawResults.first;
    }

    _ensureSelectedDrawMatchesMode();
    _normalizeAnalysisWindow(notify: false);
    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
  }

  int hitCountForTip(String tipId) {
    try {
      return _latestCheckResults
          .firstWhere((r) => r.tip.id == tipId)
          .hitCount;
    } catch (_) {
      return 0;
    }
  }

  List<int> matchedNumbersForTip(String tipId) {
    try {
      return _latestCheckResults
          .firstWhere((r) => r.tip.id == tipId)
          .matchedNumbers;
    } catch (_) {
      return const [];
    }
  }

  Future<void> toggleTipFavorite(String id) async {
    if (!gate.canUseFavorites) return;

    final changed = _savedTipService.toggleFavorite(_savedTips, id);
    if (!changed) return;

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> setRules(AnalysisRuleSet value) async {
    _rules = value;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> resetRulesAndSave() async {
    _rules = AnalysisRuleSet.initial();
    await _saveToStorage();
    notifyListeners();
  }

  void updatePreferredNumbers(List<int> values) {
    _rules = _rules.copyWith(preferredNumbers: _sanitizeNumbers(values));
    notifyListeners();
  }

  void updateExcludedNumbers(List<int> values) {
    _rules = _rules.copyWith(excludedNumbers: _sanitizeNumbers(values));
    notifyListeners();
  }

  void updateRequiredNumbers(List<int> values) {
    _rules = _rules.copyWith(requiredNumbers: _sanitizeNumbers(values));
    notifyListeners();
  }

  void updateAllowedEndDigits(List<int> values) {
    _rules = _rules.copyWith(
      allowedEndDigits: values.where((e) => e >= 0 && e <= 9).toSet().toList()
        ..sort(),
    );
    notifyListeners();
  }

  void updateBlockedEndDigits(List<int> values) {
    _rules = _rules.copyWith(
      blockedEndDigits: values.where((e) => e >= 0 && e <= 9).toSet().toList()
        ..sort(),
    );
    notifyListeners();
  }

  void updateAnalysisMode(String value) {
    _rules = _rules.copyWith(analysisMode: value);
    notifyListeners();
  }

  void updateMinEven(int value) {
    _rules = _rules.copyWith(minEven: value);
    notifyListeners();
  }

  void updateMaxEven(int value) {
    _rules = _rules.copyWith(maxEven: value);
    notifyListeners();
  }

  void updateMinLow(int value) {
    _rules = _rules.copyWith(minLowNumbers: value);
    notifyListeners();
  }

  void updateMaxLow(int value) {
    _rules = _rules.copyWith(maxLowNumbers: value);
    notifyListeners();
  }

  void updateMinSum(int value) {
    _rules = _rules.copyWith(minSum: value);
    notifyListeners();
  }

  void updateMaxSum(int value) {
    _rules = _rules.copyWith(maxSum: value);
    notifyListeners();
  }

  void updateMaxSameEndDigitCount(int value) {
    _rules = _rules.copyWith(maxSameEndDigitCount: value);
    notifyListeners();
  }

  void updateMinDistinctEndDigits(int value) {
    _rules = _rules.copyWith(minDistinctEndDigits: value);
    notifyListeners();
  }

  void updateMaxConsecutiveNumbers(int value) {
    _rules = _rules.copyWith(maxConsecutiveNumbers: value);
    notifyListeners();
  }

  void updateMinSpread(int value) {
    _rules = _rules.copyWith(minSpread: value);
    notifyListeners();
  }

  void updateGroup1to9(int min, int max) {
    _rules = _rules.copyWith(minGroup1to9: min, maxGroup1to9: max);
    notifyListeners();
  }

  void updateGroup10to19(int min, int max) {
    _rules = _rules.copyWith(minGroup10to19: min, maxGroup10to19: max);
    notifyListeners();
  }

  void updateGroup20to29(int min, int max) {
    _rules = _rules.copyWith(minGroup20to29: min, maxGroup20to29: max);
    notifyListeners();
  }

  void updateGroup30to39(int min, int max) {
    _rules = _rules.copyWith(minGroup30to39: min, maxGroup30to39: max);
    notifyListeners();
  }

  void updateGroup40to49(int min, int max) {
    _rules = _rules.copyWith(minGroup40to49: min, maxGroup40to49: max);
    notifyListeners();
  }

  void updateMaxRepeatFromLastDraw(int value) {
    _rules = _rules.copyWith(maxRepeatFromLastDraw: value);
    notifyListeners();
  }

  void updateMaxRepeatFromLast3Draws(int value) {
    _rules = _rules.copyWith(maxRepeatFromLast3Draws: value);
    notifyListeners();
  }

  void updateMaxRepeatFromLast5Draws(int value) {
    _rules = _rules.copyWith(maxRepeatFromLast5Draws: value);
    notifyListeners();
  }

  void updatePreferHotNumbers(bool value) {
    _rules = _rules.copyWith(preferHotNumbers: value);
    notifyListeners();
  }

  void updateAvoidHotNumbers(bool value) {
    _rules = _rules.copyWith(avoidHotNumbers: value);
    notifyListeners();
  }

  void updatePreferColdNumbers(bool value) {
    _rules = _rules.copyWith(preferColdNumbers: value);
    notifyListeners();
  }

  void updateAvoidColdNumbers(bool value) {
    _rules = _rules.copyWith(avoidColdNumbers: value);
    notifyListeners();
  }

  void updateHotNumberWindow(int value) {
    _rules = _rules.copyWith(hotNumberWindow: value);
    notifyListeners();
  }

  void updateColdNumberWindow(int value) {
    _rules = _rules.copyWith(coldNumberWindow: value);
    notifyListeners();
  }

  void updateMaxHotNumbersInTip(int value) {
    _rules = _rules.copyWith(maxHotNumbersInTip: value);
    notifyListeners();
  }

  void updateMaxColdNumbersInTip(int value) {
    _rules = _rules.copyWith(maxColdNumbersInTip: value);
    notifyListeners();
  }

  Future<void> generateTip() async {
    await generateRandomTip();
  }

  Future<void> generateRandomTip() async {
    final generated = _generatedTipService.generateRandomTip(_generatorService);
    _lastGeneratedTip = generated.numbers;
    _lastGeneratedSuperNumber = generated.superNumber;
    _lastGeneratedStrategy = GeneratorStrategy.basis;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> generateAnalysisTip({GeneratorStrategy strategy = GeneratorStrategy.analysis}) async {
    if (_aiMasterMode != AiMasterMode.off) {
      _applyAiMasterRecommendation();
    }

    final result = predictionEngineResult;

    if (result.primaryTip.length == 6) {
      final generated = _generatedTipService.fromNumbers(
        result.primaryTip,
        recommendedSuperNumber: result.recommendedSuperNumber,
        fallbackToRandomSuperNumber: false,
      );
      _lastGeneratedTip = generated.numbers;
      _lastGeneratedSuperNumber = generated.superNumber;
      _lastGeneratedStrategy = strategy;
    } else {
      final draws = analysisDrawResults;

      final AnalysisRuleSet effectiveRules = _rules.copyWith(
        analysisMode: _analysisFilterModeLabel(),
        hotNumberWindow: _analysisDrawCount,
        coldNumberWindow: _analysisDrawCount,
      );

      final generated = _generatedTipService.generateAnalysisTip(
        generatorService: _generatorService,
        predictionResult: result,
        rules: effectiveRules,
        historicalDraws: draws,
      );
      _lastGeneratedTip = generated.numbers;
      _lastGeneratedSuperNumber = generated.superNumber;
      _lastGeneratedStrategy = strategy;
    }

    await _saveToStorage();
    notifyListeners();
  }


  Future<void> generateSignalTip() async {
    final scores = signalScores(limit: 6);
    final generated = _generatedTipService.generateSignalTip(
      scores: scores,
      recommendedSuperNumber: recommendedSuperNumber,
    );

    if (!generated.isValid) return;

    _lastGeneratedTip = generated.numbers;
    _lastGeneratedSuperNumber = generated.superNumber;
    _lastGeneratedStrategy = GeneratorStrategy.signal;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> setSelectedSystemSize(int value) async {
    if (value < 7 || value > 16) return;
    if (_selectedSystemSize == value) return;

    _selectedSystemSize = value;
    if (_manualSystemNumbers.length > _selectedSystemSize) {
      _manualSystemNumbers =
      _manualSystemNumbers.take(_selectedSystemSize).toList()
        ..sort();
    }

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> setSystemPlayType(SystemPlayType value) async {
    if (_systemPlayType == value) return;
    _systemPlayType = value;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> toggleManualSystemNumber(int number) async {
    if (number < 1 || number > 49) return;

    if (_manualSystemNumbers.contains(number)) {
      _manualSystemNumbers.remove(number);
    } else {
      if (_manualSystemNumbers.length >= _selectedSystemSize) {
        throw Exception(
          'Für System $_selectedSystemSize können maximal $_selectedSystemSize Zahlen manuell gewählt werden.',
        );
      }
      _manualSystemNumbers.add(number);
      _manualSystemNumbers.sort();
    }

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> clearManualSystemNumbers() async {
    _manualSystemNumbers = [];
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> generateSystemTip() async {
    final draws = analysisDrawResults;

    if (_systemPlayType == SystemPlayType.full && _selectedSystemSize > 10) {
      throw Exception('Vollsystem max. 10 Zahlen erlaubt');
    }

    if (_systemPlayType == SystemPlayType.vew && _selectedSystemSize > 13) {
      throw Exception('Intervall-System max. 13 Zahlen erlaubt');
    }

    final base = _generatorService.generateSystemBaseNumbers(
      _selectedSystemSize,
      rules: _rules,
      historicalDraws: draws,
      manualNumbers: _manualSystemNumbers,
    );

    final allRows = _systemPlayType == SystemPlayType.full
        ? _generatorService.buildSystemRows(base)
        : _generatorService.buildVewSystemRows(base);

    final rows = allRows.length > 200 ? allRows.take(200).toList() : allRows;

    _systemBaseNumbers = base;
    _systemRows = rows;

    if (rows.isNotEmpty) {
      _lastGeneratedTip = List<int>.from(rows.first)..sort();
      _lastGeneratedStrategy = GeneratorStrategy.system;
    }

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> generateFullSystemTip() async {
    await setSystemPlayType(SystemPlayType.full);
    await generateSystemTip();
  }

  Future<void> generateVewSystemTip() async {
    await setSystemPlayType(SystemPlayType.vew);
    await generateSystemTip();
  }

  Future<void> generateOptimizedSystemTip() async {
    await generateSystemTip();
    final optimized = optimizedSystemAiRows;
    if (optimized.isEmpty) return;

    _systemRows = optimized.map((e) => List<int>.from(e.row)).toList();
    if (_systemRows.isNotEmpty) {
      _lastGeneratedTip = List<int>.from(_systemRows.first)..sort();
      _lastGeneratedStrategy = GeneratorStrategy.system;
    }

    await _saveToStorage();
    notifyListeners();
  }

  List<SystemAiRowScore> _buildSystemAiRowScores() {
    if (_systemRows.isEmpty) return const [];
    return _scoreAndSortSystemRows(_systemRows);
  }

  List<SystemAiRowScore> _scoreAndSortSystemRows(List<List<int>> rows) {
    if (rows.isEmpty) return const [];

    final freq = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    for (final draw in analysisDrawResults) {
      for (final n in draw.numbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }

    final pairs = pairPatterns;
    final triples = triplePatterns;

    final scored = rows.map((rawRow) {
      final row = List<int>.from(rawRow)..sort();

      double pairBonus = 0;
      for (final pair in pairs.take(10)) {
        final matches = pair.pair.where(row.contains).length;
        if (matches == 2) pairBonus += pair.count * 0.35;
      }

      double tripleBonus = 0;
      for (final triple in triples.take(6)) {
        final matches = triple.triple.where(row.contains).length;
        if (matches == 3) tripleBonus += triple.count * 0.55;
      }

      final even = row.where((n) => n.isEven).length;
      final low = row.where((n) => n <= 24).length;
      final spread = row.last - row.first;
      final sum = row.fold<int>(0, (a, b) => a + b);

      double structureBonus = 0;
      if (even >= 2 && even <= 4) structureBonus += 4;
      if (low >= 2 && low <= 4) structureBonus += 4;
      if (spread >= 18 && spread <= 42) structureBonus += 4;
      if (sum >= 95 && sum <= 190) structureBonus += 4;

      final rarityScore =
      row.fold<double>(0, (acc, n) => acc + (12 - (freq[n] ?? 0)).clamp(0, 12));

      final score = rarityScore + pairBonus + tripleBonus + structureBonus;
      final roi = (score - 30) * 1.8;
      final estimatedEuro = score * 0.85;
      final hit4Chance = ((pairBonus + tripleBonus) / 8).round().clamp(0, 9);
      final hit3Base = (structureBonus / 2).round().clamp(0, 9);

      final label = hit4Chance >= 3
          ? '4+ Fokus'
          : hit3Base >= 4
          ? '3er Basis'
          : 'Struktur';

      return SystemAiRowScore(
        row: row,
        score: score,
        label: label,
        roi: roi,
        estimatedEuro: estimatedEuro,
        hit4Chance: hit4Chance,
        hit3Base: hit3Base,
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  List<SystemAiRowScore> _optimizeSystemRows(List<SystemAiRowScore> scoredRows) {
    if (scoredRows.isEmpty) return const [];

    final total = scoredRows.length;
    final target = _systemPlayType == SystemPlayType.full
        ? (total * 0.35).round().clamp(4, 24)
        : (total * 0.6).round().clamp(4, 24);

    final selected = <SystemAiRowScore>[];
    for (final item in scoredRows) {
      if (selected.length >= target) break;

      final tooSimilar = selected.any((existing) {
        final overlap = existing.row.where(item.row.contains).length;
        return overlap >= 5;
      });

      if (!tooSimilar || selected.length < 2) {
        selected.add(SystemAiRowScore(
          row: List<int>.from(item.row),
          score: item.score,
          label: item.label,
          roi: item.roi,
          estimatedEuro: item.estimatedEuro,
          hit4Chance: item.hit4Chance,
          hit3Base: item.hit3Base,
          optimized: true,
        ));
      }
    }

    return selected.isEmpty ? scoredRows.take(target).toList() : selected;
  }

  Future<int> saveSystemRowsAsTips() async {
    if (_systemRows.isEmpty) return 0;

    final targetType = _defaultTipTargetDrawType();
    final targetDate = _nextDateForDrawType(targetType);
    final source = '${_systemPlayType == SystemPlayType.full ? 'voll' : 'vew'}_$_selectedSystemSize';

    final added = _savedTipService.addSystemRows(
      tips: _savedTips,
      rows: _systemRows,
      source: source,
      strategy: GeneratorStrategy.system,
      targetDrawType: targetType,
      targetDrawDate: targetDate,
    );

    if (added == 0) return 0;

    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
    return added;
  }

  Future<void> clearSystemTip() async {
    _systemBaseNumbers = [];
    _systemRows = [];
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> applyBestAnalyzedTip() async {
    final bestTip = bestAnalyzedTip;
    if (bestTip.length != 6) return;

    final generated = _generatedTipService.fromNumbers(
      bestTip,
      recommendedSuperNumber: recommendedSuperNumber,
    );
    _lastGeneratedTip = generated.numbers;
    _lastGeneratedSuperNumber = generated.superNumber;
    _lastGeneratedStrategy = GeneratorStrategy.pro;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> applyMultiAiTip(String suggestionId) async {
    final suggestions = multiAiSuggestions;

    MultiAiTipSuggestion? selected;
    for (final item in suggestions) {
      if (item.id == suggestionId) {
        selected = item;
        break;
      }
    }

    if (selected == null) return;
    if (selected.numbers.length != 6) return;

    final generated = _generatedTipService.fromNumbers(
      selected.numbers,
      recommendedSuperNumber: recommendedSuperNumber,
    );
    _lastGeneratedTip = generated.numbers;
    _lastGeneratedSuperNumber = generated.superNumber;
    _lastGeneratedStrategy = GeneratorStrategy.pro;
    await _saveToStorage();
    notifyListeners();
  }

  DrawType _defaultTipTargetDrawType() {
    switch (_drawMode) {
      case DrawMode.wednesday:
        return DrawType.wednesday;
      case DrawMode.saturday:
        return DrawType.saturday;
      case DrawMode.combined:
        return _nextScheduledDrawType(DateTime.now());
    }
  }

  DrawType _nextScheduledDrawType(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    final daysUntilWednesday = (DateTime.wednesday - today.weekday) % 7;
    final daysUntilSaturday = (DateTime.saturday - today.weekday) % 7;

    if (daysUntilWednesday == daysUntilSaturday) return DrawType.wednesday;
    return daysUntilWednesday < daysUntilSaturday
        ? DrawType.wednesday
        : DrawType.saturday;
  }

  DateTime? _nextDateForDrawType(DrawType type) {
    if (type == DrawType.unknown) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetWeekday = type == DrawType.wednesday
        ? DateTime.wednesday
        : DateTime.saturday;
    final daysUntilTarget = (targetWeekday - today.weekday) % 7;
    return today.add(Duration(days: daysUntilTarget));
  }

bool _sameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCalendarDateAfter(DateTime a, DateTime b) {
    final left = DateTime(a.year, a.month, a.day);
    final right = DateTime(b.year, b.month, b.day);
    return left.isAfter(right);
  }

  bool _tipMatchesDrawForEvaluation(LottoTip tip, DrawResult draw) {
    final drawType = DrawTypeX.fromDate(draw.drawDate);

    // Neue Regel: Offene/alte Tipps ohne Zielziehung werden nicht mehr blind
    // gegen die aktuell ausgewählte Ziehung geprüft.
    if (tip.targetDrawType == DrawType.unknown || drawType == DrawType.unknown) {
      return false;
    }

    if (tip.targetDrawType != drawType) return false;

    // Wenn ein Ziel-Datum vorhanden ist, muss genau diese Ziehung gewählt sein.
    final targetDate = tip.targetDrawDate;
    if (targetDate != null && !_sameCalendarDate(targetDate, draw.drawDate)) {
      return false;
    }

    // Schutz vor rückwirkenden Treffern: Ein Tipp, der erst nach dem Ziehungstag
    // gespeichert wurde, darf nicht als echter Treffer für diese Ziehung zählen.
    if (_isCalendarDateAfter(tip.createdAt, draw.drawDate)) {
      return false;
    }

    return true;
  }

  List<LottoTip> _tipsMatchingSelectedDraw(DrawResult draw) {
    return _savedTips
        .where((tip) => _tipMatchesDrawForEvaluation(tip, draw))
        .toList(growable: false);
  }

  Future<bool> saveTipFromNumbers(
    List<int> numbers, {
    int? superNumber,
    String source = 'manual',
    GeneratorStrategy? strategy,
    DrawType? targetDrawType,
    DateTime? targetDrawDate,
  }) async {
    final resolvedTargetType = targetDrawType ?? _defaultTipTargetDrawType();
    final resolvedTargetDate = targetDrawDate ?? _nextDateForDrawType(resolvedTargetType);
    final normalizedSuperNumber = _savedTipService.normalizeSuperNumber(superNumber);

    final exists = _savedTipService.containsDuplicate(
      _savedTips,
      numbers: numbers,
      superNumber: normalizedSuperNumber,
      targetDrawType: resolvedTargetType,
      targetDrawDate: resolvedTargetDate,
      strategy: strategy,
    );
    if (exists) return false;

    final tip = _savedTipService.createTipFromNumbers(
      numbers: numbers,
      superNumber: normalizedSuperNumber,
      source: source,
      strategy: strategy ?? GeneratorStrategyX.fromSource(source),
      targetDrawType: resolvedTargetType,
      targetDrawDate: resolvedTargetDate,
    );
    if (tip == null) return false;

    _savedTips.insert(0, tip);

    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<void> saveLastTip({String source = 'analysis', GeneratorStrategy? strategy}) async {
    if (_lastGeneratedTip == null) return;

    await saveTipFromNumbers(
      _lastGeneratedTip!,
      superNumber: _lastGeneratedSuperNumber,
      source: source,
      strategy: strategy ?? _lastGeneratedStrategy,
    );
  }

  void setGeneratedNumbers(List<int> numbers, {int? superNumber}) {
    _lastGeneratedTip = List<int>.from(numbers)..sort();
    _lastGeneratedSuperNumber = superNumber ?? _lastGeneratedSuperNumber;
    _lastGeneratedStrategy = GeneratorStrategy.manual;
    notifyListeners();
  }

  Future<void> removeTip(String id) async {
    final removed = _savedTipService.removeById(_savedTips, id);
    if (!removed) return;

    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> addDrawResult({
    required DateTime drawDate,
    required List<int> numbers,
    int? superNumber,
    int? additionalNumber,
    String? spiel77,
    String? super6,
  }) async {
    final normalized = List<int>.from(numbers)
      ..sort();

    final duplicateIndex = _drawResults.indexWhere(
          (draw) => DrawHistoryService.sameDate(draw.drawDate, drawDate),
    );

    final draw = DrawResult(
      id: DateTime
          .now()
          .microsecondsSinceEpoch
          .toString(),
      drawDate: drawDate,
      numbers: normalized,
      superNumber: superNumber,
      spiel77: _normalizeDigitText(spiel77),
      super6: _normalizeDigitText(super6),
    );

    if (duplicateIndex != -1) {
      _drawResults[duplicateIndex] =
          DrawHistoryService.replaceManualDraw(_drawResults[duplicateIndex], draw);
      _normalizeDrawHistory();

      if (_matchesCurrentDrawMode(_drawResults[duplicateIndex])) {
        _selectedDrawForCheck = _drawResults[duplicateIndex];
      } else {
        _ensureSelectedDrawMatchesMode();
      }

      _normalizeAnalysisWindow(notify: false);
      _rebuildCheckResults(notify: false);
      await _saveToStorage();
      notifyListeners();
      return;
    }

    _drawResults.insert(0, draw);
    _normalizeDrawHistory();

    if (_matchesCurrentDrawMode(draw)) {
      _selectedDrawForCheck = draw;
    } else {
      _ensureSelectedDrawMatchesMode();
    }

    _normalizeAnalysisWindow(notify: false);
    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> removeDrawResult(String id) async {
    final wasSelected = _selectedDrawForCheck?.id == id;

    _drawResults.removeWhere((draw) => draw.id == id);

    if (wasSelected) {
      _selectedDrawForCheck = null;
      _ensureSelectedDrawMatchesMode();
    }

    _normalizeAnalysisWindow(notify: false);
    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> selectDrawAndCheck(String drawId) async {
    try {
      final draw = _drawResults.firstWhere((d) => d.id == drawId);
      if (_matchesCurrentDrawMode(draw)) {
        _selectedDrawForCheck = draw;
      } else {
        _selectedDrawForCheck = null;
        _ensureSelectedDrawMatchesMode();
      }
    } catch (_) {
      _selectedDrawForCheck = null;
    }

    _rebuildCheckResults(notify: false);
    await _saveToStorage();
    notifyListeners();
  }

  Future<int> autoImportLatestDraws() async {
    const recentWeeks = 8;
    _beginImport(label: 'Automatische Prüfung', totalYears: 1);

    try {
      final all = await _importService.fetchRecentResults(weeks: recentWeeks);

      final toImport = all.where(
            (d) =>
        d.drawDate.weekday == DateTime.wednesday ||
            d.drawDate.weekday == DateTime.saturday,
      ).toList()
        ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

      final inserted = await _mergeImportedDraws(toImport);

      _importProcessedYears = 1;
      _lastImportMessage = inserted == 0
          ? 'Automatische Prüfung: keine neuen Ziehungen der letzten $recentWeeks Wochen.'
          : 'Automatische Prüfung: $inserted Ziehung(en) der letzten $recentWeeks Wochen importiert.';
      return inserted;
    } finally {
      _finishImport();
    }
  }

  Future<int> importHistoricalWednesdaySince2000() async {
    return importHistoricalRange(
      startYear: 2000,
      endYear: DateTime
          .now()
          .year,
      weekdayFilter: DateTime.wednesday,
      label: 'Mittwoch',
    );
  }

  Future<int> importHistoricalSaturdaySince1955() async {
    return importHistoricalRange(
      startYear: 1955,
      endYear: DateTime
          .now()
          .year,
      weekdayFilter: DateTime.saturday,
      label: 'Samstag',
    );
  }

  Future<int> importHistoricalRange({
    required int startYear,
    required int endYear,
    int? weekdayFilter,
    String? label,
  }) async {
    final minYear = startYear <= endYear ? startYear : endYear;
    final maxYear = startYear <= endYear ? endYear : startYear;

    _beginImport(
      label: label ?? 'Historischer Import',
      totalYears: maxYear - minYear + 1,
    );

    try {
      int inserted = 0;

      for (int year = maxYear; year >= minYear; year--) {
        _importCurrentYear = year;
        notifyListeners();

        List<DrawResult> yearly = [];
        try {
          yearly = await _importService.fetchYearResults(year);
        } catch (_) {
          _importProcessedYears++;
          notifyListeners();
          continue;
        }

        Iterable<DrawResult> filtered = yearly;

        if (weekdayFilter != null) {
          filtered = filtered.where((d) => d.drawDate.weekday == weekdayFilter);
        } else {
          filtered = filtered.where(
                (d) =>
            d.drawDate.weekday == DateTime.wednesday ||
                d.drawDate.weekday == DateTime.saturday,
          );
        }

        inserted += await _mergeImportedDraws(
          filtered.toList(),
          saveAfterMerge: true,
        );
        await _saveDrawHistoryBox();

        _importProcessedYears++;
        notifyListeners();
      }

      await _saveToStorage();

      final labelText = label ??
          (weekdayFilter == null ? 'Mittwoch+Samstag' : 'Ziehungen');

      _lastImportMessage = inserted == 0
          ? 'Keine neuen $labelText-Ziehungen im Zeitraum $minYear–$maxYear gefunden.'
          : '$inserted neue $labelText-Ziehungen im Zeitraum $minYear–$maxYear importiert.';
      return inserted;
    } finally {
      _finishImport();
    }
  }

  Future<int> _mergeImportedDraws(List<DrawResult> importedDraws, {
    bool saveAfterMerge = true,
  }) async {
    final inserted = DrawHistoryService.mergeImportedDraws(
      _drawResults,
      importedDraws,
    );

    _ensureSelectedDrawMatchesMode();
    _normalizeAnalysisWindow(notify: false);
    _rebuildCheckResults(notify: false);

    if (saveAfterMerge) {
      await _saveToStorage();
    }

    return inserted;
  }

  void _beginImport({
    required String label,
    required int totalYears,
  }) {
    _isImporting = true;
    _lastImportMessage = null;
    _importLabel = label;
    _importCurrentYear = null;
    _importProcessedYears = 0;
    _importTotalYears = totalYears;
    notifyListeners();
  }

  void _finishImport() {
    _isImporting = false;
    _importCurrentYear = null;
    notifyListeners();
  }

  void clearImportMessage() {
    _lastImportMessage = null;
    notifyListeners();
  }

  void resetRules() {
    _rules = AnalysisRuleSet.initial();
    notifyListeners();
  }

  void _normalizeAnalysisWindow({bool notify = true}) {
    final maxOffset = analysisMaxOffset;

    if (filteredDrawResults.isEmpty) {
      _analysisStartOffset = 0;
      _analysisEndOffset = 0;
    } else {
      _analysisStartOffset = _analysisStartOffset.clamp(0, maxOffset);
      _analysisEndOffset = _analysisEndOffset.clamp(0, maxOffset);

      if (_analysisStartOffset > _analysisEndOffset) {
        final temp = _analysisStartOffset;
        _analysisStartOffset = _analysisEndOffset;
        _analysisEndOffset = temp;
      }
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> rebuildTipTrackingNow() async {
    _rebuildTipTrackingEntries(notify: false);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> clearTipTracking() async {
    _tipTrackingEntries.clear();
    await _saveToStorage();
    notifyListeners();
  }

  void _rebuildTipTrackingEntries({bool notify = true}) {
    final draw = _selectedDrawForCheck;
    if (draw == null || _savedTips.isEmpty) {
      if (notify) notifyListeners();
      return;
    }

    final existingById = <String, TipTrackingEntry>{
      for (final entry in _tipTrackingEntries) entry.id: entry,
    };

    for (final tip in _savedTips) {
      final matched = tip.numbers
          .where((number) => draw.numbers.contains(number))
          .toSet()
          .toList()
        ..sort();

      final entry = TipTrackingEntry.fromTipAndDraw(
        tip: tip,
        draw: draw,
        matchedNumbers: matched,
      );
      existingById[entry.id] = entry;
    }

    final activeTipIds = _savedTips.map((tip) => tip.id).toSet();
    final merged = existingById.values
        .where((entry) => activeTipIds.contains(entry.tipId))
        .toList()
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));

    _tipTrackingEntries
      ..clear()
      ..addAll(merged.take(500));

    if (notify) notifyListeners();
  }

  void _rebuildCheckResults({bool notify = true}) {
    if (_selectedDrawForCheck == null || _savedTips.isEmpty) {
      _latestCheckResults = [];
    } else {
      _latestCheckResults = _drawCheckerService.checkAllTipsAgainstDraw(
        _savedTips,
        _selectedDrawForCheck!,
      );
    }

    _rebuildTipTrackingEntries(notify: false);

    if (notify) {
      notifyListeners();
    }
  }

  void _ensureSelectedDrawMatchesMode() {
    if (_selectedDrawForCheck != null &&
        _matchesCurrentDrawMode(_selectedDrawForCheck!)) {
      return;
    }

    final filtered = filteredDrawResults;
    _selectedDrawForCheck = filtered.isEmpty ? null : filtered.first;
  }

  bool _matchesCurrentDrawMode(DrawResult draw) {
    switch (_drawMode) {
      case DrawMode.combined:
        return true;
      case DrawMode.wednesday:
        return draw.drawDate.weekday == DateTime.wednesday;
      case DrawMode.saturday:
        return draw.drawDate.weekday == DateTime.saturday;
    }
  }

  String _drawModeKeyValue(DrawMode mode) {
    switch (mode) {
      case DrawMode.combined:
        return 'combined';
      case DrawMode.wednesday:
        return 'wednesday';
      case DrawMode.saturday:
        return 'saturday';
    }
  }

  DrawMode _drawModeFromKey(String? value) {
    switch (value) {
      case 'wednesday':
        return DrawMode.wednesday;
      case 'saturday':
        return DrawMode.saturday;
      case 'combined':
      default:
        return DrawMode.combined;
    }
  }

  AnalysisSummary _buildAnalysisSummary(List<DrawResult> draws) {
    if (draws.isEmpty) return AnalysisSummary.empty();

    double totalSum = 0;
    double totalEven = 0;
    double totalLow = 0;
    double totalSpread = 0;
    int repeatEvents = 0;
    int repeatTotal = 0;

    final numberCounts = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    final endDigitCounts = <int, int>{for (int i = 0; i <= 9; i++) i: 0};
    final pairCounts = <String, int>{};
    final repeatHistogram = <int, int>{};

    for (int index = 0; index < draws.length; index++) {
      final numbers = List<int>.from(draws[index].numbers)
        ..sort();

      totalSum += numbers.fold<int>(0, (a, b) => a + b);
      totalEven += numbers
          .where((n) => n.isEven)
          .length;
      totalLow += numbers
          .where((n) => n <= 24)
          .length;
      totalSpread += numbers.isEmpty ? 0 : numbers.last - numbers.first;

      for (final number in numbers) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
        final digit = number % 10;
        endDigitCounts[digit] = (endDigitCounts[digit] ?? 0) + 1;
      }

      for (int i = 0; i < numbers.length; i++) {
        for (int j = i + 1; j < numbers.length; j++) {
          final key = '${numbers[i]}-${numbers[j]}';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }

      if (index < draws.length - 1) {
        final prevNumbers = draws[index + 1].numbers.toSet();
        final repeats = numbers
            .where(prevNumbers.contains)
            .length;
        repeatEvents++;
        repeatTotal += repeats;
        repeatHistogram[repeats] = (repeatHistogram[repeats] ?? 0) + 1;
      }
    }

    final hotNumbers = numberCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    final coldNumbers = numberCounts.entries.toList()
      ..sort((a, b) {
        final byCount = a.value.compareTo(b.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    final endDigits = endDigitCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    final pairs = pairCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    return AnalysisSummary(
      drawCount: draws.length,
      averageSum: totalSum / draws.length,
      averageEven: totalEven / draws.length,
      averageLow: totalLow / draws.length,
      averageSpread: totalSpread / draws.length,
      averageRepeatFromPrevious:
      repeatEvents == 0 ? 0 : repeatTotal / repeatEvents,
      hotNumbers: hotNumbers
          .take(10)
          .map((e) => AnalysisNumberStat(number: e.key, count: e.value))
          .toList(),
      coldNumbers: coldNumbers
          .take(10)
          .map((e) => AnalysisNumberStat(number: e.key, count: e.value))
          .toList(),
      strongEndDigits: endDigits
          .take(5)
          .map((e) => AnalysisEndDigitStat(digit: e.key, count: e.value))
          .toList(),
      strongPairs: pairs
          .take(8)
          .map((e) {
        final parts = e.key.split('-').map(int.parse).toList();
        return AnalysisPairStat(pair: parts, count: e.value);
      })
          .toList(),
      repeatHistogram: repeatHistogram,
    );
  }


  List<MultiAiTipSuggestion> _buildMultiAiSuggestions(List<DrawResult> draws) {
    final pro = _buildAnalysisProSummary(draws);
    final summary = _buildAnalysisSummary(draws);
    if (draws.length < 12 || pro.topScores.length < 6) return const [];

    final lastDraw = draws.isEmpty ? const <int>[] : draws.first.numbers;
    final hot = summary.hotNumbers.map((e) => e.number).toList();
    final cold = summary.coldNumbers.map((e) => e.number).toList();
    final trendingUp = pro.trendingUp.map((e) => e.number).toList();
    final trendingDown = pro.trendingDown.map((e) => e.number).toList();
    final rebound = pro.reboundNumbers.map((e) => e.number).toList();
    final topScores = pro.topScores.map((e) => e.number).toList();

    final conservative = _composeRankedTip([
      ...topScores,
      ...hot,
      ...rebound,
    ], avoid: [...trendingDown, ...cold]);

    final balanced = _composeBalancedTip(
      topScores: topScores,
      hot: hot,
      rebound: rebound,
      trendingUp: trendingUp,
      avoid: [...trendingDown.take(4), ...cold.take(4)],
    );

    final aggressive = _composeAggressiveTip(
      trendingUp: trendingUp,
      rebound: rebound,
      topScores: topScores,
      cold: cold,
      lastDraw: lastDraw,
      avoid: trendingDown,
    );

    return [
      MultiAiTipSuggestion(
        id: 'conservative',
        title: 'Multi AI – Stabil',
        subtitle: 'Konservativ auf Basis stabiler Häufigkeit',
        numbers: conservative,
        riskLabel: 'Niedriges Risiko',
        reasoning: 'Fokus auf hohe Scores, Hot Numbers und ruhige Wiederholungsmuster. Gut für solide Standard-Tipps.',
      ),
      MultiAiTipSuggestion(
        id: 'balanced',
        title: 'Multi AI – Balanced',
        subtitle: 'Ausgewogene Mischung aus Stabilität und Trend',
        numbers: balanced,
        riskLabel: 'Mittleres Risiko',
        reasoning: 'Kombiniert stabile Scores mit Trendzahlen und Rebound-Kandidaten. Das ist der beste Allround-Mix.',
      ),
      MultiAiTipSuggestion(
        id: 'aggressive',
        title: 'Multi AI – Dynamisch',
        subtitle: 'Mehr Trend und Rückkehr-Chance, weniger Mainstream',
        numbers: aggressive,
        riskLabel: 'Höheres Risiko',
        reasoning: 'Gewichtet Trendwechsel und Rückkehr-Zahlen stärker. Etwas mutiger, dafür mit höherer Schwankung.',
      ),
    ];
  }

  List<int> _composeRankedTip(List<int> ranked, {List<int> avoid = const []}) {
    final tip = <int>[];
    for (final number in ranked) {
      if (number < 1 || number > 49) continue;
      if (avoid.contains(number)) continue;
      if (!tip.contains(number)) {
        tip.add(number);
      }
      if (tip.length == 6) break;
    }

    for (int i = 1; i <= 49 && tip.length < 6; i++) {
      if (!tip.contains(i) && !avoid.contains(i)) {
        tip.add(i);
      }
    }

    tip.sort();
    return _normalizeTipDistribution(tip);
  }

  List<int> _composeBalancedTip({
    required List<int> topScores,
    required List<int> hot,
    required List<int> rebound,
    required List<int> trendingUp,
    required List<int> avoid,
  }) {
    final pool = <int>[];
    pool.addAll(topScores.take(3));
    pool.addAll(hot.take(2));
    pool.addAll(rebound.take(2));
    pool.addAll(trendingUp.take(3));
    return _composeRankedTip(pool, avoid: avoid);
  }

  List<int> _composeAggressiveTip({
    required List<int> trendingUp,
    required List<int> rebound,
    required List<int> topScores,
    required List<int> cold,
    required List<int> lastDraw,
    required List<int> avoid,
  }) {
    final pool = <int>[];
    pool.addAll(trendingUp.take(4));
    pool.addAll(rebound.take(3));
    pool.addAll(topScores.skip(1).take(4));
    pool.addAll(cold.skip(2).take(3));
    final tip = _composeRankedTip(pool, avoid: [...avoid, ...lastDraw.take(2)]);
    return tip;
  }

  List<int> _normalizeTipDistribution(List<int> tip) {
    final unique = tip.where((e) => e >= 1 && e <= 49).toSet().toList()
      ..sort();
    while (unique.length < 6) {
      for (int i = 1; i <= 49 && unique.length < 6; i++) {
        if (!unique.contains(i)) unique.add(i);
      }
    }

    int even = unique
        .where((n) => n.isEven)
        .length;
    int low = unique
        .where((n) => n <= 24)
        .length;

    if (even == 0 || even == 6 || low == 0 || low == 6) {
      final replacementCandidates = List<int>.generate(49, (i) => i + 1)
          .where((n) => !unique.contains(n))
          .toList();
      for (final candidate in replacementCandidates) {
        final test = List<int>.from(unique);
        test[test.length - 1] = candidate;
        test.sort();
        final testEven = test
            .where((n) => n.isEven)
            .length;
        final testLow = test
            .where((n) => n <= 24)
            .length;
        if (testEven >= 2 && testEven <= 4 && testLow >= 2 && testLow <= 4) {
          unique
            ..clear()
            ..addAll(test);
          break;
        }
      }
    }

    unique.sort();
    return unique.take(6).toList();
  }

  AnalysisProSummary _buildAnalysisProSummary(List<DrawResult> draws) {
    if (draws.length < 10) return AnalysisProSummary.empty();

    final recentSize = draws.length >= 60 ? 20 : (draws.length >= 30 ? 12 : 8);
    final recent = draws.take(recentSize).toList();
    final older = draws.length > recentSize ? draws.sublist(recentSize) : <
        DrawResult>[];
    final medium = draws.take(draws.length >= 50 ? 50 : draws.length).toList();

    final totalCounts = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    final recentCounts = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    final olderCounts = <int, int>{for (int i = 1; i <= 49; i++) i: 0};
    final mediumCounts = <int, int>{for (int i = 1; i <= 49; i++) i: 0};

    for (final draw in draws) {
      for (final number in draw.numbers) {
        totalCounts[number] = (totalCounts[number] ?? 0) + 1;
      }
    }
    for (final draw in recent) {
      for (final number in draw.numbers) {
        recentCounts[number] = (recentCounts[number] ?? 0) + 1;
      }
    }
    for (final draw in older) {
      for (final number in draw.numbers) {
        olderCounts[number] = (olderCounts[number] ?? 0) + 1;
      }
    }
    for (final draw in medium) {
      for (final number in draw.numbers) {
        mediumCounts[number] = (mediumCounts[number] ?? 0) + 1;
      }
    }

    final latestDrawNumbers = draws.first.numbers.toSet();
    final reboundCandidates = <int, int>{};
    for (int number = 1; number <= 49; number++) {
      reboundCandidates[number] = _drawGap(draws, number);
    }

    final scores = <AnalysisScoreStat>[];
    for (int number = 1; number <= 49; number++) {
      final total = totalCounts[number] ?? 0;
      final recentValue = recentCounts[number] ?? 0;
      final olderValue = olderCounts[number] ?? 0;
      final mediumValue = mediumCounts[number] ?? 0;
      final recentRate = recent.isEmpty ? 0.0 : recentValue / recent.length;
      final olderRate = older.isEmpty ? 0.0 : olderValue / older.length;
      final totalRate = draws.isEmpty ? 0.0 : total / draws.length;

      double score = 0;
      score += recentValue * 3.0;
      score += mediumValue * 1.5;
      score += totalRate * 20.0;
      score += (recentRate - olderRate) * 30.0;

      final gap = reboundCandidates[number] ?? 999;
      if (!latestDrawNumbers.contains(number) && gap >= 1 && gap <= 4) {
        score += (5 - gap) * 2.0;
      }
      if (latestDrawNumbers.contains(number)) {
        score -= 2.5;
      }

      scores.add(
        AnalysisScoreStat(
          number: number,
          score: score,
          totalCount: total,
          recentCount: recentValue,
          olderCount: olderValue,
        ),
      );
    }

    scores.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.number.compareTo(b.number);
    });

    final trendDiffs = <MapEntry<int, int>>[];
    for (int number = 1; number <= 49; number++) {
      trendDiffs.add(MapEntry(
          number, (recentCounts[number] ?? 0) - (olderCounts[number] ?? 0)));
    }
    final trendingUp = trendDiffs.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byDiff = b.value.compareTo(a.value);
        if (byDiff != 0) return byDiff;
        return a.key.compareTo(b.key);
      });
    final trendingDown = trendDiffs.where((e) => e.value < 0).toList()
      ..sort((a, b) {
        final byDiff = a.value.compareTo(b.value);
        if (byDiff != 0) return byDiff;
        return a.key.compareTo(b.key);
      });

    final rebound = reboundCandidates.entries
        .where((e) =>
    !latestDrawNumbers.contains(e.key) && e.value >= 1 && e.value <= 4)
        .toList()
      ..sort((a, b) {
        final byGap = a.value.compareTo(b.value);
        if (byGap != 0) return byGap;
        final byRecent = (recentCounts[b.key] ?? 0).compareTo(
            recentCounts[a.key] ?? 0);
        if (byRecent != 0) return byRecent;
        return a.key.compareTo(b.key);
      });

    final bestTip = _buildBestTipFromScores(scores);

    return AnalysisProSummary(
      bestTip: bestTip,
      trendingUp: trendingUp.take(6).map((e) =>
          AnalysisNumberStat(number: e.key, count: e.value)).toList(),
      trendingDown: trendingDown.take(6).map((e) =>
          AnalysisNumberStat(number: e.key, count: e.value.abs())).toList(),
      reboundNumbers: rebound.take(6).map((e) =>
          AnalysisNumberStat(number: e.key, count: e.value)).toList(),
      topScores: scores.take(10).toList(),
      strategy: 'Gewichtet nach letzter Phase, Gesamt-Häufigkeit, Trendwechsel und Rückkehr-Chance außerhalb der letzten Ziehung.',
    );
  }

  List<int> _buildBestTipFromScores(List<AnalysisScoreStat> ranked) {
    final selected = <int>[];
    int evenCount = 0;
    int lowCount = 0;

    bool canStillReach(int current, int targetMin, int slotsLeft) {
      return current + slotsLeft >= targetMin;
    }

    bool wouldBreakMax(int current, int maxAllowed) => current > maxAllowed;

    for (final item in ranked) {
      if (selected.length >= 6) break;
      final n = item.number;
      final nextEven = evenCount + (n.isEven ? 1 : 0);
      final nextLow = lowCount + (n <= 24 ? 1 : 0);
      final slotsLeftAfter = 6 - (selected.length + 1);

      if (wouldBreakMax(nextEven, 4) || wouldBreakMax(nextLow, 4)) {
        continue;
      }
      if (!canStillReach(nextEven, 2, slotsLeftAfter) && selected.length >= 3) {
        continue;
      }
      if (!canStillReach(nextLow, 2, slotsLeftAfter) && selected.length >= 3) {
        continue;
      }
      if (selected.any((x) => (x % 10) == (n % 10))) {
        final remainingDistinct = ranked
            .where((e) => !selected.contains(e.number) && e.number != n)
            .length;
        if (remainingDistinct > slotsLeftAfter) {
          continue;
        }
      }

      selected.add(n);
      if (n.isEven) evenCount++;
      if (n <= 24) lowCount++;
    }

    for (final item in ranked) {
      if (selected.length >= 6) break;
      if (!selected.contains(item.number)) {
        selected.add(item.number);
      }
    }

    selected.sort();
    return selected.take(6).toList();
  }

  int _drawGap(List<DrawResult> draws, int number) {
    for (int i = 0; i < draws.length; i++) {
      if (draws[i].numbers.contains(number)) {
        return i;
      }
    }
    return draws.length + 1;
  }

  List<int> _sanitizeNumbers(List<int> input) {
    final clean = input.where((e) => e >= 1 && e <= 49).toSet().toList()
      ..sort();
    return clean;
  }

  void _normalizeDrawHistory() {
    DrawHistoryService.normalizeDrawHistory(_drawResults);
  }

  void rebuildFullAnalysis() {
    _normalizeAnalysisWindow(notify: false);
    _rebuildCheckResults(notify: false);
    notifyListeners();
  }

  TipSimulationSummary simulateTip(List<int> tip) {
    final draws = analysisDrawResults;

    final distribution = <int, int>{
      for (int i = 0; i <= 6; i++) i: 0,
    };

    final normalizedTip = tip.where((n) => n >= 1 && n <= 49).toSet().toList()
      ..sort();

    for (final draw in draws) {
      final hits = normalizedTip
          .where((n) => draw.numbers.contains(n))
          .length;
      distribution[hits] = (distribution[hits] ?? 0) + 1;
    }

    return TipSimulationSummary(
      hitDistribution: distribution,
      totalDraws: draws.length,
    );
  }

  TipSimulationSummary? get lastTipSimulation {
    if (_lastGeneratedTip == null || _lastGeneratedTip!.length != 6) {
      return null;
    }
    return simulateTip(_lastGeneratedTip!);
  }


  WinClassSimulationSummary simulateTipWithSuper(
      List<int> tip, {
        int? superNumber,
        int? drawCount,
      }) {
    final draws = analysisDrawResults;
    if (draws.isEmpty) {
      return WinClassSimulationSummary(
        totalDraws: 0,
        hit2: 0,
        hit3: 0,
        hit4: 0,
        hit4WithSuper: 0,
        hit5: 0,
        hit5WithSuper: 0,
        hit6: 0,
        hit6WithSuper: 0,
        superNumber: superNumber,
      );
    }

    final safeDrawCount = drawCount == null
        ? draws.length
        : drawCount.clamp(1, draws.length);
    final scopedDraws = draws.take(safeDrawCount).toList();

    int hit2 = 0;
    int hit3 = 0;
    int hit4 = 0;
    int hit4WithSuper = 0;
    int hit5 = 0;
    int hit5WithSuper = 0;
    int hit6 = 0;
    int hit6WithSuper = 0;

    final normalizedTip = tip.where((n) => n >= 1 && n <= 49).toSet().toList()
      ..sort();

    for (final draw in scopedDraws) {
      final hits = normalizedTip.where((n) => draw.numbers.contains(n)).length;
      final superHit = superNumber != null &&
          draw.superNumber != null &&
          superNumber == draw.superNumber;

      if (hits == 2) hit2++;
      if (hits == 3) hit3++;
      if (hits == 4 && !superHit) hit4++;
      if (hits == 4 && superHit) hit4WithSuper++;
      if (hits == 5 && !superHit) hit5++;
      if (hits == 5 && superHit) hit5WithSuper++;
      if (hits == 6 && !superHit) hit6++;
      if (hits == 6 && superHit) hit6WithSuper++;
    }

    return WinClassSimulationSummary(
      totalDraws: scopedDraws.length,
      hit2: hit2,
      hit3: hit3,
      hit4: hit4,
      hit4WithSuper: hit4WithSuper,
      hit5: hit5,
      hit5WithSuper: hit5WithSuper,
      hit6: hit6,
      hit6WithSuper: hit6WithSuper,
      superNumber: superNumber,
    );
  }

  List<WinRangeEvaluation> evaluateTipAcrossTimeWindows(
      List<int> tip, {
        int? superNumber,
      }) {
    final available = analysisDrawResults.length;
    if (tip.length != 6 || available == 0) return const [];

    final orderedWindows = <int>[
      12,
      26,
      52,
      104,
      if (available > 104) available,
    ];

    final uniqueWindows = <int>[];
    for (final value in orderedWindows) {
      final safe = value > available ? available : value;
      if (safe >= 1 && !uniqueWindows.contains(safe)) {
        uniqueWindows.add(safe);
      }
    }

    return uniqueWindows.map((window) {
      final summary = simulateTipWithSuper(
        tip,
        superNumber: superNumber,
        drawCount: window,
      );

      String recommendation;
      if (summary.hit4WithSuper > 0) {
        recommendation =
        'Stark für 4+SZ im Rücktest. Auch ROI und Modellwert wirken hier am interessantesten.';
      } else if (summary.hit4 > 0 || summary.hit5 > 0 || summary.hit5WithSuper > 0) {
        recommendation =
        'Solides Fenster für 4er oder besser. Historisch gutes Chancenprofil mit brauchbarer Rendite-Tendenz.';
      } else if (summary.hit3 > 0) {
        recommendation =
        'Bisher eher 3er-lastig. Als Einstiegsfenster okay, für 4+SZ und starke Rendite noch schwach.';
      } else {
        recommendation =
        'In diesem Zeitfenster kaum belastbare Trefferklassen. Modellwert und ROI eher niedrig.';
      }

      return WinRangeEvaluation(
        label: window == available ? 'Komplette Historie' : 'Letzte $window',
        drawCount: window,
        summary: summary,
        recommendation: recommendation,
      );
    }).toList();
  }

  List<WinRangeEvaluation> get currentTipRangeAnalysis {
    if (_lastGeneratedTip == null || _lastGeneratedTip!.length != 6) return const [];
    return evaluateTipAcrossTimeWindows(
      _lastGeneratedTip!,
      superNumber: _lastGeneratedSuperNumber,
    );
  }

  List<WinRangeEvaluation> get bestAiTipRangeAnalysis {
    final tip = bestAnalyzedTip;
    if (tip.length != 6) return const [];
    return evaluateTipAcrossTimeWindows(
      tip,
      superNumber: recommendedSuperNumber,
    );
  }

  WinRangeEvaluation? get bestCurrentTipWindow {
    final values = currentTipRangeAnalysis;
    if (values.isEmpty) return null;
    final sorted = List<WinRangeEvaluation>.from(values)
      ..sort((a, b) {
        final by4sz = b.summary.hit4WithSuper.compareTo(a.summary.hit4WithSuper);
        if (by4sz != 0) return by4sz;
        final byScore = b.summary.weightedScore.compareTo(a.summary.weightedScore);
        if (byScore != 0) return byScore;
        final byRoi = b.summary.estimatedRoiPercent.compareTo(a.summary.estimatedRoiPercent);
        if (byRoi != 0) return byRoi;
        return a.drawCount.compareTo(b.drawCount);
      });
    return sorted.first;
  }

  WinRangeEvaluation? get bestAiTipWindow {
    final values = bestAiTipRangeAnalysis;
    if (values.isEmpty) return null;
    final sorted = List<WinRangeEvaluation>.from(values)
      ..sort((a, b) {
        final by4sz = b.summary.hit4WithSuper.compareTo(a.summary.hit4WithSuper);
        if (by4sz != 0) return by4sz;
        final byScore = b.summary.weightedScore.compareTo(a.summary.weightedScore);
        if (byScore != 0) return byScore;
        final byRoi = b.summary.estimatedRoiPercent.compareTo(a.summary.estimatedRoiPercent);
        if (byRoi != 0) return byRoi;
        return a.drawCount.compareTo(b.drawCount);
      });
    return sorted.first;
  }

  bool get hasCurrentTipForWinSimulation =>
      _lastGeneratedTip != null && _lastGeneratedTip!.length == 6;

  TipSimulationSummary? get bestTipSimulation {
    final bestTip = bestAnalyzedTip;
    if (bestTip.length != 6) return null;
    return simulateTip(bestTip);
  }

String _formatDate(DateTime value) => AppFormatUtils.date(value);

  String? _normalizeDigitText(String? value) {
    if (value == null) return null;

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    return digits;
  }

  // ================= PHASE C/D PRO: MEINE TIPPS GEWINNPRUEFUNG =================
  // Diese Methoden werden von lib/features/tips/presentation/my_tips_screen.dart genutzt.
  // Sie halten die UI stabil, ohne von weiteren System-Domain-Dateien abzuhaengen.

  List<TipEvaluationResult> get tipEvaluationResults =>
      List.unmodifiable(_tipEvaluationResults);

  Future<void> clearTipEvaluationResults() async {
    _tipEvaluationResults = [];
    notifyListeners();
  }

  Future<List<TipEvaluationResult>> evaluateSavedTipsAgainstSelectedDraw() async {
    final draw = _selectedDrawForCheck;
    if (draw == null || _savedTips.isEmpty) {
      return <TipEvaluationResult>[];
    }

    final matchingTips = _tipsMatchingSelectedDraw(draw);
    if (matchingTips.isEmpty) {
      _tipEvaluationResults = <TipEvaluationResult>[];
      _rebuildCheckResults(notify: false);
      notifyListeners();
      return <TipEvaluationResult>[];
    }

    final now = DateTime.now();
    final results = <TipEvaluationResult>[];

    for (var i = 0; i < matchingTips.length; i++) {
      final tip = matchingTips[i];
      final numbers = _tipMatchService.normalizeLottoRow(tip.numbers);
      final row = _tipMatchService.buildRowEvaluation(
        rowIndex: 1,
        numbers: numbers,
        draw: draw,
        tipSuperNumber: tip.superNumber,
      );

      results.add(
        TipEvaluationResult(
          id: '${tip.id}_${draw.id}_${now.microsecondsSinceEpoch}_$i',
          evaluatedAt: now,
          playKind: LottoPlayKind.normal,
          draw: draw,
          baseNumbers: numbers,
          superNumber: tip.superNumber,
          rows: <TipRowEvaluation>[row],
          spiel77: _tipMatchService.evaluateAdditionalLottery(
            name: 'Spiel 77',
            tipNumber: null,
            drawNumber: draw.spiel77,
            expectedLength: 7,
          ),
          super6: _tipMatchService.evaluateAdditionalLottery(
            name: 'Super 6',
            tipNumber: null,
            drawNumber: draw.super6,
            expectedLength: 6,
          ),
        ),
      );
    }

    _tipEvaluationResults = _tipMatchService.sortResults(results);
    _rebuildCheckResults(notify: false);
    notifyListeners();
    return List<TipEvaluationResult>.unmodifiable(_tipEvaluationResults);
  }

  Future<TipEvaluationResult?> evaluateCurrentSystemAgainstSelectedDraw() async {
    final draw = _selectedDrawForCheck;
    if (draw == null) return null;

    final baseNumbers = _tipMatchService.normalizeLottoRow(_systemBaseNumbers);
    final sourceRows = _systemRows.isNotEmpty
        ? _systemRows
        : (baseNumbers.length >= 6 ? <List<int>>[baseNumbers] : <List<int>>[]);

    if (sourceRows.isEmpty) return null;

    final rows = <TipRowEvaluation>[];
    for (var i = 0; i < sourceRows.length; i++) {
      rows.add(
        _tipMatchService.buildRowEvaluation(
          rowIndex: i + 1,
          numbers: sourceRows[i],
          draw: draw,
          tipSuperNumber: superZahl,
        ),
      );
    }

    final result = TipEvaluationResult(
      id: 'system_${_systemPlayType.name}_${draw.id}_${DateTime.now().microsecondsSinceEpoch}',
      evaluatedAt: DateTime.now(),
      playKind: _systemPlayType == SystemPlayType.full
          ? LottoPlayKind.fullSystem
          : LottoPlayKind.vewSystem,
      draw: draw,
      baseNumbers: baseNumbers,
      superNumber: superZahl,
      rows: rows,
      spiel77: _tipMatchService.evaluateAdditionalLottery(
        name: 'Spiel 77',
        tipNumber: spiel77,
        drawNumber: draw.spiel77,
        expectedLength: 7,
      ),
      super6: _tipMatchService.evaluateAdditionalLottery(
        name: 'Super 6',
        tipNumber: super6,
        drawNumber: draw.super6,
        expectedLength: 6,
      ),
    );

    _tipEvaluationResults = _tipMatchService.sortResults(<TipEvaluationResult>[
      result,
      ..._tipEvaluationResults,
    ]).take(100).toList(growable: false);

    notifyListeners();
    return result;
  }



  // ================= ZUSATZSPIELE FINAL =================
  // Liefert immer sichtbare Werte fuer Systemspiel / Zusatzspiele.
  List<int> get top10Numbers {
    try {
      final values = getTopNumbers(count: 10).where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
      if (values.isNotEmpty) return values;
    } catch (_) {}
    final fallback = bestAnalyzedTip.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
    for (var n = 1; fallback.length < 10 && n <= 49; n++) {
      if (!fallback.contains(n)) fallback.add(n);
    }
    fallback.sort();
    return fallback.take(10).toList();
  }

  int get superZahl {
    final recommended = recommendedSuperNumber;
    if (recommended != null && recommended >= 0 && recommended <= 9) return recommended;
    final last = _lastGeneratedSuperNumber;
    if (last != null && last >= 0 && last <= 9) return last;
    return _zusatzMostLikelySingleDigit(
      extract: (draw) => draw.superNumber?.toString(),
      fallback: 0,
    );
  }

  int? get zusatzZahl {
    final selected = <int>{...bestAnalyzedTip};
    if (_lastGeneratedTip != null) selected.addAll(_lastGeneratedTip!);
    for (final n in top10Numbers) {
      if (!selected.contains(n)) return n;
    }
    for (var n = 1; n <= 49; n++) {
      if (!selected.contains(n)) return n;
    }
    return null;
  }

  String get spiel77 {
    final value = generateSpiel77();
    return value.isNotEmpty ? value : '7702026';
  }

  String get super6 {
    final value = generateSuper6();
    return value.isNotEmpty ? value : '620026';
  }

  void generateZusatzSpiele() {
    notifyListeners();
  }

  String generateSpiel77() {
    return _zusatzMostLikelyDigitSequence(
      length: 7,
      extract: (draw) => draw.spiel77,
      fallbackSeed: '7702026',
    );
  }

  String generateSuper6() {
    return _zusatzMostLikelyDigitSequence(
      length: 6,
      extract: (draw) => draw.super6,
      fallbackSeed: '620026',
    );
  }

  int _zusatzMostLikelySingleDigit({
    required String? Function(DrawResult draw) extract,
    required int fallback,
  }) {
    final counts = List<int>.filled(10, 0);
    for (final draw in analysisDrawResults) {
      final digits = _zusatzDigitsOnly(extract(draw));
      if (digits.isEmpty) continue;
      final digit = int.tryParse(digits[0]);
      if (digit != null && digit >= 0 && digit <= 9) counts[digit]++;
    }
    var best = fallback.clamp(0, 9);
    for (var i = 0; i < counts.length; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return best;
  }

  String _zusatzMostLikelyDigitSequence({
    required int length,
    required String? Function(DrawResult draw) extract,
    required String fallbackSeed,
  }) {
    final fallback = _zusatzNormalizeToLength(fallbackSeed, length);
    final matrix = List.generate(length, (_) => List<int>.filled(10, 0));
    var validRows = 0;

    for (final draw in analysisDrawResults) {
      final digits = _zusatzDigitsOnly(extract(draw));
      if (digits.length < length) continue;
      validRows++;
      final scoped = digits.substring(0, length);
      for (var i = 0; i < length; i++) {
        final digit = int.tryParse(scoped[i]);
        if (digit != null && digit >= 0 && digit <= 9) matrix[i][digit]++;
      }
    }

    if (validRows == 0) return fallback;

    final buffer = StringBuffer();
    for (var position = 0; position < length; position++) {
      var bestDigit = int.tryParse(fallback[position]) ?? 0;
      var bestCount = -1;
      for (var digit = 0; digit <= 9; digit++) {
        final count = matrix[position][digit];
        if (count > bestCount) {
          bestCount = count;
          bestDigit = digit;
        }
      }
      buffer.write(bestDigit);
    }

    final result = buffer.toString();
    return result.length == length ? result : fallback;
  }

  String _zusatzDigitsOnly(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _zusatzNormalizeToLength(String seed, int length) {
    final digits = _zusatzDigitsOnly(seed);
    if (digits.length >= length) return digits.substring(0, length);
    return (digits + ('0' * length)).substring(0, length);
  }

}