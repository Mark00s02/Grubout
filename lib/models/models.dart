import 'package:flutter/material.dart';

export '../theme/app_theme.dart'
    show kPrimary, kDark, kBg, kCard, kGrey, kLightGrey, kDivider,
         mealTypeColor, mealTypeEmoji, mealTypeIcon;

// ── Nutrition ────────────────────────────────────────────────────────────────
class NutritionFact {
  final double amount;
  final double dv;
  const NutritionFact(this.amount, this.dv);
}

typedef NutritionFacts = Map<String, NutritionFact>;

// ── Recipe ───────────────────────────────────────────────────────────────────
class Recipe {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final int caloriesPerServing;
  final List<String> ingredients;
  final List<String> directions;
  final List<String> tags;
  final NutritionFacts nutritionFacts;
  final String? imageUrl;
  final String? mealDbId;

  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.caloriesPerServing,
    required this.ingredients,
    required this.directions,
    required this.tags,
    required this.nutritionFacts,
    this.imageUrl,
    this.mealDbId,
  });
}

// ── Diet Plan ────────────────────────────────────────────────────────────────
class DietPlan {
  final String id;
  final String name;
  final String description;
  final List<String> foods;
  final Color color;
  final String emoji;
  final String? imageUrl;

  const DietPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.foods,
    required this.color,
    required this.emoji,
    this.imageUrl,
  });
}

// ── Scheduled Meal ───────────────────────────────────────────────────────────
class ScheduledMeal {
  final String mealType;
  final Recipe recipe;
  final String time;
  bool rescheduled;

  ScheduledMeal({
    required this.mealType,
    required this.recipe,
    required this.time,
    this.rescheduled = false,
  });
}

// ── App User ─────────────────────────────────────────────────────────────────
class AppUser {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;
  final int calorieGoal;
  final bool isPremium;
  final String? avatarEmoji;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    this.calorieGoal = 2000,
    this.isPremium = false,
    this.avatarEmoji,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  AppUser copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? passwordHash,
    int? calorieGoal,
    bool? isPremium,
    String? avatarEmoji,
  }) =>
      AppUser(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        calorieGoal: calorieGoal ?? this.calorieGoal,
        isPremium: isPremium ?? this.isPremium,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password_hash': passwordHash,
        'calorie_goal': calorieGoal,
        'is_premium': isPremium ? 1 : 0,
        'avatar_emoji': avatarEmoji,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as int?,
        firstName: m['first_name'] as String,
        lastName: m['last_name'] as String,
        email: m['email'] as String,
        passwordHash: m['password_hash'] as String,
        calorieGoal: (m['calorie_goal'] as int?) ?? 2000,
        isPremium: (m['is_premium'] as int?) == 1,
        avatarEmoji: m['avatar_emoji'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

// ── Food Log ─────────────────────────────────────────────────────────────────
class FoodLog {
  final int? id;
  final int userId;
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingAmount;
  final String servingUnit;
  final String mealType;
  final DateTime logDate;
  final String? fdcId;

  const FoodLog({
    this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.servingAmount,
    this.servingUnit = 'g',
    required this.mealType,
    required this.logDate,
    this.fdcId,
  });

  FoodLog copyWith({int? id}) => FoodLog(
        id: id ?? this.id,
        userId: userId,
        foodName: foodName,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingAmount: servingAmount,
        servingUnit: servingUnit,
        mealType: mealType,
        logDate: logDate,
        fdcId: fdcId,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'food_name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'serving_amount': servingAmount,
        'serving_unit': servingUnit,
        'meal_type': mealType,
        'log_date': logDate.toIso8601String().split('T')[0],
        'fdc_id': fdcId,
      };

  factory FoodLog.fromMap(Map<String, dynamic> m) => FoodLog(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        foodName: m['food_name'] as String,
        calories: (m['calories'] as num).toDouble(),
        protein: (m['protein'] as num?)?.toDouble() ?? 0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0,
        servingAmount: (m['serving_amount'] as num).toDouble(),
        servingUnit: (m['serving_unit'] as String?) ?? 'g',
        mealType: m['meal_type'] as String,
        logDate: DateTime.parse(m['log_date'] as String),
        fdcId: m['fdc_id'] as String?,
      );
}

// ── Exercise Log ─────────────────────────────────────────────────────────────
class ExerciseLog {
  final int? id;
  final int userId;
  final String name;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime logDate;

  const ExerciseLog({
    this.id,
    required this.userId,
    required this.name,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.logDate,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
        'log_date': logDate.toIso8601String().split('T')[0],
      };

  factory ExerciseLog.fromMap(Map<String, dynamic> m) => ExerciseLog(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        name: m['name'] as String,
        durationMinutes: m['duration_minutes'] as int,
        caloriesBurned: (m['calories_burned'] as num).toDouble(),
        logDate: DateTime.parse(m['log_date'] as String),
      );
}

// ── Food Search Result ────────────────────────────────────────────────────────
class FoodSearchResult {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? description;
  final bool isLocal;

  const FoodSearchResult({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.description,
    this.isLocal = false,
  });

  double caloriesForServing(double grams) =>
      caloriesPer100g * grams / 100;
}

// ── TheMealDB Recipe ──────────────────────────────────────────────────────────
class MealDbRecipe {
  final String id;
  final String name;
  final String? imageUrl;
  final String? category;
  final String? area;
  final String? instructions;
  final List<String> ingredients;
  final List<String> measures;

  const MealDbRecipe({
    required this.id,
    required this.name,
    this.imageUrl,
    this.category,
    this.area,
    this.instructions,
    this.ingredients = const [],
    this.measures = const [],
  });

  /// "2 tbsp soy sauce", "1 cup rice", etc.
  List<String> get ingredientLines => List.generate(
        ingredients.length,
        (i) {
          final m = i < measures.length ? measures[i].trim() : '';
          return m.isEmpty ? ingredients[i] : '$m ${ingredients[i]}';
        },
      );

  /// Splits raw instruction text into individual numbered steps.
  List<String> get instructionSteps {
    if (instructions == null || instructions!.trim().isEmpty) return [];
    // Split on newlines, filter blank lines
    final lines = instructions!
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length >= 2) return lines;
    // Fallback: split on '. ' for single-paragraph instructions
    return instructions!
        .split(RegExp(r'\.\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.endsWith('.') ? s : '$s.')
        .toList();
  }

  factory MealDbRecipe.fromJson(Map<String, dynamic> j) {
    final ingredients = <String>[];
    final measures = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ing = j['strIngredient$i'] as String?;
      final mea = j['strMeasure$i'] as String?;
      if (ing != null && ing.trim().isNotEmpty) {
        ingredients.add(ing.trim());
        measures.add(mea?.trim() ?? '');
      }
    }
    return MealDbRecipe(
      id: j['idMeal'] as String,
      name: j['strMeal'] as String,
      imageUrl: j['strMealThumb'] as String?,
      category: j['strCategory'] as String?,
      area: j['strArea'] as String?,
      instructions: j['strInstructions'] as String?,
      ingredients: ingredients,
      measures: measures,
    );
  }
}
