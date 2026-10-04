import 'package:equatable/equatable.dart';

enum DietaryPreference {
  none,
  vegetarian,
  vegan,
  eggetarian,
  nonVegetarian;

  static DietaryPreference fromJson(String value) => switch (value) {
        'none' => DietaryPreference.none,
        'vegetarian' => DietaryPreference.vegetarian,
        'vegan' => DietaryPreference.vegan,
        'eggetarian' => DietaryPreference.eggetarian,
        'non_vegetarian' => DietaryPreference.nonVegetarian,
        _ => DietaryPreference.none,
      };

  String toJson() => switch (this) {
        DietaryPreference.none => 'none',
        DietaryPreference.vegetarian => 'vegetarian',
        DietaryPreference.vegan => 'vegan',
        DietaryPreference.eggetarian => 'eggetarian',
        DietaryPreference.nonVegetarian => 'non_vegetarian',
      };
}

enum AllergySeverity {
  mild,
  moderate,
  severe;

  static AllergySeverity fromJson(String value) => AllergySeverity.values.firstWhere(
        (v) => v.name == value,
        orElse: () => AllergySeverity.moderate,
      );
}

class Allergy extends Equatable {
  final String id;
  final String allergen;
  final AllergySeverity severity;

  const Allergy({required this.id, required this.allergen, required this.severity});

  factory Allergy.fromJson(Map<String, dynamic> json) => Allergy(
        id: json['id'] as String,
        allergen: json['allergen'] as String,
        severity: AllergySeverity.fromJson(json['severity'] as String),
      );

  @override
  List<Object?> get props => [id, allergen, severity];
}

class DietaryRestriction extends Equatable {
  final String id;
  final String restriction;

  const DietaryRestriction({required this.id, required this.restriction});

  factory DietaryRestriction.fromJson(Map<String, dynamic> json) => DietaryRestriction(
        id: json['id'] as String,
        restriction: json['restriction'] as String,
      );

  @override
  List<Object?> get props => [id, restriction];
}

class UserProfile extends Equatable {
  final DietaryPreference dietaryPreference;
  final String? notes;
  final List<Allergy> allergies;
  final List<DietaryRestriction> restrictions;

  const UserProfile({
    required this.dietaryPreference,
    required this.notes,
    required this.allergies,
    required this.restrictions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        dietaryPreference: DietaryPreference.fromJson(json['dietaryPreference'] as String),
        notes: json['notes'] as String?,
        allergies: (json['allergies'] as List<dynamic>? ?? [])
            .map((e) => Allergy.fromJson(e as Map<String, dynamic>))
            .toList(),
        restrictions: (json['restrictions'] as List<dynamic>? ?? [])
            .map((e) => DietaryRestriction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  UserProfile copyWith({
    DietaryPreference? dietaryPreference,
    String? notes,
    List<Allergy>? allergies,
    List<DietaryRestriction>? restrictions,
  }) =>
      UserProfile(
        dietaryPreference: dietaryPreference ?? this.dietaryPreference,
        notes: notes ?? this.notes,
        allergies: allergies ?? this.allergies,
        restrictions: restrictions ?? this.restrictions,
      );

  @override
  List<Object?> get props => [dietaryPreference, notes, allergies, restrictions];
}
