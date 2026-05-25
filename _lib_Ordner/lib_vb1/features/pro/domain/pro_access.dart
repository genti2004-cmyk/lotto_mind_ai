import 'pro_feature.dart';

class ProAccess {
  final bool isPro;

  const ProAccess({
    required this.isPro,
  });

  bool canUse(ProFeature feature) {
    if (isPro) return true;

    switch (feature) {
      case ProFeature.unlimitedHistoryImport:
      case ProFeature.advancedAnalysisProfiles:
      case ProFeature.pdfExport:
      case ProFeature.premiumAnalysis:
      case ProFeature.cloudBackup:
        return false;
    }
  }
}
