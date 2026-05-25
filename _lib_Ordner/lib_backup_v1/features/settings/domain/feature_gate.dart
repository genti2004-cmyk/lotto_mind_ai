import 'app_edition.dart';

class FeatureGate {
  final AppEdition edition;

  const FeatureGate(this.edition);

  bool get canUseAdvancedStatistics {
    return edition == AppEdition.pro || edition == AppEdition.future;
  }

  bool get canUseFavorites {
    return edition == AppEdition.pro || edition == AppEdition.future;
  }

  bool get canUseRuleProfiles {
    return edition == AppEdition.future;
  }

  bool get canUseCloudSync {
    return edition == AppEdition.future;
  }

  bool get canUseExportCenter {
    return edition == AppEdition.future;
  }

  bool get canUseAdvancedHistory {
    return edition == AppEdition.pro || edition == AppEdition.future;
  }
}