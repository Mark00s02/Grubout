import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class FoodApiService {
  static final FoodApiService _instance = FoodApiService._();
  factory FoodApiService() => _instance;
  FoodApiService._();

  static const _usdaBase = 'https://api.nal.usda.gov/fdc/v1';
  static const _usdaKey  = 'DEMO_KEY';
  static const _mdbBase  = 'https://www.themealdb.com/api/json/v1/1';
  static const _offBase  = 'https://world.openfoodfacts.org';

  // ── USDA FoodData Central ────────────────────────────────────────────────
  Future<List<FoodSearchResult>> searchUSDA(String query) async {
    try {
      final uri = Uri.parse(
        '$_usdaBase/foods/search'
        '?query=${Uri.encodeComponent(query)}'
        '&api_key=$_usdaKey'
        '&pageSize=20'
        '&dataType=Survey%20%28FNDDS%29,SR%20Legacy,Foundation',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = (data['foods'] as List<dynamic>?) ?? [];

      return foods.map((f) {
        final nutrients = (f['foodNutrients'] as List<dynamic>?) ?? [];
        double cal = 0, protein = 0, carbs = 0, fat = 0;
        for (final n in nutrients) {
          final id = (n['nutrientId'] as int?) ?? 0;
          final val = (n['value'] as num?)?.toDouble() ?? 0;
          switch (id) {
            case 1008: cal     = val; break;
            case 1003: protein = val; break;
            case 1005: carbs   = val; break;
            case 1004: fat     = val; break;
          }
        }
        return FoodSearchResult(
          id: f['fdcId'].toString(),
          name: f['description'] as String? ?? 'Unknown',
          caloriesPer100g: cal,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
          description: (f['additionalDescriptions'] as String?) ??
              (f['brandOwner'] as String?),
          isLocal: false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Open Food Facts ──────────────────────────────────────────────────────
  /// Searches Open Food Facts for foods matching [query].
  /// Returns up to 20 results with macros per 100 g.
  Future<List<FoodSearchResult>> searchOpenFoodFacts(String query) async {
    try {
      final uri = Uri.parse(
        '$_offBase/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(query)}'
        '&json=1'
        '&page_size=20'
        '&search_simple=1'
        '&action=process'
        '&fields=product_name,nutriments',
      );
      final res = await http.get(uri,
          headers: {'User-Agent': 'GrubOut/1.0 (diet app)'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final products = (data['products'] as List<dynamic>?) ?? [];

      final results = <FoodSearchResult>[];
      for (final p in products) {
        final name = (p['product_name'] as String?)?.trim() ?? '';
        if (name.isEmpty) continue;
        final n = (p['nutriments'] as Map<String, dynamic>?) ?? {};
        final cal  = (n['energy-kcal_100g'] as num?)?.toDouble() ?? 0;
        final pro  = (n['proteins_100g']     as num?)?.toDouble() ?? 0;
        final carb = (n['carbohydrates_100g']as num?)?.toDouble() ?? 0;
        final fat  = (n['fat_100g']          as num?)?.toDouble() ?? 0;
        results.add(FoodSearchResult(
          id: 'off_${results.length}',
          name: name,
          caloriesPer100g: cal,
          proteinPer100g: pro,
          carbsPer100g: carb,
          fatPer100g: fat,
          isLocal: false,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ── TheMealDB ────────────────────────────────────────────────────────────
  Future<List<MealDbRecipe>> getFilipino() async {
    try {
      final res = await http
          .get(Uri.parse('$_mdbBase/filter.php?a=Filipino'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final meals = (data['meals'] as List<dynamic>?) ?? [];
      return meals.map((m) => MealDbRecipe(
            id: m['idMeal'] as String,
            name: m['strMeal'] as String,
            imageUrl: m['strMealThumb'] as String?,
          )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<MealDbRecipe?> getMealDetail(String id) async {
    try {
      final res = await http
          .get(Uri.parse('$_mdbBase/lookup.php?i=$id'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final meals = (data['meals'] as List<dynamic>?) ?? [];
      if (meals.isEmpty) return null;
      return MealDbRecipe.fromJson(meals.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<MealDbRecipe>> searchMeals(String query) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$_mdbBase/search.php?s=${Uri.encodeComponent(query)}'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final meals = (data['meals'] as List<dynamic>?) ?? [];
      return meals
          .map((m) => MealDbRecipe.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<MealDbRecipe?> getRandomMeal() async {
    try {
      final res = await http
          .get(Uri.parse('$_mdbBase/random.php'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final meals = (data['meals'] as List<dynamic>?) ?? [];
      if (meals.isEmpty) return null;
      return MealDbRecipe.fromJson(meals.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
