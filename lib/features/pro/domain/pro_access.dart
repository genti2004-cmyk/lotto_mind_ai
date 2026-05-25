import '../../settings/domain/app_edition.dart';
import 'pro_feature.dart';

/// Kompatibilitäts-Adapter für ältere Stellen, die noch `ProAccess` nutzen.
/// Neue Logik sollte bevorzugt `FeatureGate` verwenden.
class ProAccess {
  final bool isPro;
  final AppEdition? edition;

  const ProAccess({
    required this.isPro,
    this.edition,
  });

  bool canUse(ProFeature feature) {
    final currentEdition = edition ?? (isPro ? AppEdition.pro : AppEdition.free);

    switch (feature) {
      case ProFeature.unlimitedHistoryImport:
      case ProFeature.advancedAnalysisProfiles:
      case ProFeature.trackingPro:
      case ProFeature.systemGenerator:
        return currentEdition.isPro || currentEdition.isPremium;
      case ProFeature.pdfExport:
      case ProFeature.premiumAnalysis:
      case ProFeature.cloudBackup:
      case ProFeature.strategyComparison:
      case ProFeature.expertModels:
        return currentEdition.isPremium;
    }
  }
}
