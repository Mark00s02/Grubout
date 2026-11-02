import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class FoodApiService {
  static final FoodApiService _instance = FoodApiService._();
  factory FoodApiService() => _instance;
  FoodApiService._();

  static const _usdaBase = 'https://api.nal.usda.gov/fdc/v1';
  // DEMO_KEY is heavily rate-limited. Get a free key at
  // https://fdc.nal.usda.gov/api-key-signup and build with
  // --dart-define=USDA_API_KEY=yourkey
  static const _usdaKey = String.fromEnvironment('USDA_API_KEY', defaultValue: 'DEMO_KEY');
  static const _mdbBase = 'https://www.themealdb.com/api/json/v1/1';
  static const _offBase = 'https://world.openfoodfacts.org';
  static const _headers = {'User-Agent': 'GrubOut/1.0 (iOS/Android diet tracker)'};
  static const _timeout = Duration(seconds: 10);

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Searches USDA + Open Food Facts in parallel and drops near-duplicates.
  Future<List<FoodSearchResult>> searchAll(String query) async {
    final results = await Future.wait([searchUSDA(query), searchOpenFoodFacts(query)]);
    final seen = <String>{};
    final out = <FoodSearchResult>[];
    for (final f in [...results[0], ...results[1]]) {
      final key = '${f.name.toLowerCase()}|${f.brand?.toLowerCase() ?? ''}';
      if (f.caloriesPer100g <= 0 || !seen.add(key)) continue;
      out.add(f);
    }
    return out;
  }

  // ── USDA FoodData Central ────────────────────────────────────────────────
  Future<List<FoodSearchResult>> searchUSDA(String query) async {
    try {
      final uri = Uri.parse('$_usdaBase/foods/search').replace(queryParameters: {
        'query': query,
        'api_key': _usdaKey,
        'pageSize': '25',
        'dataType': 'Survey (FNDDS),SR Legacy,Foundation,Branded',
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final foods = (jsonDecode(res.body)['foods'] as List<dynamic>?) ?? [];

      return foods.map((f) {
        double cal = 0, protein = 0, carbs = 0, fat = 0;
        for (final n in (f['foodNutrients'] as List<dynamic>? ?? [])) {
          final val = _num(n['value']);
          switch (n['nutrientId'] as int? ?? 0) {
            case 1008: cal = val;
            case 2047: if (cal == 0) cal = val;
            case 1003: protein = val;
            case 1005: carbs = val;
            case 1004: fat = val;
          }
        }
        final servingSize = _num(f['servingSize']);
        final unit = (f['servingSizeUnit'] as String?)?.toLowerCase();
        final hasServing = servingSize > 0 && (unit == 'g' || unit == 'ml' || unit == 'grm');
        return FoodSearchResult(
          id: 'usda_${f['fdcId']}',
          name: _titleCase(f['description'] as String? ?? 'Unknown'),
          brand: f['brandName'] as String? ?? f['brandOwner'] as String?,
          caloriesPer100g: cal,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
          servingGrams: hasServing ? servingSize : null,
          servingLabel: hasServing
              ? (f['householdServingFullText'] as String? ?? '${servingSize.round()} g')
              : null,
          source: FoodSource.usda,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Open Food Facts ──────────────────────────────────────────────────────
  static const _offFields = 'code,product_name,brands,nutriments,serving_size,serving_quantity';

  FoodSearchResult? _fromOff(Map<String, dynamic> p, {FoodSource source = FoodSource.openFoodFacts}) {
    final name = (p['product_name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    final n = (p['nutriments'] as Map<String, dynamic>?) ?? {};
    var cal = _num(n['energy-kcal_100g']);
    if (cal == 0 && n['energy_100g'] != null) cal = _num(n['energy_100g']) / 4.184;
    final servingQty = _num(p['serving_quantity']);
    return FoodSearchResult(
      id: 'off_${p['code'] ?? name.hashCode}',
      name: name,
      brand: (p['brands'] as String?)?.split(',').first.trim(),
      caloriesPer100g: cal,
      proteinPer100g: _num(n['proteins_100g']),
      carbsPer100g: _num(n['carbohydrates_100g']),
      fatPer100g: _num(n['fat_100g']),
      servingGrams: servingQty > 0 ? servingQty : null,
      servingLabel: servingQty > 0 ? (p['serving_size'] as String?) : null,
      source: source,
    );
  }

  Future<List<FoodSearchResult>> searchOpenFoodFacts(String query) async {
    try {
      final uri = Uri.parse('$_offBase/cgi/search.pl').replace(queryParameters: {
        'search_terms': query,
        'json': '1',
        'page_size': '20',
        'search_simple': '1',
        'action': 'process',
        'fields': _offFields,
      });
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final products = (jsonDecode(res.body)['products'] as List<dynamic>?) ?? [];
      return products
          .map((p) => _fromOff(p as Map<String, dynamic>))
          .whereType<FoodSearchResult>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Looks up a packaged food by its EAN/UPC barcode.
  Future<FoodSearchResult?> lookupBarcode(String code) async {
    try {
      final uri = Uri.parse('$_offBase/api/v2/product/$code.json?fields=$_offFields');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 1 || data['product'] == null) return null;
      return _fromOff({...data['product'] as Map<String, dynamic>, 'code': code},
          source: FoodSource.barcode);
    } catch (_) {
      return null;
    }
  }

  // ── TheMealDB ────────────────────────────────────────────────────────────
  Future<List<MealDbRecipe>> _mealList(String path, {bool full = false}) async {
    try {
      final res = await http.get(Uri.parse('$_mdbBase/$path')).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final meals = (jsonDecode(res.body)['meals'] as List<dynamic>?) ?? [];
      return meals.map((m) {
        final j = m as Map<String, dynamic>;
        return full
            ? MealDbRecipe.fromJson(j)
            : MealDbRecipe(
                id: j['idMeal'] as String,
                name: j['strMeal'] as String,
                imageUrl: j['strMealThumb'] as String?,
              );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MealDbRecipe>> getFilipino() => _mealList('filter.php?a=Filipino');

  Future<List<MealDbRecipe>> getByCategory(String category) =>
      _mealList('filter.php?c=${Uri.encodeComponent(category)}');

  Future<List<MealDbRecipe>> getByIngredient(String ingredient) =>
      _mealList('filter.php?i=${Uri.encodeComponent(ingredient.toLowerCase().replaceAll(' ', '_'))}');

  Future<List<MealDbRecipe>> searchMeals(String query) =>
      _mealList('search.php?s=${Uri.encodeComponent(query)}', full: true);

  Future<MealDbRecipe?> getMealDetail(String id) async {
    final list = await _mealList('lookup.php?i=$id', full: true);
    return list.isEmpty ? null : list.first;
  }

  Future<MealDbRecipe?> getRandomMeal() async {
    final list = await _mealList('random.php', full: true);
    return list.isEmpty ? null : list.first;
  }

  static String _titleCase(String s) {
    if (s != s.toUpperCase()) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
