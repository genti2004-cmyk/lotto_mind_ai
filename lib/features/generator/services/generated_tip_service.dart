import 'dart:math';

import '../../draws/domain/draw_result.dart';
import '../domain/analysis_rule_set.dart';
import '../domain/lotto_generator_service.dart';
import 'pro_prediction_engine.dart';

class GeneratedTipPayload {
  final List<int> numbers;
  final int? superNumber;

  const GeneratedTipPayload({
    required this.numbers,
    required this.superNumber,
  });

  bool get isValid => numbers.length == 6;
}

class GeneratedTipService {
  final Random _random;

  GeneratedTipService({Random? random}) : _random = random ?? Random();

  int generateRandomSuperNumber() {
    return _random.nextInt(10);
  }

  GeneratedTipPayload generateRandomTip(LottoGeneratorService generatorService) {
    return GeneratedTipPayload(
      numbers: generatorService.generateRandomTip(),
      superNumber: generateRandomSuperNumber(),
    );
  }

  GeneratedTipPayload generateAnalysisTip({
    required LottoGeneratorService generatorService,
    required PredictionEngineResult predictionResult,
    required AnalysisRuleSet rules,
    required List<DrawResult> historicalDraws,
  }) {
    if (predictionResult.primaryTip.length == 6) {
      return GeneratedTipPayload(
        numbers: _normalizeNumbers(predictionResult.primaryTip),
        superNumber: _normalizeSuperNumber(predictionResult.recommendedSuperNumber),
      );
    }

    return GeneratedTipPayload(
      numbers: generatorService.generateAnalysisTip(
        rules,
        historicalDraws: historicalDraws,
      ),
      superNumber: _normalizeSuperNumber(predictionResult.recommendedSuperNumber) ??
          generateRandomSuperNumber(),
    );
  }

  GeneratedTipPayload fromNumbers(
    List<int> numbers, {
    int? recommendedSuperNumber,
    bool fallbackToRandomSuperNumber = true,
  }) {
    final normalizedSuperNumber = _normalizeSuperNumber(recommendedSuperNumber);
    return GeneratedTipPayload(
      numbers: _normalizeNumbers(numbers),
      superNumber: normalizedSuperNumber ??
          (fallbackToRandomSuperNumber ? generateRandomSuperNumber() : null),
    );
  }

  List<int> _normalizeNumbers(List<int> numbers) {
    return numbers.where((n) => n >= 1 && n <= 49).toSet().toList()..sort();
  }

  int? _normalizeSuperNumber(int? value) {
    if (value == null) return null;
    if (value < 0 || value > 9) return null;
    return value;
  }
}
