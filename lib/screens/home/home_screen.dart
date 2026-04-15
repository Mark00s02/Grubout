import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../data/mock_data.dart';
import '../../services/food_api_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/recipe_card.dart';
import '../search_screen.dart';
import '../recipe_screen.dart';
import '../meal_db_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MealDbRecipe? _featured;
  List<MealDbRecipe> _filipinoMeals = [];
  bool _loadingApi = true;

  static const _categories = [
    _Category('Filipino',  Icons.flag,                  Color(0xFF3D7A48)),
    _Category('Salads',    Icons.eco,                   Color(0xFF4CAF50)),
    _Category('Soups',     Icons.soup_kitchen,          Color(0xFF2196F3)),
    _Category('Grilled',   Icons.local_fire_department, Color(0xFFFF9800)),
  ];

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  Future<void> _loadApiData() async {
    final api = FoodApiService();
    final results = await Future.wait([
      api.getFilipino(),
      api.getRandomMeal(),
    ]);
    if (!mounted) return;
    setState(() {
      _filipinoMeals = results[0] as List<MealDbRecipe>;
      _featured      = results[1] as MealDbRecipe?;
      _loadingApi    = false;
    });
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchRoot()),
    );
  }

  void _openRecipe(Recipe r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeScreen(recipe: r)),
    );
  }

  void _openMealDetail(MealDbRecipe meal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealDbScreen(meal: meal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadApiData,
          color: kPrimary,
          child: ListView(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  // Search bar
                  Expanded(
                    child: GestureDetector(
                      onTap: _openSearch,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(children: [
                          const Icon(Icons.search, color: kGrey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search recipes, ingredients...',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 14),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Mic
                  _IconBtn(Icons.mic_none, onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SearchRoot(autoVoice: true)),
                    );
                  }),
                  const SizedBox(width: 8),
                  // Bell
                  _IconBtn(Icons.notifications_none, onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20))),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40, height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                  color: kLightGrey,
                                  borderRadius: BorderRadius.circular(2)),
                            ),
                            const Text('Notifications',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: kDark)),
                            const SizedBox(height: 32),
                            const Icon(Icons.notifications_off_outlined,
                                size: 48, color: kGrey),
                            const SizedBox(height: 12),
                            const Text('No new notifications',
                                style: TextStyle(color: kGrey, fontSize: 15)),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  }),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Greeting ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  user != null
                      ? 'Hello, ${user.firstName}! 👋'
                      : 'Hello, Guest! 👋',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kDark),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Text('What would you like to eat today?',
                    style: TextStyle(color: kGrey, fontSize: 13)),
              ),

              const SizedBox(height: 20),

              // ── Meal type quick-select ────────────────────────────────────
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _MealTypeBtn('Breakfast', Icons.free_breakfast,
                        const Color(0xFFFF9800), onTap: () => _openSearch()),
                    _MealTypeBtn('Lunch', Icons.lunch_dining,
                        const Color(0xFF4CAF50), onTap: () => _openSearch()),
                    _MealTypeBtn('Dinner', Icons.dinner_dining,
                        const Color(0xFF9C27B0), onTap: () => _openSearch()),
                    _MealTypeBtn('Snacks', Icons.apple,
                        const Color(0xFFE91E63), onTap: () => _openSearch()),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Premium banner ────────────────────────────────────────────
              if (user == null || !user.isPremium)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3D7A48), Color(0xFF5A9E68)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.workspace_premium,
                          color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Get Premium now!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text('Unlock all features of the app',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 14),
                    ]),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Featured recipe ───────────────────────────────────────────
              _SectionHeader('Featured Recipe'),
              const SizedBox(height: 12),
              if (_loadingApi)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _ShimmerBox(height: 200, radius: 16),
                )
              else if (_featured != null)
                _FeaturedCard(meal: _featured!,
                    onTap: () => _openMealDetail(_featured!))
              else
                _FeaturedLocalCard(recipe: recipes.first,
                    onTap: () => _openRecipe(recipes.first)),

              const SizedBox(height: 24),

              // ── Added Recipes (local mock) ────────────────────────────────
              _SectionHeader('Added Recipes'),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recipes.length,
                  itemBuilder: (_, i) => RecipeCard(
                    recipe: recipes[i],
                    onTap: () => _openRecipe(recipes[i]),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Filipino meals from API ───────────────────────────────────
              if (_filipinoMeals.isNotEmpty) ...[
                _SectionHeader('Filipino Recipes'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filipinoMeals.length,
                    itemBuilder: (_, i) => _ApiRecipeCard(
                          meal: _filipinoMeals[i],
                          onTap: () => _openMealDetail(_filipinoMeals[i]),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── All Recipes categories ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('All Recipes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kDark)),
                    Text('Show more >',
                        style: TextStyle(
                            color: kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: _categories
                      .map((c) => _CategoryTile(category: c))
                      .toList(),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
      );
}

// ── Icon button ─────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, {required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: kBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: kDark, size: 22),
        ),
      );
}

// ── Meal type button ─────────────────────────────────────────────────────────
class _MealTypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _MealTypeBtn(this.label, this.icon, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: color, size: 24)),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kDark)),
          ]),
        ),
      );
}

// ── Featured card (API) ──────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final MealDbRecipe meal;
  final VoidCallback? onTap;
  const _FeaturedCard({required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            CachedNetworkImage(
              imageUrl: meal.imageUrl ?? '',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(height: 200, color: const Color(0xFFE0E0E0)),
              errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: kPrimary,
                  child: const Center(
                      child: Text('🍽️',
                          style: TextStyle(fontSize: 60)))),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('FEATURED',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 6),
                    Text(meal.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    if (meal.category != null)
                      Text(meal.category!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ]),
        ),
        ),
      );
}

// ── Featured card (local fallback) ───────────────────────────────────────────
class _FeaturedLocalCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  const _FeaturedLocalCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              color: recipe.color,
              child: Stack(children: [
                Center(
                    child: Text(recipe.emoji,
                        style: const TextStyle(fontSize: 80))),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Text(recipe.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

// ── API recipe card ──────────────────────────────────────────────────────────
class _ApiRecipeCard extends StatelessWidget {
  final MealDbRecipe meal;
  final VoidCallback? onTap;
  const _ApiRecipeCard({required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 130,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              CachedNetworkImage(
                imageUrl: meal.imageUrl ?? '',
                width: 130, height: 160,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: const Color(0xFFE0E0E0)),
                errorWidget: (_, __, ___) =>
                    Container(color: kPrimary),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                  child: Text(meal.name,
                      maxLines: 2,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
        ),
      );
}

// ── Category tile ────────────────────────────────────────────────────────────
class _Category {
  final String name;
  final IconData icon;
  final Color color;
  const _Category(this.name, this.icon, this.color);
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchRoot()),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: category.color,
            child: Stack(children: [
              Positioned(
                right: -8, bottom: -8,
                child: Icon(category.icon,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(category.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ]),
          ),
        ),
      );
}

// ── Shimmer placeholder ──────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
