import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/food_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'food/food_detail_sheet.dart';
import 'recipe_screen.dart';

/// Recipe from TheMealDB (loads full details if only a summary was passed).
class MealDbScreen extends StatefulWidget {
  final MealDbRecipe meal;
  const MealDbScreen({super.key, required this.meal});

  @override
  State<MealDbScreen> createState() => _MealDbScreenState();
}

class _MealDbScreenState extends State<MealDbScreen> {
  late MealDbRecipe _meal = widget.meal;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_meal.ingredients.isEmpty) _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final full = await FoodApiService().getMealDetail(_meal.id);
    if (!mounted) return;
    setState(() {
      if (full != null) _meal = full;
      _loading = false;
    });
  }

  Future<void> _log() async {
    final meal = await pickMeal(context);
    if (meal == null || !mounted) return;
    // Library recipes have no nutrition data — let the user enter calories.
    await showQuickAddSheet(context, mealType: meal, name: _meal.name);
  }

  @override
  Widget build(BuildContext context) {
    final m = _meal;
    final c = context.colors;
    final p = context.watch<AppProvider>();
    final savedId = 'mdb_${m.id}';
    final saved = p.isRecipeSaved(savedId);
    final steps = m.instructionSteps;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: CircleAvatar(
              backgroundColor: c.surface.withValues(alpha: 0.92),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: c.text),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: c.surface.withValues(alpha: 0.92),
                child: IconButton(
                  icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: saved ? kDanger : c.text),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    p.toggleSavedRecipe(savedId, m.name);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(background: NetImage(m.imageUrl)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name, style: context.text.headlineSmall),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [
                if (m.area != null) Pill(m.area!, icon: Icons.public_rounded),
                if (m.category != null) Pill(m.category!, icon: Icons.category_rounded, color: kProteinColor),
              ]),
              if (_loading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              if (m.ingredients.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Ingredients', style: context.text.titleMedium),
                const SizedBox(height: 8),
                for (final line in m.ingredientLines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6, color: kPrimary)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(line, style: const TextStyle(height: 1.4))),
                    ]),
                  ),
              ],
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Directions', style: context.text.titleMedium),
                const SizedBox(height: 8),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: kPrimary.withValues(alpha: 0.12),
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPrimary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(steps[i], style: const TextStyle(height: 1.5))),
                    ]),
                  ),
              ],
              const SizedBox(height: 16),
              Text('Recipe from TheMealDB. Nutrition is not provided for library recipes.',
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: _log,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Log to diary'),
          ),
        ),
      ),
    );
  }
}
