import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  static const _version = 2;
  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'grubout.db'),
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createV1(db);
        await _upgradeToV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _upgradeToV2(db);
      },
    );
  }

  Future<void> _createV1(Database db) async {
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
      )''');
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
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE exercise_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        calories_burned REAL NOT NULL,
        log_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE saved_recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        recipe_id TEXT NOT NULL,
        recipe_name TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        UNIQUE(user_id, recipe_id)
      )''');
  }

  Future<void> _upgradeToV2(Database db) async {
    const userColumns = {
      'sex': "TEXT DEFAULT 'female'",
      'birth_year': 'INTEGER DEFAULT 1995',
      'height_cm': 'REAL DEFAULT 165',
      'start_weight_kg': 'REAL DEFAULT 65',
      'target_weight_kg': 'REAL DEFAULT 60',
      'activity_level': 'INTEGER DEFAULT 1',
      'goal_type': "TEXT DEFAULT 'lose'",
      'weekly_rate_kg': 'REAL DEFAULT 0.5',
      'protein_pct': 'INTEGER DEFAULT 25',
      'carbs_pct': 'INTEGER DEFAULT 45',
      'fat_pct': 'INTEGER DEFAULT 30',
      'water_goal_ml': 'INTEGER DEFAULT 2500',
      'onboarded': 'INTEGER DEFAULT 0',
    };
    for (final e in userColumns.entries) {
      await db.execute('ALTER TABLE users ADD COLUMN ${e.key} ${e.value}');
    }
    await db.execute('ALTER TABLE food_logs ADD COLUMN grams REAL');
    await db.execute('CREATE INDEX idx_food_user_date ON food_logs(user_id, log_date)');
    await db.execute('''
      CREATE TABLE water_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        log_date TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        log_date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        UNIQUE(user_id, log_date),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE custom_foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        brand TEXT,
        serving_label TEXT NOT NULL,
        serving_grams REAL NOT NULL,
        calories REAL NOT NULL,
        protein REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE fasting_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        target_hours INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )''');
  }

  // ── Users ────────────────────────────────────────────────────────────────
  Future<AppUser> insertUser(AppUser user) async {
    final d = await db;
    final id = await d.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final d = await db;
    final rows = await d.query('users', where: 'email = ?', whereArgs: [email.toLowerCase()]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> getUserById(int id) async {
    final d = await db;
    final rows = await d.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<void> updateUser(AppUser user) async {
    final d = await db;
    await d.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  /// Permanently removes the user and every row that belongs to them.
  Future<void> deleteUser(int userId) async {
    final d = await db;
    await d.transaction((txn) async {
      for (final t in [
        'food_logs', 'exercise_logs', 'saved_recipes', 'water_logs',
        'weight_logs', 'custom_foods', 'fasting_sessions',
      ]) {
        await txn.delete(t, where: 'user_id = ?', whereArgs: [userId]);
      }
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    });
  }

  // ── Food Logs ────────────────────────────────────────────────────────────
  Future<FoodLog> insertFoodLog(FoodLog log) async {
    final d = await db;
    final id = await d.insert('food_logs', log.toMap()..remove('id'));
    return log.copyWith(id: id);
  }

  Future<void> updateFoodLog(FoodLog log) async {
    final d = await db;
    await d.update('food_logs', log.toMap(), where: 'id = ?', whereArgs: [log.id]);
  }

  Future<List<FoodLog>> getFoodLogs(int userId, DateTime date) async {
    final d = await db;
    final rows = await d.query('food_logs',
        where: 'user_id = ? AND log_date = ?',
        whereArgs: [userId, dateKey(date)],
        orderBy: 'id ASC');
    return rows.map(FoodLog.fromMap).toList();
  }

  Future<void> deleteFoodLog(int id) async {
    final d = await db;
    await d.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// Most recently logged distinct foods, newest first.
  Future<List<FoodLog>> getRecentFoods(int userId, {int limit = 40}) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT * FROM food_logs WHERE id IN (
        SELECT MAX(id) FROM food_logs WHERE user_id = ? GROUP BY LOWER(food_name)
      ) ORDER BY id DESC LIMIT ?''', [userId, limit]);
    return rows.map(FoodLog.fromMap).toList();
  }

  /// Distinct dates (yyyy-MM-dd) with at least one food log, newest first.
  Future<List<String>> getLoggedDates(int userId, {int limit = 400}) async {
    final d = await db;
    final rows = await d.rawQuery(
        'SELECT DISTINCT log_date FROM food_logs WHERE user_id = ? ORDER BY log_date DESC LIMIT ?',
        [userId, limit]);
    return rows.map((r) => r['log_date'] as String).toList();
  }

  Future<List<DaySummary>> getDailySummaries(int userId, DateTime from, DateTime to) async {
    final d = await db;
    final food = await d.rawQuery('''
      SELECT log_date, SUM(calories) c, SUM(protein) p, SUM(carbs) cb, SUM(fat) f
      FROM food_logs WHERE user_id = ? AND log_date BETWEEN ? AND ?
      GROUP BY log_date''', [userId, dateKey(from), dateKey(to)]);
    final ex = await d.rawQuery('''
      SELECT log_date, SUM(calories_burned) e FROM exercise_logs
      WHERE user_id = ? AND log_date BETWEEN ? AND ? GROUP BY log_date''',
        [userId, dateKey(from), dateKey(to)]);
    final byDate = {for (final r in food) r['log_date'] as String: r};
    final exByDate = {for (final r in ex) r['log_date'] as String: (r['e'] as num).toDouble()};

    final out = <DaySummary>[];
    final last = dateOnly(to);
    for (var day = dateOnly(from); !day.isAfter(last);day = DateTime(day.year, day.month, day.day + 1)) {
      final k = dateKey(day);
      final r = byDate[k];
      out.add(DaySummary(
        date: day,
        calories: (r?['c'] as num?)?.toDouble() ?? 0,
        protein: (r?['p'] as num?)?.toDouble() ?? 0,
        carbs: (r?['cb'] as num?)?.toDouble() ?? 0,
        fat: (r?['f'] as num?)?.toDouble() ?? 0,
        exercise: exByDate[k] ?? 0,
      ));
    }
    return out;
  }

  // ── Exercise Logs ────────────────────────────────────────────────────────
  Future<ExerciseLog> insertExerciseLog(ExerciseLog log) async {
    final d = await db;
    final id = await d.insert('exercise_logs', log.toMap()..remove('id'));
    return log.copyWith(id: id);
  }

  Future<List<ExerciseLog>> getExerciseLogs(int userId, DateTime date) async {
    final d = await db;
    final rows = await d.query('exercise_logs',
        where: 'user_id = ? AND log_date = ?',
        whereArgs: [userId, dateKey(date)],
        orderBy: 'id ASC');
    return rows.map(ExerciseLog.fromMap).toList();
  }

  Future<void> deleteExerciseLog(int id) async {
    final d = await db;
    await d.delete('exercise_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ── Water ────────────────────────────────────────────────────────────────
  Future<int> getWaterMl(int userId, DateTime date) async {
    final d = await db;
    final rows = await d.rawQuery(
        'SELECT COALESCE(SUM(amount_ml), 0) t FROM water_logs WHERE user_id = ? AND log_date = ?',
        [userId, dateKey(date)]);
    return (rows.first['t'] as num).toInt();
  }

  Future<void> addWater(int userId, DateTime date, int ml) async {
    final d = await db;
    await d.insert('water_logs', {'user_id': userId, 'log_date': dateKey(date), 'amount_ml': ml});
  }

  Future<void> resetWater(int userId, DateTime date) async {
    final d = await db;
    await d.delete('water_logs', where: 'user_id = ? AND log_date = ?', whereArgs: [userId, dateKey(date)]);
  }

  // ── Weight ───────────────────────────────────────────────────────────────
  Future<void> upsertWeight(int userId, DateTime date, double kg) async {
    final d = await db;
    await d.insert('weight_logs', {'user_id': userId, 'log_date': dateKey(date), 'weight_kg': kg},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteWeight(int userId, DateTime date) async {
    final d = await db;
    await d.delete('weight_logs', where: 'user_id = ? AND log_date = ?', whereArgs: [userId, dateKey(date)]);
  }

  Future<List<WeightEntry>> getWeights(int userId) async {
    final d = await db;
    final rows = await d.query('weight_logs',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'log_date ASC');
    return rows
        .map((r) => WeightEntry(DateTime.parse(r['log_date'] as String), (r['weight_kg'] as num).toDouble()))
        .toList();
  }

  // ── Custom foods ─────────────────────────────────────────────────────────
  Future<void> insertCustomFood(int userId, FoodSearchResult f) async {
    final d = await db;
    final g = f.servingGrams ?? 100;
    await d.insert('custom_foods', {
      'user_id': userId,
      'name': f.name,
      'brand': f.brand,
      'serving_label': f.servingLabel ?? '1 serving',
      'serving_grams': g,
      'calories': f.caloriesPer100g * g / 100,
      'protein': f.proteinPer100g * g / 100,
      'carbs': f.carbsPer100g * g / 100,
      'fat': f.fatPer100g * g / 100,
    });
  }

  Future<List<FoodSearchResult>> getCustomFoods(int userId) async {
    final d = await db;
    final rows = await d.query('custom_foods', where: 'user_id = ?', whereArgs: [userId], orderBy: 'name COLLATE NOCASE');
    return rows.map((r) {
      final g = (r['serving_grams'] as num).toDouble();
      final f = 100 / g;
      return FoodSearchResult(
        id: 'custom_${r['id']}',
        name: r['name'] as String,
        brand: r['brand'] as String?,
        caloriesPer100g: (r['calories'] as num).toDouble() * f,
        proteinPer100g: (r['protein'] as num).toDouble() * f,
        carbsPer100g: (r['carbs'] as num).toDouble() * f,
        fatPer100g: (r['fat'] as num).toDouble() * f,
        servingGrams: g,
        servingLabel: r['serving_label'] as String,
        source: FoodSource.custom,
      );
    }).toList();
  }

  Future<void> deleteCustomFood(int id) async {
    final d = await db;
    await d.delete('custom_foods', where: 'id = ?', whereArgs: [id]);
  }

  // ── Fasting ──────────────────────────────────────────────────────────────
  Future<FastingSession> startFast(int userId, int targetHours) async {
    final d = await db;
    final now = DateTime.now();
    final id = await d.insert('fasting_sessions', {
      'user_id': userId,
      'start_time': now.toIso8601String(),
      'target_hours': targetHours,
    });
    return FastingSession(id: id, start: now, targetHours: targetHours);
  }

  Future<void> endFast(int id) async {
    final d = await db;
    await d.update('fasting_sessions', {'end_time': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFast(int id) async {
    final d = await db;
    await d.delete('fasting_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FastingSession>> getFasts(int userId, {int limit = 30}) async {
    final d = await db;
    final rows = await d.query('fasting_sessions',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'start_time DESC', limit: limit);
    return rows.map(FastingSession.fromMap).toList();
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
        where: 'user_id = ? AND recipe_id = ?', whereArgs: [userId, recipeId]);
  }

  Future<List<String>> getSavedRecipeIds(int userId) async {
    final d = await db;
    final rows = await d.query('saved_recipes',
        columns: ['recipe_id'], where: 'user_id = ?', whereArgs: [userId]);
    return rows.map((r) => r['recipe_id'] as String).toList();
  }
}
