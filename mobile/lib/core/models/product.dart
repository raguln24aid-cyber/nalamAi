import 'package:equatable/equatable.dart';
import 'provenance.dart';

enum DietFlagType {
  vegetarian,
  nonVegetarian,
  vegan,
  glutenFree,
  containsGluten;

  static DietFlagType fromJson(String value) => switch (value) {
        'vegetarian' => DietFlagType.vegetarian,
        'non_vegetarian' => DietFlagType.nonVegetarian,
        'vegan' => DietFlagType.vegan,
        'gluten_free' => DietFlagType.glutenFree,
        'contains_gluten' => DietFlagType.containsGluten,
        _ => DietFlagType.vegetarian,
      };
}

class NutritionFacts extends Equatable {
  final String? servingSize;
  final double? calories;
  final double? sugarG;
  final double? proteinG;
  final double? fatG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final double? fiberG;
  final ProvenanceSource provenance;

  const NutritionFacts({
    required this.servingSize,
    required this.calories,
    required this.sugarG,
    required this.proteinG,
    required this.fatG,
    required this.saturatedFatG,
    required this.sodiumMg,
    required this.fiberG,
    required this.provenance,
  });

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return NutritionFacts(
      servingSize: json['servingSize'] as String?,
      calories: asDouble(json['calories']),
      sugarG: asDouble(json['sugarG']),
      proteinG: asDouble(json['proteinG']),
      fatG: asDouble(json['fatG']),
      saturatedFatG: asDouble(json['saturatedFatG']),
      sodiumMg: asDouble(json['sodiumMg']),
      fiberG: asDouble(json['fiberG']),
      provenance: ProvenanceSource.fromJson(json['provenance'] as String? ?? 'unverified'),
    );
  }

  @override
  List<Object?> get props =>
      [servingSize, calories, sugarG, proteinG, fatG, saturatedFatG, sodiumMg, fiberG, provenance];
}

class IngredientEntry extends Equatable {
  final String name;
  final int position;
  final ProvenanceSource provenance;

  const IngredientEntry({required this.name, required this.position, required this.provenance});

  factory IngredientEntry.fromJson(Map<String, dynamic> json) => IngredientEntry(
        name: json['name'] as String,
        position: json['position'] as int? ?? 0,
        provenance: ProvenanceSource.fromJson(json['provenance'] as String? ?? 'unverified'),
      );

  @override
  List<Object?> get props => [name, position, provenance];
}

class AllergenEntry extends Equatable {
  final String name;
  final bool declared;
  final ProvenanceSource provenance;

  const AllergenEntry({required this.name, required this.declared, required this.provenance});

  factory AllergenEntry.fromJson(Map<String, dynamic> json) => AllergenEntry(
        name: json['name'] as String,
        declared: json['declared'] as bool? ?? false,
        provenance: ProvenanceSource.fromJson(json['provenance'] as String? ?? 'unverified'),
      );

  @override
  List<Object?> get props => [name, declared, provenance];
}

class DietFlagEntry extends Equatable {
  final DietFlagType type;
  final ProvenanceSource provenance;

  const DietFlagEntry({required this.type, required this.provenance});

  factory DietFlagEntry.fromJson(Map<String, dynamic> json) => DietFlagEntry(
        type: DietFlagType.fromJson(json['type'] as String),
        provenance: ProvenanceSource.fromJson(json['provenance'] as String? ?? 'unverified'),
      );

  @override
  List<Object?> get props => [type, provenance];
}

class Product extends Equatable {
  final String id;
  final String? barcode;
  final String? name;
  final String? brand;
  final NutritionFacts? nutritionFacts;
  final List<IngredientEntry> ingredients;
  final List<AllergenEntry> allergens;
  final List<DietFlagEntry> dietFlags;

  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.nutritionFacts,
    required this.ingredients,
    required this.allergens,
    required this.dietFlags,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        barcode: json['barcode'] as String?,
        name: json['name'] as String?,
        brand: json['brand'] as String?,
        nutritionFacts: json['nutritionFacts'] == null
            ? null
            : NutritionFacts.fromJson(json['nutritionFacts'] as Map<String, dynamic>),
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => IngredientEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        allergens: (json['allergens'] as List<dynamic>? ?? [])
            .map((e) => AllergenEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        dietFlags: (json['dietFlags'] as List<dynamic>? ?? [])
            .map((e) => DietFlagEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'nutritionFacts': nutritionFacts == null
            ? null
            : {
                'servingSize': nutritionFacts!.servingSize,
                'calories': nutritionFacts!.calories,
                'sugarG': nutritionFacts!.sugarG,
                'proteinG': nutritionFacts!.proteinG,
                'fatG': nutritionFacts!.fatG,
                'saturatedFatG': nutritionFacts!.saturatedFatG,
                'sodiumMg': nutritionFacts!.sodiumMg,
                'fiberG': nutritionFacts!.fiberG,
                'provenance': nutritionFacts!.provenance.name,
              },
        'ingredients': ingredients
            .map((i) => {'name': i.name, 'position': i.position, 'provenance': i.provenance.name})
            .toList(),
        'allergens': allergens
            .map((a) => {'name': a.name, 'declared': a.declared, 'provenance': a.provenance.name})
            .toList(),
        'dietFlags': dietFlags.map((d) => {'type': d.type.name, 'provenance': d.provenance.name}).toList(),
      };

  @override
  List<Object?> get props => [id, barcode, name, brand, nutritionFacts, ingredients, allergens, dietFlags];
}
