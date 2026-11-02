import 'package:flutter/material.dart';

export '../theme/app_theme.dart'
    show kPrimary, kPrimaryDark, kPrimaryLight, kGold, kDanger,
         kProteinColor, kCarbsColor, kFatColor, kWaterColor,
         mealTypes, mealTypeColor, mealTypeIcon, mealTypeLabel;

/// Dates are stored as local `yyyy-MM-dd` strings so a log never shifts days
/// because of a timezone conversion.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

  double get protein => nutritionFacts['Protein']?.amount ?? 0;
  double get carbs => nutritionFacts['Total Carbs']?.amount ?? 0;
  double get fat => nutritionFacts['Total Fat']?.amount ?? 0;
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

  const ScheduledMeal({
    required this.mealType,
    required this.recipe,
    required this.time,
  });
}

// ── Goals ────────────────────────────────────────────────────────────────────
enum GoalType { lose, maintain, gain }

enum Sex { male, female }

const activityLevels = [
  ('Sedentary', 'Desk job, little exercise'),
  ('Lightly active', 'Light exercise 1–3 days/week'),
  ('Moderately active', 'Exercise 3–5 days/week'),
  ('Very active', 'Hard exercise 6–7 days/week'),
  ('Athlete', 'Physical job or twice-a-day training'),
];

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

  // Body & goal profile
  final Sex sex;
  final int birthYear;
  final double heightCm;
  final double startWeightKg;
  final double targetWeightKg;
  final int activityLevel;
  final GoalType goalType;
  final double weeklyRateKg;
  final int proteinPct;
  final int carbsPct;
  final int fatPct;
  final int waterGoalMl;
  final bool onboarded;

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
    this.sex = Sex.female,
    this.birthYear = 1995,
    this.heightCm = 165,
    this.startWeightKg = 65,
    this.targetWeightKg = 60,
    this.activityLevel = 1,
    this.goalType = GoalType.lose,
    this.weeklyRateKg = 0.5,
    this.proteinPct = 25,
    this.carbsPct = 45,
    this.fatPct = 30,
    this.waterGoalMl = 2500,
    this.onboarded = false,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  int get age => DateTime.now().year - birthYear;

  double get proteinGoalG => calorieGoal * proteinPct / 100 / 4;
  double get carbsGoalG => calorieGoal * carbsPct / 100 / 4;
  double get fatGoalG => calorieGoal * fatPct / 100 / 9;

  AppUser copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? passwordHash,
    int? calorieGoal,
    bool? isPremium,
    String? avatarEmoji,
    Sex? sex,
    int? birthYear,
    double? heightCm,
    double? startWeightKg,
    double? targetWeightKg,
    int? activityLevel,
    GoalType? goalType,
    double? weeklyRateKg,
    int? proteinPct,
    int? carbsPct,
    int? fatPct,
    int? waterGoalMl,
    bool? onboarded,
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
        sex: sex ?? this.sex,
        birthYear: birthYear ?? this.birthYear,
        heightCm: heightCm ?? this.heightCm,
        startWeightKg: startWeightKg ?? this.startWeightKg,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goalType: goalType ?? this.goalType,
        weeklyRateKg: weeklyRateKg ?? this.weeklyRateKg,
        proteinPct: proteinPct ?? this.proteinPct,
        carbsPct: carbsPct ?? this.carbsPct,
        fatPct: fatPct ?? this.fatPct,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
        onboarded: onboarded ?? this.onboarded,
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
        'sex': sex.name,
        'birth_year': birthYear,
        'height_cm': heightCm,
        'start_weight_kg': startWeightKg,
        'target_weight_kg': targetWeightKg,
        'activity_level': activityLevel,
        'goal_type': goalType.name,
        'weekly_rate_kg': weeklyRateKg,
        'protein_pct': proteinPct,
        'carbs_pct': carbsPct,
        'fat_pct': fatPct,
        'water_goal_ml': waterGoalMl,
        'onboarded': onboarded ? 1 : 0,
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
        sex: Sex.values.asNameMap()[m['sex']] ?? Sex.female,
        birthYear: (m['birth_year'] as int?) ?? 1995,
        heightCm: (m['height_cm'] as num?)?.toDouble() ?? 165,
        startWeightKg: (m['start_weight_kg'] as num?)?.toDouble() ?? 65,
        targetWeightKg: (m['target_weight_kg'] as num?)?.toDouble() ?? 60,
        activityLevel: (m['activity_level'] as int?) ?? 1,
        goalType: GoalType.values.asNameMap()[m['goal_type']] ?? GoalType.lose,
        weeklyRateKg: (m['weekly_rate_kg'] as num?)?.toDouble() ?? 0.5,
        proteinPct: (m['protein_pct'] as int?) ?? 25,
        carbsPct: (m['carbs_pct'] as int?) ?? 45,
        fatPct: (m['fat_pct'] as int?) ?? 30,
        waterGoalMl: (m['water_goal_ml'] as int?) ?? 2500,
        onboarded: (m['onboarded'] as int?) == 1,
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
  final double? grams;
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
    this.grams,
    required this.mealType,
    required this.logDate,
    this.fdcId,
  });

  String get servingText {
    final amt = servingAmount == servingAmount.roundToDouble()
        ? servingAmount.round().toString()
        : servingAmount.toStringAsFixed(1);
    return '$amt $servingUnit';
  }

  FoodLog copyWith({int? id, DateTime? logDate, String? mealType}) => FoodLog(
        id: id ?? this.id,
        userId: userId,
        foodName: foodName,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingAmount: servingAmount,
        servingUnit: servingUnit,
        grams: grams,
        mealType: mealType ?? this.mealType,
        logDate: logDate ?? this.logDate,
        fdcId: fdcId,
      );

  /// Rebuilds a per-100 g food so a past log can be re-used from "Recent".
  FoodSearchResult toFood() {
    final g = (grams != null && grams! > 0) ? grams! : 100.0;
    final f = 100 / g;
    return FoodSearchResult(
      id: fdcId ?? 'log_$foodName',
      name: foodName,
      caloriesPer100g: calories * f,
      proteinPer100g: protein * f,
      carbsPer100g: carbs * f,
      fatPer100g: fat * f,
      servingGrams: g,
      servingLabel: servingText,
      source: FoodSource.recent,
    );
  }

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
        'grams': grams,
        'meal_type': mealType,
        'log_date': dateKey(logDate),
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
        grams: (m['grams'] as num?)?.toDouble(),
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

  ExerciseLog copyWith({int? id}) => ExerciseLog(
        id: id ?? this.id,
        userId: userId,
        name: name,
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        logDate: logDate,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
        'log_date': dateKey(logDate),
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

// ── Weight entry ─────────────────────────────────────────────────────────────
class WeightEntry {
  final DateTime date;
  final double weightKg;
  const WeightEntry(this.date, this.weightKg);
}

// ── Fasting ──────────────────────────────────────────────────────────────────
class FastingSession {
  final int? id;
  final DateTime start;
  final DateTime? end;
  final int targetHours;

  const FastingSession({this.id, required this.start, this.end, required this.targetHours});

  bool get isActive => end == null;
  Duration get elapsed => (end ?? DateTime.now()).difference(start);
  double get progress =>
      (elapsed.inSeconds / (targetHours * 3600)).clamp(0.0, 1.0).toDouble();
  bool get completed => elapsed.inMinutes >= targetHours * 60;

  factory FastingSession.fromMap(Map<String, dynamic> m) => FastingSession(
        id: m['id'] as int?,
        start: DateTime.parse(m['start_time'] as String),
        end: m['end_time'] == null ? null : DateTime.parse(m['end_time'] as String),
        targetHours: m['target_hours'] as int,
      );
}

// ── Daily summary (charts / insights) ────────────────────────────────────────
class DaySummary {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double exercise;
  const DaySummary({
    required this.date,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.exercise = 0,
  });
}

// ── Food ─────────────────────────────────────────────────────────────────────
enum FoodSource { local, usda, openFoodFacts, custom, recent, barcode }

class FoodSearchResult {
  final String id;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? description;
  final bool isLocal;
  /// Grams in one default serving (e.g. 1 cup of rice = 158 g). Null = 100 g.
  final double? servingGrams;
  final String? servingLabel;
  final FoodSource source;

  const FoodSearchResult({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    this.brand,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.description,
    this.isLocal = false,
    this.servingGrams,
    this.servingLabel,
    this.source = FoodSource.local,
  });

  double caloriesForServing(double grams) => caloriesPer100g * grams / 100;

  String get subtitle {
    final parts = <String>[
      if (brand != null && brand!.isNotEmpty) brand!,
      if (servingGrams != null)
        '${caloriesForServing(servingGrams!).round()} kcal · ${servingLabel ?? '${servingGrams!.round()} g'}'
      else
        '${caloriesPer100g.round()} kcal · 100 g',
    ];
    return parts.join(' · ');
  }
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

  /// Splits raw instruction text into individual steps.
  List<String> get instructionSteps {
    if (instructions == null || instructions!.trim().isEmpty) return [];
    final lines = instructions!
        .split(RegExp(r'\r?\n'))
        .map((l) => l.replaceFirst(RegExp(r'^(step\s*)?\d+[\.\):]?\s*', caseSensitive: false), '').trim())
        .where((l) => l.length > 2)
        .toList();
    if (lines.length >= 2) return lines;
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
