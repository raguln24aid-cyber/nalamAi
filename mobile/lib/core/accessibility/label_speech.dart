import '../localization/generated/app_localizations.dart';
import '../models/product.dart';
import '../models/scan.dart';

/// Builds the spoken text for each part of a scanned label. Shared by Product Result (full
/// segmented read-through), Nutrition Details, and Ingredients & Allergens (each speaks just
/// its own section on open) so the wording — and the provenance/allergen phrasing rules from
/// docs/SAFETY_RULES.md — stays consistent everywhere it's read aloud.
class LabelSpeech {
  LabelSpeech._();

  static String fmtNumber(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  static String dietFlagLabel(AppLocalizations l10n, DietFlagType type) => switch (type) {
        DietFlagType.vegetarian => l10n.dietFlagVegetarian,
        DietFlagType.nonVegetarian => l10n.dietFlagNonVegetarian,
        DietFlagType.vegan => l10n.dietFlagVegan,
        DietFlagType.glutenFree => l10n.dietFlagGlutenFree,
        DietFlagType.containsGluten => l10n.dietFlagContainsGluten,
      };

  static String headline(Scan scan, AppLocalizations l10n) {
    final buffer = StringBuffer(scan.product?.name ?? l10n.unknownProduct);
    if (scan.safetyFlags.isEmpty) {
      buffer.write('. ${l10n.noSafetyFlags}');
    } else {
      buffer.write('. ${l10n.safetyFlagsHeading}: ');
      for (final flag in scan.safetyFlags) {
        buffer.write('${flag.message} ');
      }
    }
    return buffer.toString();
  }

  static String? nutrition(NutritionFacts? facts, AppLocalizations l10n) {
    if (facts == null) return null;
    final buffer = StringBuffer('${l10n.nutritionTitle}. ');
    if (facts.servingSize != null) buffer.write('${l10n.servingSize}: ${facts.servingSize}. ');
    if (facts.calories != null) buffer.write('${l10n.calories}: ${fmtNumber(facts.calories)}. ');
    if (facts.sugarG != null) buffer.write('${l10n.sugar}: ${fmtNumber(facts.sugarG)} grams. ');
    if (facts.proteinG != null) buffer.write('${l10n.protein}: ${fmtNumber(facts.proteinG)} grams. ');
    if (facts.fatG != null) buffer.write('${l10n.fat}: ${fmtNumber(facts.fatG)} grams. ');
    if (facts.saturatedFatG != null) {
      buffer.write('${l10n.saturatedFat}: ${fmtNumber(facts.saturatedFatG)} grams. ');
    }
    if (facts.sodiumMg != null) buffer.write('${l10n.sodium}: ${fmtNumber(facts.sodiumMg)} milligrams. ');
    if (facts.fiberG != null) buffer.write('${l10n.fiber}: ${fmtNumber(facts.fiberG)} grams. ');
    return buffer.toString();
  }

  static String? ingredients(List<IngredientEntry> ingredients, AppLocalizations l10n) {
    if (ingredients.isEmpty) return null;
    final sorted = [...ingredients]..sort((a, b) => a.position.compareTo(b.position));
    return '${l10n.ingredientsHeading}: ${sorted.map((i) => i.name).join(', ')}.';
  }

  static String? allergens(List<AllergenEntry> allergens, AppLocalizations l10n) {
    if (allergens.isEmpty) return null;
    final buffer = StringBuffer('${l10n.allergensHeading}. ');
    for (final allergen in allergens) {
      final badge = allergen.declared ? l10n.allergenDeclared : l10n.allergenInferred;
      buffer.write('${allergen.name}, $badge. ');
    }
    return buffer.toString();
  }

  static String? dietFlags(List<DietFlagEntry> flags, AppLocalizations l10n) {
    if (flags.isEmpty) return null;
    return '${l10n.dietInfoHeading}: ${flags.map((d) => dietFlagLabel(l10n, d.type)).join(', ')}.';
  }

  /// Short spoken verdict played right after a scan: the cons (safety flags, allergens, high
  /// sugar/sodium/saturated fat) first, then the pros (protein, fibre, diet flags). Built only
  /// from extracted values — no invented claims (docs/SAFETY_RULES.md). Details are left for the
  /// user to ask about.
  static String summary(Scan scan, AppLocalizations l10n) {
    final product = scan.product;
    final watch = <String>[for (final f in scan.safetyFlags) f.message];
    final good = <String>[];
    final n = product?.nutritionFacts;
    if (n != null) {
      String line(String label, double v, String unit) =>
          '${l10n.summaryHigh} $label: ${fmtNumber(v)} $unit';
      if ((n.sugarG ?? 0) >= 10) watch.add(line(l10n.sugar, n.sugarG!, 'grams'));
      if ((n.sodiumMg ?? 0) >= 400) watch.add(line(l10n.sodium, n.sodiumMg!, 'milligrams'));
      if ((n.saturatedFatG ?? 0) >= 5) {
        watch.add(line(l10n.saturatedFat, n.saturatedFatG!, 'grams'));
      }
      if ((n.proteinG ?? 0) >= 8) good.add(line(l10n.protein, n.proteinG!, 'grams'));
      if ((n.fiberG ?? 0) >= 3) good.add(line(l10n.fiber, n.fiberG!, 'grams'));
    }
    if (product != null) {
      for (final a in product.allergens) {
        watch.add('${l10n.allergensHeading}: ${a.name}');
      }
      for (final d in product.dietFlags) {
        final label = dietFlagLabel(l10n, d.type);
        (d.type == DietFlagType.nonVegetarian || d.type == DietFlagType.containsGluten
                ? watch
                : good)
            .add(label);
      }
    }
    String section(String heading, List<String> items) =>
        '$heading: ${items.isEmpty ? l10n.summaryNoneNoted : items.join('. ')}.';
    return [
      scan.product?.name ?? l10n.unknownProduct,
      section(l10n.summaryWatchOut, watch),
      section(l10n.summaryGoodPoints, good),
    ].join('. ');
  }

  /// Every section as one ordered list of non-empty spoken segments — the full label
  /// read-through used by Product Result.
  static List<String> allSegments(Scan scan, AppLocalizations l10n) {
    final product = scan.product;
    return [
      headline(scan, l10n),
      if (product != null) ...[
        nutrition(product.nutritionFacts, l10n),
        ingredients(product.ingredients, l10n),
        allergens(product.allergens, l10n),
        dietFlags(product.dietFlags, l10n),
      ],
    ].whereType<String>().toList();
  }
}
