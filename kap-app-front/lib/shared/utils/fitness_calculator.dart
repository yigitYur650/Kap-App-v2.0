class HealthProfileData {
  final double weight; // kg
  final double height; // cm
  final int age;
  final String gender; // 'male' or 'female'
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very-active'
  final String goal; // 'lose', 'maintain', 'gain'
  final bool isPublic;
  final double dailyWaterIntakeLiters; // Liters per day
  final double bodyFatPercentage; // % body fat

  const HealthProfileData({
    this.weight = 70.0,
    this.height = 170.0,
    this.age = 25,
    this.gender = 'male',
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
    this.isPublic = true,
    this.dailyWaterIntakeLiters = 2.5,
    this.bodyFatPercentage = 20.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activity_level': activityLevel,
      'goal': goal,
      'is_public': isPublic,
      'daily_water_intake_liters': dailyWaterIntakeLiters,
      'body_fat_percentage': bodyFatPercentage,
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
      isPublic: (json['is_public'] as bool?) ?? true,
      dailyWaterIntakeLiters: (json['daily_water_intake_liters'] as num?)?.toDouble() ?? 2.5,
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble() ?? 20.0,
    );
  }
}

class CalculatedMacros {
  final int bmr;
  final int tdee;
  final int targetCalories;
  final int proteinGrams;
  final int fatGrams;
  final int carbGrams;
  final double recommendedWaterLiters;
  final String bodyFatCategory;

  const CalculatedMacros({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbGrams,
    required this.recommendedWaterLiters,
    required this.bodyFatCategory,
  });
}

class FitnessCalculator {
  /// Mifflin-St Jeor Equation for BMR calculation
  static int calculateBMR(HealthProfileData profile) {
    final baseBMR = 10 * profile.weight + 6.25 * profile.height - 5 * profile.age;
    final genderFactor = profile.gender == 'male' ? 5 : -161;
    return (baseBMR + genderFactor).round();
  }

  /// TDEE (Total Daily Energy Expenditure) = BMR * Activity Multiplier
  static int calculateTDEE(int bmr, String activityLevel) {
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very-active': 1.9,
    };
    final mult = multipliers[activityLevel] ?? 1.55;
    return (bmr * mult).round();
  }

  /// Adjust TDEE based on user goal
  static int adjustForGoal(int tdee, String goal) {
    final adjustments = {
      'lose': -500,
      'maintain': 0,
      'gain': 500,
    };
    final adj = adjustments[goal] ?? 0;
    final res = tdee + adj;
    return res < 1000 ? 1000 : res;
  }

  /// Calculate recommended daily water intake based on weight & activity
  static double calculateRecommendedWater(HealthProfileData profile) {
    final activityBonuses = {
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

  /// Calculate Macro & Hydration distribution
  static CalculatedMacros calculateAll(HealthProfileData profile) {
    final bmr = calculateBMR(profile);
    final tdee = calculateTDEE(bmr, profile.activityLevel);
    final targetCal = adjustForGoal(tdee, profile.goal);

    final proteinGrams = (profile.weight * 2.0).round();
    final fatGrams = (profile.weight * 0.8).round();

    final proteinCal = proteinGrams * 4;
    final fatCal = fatGrams * 9;
    final remainingCal = targetCal - proteinCal - fatCal;
    final carbGrams = remainingCal > 0 ? (remainingCal / 4).round() : 0;

    final recommendedWater = calculateRecommendedWater(profile);
    final bfCategory = categorizeBodyFat(profile.bodyFatPercentage, profile.gender);

    return CalculatedMacros(
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCal,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbGrams: carbGrams,
      recommendedWaterLiters: recommendedWater,
      bodyFatCategory: bfCategory,
    );
  }
}
