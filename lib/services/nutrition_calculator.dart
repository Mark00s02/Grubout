import 'dart:math';
import '../models/models.dart';

/// Pure functions for calorie / macro targets. No Flutter imports so they are
/// trivially unit-testable.
class NutritionCalculator {
  static const activityMultipliers = [1.2, 1.375, 1.55, 1.725, 1.9];

  /// 1 kg of body fat ≈ 7700 kcal.
  static const kcalPerKg = 7700.0;

  /// Mifflin–St Jeor basal metabolic rate.
  static double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return sex == Sex.male ? base + 5 : base - 161;
  }

  static double tdee({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required int activityLevel,
  }) =>
      bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age) *
      activityMultipliers[activityLevel.clamp(0, activityMultipliers.length - 1)];

  /// Minimum safe intake without medical supervision.
  static int minimumCalories(Sex sex) => sex == Sex.male ? 1500 : 1200;

  /// Daily calorie goal, rounded to the nearest 10 kcal.
  static int dailyGoal({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required int activityLevel,
    required GoalType goal,
    required double weeklyRateKg,
  }) {
    final maintenance = tdee(
        sex: sex, weightKg: weightKg, heightCm: heightCm, age: age, activityLevel: activityLevel);
    final delta = weeklyRateKg * kcalPerKg / 7;
    final raw = switch (goal) {
      GoalType.lose => maintenance - delta,
      GoalType.gain => maintenance + delta,
      GoalType.maintain => maintenance,
    };
    return (max(raw, minimumCalories(sex).toDouble()) / 10).round() * 10;
  }

  static int goalFor(AppUser u, {double? currentWeightKg}) => dailyGoal(
        sex: u.sex,
        weightKg: currentWeightKg ?? u.startWeightKg,
        heightCm: u.heightCm,
        age: u.age,
        activityLevel: u.activityLevel,
        goal: u.goalType,
        weeklyRateKg: u.weeklyRateKg,
      );

  /// ~35 ml per kg, rounded to a 250 ml glass.
  static int waterGoalMl(double weightKg) =>
      ((weightKg * 35) / 250).round().clamp(6, 20) * 250;

  static double bmi(double weightKg, double heightCm) {
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Weeks until [targetKg] at the chosen weekly rate (null if maintaining).
  static int? weeksToGoal(double currentKg, double targetKg, double weeklyRateKg) {
    if (weeklyRateKg <= 0) return null;
    final diff = (currentKg - targetKg).abs();
    if (diff < 0.1) return 0;
    return (diff / weeklyRateKg).ceil();
  }

  /// MyFitnessPal-style projection: "if every day were like today, in five
  /// weeks you would weigh …".
  static double projectedWeight({
    required double currentKg,
    required double maintenanceKcal,
    required double netKcal,
    int days = 35,
  }) =>
      currentKg - (maintenanceKcal - netKcal) * days / kcalPerKg;

  /// Calories burned for an activity with the given MET value.
  static double exerciseCalories({
    required double met,
    required double weightKg,
    required int minutes,
  }) =>
      met * 3.5 * weightKg / 200 * minutes;
}

class ExerciseType {
  final String name;
  final double met;
  final String icon;
  const ExerciseType(this.name, this.met, this.icon);
}

const exerciseTypes = [
  ExerciseType('Walking (moderate)', 3.5, '🚶'),
  ExerciseType('Brisk walking', 4.3, '🚶'),
  ExerciseType('Running (8 km/h)', 8.3, '🏃'),
  ExerciseType('Running (10 km/h)', 9.8, '🏃'),
  ExerciseType('Cycling (moderate)', 7.5, '🚴'),
  ExerciseType('Swimming', 6.0, '🏊'),
  ExerciseType('Strength training', 5.0, '🏋️'),
  ExerciseType('HIIT', 8.0, '🔥'),
  ExerciseType('Yoga', 2.5, '🧘'),
  ExerciseType('Pilates', 3.0, '🧘'),
  ExerciseType('Dancing / Zumba', 5.5, '💃'),
  ExerciseType('Basketball', 6.5, '🏀'),
  ExerciseType('Badminton', 5.5, '🏸'),
  ExerciseType('Volleyball', 4.0, '🏐'),
  ExerciseType('Hiking', 6.0, '🥾'),
  ExerciseType('Jump rope', 11.0, '🪢'),
  ExerciseType('Stair climbing', 8.8, '🪜'),
  ExerciseType('Household chores', 3.3, '🧹'),
];
