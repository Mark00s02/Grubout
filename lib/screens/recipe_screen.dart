import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../widgets/recipe_card.dart';
import '../providers/app_provider.dart';

class RecipeScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeScreen({super.key, required this.recipe});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _servings = 1;
  bool _isFavorite = false;
  bool _showAddedNotif = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final provider = context.read<AppProvider>();
    if (provider.user != null) {
      final saved =
          await provider.isRecipeSaved(widget.recipe.id);
      if (mounted) setState(() => _isFavorite = saved);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _totalCals =>
      widget.recipe.caloriesPerServing * _servings;

  void _toggleFavorite() {
    final provider = context.read<AppProvider>();
    provider.toggleSavedRecipe(widget.recipe.id, widget.recipe.name);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _showAddToMeal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddToMealSheet(
        onAdd: (mealType) {
          Navigator.pop(context);
          setState(() => _showAddedNotif = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showAddedNotif = false);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final others = recipes.where((x) => x.id != r.id).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        CustomScrollView(
          slivers: [
            // ── Photo header ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: r.color,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleIconBtn(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _CircleIconBtn(
                    icon: _isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                    onTap: _toggleFavorite,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _RecipeHero(recipe: r),
              ),
            ),

            // ── Recipe name + tags ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: kDark,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('${r.caloriesPerServing} calories per serving',
                        style: const TextStyle(
                            color: kGrey, fontSize: 13)),
                    const SizedBox(height: 12),
                    // Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: r.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: r.color.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(t,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: r.color,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Tab bar ────────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: kPrimary,
                  labelColor: kPrimary,
                  unselectedLabelColor: kGrey,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Recipe'),
                    Tab(text: 'Nutritional Facts'),
                  ],
                ),
              ),
            ),

            // ── Tab content ────────────────────────────────────────────
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RecipeTab(
                    recipe: r,
                    servings: _servings,
                    totalCals: _totalCals,
                    onServingsChanged: (v) =>
                        setState(() => _servings = v),
                    otherRecipes: others,
                    onRecipeTap: (rec) => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RecipeScreen(recipe: rec)),
                    ),
                  ),
                  _NutritionTab(recipe: r),
                ],
              ),
            ),
          ],
        ),

        // ── Success notification ───────────────────────────────────────
        if (_showAddedNotif)
          Positioned(
            bottom: 100, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Text('✅', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Text('Added to your meal plan!',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton(
            onPressed: _showAddToMeal,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Add to Meal',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

// ── Recipe hero image ─────────────────────────────────────────────────────────
class _RecipeHero extends StatelessWidget {
  final Recipe recipe;
  const _RecipeHero({required this.recipe});

  @override
  Widget build(BuildContext context) {
    if (recipe.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: recipe.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(color: recipe.color,
                child: Center(
                    child: Text(recipe.emoji,
                        style: const TextStyle(fontSize: 80)))),
        errorWidget: (_, __, ___) =>
            Container(color: recipe.color,
                child: Center(
                    child: Text(recipe.emoji,
                        style: const TextStyle(fontSize: 80)))),
      );
    }
    return Container(
      color: recipe.color,
      child: Center(
          child: Text(recipe.emoji,
              style: const TextStyle(fontSize: 80))),
    );
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────
class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _CircleIconBtn(
      {required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle),
          child: Icon(icon,
              size: 20, color: color ?? kDark),
        ),
      );
}

// ── Recipe tab ────────────────────────────────────────────────────────────────
class _RecipeTab extends StatelessWidget {
  final Recipe recipe;
  final int servings;
  final int totalCals;
  final ValueChanged<int> onServingsChanged;
  final List<Recipe> otherRecipes;
  final ValueChanged<Recipe> onRecipeTap;

  const _RecipeTab({
    required this.recipe,
    required this.servings,
    required this.totalCals,
    required this.onServingsChanged,
    required this.otherRecipes,
    required this.onRecipeTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Serving size
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kBg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Serving Size',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: kDark)),
                Text('$totalCals cals total',
                    style: const TextStyle(color: kGrey, fontSize: 12)),
              ]),
              Row(children: [
                _CounterBtn(
                    icon: Icons.remove,
                    onTap: () {
                      if (servings > 1) onServingsChanged(servings - 1);
                    }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$servings',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                ),
                _CounterBtn(
                    icon: Icons.add,
                    onTap: () => onServingsChanged(servings + 1)),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Ingredients
        const Text('Ingredients',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
        const SizedBox(height: 10),
        ...recipe.ingredients.map((ing) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(
                        color: recipe.color, shape: BoxShape.circle),
                  ),
                  Expanded(
                      child: Text(ing,
                          style: const TextStyle(
                              fontSize: 14, color: kDark, height: 1.4))),
                ],
              ),
            )),

        const SizedBox(height: 20),

        // Directions
        const Text('Directions',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
        const SizedBox(height: 10),
        ...recipe.directions.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26, height: 26,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                        color: recipe.color, shape: BoxShape.circle),
                    child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700))),
                  ),
                  Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 14, color: kDark, height: 1.5))),
                ],
              ),
            )),

        const SizedBox(height: 20),

        // Other Recipes
        const Text('Other Recipes',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: otherRecipes.length,
            itemBuilder: (_, i) => RecipeCard(
              recipe: otherRecipes[i],
              onTap: () => onRecipeTap(otherRecipes[i]),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Find alternatives
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kPrimary),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Find other alternatives',
              style: TextStyle(
                  color: kPrimary, fontWeight: FontWeight.w600)),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Nutrition tab ─────────────────────────────────────────────────────────────
class _NutritionTab extends StatelessWidget {
  final Recipe recipe;
  const _NutritionTab({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: kDark, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nutrition Facts',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: kDark)),
              const Divider(color: kDark, thickness: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kDark)),
                  const Text('Per Serving',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kDark)),
                ],
              ),
              const Divider(color: kDark, thickness: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Calories',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kDark)),
                  Text('${recipe.caloriesPerServing}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: kDark)),
                ],
              ),
              const Divider(color: kDark, thickness: 4),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('% Daily Value*',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: kDark)),
              ),
              ...recipe.nutritionFacts.entries
                  .map((e) => _NutrRow(label: e.key, fact: e.value)),
              const Divider(color: kDark),
              const Text(
                '* The % Daily Value (DV) tells you how much a nutrient in a serving contributes to a daily diet. 2000 calories a day is used for general nutrition advice.',
                style: TextStyle(fontSize: 11, color: kGrey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _NutrRow extends StatelessWidget {
  final String label;
  final NutritionFact fact;
  const _NutrRow({required this.label, required this.fact});

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kDark)),
              Text(
                  '${fact.amount.toStringAsFixed(0)}g  '
                  '${fact.dv.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 13, color: kDark)),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFDDDDDD)),
      ]);
}

// ── Add to Meal sheet ─────────────────────────────────────────────────────────
class _AddToMealSheet extends StatelessWidget {
  final ValueChanged<String> onAdd;
  const _AddToMealSheet({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add to Meal',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kDark)),
          const SizedBox(height: 16),
          ...mealTypes.map((mt) => ListTile(
                leading: Text(mealTypeEmoji(mt),
                    style: const TextStyle(fontSize: 22)),
                title: Text(mt,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: kDark)),
                contentPadding: EdgeInsets.zero,
                onTap: () => onAdd(mt),
              )),
        ],
      ),
    );
  }
}

// ── Counter button ────────────────────────────────────────────────────────────
class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: kBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: kDark),
        ),
      );
}

// ── Tab delegate ──────────────────────────────────────────────────────────────
class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(_, __, ___) =>
      Container(color: Colors.white, child: tabBar);

  @override
  bool shouldRebuild(_) => false;
}
