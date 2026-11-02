import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Opens a sheet to pick a meal; returns the chosen meal type.
Future<String?> pickMeal(BuildContext context, {String title = 'Log to which meal?'}) =>
    showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: ctx.text.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              for (final m in mealTypes)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(ctx, m),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: mealTypeColor(m),
                          child: Icon(mealTypeIcon(m), color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(mealTypeLabel(m), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );

class RecipeScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeScreen({super.key, required this.recipe});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int _servings = 1;
  bool _nutrition = false;

  Future<void> _log() async {
    final meal = await pickMeal(context);
    if (meal == null || !mounted) return;
    final p = context.read<AppProvider>();
    final r = widget.recipe;
    await p.addFoodLog(FoodLog(
      userId: p.user!.id!,
      foodName: r.name,
      calories: (r.caloriesPerServing * _servings).toDouble(),
      protein: r.protein * _servings,
      carbs: r.carbs * _servings,
      fat: r.fat * _servings,
      servingAmount: _servings.toDouble(),
      servingUnit: _servings == 1 ? 'serving' : 'servings',
      mealType: meal,
      logDate: p.selectedDate,
      fdcId: 'recipe_${r.id}',
    ));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    showSnack(context, '${r.name} added to ${mealTypeLabel(meal)}');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final c = context.colors;
    final p = context.watch<AppProvider>();
    final saved = p.isRecipeSaved(r.id);
    final others = recipes.where((x) => x.id != r.id).take(6).toList();

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          leading: _CircleButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
          actions: [
            _CircleButton(
              icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: saved ? kDanger : null,
              onTap: () {
                HapticFeedback.selectionClick();
                p.toggleSavedRecipe(r.id, r.name);
              },
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: NetImage(r.imageUrl, fallbackEmoji: r.emoji),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: context.text.headlineSmall),
              const SizedBox(height: 12),
              Row(children: [
                _Stat('${r.caloriesPerServing * _servings}', 'kcal', kPrimary),
                _Stat('${(r.protein * _servings).round()}g', 'protein', kProteinColor),
                _Stat('${(r.carbs * _servings).round()}g', 'carbs', kCarbsColor),
                _Stat('${(r.fat * _servings).round()}g', 'fat', kFatColor),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final t in r.tags) Pill(t)]),
              const SizedBox(height: 20),
              Row(children: [
                Text('Servings', style: context.text.titleMedium),
                const Spacer(),
                StepperButton(
                    icon: Icons.remove_rounded,
                    onTap: () => setState(() => _servings = (_servings - 1).clamp(1, 20))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_servings', style: context.text.titleLarge),
                ),
                StepperButton(
                    icon: Icons.add_rounded, onTap: () => setState(() => _servings = (_servings + 1).clamp(1, 20))),
              ]),
              const SizedBox(height: 20),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Recipe')),
                  ButtonSegment(value: true, label: Text('Nutrition facts')),
                ],
                selected: {_nutrition},
                onSelectionChanged: (s) => setState(() => _nutrition = s.first),
              ),
              const SizedBox(height: 20),
              if (!_nutrition) ...[
                Text('Ingredients', style: context.text.titleMedium),
                const SizedBox(height: 8),
                for (final i in r.ingredients)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Icon(Icons.circle, size: 6, color: kPrimary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(i, style: const TextStyle(height: 1.4))),
                    ]),
                  ),
                const SizedBox(height: 20),
                Text('Directions', style: context.text.titleMedium),
                const SizedBox(height: 8),
                for (var i = 0; i < r.directions.length; i++)
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
                      Expanded(child: Text(r.directions[i], style: const TextStyle(height: 1.5))),
                    ]),
                  ),
              ] else
                _NutritionLabel(recipe: r, servings: _servings),
              const SizedBox(height: 24),
              Text('More recipes', style: context.text.titleMedium),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 170,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: others.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => RecipeScreen(recipe: others[i]))),
                child: SizedBox(
                  width: 130,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: NetImage(others[i].imageUrl, width: 130, height: 120, fallbackEmoji: others[i].emoji),
                    ),
                    const SizedBox(height: 6),
                    Text(others[i].name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${others[i].caloriesPerServing} kcal', style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: _log,
            icon: const Icon(Icons.add_task_rounded),
            label: Text('Log $_servings serving${_servings == 1 ? '' : 's'} · ${r.caloriesPerServing * _servings} kcal'),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _CircleButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: context.colors.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: color ?? context.colors.text, size: 22)),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(label, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
          ]),
        ),
      );
}

class _NutritionLabel extends StatelessWidget {
  final Recipe recipe;
  final int servings;
  const _NutritionLabel({required this.recipe, required this.servings});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String unit(String k) => (k == 'Sodium' || k == 'Cholesterol' || k == 'Potassium') ? 'mg' : 'g';
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Nutrition Facts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text('$servings serving${servings == 1 ? '' : 's'}', style: TextStyle(color: c.textMuted)),
        Divider(thickness: 6, color: c.text, height: 20),
        Row(children: [
          const Text('Calories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('${recipe.caloriesPerServing * servings}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        ]),
        Divider(thickness: 3, color: c.text, height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('% Daily Value*', style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w700)),
        ),
        for (final e in recipe.nutritionFacts.entries) ...[
          Divider(color: c.border),
          Row(children: [
            Padding(
              padding: EdgeInsets.only(left: e.key == 'Saturated Fat' || e.key == 'Dietary Fiber' || e.key == 'Sugars' ? 16 : 0),
              child: Text(e.key,
                  style: TextStyle(
                      fontWeight: e.key.startsWith('Total') || e.key == 'Protein' ? FontWeight.w800 : FontWeight.w500)),
            ),
            const SizedBox(width: 6),
            Text('${(e.value.amount * servings).toStringAsFixed(e.value.amount * servings < 10 ? 1 : 0)}${unit(e.key)}',
                style: TextStyle(color: c.textMuted)),
            const Spacer(),
            Text('${(e.value.dv * servings).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ],
        const SizedBox(height: 10),
        Text('*Percent Daily Values are based on a 2,000 calorie diet.',
            style: TextStyle(fontSize: 11, color: c.textMuted)),
      ]),
    );
  }
}
