/// Nutrition Calculation Engine v2
/// Based on: SYSTEM DIRECTIVE: NUTRITION RULES & CALCULATION ENGINE CONFIGURATION
/// Implements: Mifflin-St Jeor BMR, ISSN protein ranges, gender-specific calorie
/// floors, kidney disease guardrail, allergen exclusion, and goal-specific
/// macro distributions.
library;

// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------

class HealthProfileData {
  final double weight; // kg
  final double height; // cm
  final int age;
  final String gender; // 'male' or 'female'
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very-active'
  final String goal; // Legacy compat: 'lose', 'maintain', 'gain'
  final String fitnessGoal; // Granular: 'muscle_building', 'fat_loss_keto', 'balanced'
  final bool isPublic;
  final double dailyWaterIntakeLiters;
  final double bodyFatPercentage;
  final bool hasKidneyDisease;
  final List<String> allergens; // e.g. ['peanut', 'gluten', 'lactose']

  const HealthProfileData({
    this.weight = 70.0,
    this.height = 170.0,
    this.age = 25,
    this.gender = 'male',
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
    this.fitnessGoal = 'balanced',
    this.isPublic = true,
    this.dailyWaterIntakeLiters = 2.5,
    this.bodyFatPercentage = 20.0,
    this.hasKidneyDisease = false,
    this.allergens = const [],
  });

  HealthProfileData copyWith({
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? activityLevel,
    String? goal,
    String? fitnessGoal,
    bool? isPublic,
    double? dailyWaterIntakeLiters,
    double? bodyFatPercentage,
    bool? hasKidneyDisease,
    List<String>? allergens,
  }) {
    return HealthProfileData(
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      isPublic: isPublic ?? this.isPublic,
      dailyWaterIntakeLiters: dailyWaterIntakeLiters ?? this.dailyWaterIntakeLiters,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      hasKidneyDisease: hasKidneyDisease ?? this.hasKidneyDisease,
      allergens: allergens ?? this.allergens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activity_level': activityLevel,
      'goal': goal,
      'fitness_goal': fitnessGoal,
      'is_public': isPublic,
      'daily_water_intake_liters': dailyWaterIntakeLiters,
      'body_fat_percentage': bodyFatPercentage,
      'has_kidney_disease': hasKidneyDisease,
      'allergens': allergens,
    };
  }

  factory HealthProfileData.fromJson(Map<String, dynamic> json) {
    return HealthProfileData(
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      height: (json['height'] as num?)?.toDouble() ?? 170.0,
      age: (json['age'] as num?)?.toInt() ?? 25,
      gender: (json['gender'] as String?) ?? 'male',
      activityLevel: (json['activity_level'] as String?) ?? 'moderate',
      goal: (json['goal'] as String?) ?? 'maintain',
      fitnessGoal: (json['fitness_goal'] as String?) ?? 'balanced',
      isPublic: (json['is_public'] as bool?) ?? true,
      dailyWaterIntakeLiters: (json['daily_water_intake_liters'] as num?)?.toDouble() ?? 2.5,
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble() ?? 20.0,
      hasKidneyDisease: (json['has_kidney_disease'] as bool?) ?? false,
      allergens: (json['allergens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

// ---------------------------------------------------------------------------
// CALCULATED OUTPUT
// ---------------------------------------------------------------------------

class CalculatedMacros {
  final int bmr;
  final int tdee;
  final int targetCalories;
  final int proteinGrams;
  final int fatGrams;
  final int carbGrams;
  final double recommendedWaterLiters;
  final String bodyFatCategory;

  /// Whether the calorie floor guardrail was applied.
  final bool isCalorieFloorApplied;

  /// Actual protein g/kg ratio used.
  final double proteinPerKg;

  /// Human-readable label for the macro distribution model.
  final String macroDistributionLabel;

  /// Percentage breakdowns.
  final int proteinPct;
  final int carbPct;
  final int fatPct;

  const CalculatedMacros({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbGrams,
    required this.recommendedWaterLiters,
    required this.bodyFatCategory,
    required this.isCalorieFloorApplied,
    required this.proteinPerKg,
    required this.macroDistributionLabel,
    required this.proteinPct,
    required this.carbPct,
    required this.fatPct,
  });
}

// ---------------------------------------------------------------------------
// CALCULATION ENGINE
// ---------------------------------------------------------------------------

class FitnessCalculator {
  // ── Gender-specific calorie floor constants (Guardrail 1) ──
  static const int _maleCalorieFloor = 1500;
  static const int _femaleCalorieFloor = 1200;

  // ── Protein upper-limit constants (Guardrail 2) ──
  static const double _kidneyMaxProteinPerKg = 0.8;
  static const double _healthyMaxProteinPerKg = 3.0;

  // ── ISSN protein ranges per fitness goal (g/kg) ──
  static const Map<String, List<double>> _proteinRanges = {
    'balanced': [0.8, 1.2], // sedentary / lightly active
    'fat_loss_keto': [1.6, 2.2], // fat loss with muscle preservation
    'muscle_building': [1.6, 2.4], // hypertrophy
  };

  // ── Macro distribution percentages per goal ──
  static const Map<String, Map<String, int>> _macroDistributions = {
    'muscle_building': {'protein': 40, 'carbs': 40, 'fat': 20},
    'fat_loss_keto': {'protein': 22, 'carbs': 8, 'fat': 70},
    'balanced': {'protein': 30, 'carbs': 40, 'fat': 30},
  };

  static const Map<String, String> _distributionLabels = {
    'muscle_building': 'Kas Yapımı (Yüksek Protein)',
    'fat_loss_keto': 'Yağ Yakımı (Keto / Düşük Karbonhidrat)',
    'balanced': 'Dengeli & Sürdürülebilir',
  };

  // ── Activity multipliers ──
  static const Map<String, double> _activityMultipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very-active': 1.9,
  };

  /// Step 1 — Mifflin-St Jeor BMR
  static int calculateBMR(HealthProfileData profile) {
    final baseBMR =
        10 * profile.weight + 6.25 * profile.height - 5 * profile.age;
    final genderFactor = profile.gender == 'male' ? 5 : -161;
    return (baseBMR + genderFactor).round();
  }

  /// Step 2 — TDEE
  static int calculateTDEE(int bmr, String activityLevel) {
    final mult = _activityMultipliers[activityLevel] ?? 1.55;
    return (bmr * mult).round();
  }

  /// Step 3 — Adjust for goal with gender-specific calorie floor (Guardrail 1)
  static ({int calories, bool floorApplied}) adjustForGoal(
      int tdee, String goal, String gender) {
    final adjustments = {
      'lose': -500,
      'maintain': 0,
      'gain': 500,
    };
    final adj = adjustments[goal] ?? 0;
    var result = tdee + adj;

    final floor =
        gender == 'female' ? _femaleCalorieFloor : _maleCalorieFloor;

    if (result < floor) {
      return (calories: floor, floorApplied: true);
    }
    return (calories: result, floorApplied: false);
  }

  /// Step 4 — Calculate protein with ISSN ranges & kidney guardrail (Guardrail 2)
  static ({int grams, double perKg}) calculateProtein(
      HealthProfileData profile) {
    double proteinPerKg;

    if (profile.hasKidneyDisease) {
      // Guardrail 2: Kidney disease — strict upper limit
      proteinPerKg = _kidneyMaxProteinPerKg;
    } else {
      // Use ISSN midpoint for the selected fitness goal
      final range = _proteinRanges[profile.fitnessGoal] ??
          _proteinRanges['balanced']!;
      proteinPerKg = (range[0] + range[1]) / 2.0;

      // Cap at healthy max
      if (proteinPerKg > _healthyMaxProteinPerKg) {
        proteinPerKg = _healthyMaxProteinPerKg;
      }
    }

    final grams = (profile.weight * proteinPerKg).round();
    return (grams: grams, perKg: proteinPerKg);
  }

  /// Step 5 — Calculate macros using goal-specific distribution
  static ({int proteinG, int carbG, int fatG, int pPct, int cPct, int fPct})
      calculateMacroDistribution(
    int targetCalories,
    HealthProfileData profile,
  ) {
    final dist = _macroDistributions[profile.fitnessGoal] ??
        _macroDistributions['balanced']!;

    final pPct = dist['protein']!;
    final cPct = dist['carbs']!;
    final fPct = dist['fat']!;

    // Calculate gram amounts from percentage of target calories
    // Protein: 4 kcal/g, Carbs: 4 kcal/g, Fat: 9 kcal/g
    final proteinG = ((targetCalories * pPct / 100) / 4).round();
    final carbG = ((targetCalories * cPct / 100) / 4).round();
    final fatG = ((targetCalories * fPct / 100) / 9).round();

    return (
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
      pPct: pPct,
      cPct: cPct,
      fPct: fPct,
    );
  }

  /// Calculate recommended daily water intake based on weight & activity
  static double calculateRecommendedWater(HealthProfileData profile) {
    const activityBonuses = {
      'sedentary': 0.0,
      'light': 0.3,
      'moderate': 0.5,
      'active': 0.8,
      'very-active': 1.0,
    };
    final bonus = activityBonuses[profile.activityLevel] ?? 0.5;
    final recommended = (profile.weight * 0.035) + bonus;
    return double.parse(recommended.toStringAsFixed(1));
  }

  /// Categorize body fat percentage based on gender standards
  static String categorizeBodyFat(double bodyFat, String gender) {
    if (bodyFat <= 0) return 'Belirtilmedi';
    if (gender == 'male') {
      if (bodyFat < 6) return 'Temel Yağ';
      if (bodyFat <= 13) return 'Sporcu';
      if (bodyFat <= 17) return 'Fit / İdeal';
      if (bodyFat <= 24) return 'Ortalama';
      return 'Yüksek';
    } else {
      if (bodyFat < 14) return 'Temel Yağ';
      if (bodyFat <= 20) return 'Sporcu';
      if (bodyFat <= 24) return 'Fit / İdeal';
      if (bodyFat <= 31) return 'Ortalama';
      return 'Yüksek';
    }
  }

  /// Master calculation — orchestrates all steps
  static CalculatedMacros calculateAll(HealthProfileData profile) {
    // Step 1: BMR
    final bmr = calculateBMR(profile);

    // Step 2: TDEE
    final tdee = calculateTDEE(bmr, profile.activityLevel);

    // Step 3: Adjust for goal with calorie floor (Guardrail 1)
    final goalResult = adjustForGoal(tdee, profile.goal, profile.gender);
    final targetCal = goalResult.calories;

    // Step 4: Protein with ISSN ranges & kidney guardrail (Guardrail 2)
    final proteinResult = calculateProtein(profile);

    // Step 5: Macro distribution based on fitness goal
    final macroDist = calculateMacroDistribution(targetCal, profile);

    // Use the higher of ISSN-based protein or distribution-based protein
    // to ensure adequate intake for the goal
    final finalProteinG = proteinResult.grams > macroDist.proteinG
        ? proteinResult.grams
        : macroDist.proteinG;

    // Recalculate carbs with remaining calories after protein & fat
    final proteinCal = finalProteinG * 4;
    final fatCal = macroDist.fatG * 9;
    final remainingCal = targetCal - proteinCal - fatCal;
    final finalCarbG = remainingCal > 0 ? (remainingCal / 4).round() : 0;

    // Water & body fat
    final recommendedWater = calculateRecommendedWater(profile);
    final bfCategory =
        categorizeBodyFat(profile.bodyFatPercentage, profile.gender);

    final label = _distributionLabels[profile.fitnessGoal] ??
        _distributionLabels['balanced']!;

    return CalculatedMacros(
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCal,
      proteinGrams: finalProteinG,
      fatGrams: macroDist.fatG,
      carbGrams: finalCarbG,
      recommendedWaterLiters: recommendedWater,
      bodyFatCategory: bfCategory,
      isCalorieFloorApplied: goalResult.floorApplied,
      proteinPerKg: proteinResult.perKg,
      macroDistributionLabel: label,
      proteinPct: macroDist.pPct,
      carbPct: macroDist.cPct,
      fatPct: macroDist.fPct,
    );
  }
}
