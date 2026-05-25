import 'app_edition.dart';

/// Zentrale Funktionsfreischaltung für Normal, Pro und Premium.
///
/// Diese Klasse ist bewusst klein und UI-unabhängig. Später kann sie an
/// In-App-Käufe, Lizenzprüfung, Remote Config oder Accounts angeschlossen
/// werden, ohne dass Screens und Fachlogik überall geändert werden müssen.
class FeatureGate {
  final AppEdition edition;

  const FeatureGate(this.edition);

  bool get isNormal => edition.isNormal;
  bool get isPro => edition.isPro;
  bool get isPremium => edition.isPremium;

  bool get canUseBasicGenerator => true;
  bool get canUseManualDrawSearch => true;
  bool get canUseBasicEvaluation => true;

  bool get canUseAdvancedStatistics => edition.isPro || edition.isPremium;
  bool get canUseAdvancedHistory => edition.isPro || edition.isPremium;
  bool get canUseTrackingPro => edition.isPro || edition.isPremium;
  bool get canUseSystemGenerator => edition.isPro || edition.isPremium;
  bool get canUseFavorites => edition.isPro || edition.isPremium;

  bool get canUseRuleProfiles => edition.isPremium;
  bool get canUseCloudSync => edition.isPremium;
  bool get canUseExportCenter => edition.isPremium;
  bool get canUseExpertModels => edition.isPremium;
  bool get canUseStrategyComparison => edition.isPremium;
}
