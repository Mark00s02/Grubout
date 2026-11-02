import 'package:diet_app/models/models.dart';
import 'package:diet_app/services/nutrition_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NutritionCalculator', () {
    test('Mifflin-St Jeor BMR matches reference values', () {
      // 30-year-old, 180 cm, 80 kg male: 10*80 + 6.25*180 - 5*30 + 5 = 1780
      expect(NutritionCalculator.bmr(sex: Sex.male, weightKg: 80, heightCm: 180, age: 30), 1780);
      // Same body, female: -161 instead of +5 = 1614
      expect(NutritionCalculator.bmr(sex: Sex.female, weightKg: 80, heightCm: 180, age: 30), 1614);
    });

    test('losing 0.5 kg/week subtracts ~550 kcal from maintenance', () {
      final maintain = NutritionCalculator.dailyGoal(
          sex: Sex.male, weightKg: 80, heightCm: 180, age: 30,
          activityLevel: 2, goal: GoalType.maintain, weeklyRateKg: 0);
      final lose = NutritionCalculator.dailyGoal(
          sex: Sex.male, weightKg: 80, heightCm: 180, age: 30,
          activityLevel: 2, goal: GoalType.lose, weeklyRateKg: 0.5);
      expect(maintain, 2760); // 1780 * 1.55 = 2759 -> rounded to 10
      expect(maintain - lose, closeTo(550, 10));
    });

    test('goal never drops below the safe minimum', () {
      final goal = NutritionCalculator.dailyGoal(
          sex: Sex.female, weightKg: 45, heightCm: 150, age: 60,
          activityLevel: 0, goal: GoalType.lose, weeklyRateKg: 1);
      expect(goal, NutritionCalculator.minimumCalories(Sex.female));
    });

    test('water goal is rounded to whole glasses', () {
      expect(NutritionCalculator.waterGoalMl(70) % 250, 0);
      expect(NutritionCalculator.waterGoalMl(70), 2500);
    });

    test('weeks to goal and BMI', () {
      expect(NutritionCalculator.weeksToGoal(80, 75, 0.5), 10);
      expect(NutritionCalculator.weeksToGoal(80, 80, 0.5), 0);
      expect(NutritionCalculator.bmi(70, 175), closeTo(22.86, 0.01));
      expect(NutritionCalculator.bmiCategory(22.9), 'Healthy');
    });

    test('exercise calories use MET formula', () {
      // Running 9.8 MET, 70 kg, 30 min = 9.8*3.5*70/200*30 = 360.15
      expect(NutritionCalculator.exerciseCalories(met: 9.8, weightKg: 70, minutes: 30), closeTo(360.15, 0.01));
    });

    test('projection: eating 770 kcal under maintenance for 35 days loses 3.5 kg', () {
      expect(
        NutritionCalculator.projectedWeight(currentKg: 80, maintenanceKcal: 2500, netKcal: 1730),
        closeTo(76.5, 0.001),
      );
    });
  });

  group('models', () {
    test('dateKey is zero-padded local date', () {
      expect(dateKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('FoodLog.toFood rebuilds per-100 g values', () {
      final log = FoodLog(
        userId: 1, foodName: 'Rice', calories: 260, protein: 5, carbs: 56, fat: 0.6,
        servingAmount: 1, servingUnit: 'cup', grams: 200, mealType: 'lunch', logDate: DateTime(2026),
      );
      final food = log.toFood();
      expect(food.caloriesPer100g, 130);
      expect(food.carbsPer100g, 28);
      expect(food.servingGrams, 200);
    });

    test('AppUser macro goals follow percentages', () {
      final u = AppUser(
          firstName: 'A', lastName: 'B', email: 'a@b.c', passwordHash: 'x',
          createdAt: DateTime(2026), calorieGoal: 2000, proteinPct: 30, carbsPct: 40, fatPct: 30);
      expect(u.proteinGoalG, 150);
      expect(u.carbsGoalG, 200);
      expect(u.fatGoalG, closeTo(66.7, 0.1));
      expect(AppUser.fromMap(u.toMap()).proteinPct, 30);
    });
  });
}
