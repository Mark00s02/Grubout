import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'grubout.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            calorie_goal INTEGER DEFAULT 2000,
            is_premium INTEGER DEFAULT 0,
            avatar_emoji TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE food_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            food_name TEXT NOT NULL,
            calories REAL NOT NULL,
            protein REAL DEFAULT 0,
            carbs REAL DEFAULT 0,
            fat REAL DEFAULT 0,
            serving_amount REAL NOT NULL,
            serving_unit TEXT DEFAULT 'g',
            meal_type TEXT NOT NULL,
            log_date TEXT NOT NULL,
            fdc_id TEXT,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE exercise_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            calories_burned REAL NOT NULL,
            log_date TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE saved_recipes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            recipe_id TEXT NOT NULL,
            recipe_name TEXT NOT NULL,
            saved_at TEXT NOT NULL,
            UNIQUE(user_id, recipe_id)
          )
        ''');
      },
    );
  }

  // ── Users ────────────────────────────────────────────────────────────────
  Future<AppUser> insertUser(AppUser user) async {
    final d = await db;
    final id = await d.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final d = await db;
    final rows = await d.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> getUserById(int id) async {
    final d = await db;
    final rows = await d.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<void> updateUser(AppUser user) async {
    final d = await db;
    await d.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  // ── Food Logs ────────────────────────────────────────────────────────────
  Future<FoodLog> insertFoodLog(FoodLog log) async {
    final d = await db;
    final id = await d.insert('food_logs', log.toMap());
    return log.copyWith(id: id);
  }

  Future<List<FoodLog>> getFoodLogs(int userId, DateTime date) async {
    final d = await db;
    final dateStr = date.toIso8601String().split('T')[0];
    final rows = await d.query('food_logs',
        where: 'user_id = ? AND log_date = ?',
        whereArgs: [userId, dateStr],
        orderBy: 'id ASC');
    return rows.map(FoodLog.fromMap).toList();
  }

  Future<void> deleteFoodLog(int id) async {
    final d = await db;
    await d.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ── Exercise Logs ────────────────────────────────────────────────────────
  Future<ExerciseLog> insertExerciseLog(ExerciseLog log) async {
    final d = await db;
    final id = await d.insert('exercise_logs', log.toMap());
    return ExerciseLog(
      id: id,
      userId: log.userId,
      name: log.name,
      durationMinutes: log.durationMinutes,
      caloriesBurned: log.caloriesBurned,
      logDate: log.logDate,
    );
  }

  Future<List<ExerciseLog>> getExerciseLogs(int userId, DateTime date) async {
    final d = await db;
    final dateStr = date.toIso8601String().split('T')[0];
    final rows = await d.query('exercise_logs',
        where: 'user_id = ? AND log_date = ?',
        whereArgs: [userId, dateStr],
        orderBy: 'id ASC');
    return rows.map(ExerciseLog.fromMap).toList();
  }

  Future<void> deleteExerciseLog(int id) async {
    final d = await db;
    await d.delete('exercise_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ── Saved Recipes ────────────────────────────────────────────────────────
  Future<void> saveRecipe(int userId, String recipeId, String name) async {
    final d = await db;
    await d.insert(
      'saved_recipes',
      {
        'user_id': userId,
        'recipe_id': recipeId,
        'recipe_name': name,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unsaveRecipe(int userId, String recipeId) async {
    final d = await db;
    await d.delete('saved_recipes',
        where: 'user_id = ? AND recipe_id = ?',
        whereArgs: [userId, recipeId]);
  }

  Future<List<String>> getSavedRecipeIds(int userId) async {
    final d = await db;
    final rows = await d.query('saved_recipes',
        columns: ['recipe_id'],
        where: 'user_id = ?',
        whereArgs: [userId]);
    return rows.map((r) => r['recipe_id'] as String).toList();
  }

  Future<bool> isRecipeSaved(int userId, String recipeId) async {
    final d = await db;
    final rows = await d.query('saved_recipes',
        where: 'user_id = ? AND recipe_id = ?',
        whereArgs: [userId, recipeId]);
    return rows.isNotEmpty;
  }
}
