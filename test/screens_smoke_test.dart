import 'package:diet_app/data/mock_data.dart';
import 'package:diet_app/models/models.dart';
import 'package:diet_app/providers/app_provider.dart';
import 'package:diet_app/screens/diary/diary_screen.dart';
import 'package:diet_app/screens/diet_plan_screen.dart';
import 'package:diet_app/screens/fasting/fasting_screen.dart';
import 'package:diet_app/screens/food/create_food_screen.dart';
import 'package:diet_app/screens/goals/goal_setup_screen.dart';
import 'package:diet_app/screens/home/dashboard_screen.dart';
import 'package:diet_app/screens/onboarding_screen.dart';
import 'package:diet_app/screens/premium/paywall_screen.dart';
import 'package:diet_app/screens/profile/profile_screen.dart';
import 'package:diet_app/screens/progress/progress_screen.dart';
import 'package:diet_app/screens/recipe_screen.dart';
import 'package:diet_app/services/purchase_service.dart';
import 'package:diet_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders each main screen at iPhone size in light and dark mode with
/// realistic data. Fails on layout overflows or build exceptions.
void main() {
  final today = dateOnly(DateTime.now());
  final user = AppUser(
    id: 1,
    firstName: 'Maria',
    lastName: 'Santos',
    email: 'maria@example.com',
    passwordHash: 'x',
    createdAt: DateTime(2026, 1, 5),
    calorieGoal: 1850,
    onboarded: true,
    startWeightKg: 72,
    targetWeightKg: 64,
  );
  FoodLog log(String name, double kcal, String meal) => FoodLog(
        id: name.hashCode,
        userId: 1,
        foodName: name,
        calories: kcal,
        protein: kcal * 0.06,
        carbs: kcal * 0.12,
        fat: kcal * 0.03,
        servingAmount: 1,
        servingUnit: 'serving',
        grams: 150,
        mealType: meal,
        logDate: today,
      );

  AppProvider seeded() => AppProvider()
    ..debugSeed(
      user: user,
      foodLogs: [
        log('Pandesal with egg', 320, 'breakfast'),
        log('Chicken Adobo with a very long descriptive name and garlic rice', 610, 'lunch'),
        log('Turon', 240, 'snacks'),
      ],
      exerciseLogs: [
        ExerciseLog(id: 1, userId: 1, name: 'Brisk walking', durationMinutes: 40, caloriesBurned: 210, logDate: today),
      ],
      weights: [WeightEntry(today.subtract(const Duration(days: 14)), 72), WeightEntry(today, 70.4)],
      waterMl: 1250,
      streak: 6,
    );

  final screens = <String, Widget Function()>{
    'dashboard': () => const DashboardScreen(),
    'diary': () => const DiaryScreen(),
    'progress': () => const ProgressScreen(),
    'profile': () => const ProfileScreen(),
    'paywall': () => const PaywallScreen(),
    'goals': () => const GoalSetupScreen(),
    'onboarding': () => const OnboardingScreen(),
    'fasting': () => const FastingScreen(),
    'diet plans': () => const DietPlanScreen(),
    'recipe': () => RecipeScreen(recipe: recipes.first),
    'create food': () => const CreateFoodScreen(),
  };

  for (final dark in [false, true]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders (${dark ? 'dark' : 'light'})', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: seeded()),
            ChangeNotifierProvider.value(value: PurchaseService()),
          ],
          child: MaterialApp(
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: entry.value(),
          ),
        ));
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
