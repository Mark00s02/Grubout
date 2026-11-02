import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/nutrition_calculator.dart';

class AppProvider extends ChangeNotifier {
  final _db = DatabaseService();

  AppUser? _user;
  DateTime _selectedDate = dateOnly(DateTime.now());
  List<FoodLog> _foodLogs = [];
  List<ExerciseLog> _exerciseLogs = [];
  int _waterMl = 0;
  List<WeightEntry> _weights = [];
  List<FoodLog> _recentFoods = [];
  List<FoodSearchResult> _customFoods = [];
  List<FastingSession> _fasts = [];
  Set<String> _savedRecipeIds = {};
  int _streak = 0;
  int _daysLogged = 0;
  bool _loading = false;

  ThemeMode _themeMode = ThemeMode.system;

  AppUser?               get user           => _user;
  DateTime               get selectedDate   => _selectedDate;
  List<FoodLog>          get foodLogs       => _foodLogs;
  List<ExerciseLog>      get exerciseLogs   => _exerciseLogs;
  int                    get waterMl        => _waterMl;
  List<WeightEntry>      get weights        => _weights;
  List<FoodLog>          get recentFoods    => _recentFoods;
  List<FoodSearchResult> get customFoods    => _customFoods;
  List<FastingSession>   get fasts          => _fasts;
  Set<String>            get savedRecipeIds => _savedRecipeIds;
  int                    get streak         => _streak;
  int                    get daysLogged     => _daysLogged;
  bool                   get loading        => _loading;
  bool                   get isLoggedIn     => _user != null;
  bool                   get isPremium      => _user?.isPremium ?? false;
  ThemeMode              get themeMode      => _themeMode;

  bool get isToday => _selectedDate == dateOnly(DateTime.now());

  // ── Preferences ───────────────────────────────────────────────────────────
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyDark = prefs.getBool('dark_mode');
    final mode = prefs.getString('theme_mode');
    _themeMode = ThemeMode.values.asNameMap()[mode] ??
        (legacyDark == true ? ThemeMode.dark : ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  // ── Calories ──────────────────────────────────────────────────────────────
  int    get calorieGoal       => _user?.calorieGoal ?? 2000;
  double get caloriesConsumed  => _foodLogs.fold(0.0, (s, l) => s + l.calories);
  double get caloriesBurned    => _exerciseLogs.fold(0.0, (s, l) => s + l.caloriesBurned);
  double get caloriesNet       => caloriesConsumed - caloriesBurned;
  double get caloriesRemaining => calorieGoal - caloriesNet;

  double get totalProtein => _foodLogs.fold(0.0, (s, l) => s + l.protein);
  double get totalCarbs   => _foodLogs.fold(0.0, (s, l) => s + l.carbs);
  double get totalFat     => _foodLogs.fold(0.0, (s, l) => s + l.fat);

  List<FoodLog> logsForMeal(String mealType) =>
      _foodLogs.where((l) => l.mealType == mealType.toLowerCase()).toList();

  double get currentWeightKg =>
      _weights.isNotEmpty ? _weights.last.weightKg : (_user?.startWeightKg ?? 70);

  double get maintenanceCalories {
    final u = _user;
    if (u == null) return 2000;
    return NutritionCalculator.tdee(
        sex: u.sex, weightKg: currentWeightKg, heightCm: u.heightCm,
        age: u.age, activityLevel: u.activityLevel);
  }

  FastingSession? get activeFast =>
      _fasts.isNotEmpty && _fasts.first.isActive ? _fasts.first : null;

  // ── Auth / session ────────────────────────────────────────────────────────
  Future<void> setUser(AppUser? user) async {
    _user = user;
    _selectedDate = dateOnly(DateTime.now());
    if (user == null) {
      _foodLogs = [];
      _exerciseLogs = [];
      _waterMl = 0;
      _weights = [];
      _recentFoods = [];
      _customFoods = [];
      _fasts = [];
      _savedRecipeIds = {};
      _streak = 0;
      _daysLogged = 0;
      notifyListeners();
      return;
    }
    notifyListeners();
    await Future.wait([loadDayData(), _loadUserData()]);
  }

  Future<void> _loadUserData() async {
    final id = _user?.id;
    if (id == null) return;
    final results = await Future.wait([
      _db.getWeights(id),
      _db.getRecentFoods(id),
      _db.getCustomFoods(id),
      _db.getFasts(id),
      _db.getSavedRecipeIds(id),
    ]);
    _weights = results[0] as List<WeightEntry>;
    _recentFoods = results[1] as List<FoodLog>;
    _customFoods = results[2] as List<FoodSearchResult>;
    _fasts = results[3] as List<FastingSession>;
    _savedRecipeIds = (results[4] as List<String>).toSet();
    await _refreshStreak();
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService().logout();
    await setUser(null);
  }

  Future<void> deleteAccount() async {
    final id = _user?.id;
    if (id == null) return;
    await AuthService().deleteAccount(id);
    await NotificationService().cancelAll();
    await setUser(null);
  }

  Future<void> updateUser(AppUser updated) async {
    await _db.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  /// Saves the goal-setup answers and recalculates every target.
  Future<void> applyGoals(AppUser profile, {double? currentWeightKg}) async {
    final weight = currentWeightKg ?? profile.startWeightKg;
    final updated = profile.copyWith(
      calorieGoal: NutritionCalculator.goalFor(profile, currentWeightKg: weight),
      waterGoalMl: NutritionCalculator.waterGoalMl(weight),
      onboarded: true,
    );
    await updateUser(updated);
    if (_weights.isEmpty) await logWeight(weight, dateOnly(DateTime.now()));
  }

  Future<void> setPremium(bool value) async {
    final u = _user;
    if (u == null || u.isPremium == value) return;
    await updateUser(u.copyWith(isPremium: value));
  }

  // ── Date ─────────────────────────────────────────────────────────────────
  void selectDate(DateTime date) {
    _selectedDate = dateOnly(date);
    notifyListeners();
    loadDayData();
  }

  void shiftDate(int days) => selectDate(_selectedDate.add(Duration(days: days)));

  Future<void> loadDayData() async {
    final id = _user?.id;
    if (id == null) return;
    final date = _selectedDate;
    _loading = true;
    notifyListeners();
    final results = await Future.wait([
      _db.getFoodLogs(id, date),
      _db.getExerciseLogs(id, date),
      _db.getWaterMl(id, date),
    ]);
    if (date != _selectedDate) return; // user moved on while loading
    _foodLogs = results[0] as List<FoodLog>;
    _exerciseLogs = results[1] as List<ExerciseLog>;
    _waterMl = results[2] as int;
    _loading = false;
    notifyListeners();
  }

  // ── Food logs ─────────────────────────────────────────────────────────────
  FoodLog buildLog({
    required FoodSearchResult food,
    required double grams,
    required double amount,
    required String unit,
    required String mealType,
    DateTime? date,
  }) =>
      FoodLog(
        userId: _user!.id!,
        foodName: food.name,
        calories: food.caloriesPer100g * grams / 100,
        protein: food.proteinPer100g * grams / 100,
        carbs: food.carbsPer100g * grams / 100,
        fat: food.fatPer100g * grams / 100,
        servingAmount: amount,
        servingUnit: unit,
        grams: grams,
        mealType: mealType.toLowerCase(),
        logDate: date ?? _selectedDate,
        fdcId: food.id,
      );

  Future<void> addFoodLog(FoodLog log) async {
    final saved = await _db.insertFoodLog(log);
    if (dateOnly(saved.logDate) == _selectedDate) {
      _foodLogs = [..._foodLogs, saved];
    }
    _recentFoods = [
      saved,
      ..._recentFoods.where((r) => r.foodName.toLowerCase() != saved.foodName.toLowerCase()),
    ].take(40).toList();
    await _refreshStreak();
    notifyListeners();
  }

  Future<void> updateFoodLog(FoodLog log) async {
    await _db.updateFoodLog(log);
    _foodLogs = [for (final l in _foodLogs) l.id == log.id ? log : l];
    notifyListeners();
  }

  Future<void> removeFoodLog(int id) async {
    await _db.deleteFoodLog(id);
    _foodLogs = _foodLogs.where((l) => l.id != id).toList();
    await _refreshStreak();
    notifyListeners();
  }

  /// Copies every item of [mealType] from [from] into the selected day.
  Future<int> copyMeal(String mealType, DateTime from) async {
    final id = _user?.id;
    if (id == null) return 0;
    final source = (await _db.getFoodLogs(id, from)).where((l) => l.mealType == mealType).toList();
    for (final l in source) {
      final saved = await _db.insertFoodLog(l.copyWith(id: null, logDate: _selectedDate));
      _foodLogs = [..._foodLogs, saved];
    }
    await _refreshStreak();
    notifyListeners();
    return source.length;
  }

  Future<void> quickAdd({
    required String mealType,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    String name = 'Quick add',
  }) =>
      addFoodLog(FoodLog(
        userId: _user!.id!,
        foodName: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingAmount: 1,
        servingUnit: 'serving',
        mealType: mealType,
        logDate: _selectedDate,
        fdcId: 'quick',
      ));

  // ── Exercise ──────────────────────────────────────────────────────────────
  Future<void> addExerciseLog(ExerciseLog log) async {
    final saved = await _db.insertExerciseLog(log);
    if (dateOnly(saved.logDate) == _selectedDate) _exerciseLogs = [..._exerciseLogs, saved];
    notifyListeners();
  }

  Future<void> removeExerciseLog(int id) async {
    await _db.deleteExerciseLog(id);
    _exerciseLogs = _exerciseLogs.where((l) => l.id != id).toList();
    notifyListeners();
  }

  // ── Water ─────────────────────────────────────────────────────────────────
  Future<void> addWater(int ml) async {
    final id = _user?.id;
    if (id == null) return;
    if (ml < 0 && _waterMl + ml < 0) ml = -_waterMl;
    if (ml == 0) return;
    _waterMl += ml;
    notifyListeners();
    await _db.addWater(id, _selectedDate, ml);
  }

  // ── Weight ────────────────────────────────────────────────────────────────
  Future<void> logWeight(double kg, DateTime date) async {
    final id = _user?.id;
    if (id == null) return;
    await _db.upsertWeight(id, dateOnly(date), kg);
    _weights = await _db.getWeights(id);
    notifyListeners();
  }

  Future<void> deleteWeight(DateTime date) async {
    final id = _user?.id;
    if (id == null) return;
    await _db.deleteWeight(id, date);
    _weights = await _db.getWeights(id);
    notifyListeners();
  }

  // ── Custom foods ──────────────────────────────────────────────────────────
  Future<void> addCustomFood(FoodSearchResult food) async {
    final id = _user?.id;
    if (id == null) return;
    await _db.insertCustomFood(id, food);
    _customFoods = await _db.getCustomFoods(id);
    notifyListeners();
  }

  Future<void> deleteCustomFood(String foodId) async {
    final id = _user?.id;
    final rowId = int.tryParse(foodId.replaceFirst('custom_', ''));
    if (id == null || rowId == null) return;
    await _db.deleteCustomFood(rowId);
    _customFoods = await _db.getCustomFoods(id);
    notifyListeners();
  }

  // ── Fasting ───────────────────────────────────────────────────────────────
  Future<void> startFast(int hours) async {
    final id = _user?.id;
    if (id == null || activeFast != null) return;
    final f = await _db.startFast(id, hours);
    _fasts = [f, ..._fasts];
    notifyListeners();
  }

  Future<void> endFast() async {
    final f = activeFast;
    if (f?.id == null) return;
    await _db.endFast(f!.id!);
    _fasts = await _db.getFasts(_user!.id!);
    notifyListeners();
  }

  Future<void> deleteFast(int fastId) async {
    await _db.deleteFast(fastId);
    _fasts = _fasts.where((f) => f.id != fastId).toList();
    notifyListeners();
  }

  // ── Insights ──────────────────────────────────────────────────────────────
  Future<List<DaySummary>> summaries(int days) async {
    final id = _user?.id;
    if (id == null) return [];
    final today = dateOnly(DateTime.now());
    try {
      return await _db.getDailySummaries(id, today.subtract(Duration(days: days - 1)), today);
    } catch (e) {
      debugPrint('summaries failed: $e');
      return [];
    }
  }

  /// Populates state without touching the database (widget tests only).
  @visibleForTesting
  void debugSeed({
    required AppUser user,
    List<FoodLog> foodLogs = const [],
    List<ExerciseLog> exerciseLogs = const [],
    List<WeightEntry> weights = const [],
    int waterMl = 0,
    int streak = 0,
  }) {
    _user = user;
    _foodLogs = foodLogs;
    _exerciseLogs = exerciseLogs;
    _weights = weights;
    _recentFoods = foodLogs;
    _waterMl = waterMl;
    _streak = streak;
    _daysLogged = streak;
    notifyListeners();
  }

  Future<void> _refreshStreak() async {
    final id = _user?.id;
    if (id == null) return;
    final dates = (await _db.getLoggedDates(id)).toSet();
    _daysLogged = dates.length;
    var day = dateOnly(DateTime.now());
    // Today not logged yet doesn't break the streak until tomorrow.
    if (!dates.contains(dateKey(day))) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (dates.contains(dateKey(day))) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    _streak = streak;
  }

  // ── Saved recipes ─────────────────────────────────────────────────────────
  bool isRecipeSaved(String recipeId) => _savedRecipeIds.contains(recipeId);

  Future<void> toggleSavedRecipe(String recipeId, String name) async {
    final id = _user?.id;
    if (id == null) return;
    if (_savedRecipeIds.contains(recipeId)) {
      _savedRecipeIds = {..._savedRecipeIds}..remove(recipeId);
      notifyListeners();
      await _db.unsaveRecipe(id, recipeId);
    } else {
      _savedRecipeIds = {..._savedRecipeIds, recipeId};
      notifyListeners();
      await _db.saveRecipe(id, recipeId, name);
    }
  }
}
