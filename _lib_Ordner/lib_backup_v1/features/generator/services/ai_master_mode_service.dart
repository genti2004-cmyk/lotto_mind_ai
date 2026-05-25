import 'dart:math';

enum AiMasterMode {
  off,
  autoBalanced,
  trend,
  rebound,
  jackpot,
}

enum AiMasterProfileTarget {
  defensive,
  balanced,
  aggressive,
}

class AiMasterRecommendation {
  final AiMasterMode mode;
  final int drawCount;
  final AiMasterProfileTarget profileTarget;
  final String title;
  final String subtitle;
  final String confidenceLabel;
  final String strategyLabel;
  final String reasoning;

  const AiMasterRecommendation({
    required this.mode,
    required this.drawCount,
    required this.profileTarget,
    required this.title,
    required this.subtitle,
    required this.confidenceLabel,
    required this.strategyLabel,
    required this.reasoning,
  });

  bool get isEnabled => mode != AiMasterMode.off;
}

class AiMasterModeService {
  const AiMasterModeService();

  AiMasterRecommendation recommend({
    required AiMasterMode mode,
    required int availableDrawCount,
    required int currentDrawCount,
  }) {
    final maxCount = max(1, availableDrawCount);
    final safeCurrent = currentDrawCount.clamp(1, maxCount);

    switch (mode) {
      case AiMasterMode.off:
        return AiMasterRecommendation(
          mode: mode,
          drawCount: safeCurrent,
          profileTarget: AiMasterProfileTarget.balanced,
          title: 'Manuelle Kontrolle',
          subtitle: 'Master Mode ist aus.',
          confidenceLabel: _confidenceFor(maxCount, safeCurrent),
          strategyLabel: 'Manuell',
          reasoning: 'Keine automatische Änderung von Analyse-Ziehungen oder Profil.',
        );

      case AiMasterMode.autoBalanced:
        final target = _target(maxCount, preferred: 52, fallback: 26);
        return AiMasterRecommendation(
          mode: mode,
          drawCount: target,
          profileTarget: AiMasterProfileTarget.balanced,
          title: 'Master Auto',
          subtitle: 'Ausgewogener Standard für stabile Tipps.',
          confidenceLabel: _confidenceFor(maxCount, target),
          strategyLabel: 'Balanced 52',
          reasoning: 'Ein Jahresfenster pro Ziehungstag: gute Balance zwischen Trend und Stabilität.',
        );

      case AiMasterMode.trend:
        final target = _target(maxCount, preferred: 26, fallback: 18);
        return AiMasterRecommendation(
          mode: mode,
          drawCount: target,
          profileTarget: AiMasterProfileTarget.aggressive,
          title: 'Trend Boost',
          subtitle: 'Mehr Gewicht auf aktuelle Hot-Zahlen.',
          confidenceLabel: _confidenceFor(maxCount, target),
          strategyLabel: 'Hot / Trend',
          reasoning: 'Kürzeres Fenster reagiert schneller, schwankt aber stärker.',
        );

      case AiMasterMode.rebound:
        final target = _target(maxCount, preferred: 78, fallback: 52);
        return AiMasterRecommendation(
          mode: mode,
          drawCount: target,
          profileTarget: AiMasterProfileTarget.defensive,
          title: 'Rebound Control',
          subtitle: 'Kontrollierter Blick auf überfällige Zahlen.',
          confidenceLabel: _confidenceFor(maxCount, target),
          strategyLabel: 'Cold / Rebound',
          reasoning: 'Größeres Fenster dämpft Zufallsspitzen.',
        );

      case AiMasterMode.jackpot:
        final target = _target(maxCount, preferred: 104, fallback: 52);
        return AiMasterRecommendation(
          mode: mode,
          drawCount: target,
          profileTarget: AiMasterProfileTarget.aggressive,
          title: 'Jackpot Range',
          subtitle: 'Breitere Streuung und höhere Varianz.',
          confidenceLabel: _confidenceFor(maxCount, target),
          strategyLabel: 'High Variance',
          reasoning: 'Für Risiko-Modus mit breiterer Historie.',
        );
    }
  }

  int _target(int maxCount, {required int preferred, required int fallback}) {
    if (maxCount >= preferred) return preferred;
    if (maxCount >= fallback) return fallback;
    return max(1, maxCount);
  }

  String _confidenceFor(int maxCount, int activeCount) {
    if (maxCount >= 104 && activeCount >= 52) return 'Hoch';
    if (maxCount >= 52 && activeCount >= 26) return 'Mittel';
    return 'Niedrig';
  }
}