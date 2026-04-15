import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../data/filipino_calories.dart';
import '../services/food_api_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe_screen.dart';
import 'meal_db_screen.dart';

class SearchRoot extends StatelessWidget {
  final bool autoVoice;
  const SearchRoot({super.key, this.autoVoice = false});

  @override
  Widget build(BuildContext context) => Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => SearchPage(autoVoice: autoVoice)),
      );
}

class SearchPage extends StatefulWidget {
  final bool autoVoice;
  const SearchPage({super.key, this.autoVoice = false});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _loading = false;

  // Results buckets
  List<Recipe> _localRecipes = [];
  List<MealDbRecipe> _apiMeals = [];
  List<FoodSearchResult> _foods = [];

  // Filter tab: All / Recipes / Foods
  String _tab = 'All';

  // Voice search
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Show everything on open
    _localRecipes = recipes;
    _foods = filipinoFoods.take(30).toList();
    if (widget.autoVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toggleListening());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (available && mounted) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _ctrl.text = result.recognizedWords;
            _search(result.recognizedWords);
            setState(() => _isListening = false);
          } else {
            setState(() => _ctrl.text = result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_PH',
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available')),
      );
    }
  }

  Future<void> _search(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _localRecipes = recipes;
        _apiMeals = [];
        _foods = filipinoFoods.take(30).toList();
        _loading = false;
      });
      return;
    }

    setState(() { _query = trimmed; _loading = true; });

    final lower = trimmed.toLowerCase();

    // 1. Local recipe filter (instant)
    final localHits = recipes
        .where((r) =>
            r.name.toLowerCase().contains(lower) ||
            r.tags.any((t) => t.toLowerCase().contains(lower)))
        .toList();

    // 2. Local Filipino food filter (instant) — show immediately
    final filipinoHits = filipinoFoods
        .where((f) => f.name.toLowerCase().contains(lower))
        .toList();

    setState(() {
      _localRecipes = localHits;
      _foods = filipinoHits;
    });

    // 3. Fire all API calls in parallel
    final api = FoodApiService();
    final results = await Future.wait([
      api.searchMeals(trimmed),
      api.searchUSDA(trimmed),
      api.searchOpenFoodFacts(trimmed),
    ]);

    if (!mounted) return;

    final mealHits = results[0] as List<MealDbRecipe>;
    final usdaHits = results[1] as List<FoodSearchResult>;
    final offHits  = results[2] as List<FoodSearchResult>;

    // Deduplicate food results by name (case-insensitive)
    final seen = <String>{};
    final mergedFoods = <FoodSearchResult>[];
    for (final f in [...filipinoHits, ...usdaHits, ...offHits]) {
      final key = f.name.toLowerCase();
      if (seen.add(key)) mergedFoods.add(f);
    }

    setState(() {
      _apiMeals = mealHits;
      _foods = mergedFoods;
      _loading = false;
    });
  }

  void _openRecipe(Recipe r) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => RecipeScreen(recipe: r)));

  void _openMeal(MealDbRecipe m) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => MealDbScreen(meal: m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_back, color: kDark, size: 22),
                ),
              ),
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, color: kGrey, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search recipes, Filipino food...',
                          hintStyle: TextStyle(color: kGrey, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 15, color: kDark),
                        onChanged: (v) {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (_ctrl.text == v) _search(v);
                          });
                        },
                      ),
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kPrimary),
                        ),
                      )
                    else if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          _search('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.close, color: kGrey, size: 18),
                        ),
                      ),
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10, left: 4),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? kPrimary : kGrey,
                          size: 22,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),

          // ── Filter tabs ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: ['All', 'Recipes', 'Foods'].map((t) {
                final active = _tab == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? kPrimary : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: active
                                ? Colors.white
                                : Colors.grey.shade600,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Local recipes
                if (_tab != 'Foods' && _localRecipes.isNotEmpty) ...[
                  _SectionHeader('Local Recipes (${_localRecipes.length})'),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _localRecipes.length,
                      itemBuilder: (_, i) => RecipeCard(
                        recipe: _localRecipes[i],
                        large: true,
                        onTap: () => _openRecipe(_localRecipes[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // TheMealDB results
                if (_tab != 'Foods' && _apiMeals.isNotEmpty) ...[
                  _SectionHeader('Online Recipes (${_apiMeals.length})'),
                  ..._apiMeals.map((m) => _MealTile(
                        meal: m,
                        onTap: () => _openMeal(m),
                      )),
                  const SizedBox(height: 16),
                ],

                // Filipino food nutrition
                if (_tab != 'Recipes' && _foods.isNotEmpty) ...[
                  _SectionHeader('Filipino Foods (${_foods.length})'),
                  ..._foods.map((f) => _FoodTile(food: f)),
                ],

                // Empty state
                if (_query.isNotEmpty &&
                    _localRecipes.isEmpty &&
                    _apiMeals.isEmpty &&
                    _foods.isEmpty &&
                    !_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(children: [
                      const Icon(Icons.search_off,
                          size: 56, color: kGrey),
                      const SizedBox(height: 12),
                      Text('No results for "$_query"',
                          style: const TextStyle(
                              color: kGrey, fontSize: 15)),
                    ]),
                  ),

                if (_query.isEmpty) ...[
                  _SectionHeader('Popular Ingredients'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: allIngredients.take(20).map((ing) =>
                      GestureDetector(
                        onTap: () {
                          _ctrl.text = ing;
                          _search(ing);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(ing,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700)),
                        ),
                      ),
                    ).toList(),
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kDark)),
      );
}

class _MealTile extends StatelessWidget {
  final MealDbRecipe meal;
  final VoidCallback onTap;
  const _MealTile({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: meal.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: meal.imageUrl!,
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          width: 56, height: 56,
                          color: kPrimary,
                          child: const Icon(Icons.restaurant,
                              color: Colors.white, size: 28)),
                    )
                  : Container(
                      width: 56, height: 56,
                      color: kPrimary,
                      child: const Icon(Icons.restaurant,
                          color: Colors.white, size: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kDark)),
                  if (meal.category != null)
                    Text(meal.category!,
                        style: const TextStyle(
                            fontSize: 12, color: kGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kGrey, size: 18),
          ]),
        ),
      );
}

class _FoodTile extends StatelessWidget {
  final FoodSearchResult food;
  const _FoodTile({required this.food});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.rice_bowl,
                color: kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDark)),
                Text(
                  '${food.caloriesPer100g.round()} kcal / 100g'
                  '  •  P:${food.proteinPer100g.round()}g'
                  '  C:${food.carbsPer100g.round()}g'
                  '  F:${food.fatPer100g.round()}g',
                  style: const TextStyle(fontSize: 11, color: kGrey),
                ),
              ],
            ),
          ),
          if (food.isLocal)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('PH',
                  style: TextStyle(
                      fontSize: 10,
                      color: kPrimary,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
      );
}
