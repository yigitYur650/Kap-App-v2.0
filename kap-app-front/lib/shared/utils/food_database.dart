/// Food Classification Database
/// Based on: SYSTEM DIRECTIVE: NUTRITION RULES & CALCULATION ENGINE CONFIGURATION
/// Provides categorized food lists with allergen filtering (Guardrail 3).
library;

class FoodItem {
  final String name;
  final Set<String> allergenTags; // e.g. {'peanut', 'gluten', 'lactose'}

  const FoodItem(this.name, [this.allergenTags = const {}]);
}

class FoodDatabase {
  // ─────────────────────────────────────────────────────────────────────────
  // PROTEIN-DENSE FOODS
  // ─────────────────────────────────────────────────────────────────────────

  static const List<FoodItem> proteinAnimal = [
    FoodItem('Tavuk Göğsü'),
    FoodItem('Hindi Göğsü'),
    FoodItem('Dana Biftek/Bonfile'),
    FoodItem('Somon'),
    FoodItem('Taze Ton Balığı'),
    FoodItem('Yumurta Akı'),
    FoodItem('Lor Peyniri', {'lactose'}),
    FoodItem('Süzme Yoğurt', {'lactose'}),
    FoodItem('Whey Protein', {'lactose'}),
  ];

  static const List<FoodItem> proteinPlantBased = [
    FoodItem('Tofu'),
    FoodItem('Tempeh'),
    FoodItem('Seitan', {'gluten'}),
    FoodItem('Yeşil Mercimek'),
    FoodItem('Kırmızı Mercimek'),
    FoodItem('Nohut'),
    FoodItem('Siyah Fasulye'),
    FoodItem('Edamame'),
    FoodItem('Kinoa'),
    FoodItem('Kabak Çekirdeği'),
    FoodItem('Spirulina'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // HEALTHY FAT-DENSE FOODS
  // ─────────────────────────────────────────────────────────────────────────

  static const List<FoodItem> healthyFatsUnsaturated = [
    FoodItem('Avokado'),
    FoodItem('Sızma Zeytinyağı'),
    FoodItem('Ceviz'),
    FoodItem('Badem'),
    FoodItem('Fındık'),
    FoodItem('Chia Tohumu'),
    FoodItem('Keten Tohumu'),
    FoodItem('Kabak Çekirdeği'),
  ];

  static const List<FoodItem> healthyFatsOmega3 = [
    FoodItem('Somon'),
    FoodItem('Uskumru'),
    FoodItem('Sardalya'),
    FoodItem('Ceviz'),
    FoodItem('Keten Tohumu'),
  ];

  static const List<FoodItem> healthyFatsSaturatedKeto = [
    FoodItem('Hindistan Cevizi Yağı'),
    FoodItem('Sade Yağ (Ghee)', {'lactose'}),
    FoodItem('Tam Yağlı Sert Peynirler', {'lactose'}),
    FoodItem('Yumurta Sarısı'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // COMPLEX CARBOHYDRATES
  // ─────────────────────────────────────────────────────────────────────────

  static const List<FoodItem> complexCarbsLowGI = [
    FoodItem('Yulaf Ezmesi', {'gluten'}),
    FoodItem('Karabuğday (Greçka)'),
    FoodItem('Kinoa'),
    FoodItem('Tatlı Patates'),
    FoodItem('Esmer Pirinç'),
    FoodItem('Siyez Bulguru', {'gluten'}),
    FoodItem('Mercimek'),
    FoodItem('Nohut'),
  ];

  static const List<FoodItem> fiberRich = [
    FoodItem('Brokoli'),
    FoodItem('Karnabahar'),
    FoodItem('Kuşkonmaz'),
    FoodItem('Ispanak'),
    FoodItem('Chia Tohumu'),
    FoodItem('Keten Tohumu'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // ALLERGEN FILTERING (Guardrail 3)
  // ─────────────────────────────────────────────────────────────────────────

  /// Filters out any food items that contain any of the user's allergens.
  /// Returns a new list with allergen-free items only.
  static List<FoodItem> filterByAllergens(
    List<FoodItem> foods,
    List<String> userAllergens,
  ) {
    if (userAllergens.isEmpty) return foods;
    final allergenSet = userAllergens.toSet();
    return foods
        .where((food) => food.allergenTags.intersection(allergenSet).isEmpty)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GOAL-BASED RECOMMENDATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns recommended foods for the given fitness goal, with allergens excluded.
  static Map<String, List<FoodItem>> getRecommendationsForGoal(
    String fitnessGoal,
    List<String> allergens,
  ) {
    switch (fitnessGoal) {
      case 'muscle_building':
        return {
          'Protein Kaynakları': filterByAllergens(
            [...proteinAnimal, ...proteinPlantBased],
            allergens,
          ),
          'Kompleks Karbonhidratlar': filterByAllergens(
            complexCarbsLowGI,
            allergens,
          ),
          'Sağlıklı Yağlar': filterByAllergens(
            healthyFatsUnsaturated,
            allergens,
          ),
        };

      case 'fat_loss_keto':
        return {
          'Protein Kaynakları': filterByAllergens(
            [...proteinAnimal, ...proteinPlantBased],
            allergens,
          ),
          'Sağlıklı Yağlar (Omega-3)': filterByAllergens(
            [...healthyFatsUnsaturated, ...healthyFatsOmega3],
            allergens,
          ),
          'Keto Uyumlu Yağlar': filterByAllergens(
            healthyFatsSaturatedKeto,
            allergens,
          ),
          'Lifli Sebzeler': filterByAllergens(
            fiberRich,
            allergens,
          ),
        };

      case 'balanced':
      default:
        return {
          'Protein Kaynakları': filterByAllergens(
            [...proteinAnimal, ...proteinPlantBased],
            allergens,
          ),
          'Kompleks Karbonhidratlar': filterByAllergens(
            complexCarbsLowGI,
            allergens,
          ),
          'Sağlıklı Yağlar': filterByAllergens(
            [...healthyFatsUnsaturated, ...healthyFatsOmega3],
            allergens,
          ),
        };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AVAILABLE ALLERGEN LIST
  // ─────────────────────────────────────────────────────────────────────────

  /// All recognized allergens for the UI filter chips.
  static const List<({String key, String label, String emoji})> availableAllergens = [
    (key: 'peanut', label: 'Fıstık', emoji: '🥜'),
    (key: 'gluten', label: 'Gluten', emoji: '🌾'),
    (key: 'lactose', label: 'Laktoz', emoji: '🥛'),
    (key: 'shellfish', label: 'Kabuklu Deniz Ürünleri', emoji: '🦐'),
    (key: 'egg', label: 'Yumurta', emoji: '🥚'),
    (key: 'soy', label: 'Soya', emoji: '🫘'),
    (key: 'fish', label: 'Balık', emoji: '🐟'),
    (key: 'treenut', label: 'Ağaç Kabukluları', emoji: '🌰'),
  ];
}
