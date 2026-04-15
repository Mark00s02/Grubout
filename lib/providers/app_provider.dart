import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final _db = DatabaseService();

  AppUser? _user;
  DateTime _selectedDate = DateTime.now();
  List<FoodLog> _foodLogs = [];
  List<ExerciseLog> _exerciseLogs = [];
  bool _loading = false;

  // ── Preferences ───────────────────────────────────────────────────────────
  bool   _isDarkMode = false;
  String _language   = 'English';

  AppUser?          get user          => _user;
  DateTime          get selectedDate  => _selectedDate;
  List<FoodLog>     get foodLogs      => _foodLogs;
  List<ExerciseLog> get exerciseLogs  => _exerciseLogs;
  bool              get loading       => _loading;
  bool              get isLoggedIn    => _user != null;
  bool              get isDarkMode    => _isDarkMode;
  String            get language      => _language;
  ThemeMode         get themeMode     => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _language   = prefs.getString('language') ?? 'English';
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('dark_mode', value);
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('language', value);
  }

  // ── Calories ──────────────────────────────────────────────────────────────
  int get calorieGoal =>
      _user?.calorieGoal ?? 2000;

  double get caloriesConsumed =>
      _foodLogs.fold(0.0, (s, l) => s + l.calories);

  double get caloriesBurnedExercise =>
      _exerciseLogs.fold(0.0, (s, l) => s + l.caloriesBurned);

  double get caloriesNet =>
      caloriesConsumed - caloriesBurnedExercise;

  double get caloriesRemaining =>
      calorieGoal - caloriesNet;

  // ── Macros ────────────────────────────────────────────────────────────────
  double get totalProtein =>
      _foodLogs.fold(0.0, (s, l) => s + l.protein);
  double get totalCarbs =>
      _foodLogs.fold(0.0, (s, l) => s + l.carbs);
  double get totalFat =>
      _foodLogs.fold(0.0, (s, l) => s + l.fat);

  double get totalMacros => totalProtein + totalCarbs + totalFat;

  double get proteinPct =>
      totalMacros > 0 ? totalProtein / totalMacros : 0;
  double get carbsPct =>
      totalMacros > 0 ? totalCarbs / totalMacros : 0;
  double get fatPct =>
      totalMacros > 0 ? totalFat / totalMacros : 0;

  // ── Logs by meal ──────────────────────────────────────────────────────────
  List<FoodLog> logsForMeal(String mealType) =>
      _foodLogs.where((l) => l.mealType == mealType).toList();

  // ── Auth ──────────────────────────────────────────────────────────────────
  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
    if (user != null) loadDayData();
  }

  Future<void> refreshUser() async {
    if (_user?.id == null) return;
    _user = await _db.getUserById(_user!.id!);
    notifyListeners();
  }

  Future<void> updateUser(AppUser updated) async {
    await _db.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  // ── Date ─────────────────────────────────────────────────────────────────
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    loadDayData();
  }

  // ── Load data for selected day ─────────────────────────────────────────
  Future<void> loadDayData() async {
    if (_user == null) return;
    _loading = true;
    notifyListeners();

    _foodLogs = await _db.getFoodLogs(_user!.id!, _selectedDate);
    _exerciseLogs = await _db.getExerciseLogs(_user!.id!, _selectedDate);

    _loading = false;
    notifyListeners();
  }

  // ── Food logs ─────────────────────────────────────────────────────────────
  Future<void> addFoodLog(FoodLog log) async {
    final saved = await _db.insertFoodLog(log);
    _foodLogs = [..._foodLogs, saved];
    notifyListeners();
  }

  Future<void> removeFoodLog(int id) async {
    await _db.deleteFoodLog(id);
    _foodLogs = _foodLogs.where((l) => l.id != id).toList();
    notifyListeners();
  }

  // ── Exercise logs ─────────────────────────────────────────────────────────
  Future<void> addExerciseLog(ExerciseLog log) async {
    final saved = await _db.insertExerciseLog(log);
    _exerciseLogs = [..._exerciseLogs, saved];
    notifyListeners();
  }

  Future<void> removeExerciseLog(int id) async {
    await _db.deleteExerciseLog(id);
    _exerciseLogs = _exerciseLogs.where((l) => l.id != id).toList();
    notifyListeners();
  }

  // ── Saved recipes ─────────────────────────────────────────────────────────
  Future<bool> isRecipeSaved(String recipeId) async {
    if (_user == null) return false;
    return _db.isRecipeSaved(_user!.id!, recipeId);
  }

  Future<void> toggleSavedRecipe(String recipeId, String name) async {
    if (_user == null) return;
    final saved = await _db.isRecipeSaved(_user!.id!, recipeId);
    if (saved) {
      await _db.unsaveRecipe(_user!.id!, recipeId);
    } else {
      await _db.saveRecipe(_user!.id!, recipeId, name);
    }
    notifyListeners();
  }
}
