import '../../generator/domain/analysis_rule_set.dart';

class RuleProfile {
  final String id;
  final String name;
  final DateTime createdAt;
  final AnalysisRuleSet rules;

  const RuleProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.rules,
  });

  RuleProfile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    AnalysisRuleSet? rules,
  }) {
    return RuleProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'rules': rules.toMap(),
    };
  }

  factory RuleProfile.fromMap(Map<String, dynamic> map) {
    return RuleProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      rules: map['rules'] is Map
          ? AnalysisRuleSet.fromMap(Map<String, dynamic>.from(map['rules']))
          : AnalysisRuleSet.initial(),
    );
  }
}
