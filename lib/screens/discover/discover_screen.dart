import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/food_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/recipe_card.dart';
import '../diet_plan_screen.dart';
import '../fasting/fasting_screen.dart';
import '../meal_db_screen.dart';
import '../recipe_screen.dart';
import '../search_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<MealDbRecipe> _filipino = [];
  MealDbRecipe? _featured;
  bool _loading = true;

  static const _categories = [
    ('Filipino', '🇵🇭'),
    ('Chicken', '🍗'),
    ('Seafood', '🐟'),
    ('Vegetarian', '🥦'),
    ('Vegan', '🌱'),
    ('Breakfast', '🍳'),
    ('Pasta', '🍝'),
    ('Beef', '🥩'),
    ('Pork', '🥓'),
    ('Dessert', '🍮'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = FoodApiService();
    final results = await Future.wait([api.getFilipino(), api.getRandomMeal()]);
    if (!mounted) return;
    setState(() {
      _filipino = results[0] as List<MealDbRecipe>;
      _featured = results[1] as MealDbRecipe?;
      _loading = false;
    });
  }

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = context.watch<AppProvider>();
    final saved = recipes.where((r) => p.isRecipeSaved(r.id)).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Discover', style: context.text.headlineSmall),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _push(const RecipeSearchScreen()),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          Icon(Icons.search_rounded, color: c.textMuted),
                          const SizedBox(width: 10),
                          Text('Search recipes', style: TextStyle(color: c.textMuted, fontSize: 15)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Voice search',
                    iconSize: 24,
                    style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
                    icon: const Icon(Icons.mic_none_rounded),
                    onPressed: () => _push(const RecipeSearchScreen(autoVoice: true)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Tools ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: _ToolCard(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Diet plans',
                      subtitle: 'Daily meal schedules',
                      color: kPrimary,
                      premium: !p.isPremium,
                      onTap: () => _push(const DietPlanScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToolCard(
                      icon: Icons.kitchen_rounded,
                      title: 'Cook with',
                      subtitle: 'What I have at home',
                      color: kCarbsColor,
                      onTap: () => _push(const RecipeSearchScreen(byIngredients: true)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToolCard(
                      icon: Icons.timer_rounded,
                      title: 'Fasting',
                      subtitle: 'Timers & history',
                      color: const Color(0xFF8E5CD9),
                      premium: !p.isPremium,
                      onTap: () => _push(const FastingScreen()),
                    ),
                  ),
                ]),
              ),

              // ── Categories ───────────────────────────────────────────────
              const SectionHeader('Browse by category'),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    return GestureDetector(
                      onTap: () => _push(RecipeSearchScreen(category: cat.$1)),
                      child: Column(children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: c.border)),
                          alignment: Alignment.center,
                          child: Text(cat.$2, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(height: 6),
                        Text(cat.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    );
                  },
                ),
              ),

              // ── Featured ─────────────────────────────────────────────────
              if (_featured != null) ...[
                const SectionHeader('Recipe of the moment'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => _push(MealDbScreen(meal: _featured!)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 210,
                        child: Stack(fit: StackFit.expand, children: [
                          NetImage(_featured!.imageUrl),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Color(0xCC000000)],
                                begin: Alignment.center,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 16,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Pill('FEATURED', color: kPrimary, filled: true),
                              const SizedBox(height: 8),
                              Text(_featured!.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              if (_featured!.area != null)
                                Text('${_featured!.area} · ${_featured!.category ?? ''}',
                                    style: const TextStyle(color: Colors.white70)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ] else if (_loading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Container(
                    height: 210,
                    decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(24)),
                  ),
                ),

              if (saved.isNotEmpty) ...[
                const SectionHeader('Saved'),
                _HorizontalRecipes(children: [
                  for (final r in saved)
                    RecipeCard(
                      title: r.name,
                      imageUrl: r.imageUrl,
                      emoji: r.emoji,
                      subtitle: '${r.caloriesPerServing} kcal',
                      onTap: () => _push(RecipeScreen(recipe: r)),
                    ),
                ]),
              ],

              const SectionHeader('Healthy GrubOut recipes'),
              _HorizontalRecipes(children: [
                for (final r in recipes)
                  RecipeCard(
                    title: r.name,
                    imageUrl: r.imageUrl,
                    emoji: r.emoji,
                    subtitle: '${r.caloriesPerServing} kcal · ${r.protein.round()}g protein',
                    onTap: () => _push(RecipeScreen(recipe: r)),
                  ),
              ]),

              if (_filipino.isNotEmpty) ...[
                SectionHeader('Filipino favourites',
                    action: 'See all', onAction: () => _push(const RecipeSearchScreen(category: 'Filipino'))),
                _HorizontalRecipes(children: [
                  for (final m in _filipino)
                    RecipeCard(title: m.name, imageUrl: m.imageUrl, onTap: () => _push(MealDbScreen(meal: m))),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalRecipes extends StatelessWidget {
  final List<Widget> children;
  const _HorizontalRecipes({required this.children});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 190,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: 150, child: children[i]),
        ),
      );
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool premium;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.premium = false,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            if (premium) const Icon(Icons.workspace_premium_rounded, color: kGold, size: 18),
          ]),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(subtitle,
              maxLines: 2, style: TextStyle(fontSize: 11, color: context.colors.textMuted, height: 1.3)),
        ]),
      );
}
