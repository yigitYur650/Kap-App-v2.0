import 'package:flutter_test/flutter_test.dart';
import 'package:kap_app_front/shared/utils/category_helper.dart';
import 'package:kap_app_front/shared/utils/fitness_calculator.dart';
import 'package:kap_app_front/shared/utils/food_database.dart';

void main() {
  group('CategoryHelper Unit Tests', () {
    test('Detects Süt & Kahvaltılık items correctly', () {
      expect(CategoryHelper.detectCategory('Kaşar Peyniri'), CategoryHelper.sutKahvaltilik);
      expect(CategoryHelper.detectCategory('Süt 1L'), CategoryHelper.sutKahvaltilik);
      expect(CategoryHelper.detectCategory('Tereyağı'), CategoryHelper.sutKahvaltilik);
    });

    test('Detects Et & Piliç items correctly', () {
      expect(CategoryHelper.detectCategory('Tavuk Göğsü'), CategoryHelper.etPilic);
      expect(CategoryHelper.detectCategory('Dana Kıyma'), CategoryHelper.etPilic);
    });

    test('Detects Meyve & Sebze items correctly', () {
      expect(CategoryHelper.detectCategory('Domates 1kg'), CategoryHelper.meyveSebze);
      expect(CategoryHelper.detectCategory('Amasya Elması'), CategoryHelper.meyveSebze);
    });

    test('Detects İçecek items correctly', () {
      expect(CategoryHelper.detectCategory('Coca Cola 1.5L'), CategoryHelper.icecek);
      expect(CategoryHelper.detectCategory('Maden Suyu'), CategoryHelper.icecek);
    });

    test('Defaults unknown items to Genel', () {
      expect(CategoryHelper.detectCategory('Bilinmeyen Ürün 123'), CategoryHelper.genel);
      expect(CategoryHelper.detectCategory(''), CategoryHelper.genel);
    });

    test('Returns correct category icons', () {
      expect(CategoryHelper.getCategoryIcon(CategoryHelper.sutKahvaltilik), '🧀');
      expect(CategoryHelper.getCategoryIcon(CategoryHelper.meyveSebze), '🥦');
      expect(CategoryHelper.getCategoryIcon(CategoryHelper.etPilic), '🍗');
    });
  });

  group('FitnessCalculator Unit Tests', () {
    test('Calculates BMR accurately for male', () {
      const profile = HealthProfileData(
        weight: 80.0,
        height: 180.0,
        age: 25,
        gender: 'male',
      );
      // BMR = 10*80 + 6.25*180 - 5*25 + 5 = 800 + 1125 - 125 + 5 = 1805
      final bmr = FitnessCalculator.calculateBMR(profile);
      expect(bmr, 1805);
    });

    test('Guardrail 1: Calorie floor applied when calorie deficit is too low', () {
      // Female with low weight/height
      const profile = HealthProfileData(
        weight: 45.0,
        height: 155.0,
        age: 30,
        gender: 'female',
        activityLevel: 'sedentary',
        goal: 'lose',
      );
      final macros = FitnessCalculator.calculateAll(profile);
      expect(macros.isCalorieFloorApplied, isTrue);
      expect(macros.targetCalories, 1200); // Female floor
    });

    test('Guardrail 2: Kidney disease caps protein at 0.8 g/kg', () {
      const profile = HealthProfileData(
        weight: 70.0,
        fitnessGoal: 'muscle_building', // Usually 1.6-2.4 g/kg
        hasKidneyDisease: true,
      );
      final proteinResult = FitnessCalculator.calculateProtein(profile);
      expect(proteinResult.perKg, 0.8);
      expect(proteinResult.grams, 56); // 70 * 0.8 = 56g
    });
  });

  group('FoodDatabase Unit Tests', () {
    test('Guardrail 3: Filters out user allergens', () {
      const testFoods = [
        FoodItem('Lor Peyniri', {'lactose'}),
        FoodItem('Seitan', {'gluten'}),
        FoodItem('Tavuk Göğsü'),
      ];

      final filtered = FoodDatabase.filterByAllergens(testFoods, ['lactose']);
      expect(filtered.length, 2);
      expect(filtered.any((f) => f.name == 'Lor Peyniri'), isFalse);
      expect(filtered.any((f) => f.name == 'Tavuk Göğsü'), isTrue);
    });
  });
}
