import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'premium/paywall_screen.dart';
import 'recipe_screen.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  DietPlan? _plan;
  bool _loaded = false;
  DateTime _day = dateOnly(DateTime.now());

  String get _prefKey => 'diet_plan_${context.read<AppProvider>().user?.id}';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey);
    if (!mounted) return;
    setState(() {
      _plan = dietPlans.where((p) => p.id == id).firstOrNull;
      _loaded = true;
    });
  }

  Future<void> _choose(DietPlan? plan) async {
    final prefs = await SharedPreferences.getInstance();
    if (plan == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, plan.id);
    }
    if (mounted) setState(() => _plan = plan);
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.select<AppProvider, bool>((p) => p.isPremium);
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan?.name ?? 'Diet plans'),
        actions: [
          if (_plan != null && premium)
            TextButton(onPressed: () => _choose(null), child: const Text('Change plan')),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : !premium
              ? _Locked()
              : _plan == null
                  ? _PlanList(onSelect: (p) async {
                      final chosen = await Navigator.push<bool>(
                          context, MaterialPageRoute(builder: (_) => _PlanDetail(plan: p)));
                      if (chosen == true) _choose(p);
                    })
                  : _Schedule(plan: _plan!, day: _day, onDay: (d) => setState(() => _day = d)),
    );
  }
}

class _Locked extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EmptyState(
            icon: Icons.restaurant_menu_rounded,
            title: 'Diet plans are Premium',
            message: 'Pick a proven eating style and get a daily meal schedule you can log in one tap.',
            action: FilledButton.icon(
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Unlock with Premium'),
              onPressed: () => showPaywall(context),
            ),
          ),
          for (final p in dietPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(opacity: 0.6, child: _PlanBanner(plan: p, locked: true)),
            ),
        ],
      );
}

class _PlanList extends StatelessWidget {
  final ValueChanged<DietPlan> onSelect;
  const _PlanList({required this.onSelect});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Choose a plan that fits your lifestyle', style: TextStyle(color: context.colors.textMuted)),
          const SizedBox(height: 12),
          for (final p in dietPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(onTap: () => onSelect(p), child: _PlanBanner(plan: p)),
            ),
        ],
      );
}

class _PlanBanner extends StatelessWidget {
  final DietPlan plan;
  final bool locked;
  const _PlanBanner({required this.plan, this.locked = false});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 130,
          child: Stack(fit: StackFit.expand, children: [
            NetImage(plan.imageUrl, fallbackEmoji: plan.emoji),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('${plan.emoji}  ${plan.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  ),
                ),
                Icon(locked ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ]),
            ),
          ]),
        ),
      );
}

class _PlanDetail extends StatelessWidget {
  final DietPlan plan;
  const _PlanDetail({required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NetImage(plan.imageUrl, height: 180, width: double.infinity, fallbackEmoji: plan.emoji),
          ),
          const SizedBox(height: 20),
          Text(plan.description, style: const TextStyle(height: 1.55, fontSize: 15)),
          const SizedBox(height: 24),
          Text('Foods to enjoy', style: context.text.titleMedium),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final f in plan.foods)
              Chip(label: Text(f), backgroundColor: c.surfaceAlt, visualDensity: VisualDensity.compact),
          ]),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start this plan'),
          ),
        ),
      ),
    );
  }
}

class _Schedule extends StatelessWidget {
  final DietPlan plan;
  final DateTime day;
  final ValueChanged<DateTime> onDay;
  const _Schedule({required this.plan, required this.day, required this.onDay});

  Future<void> _log(BuildContext context, ScheduledMeal m) async {
    final p = context.read<AppProvider>();
    final r = m.recipe;
    await p.addFoodLog(FoodLog(
      userId: p.user!.id!,
      foodName: r.name,
      calories: r.caloriesPerServing.toDouble(),
      protein: r.protein,
      carbs: r.carbs,
      fat: r.fat,
      servingAmount: 1,
      servingUnit: 'serving',
      mealType: m.mealType.toLowerCase(),
      logDate: day,
      fdcId: 'recipe_${r.id}',
    ));
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    showSnack(context, '${r.name} logged for ${DateFormat('EEE').format(day)}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    final meals = scheduledMealsForDate(day);
    final total = meals.fold(0, (s, m) => s + m.recipe.caloriesPerServing);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        SizedBox(
          height: 72,
          child: Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Builder(builder: (_) {
                  final d = start.add(Duration(days: i));
                  final sel = d == day;
                  return GestureDetector(
                    onTap: () => onDay(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: d == today && !sel ? Border.all(color: kPrimary) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(DateFormat('E').format(d).substring(0, 3),
                            style: TextStyle(fontSize: 11, color: sel ? Colors.white70 : c.textMuted)),
                        const SizedBox(height: 4),
                        Text('${d.day}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16, color: sel ? Colors.white : c.text)),
                      ]),
                    ),
                  );
                }),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('${DateFormat('EEEE').format(day)} · ${fmtNum(total)} kcal planned',
            style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (final m in meals)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeScreen(recipe: m.recipe))),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: NetImage(m.recipe.imageUrl, width: 72, height: 72, fallbackEmoji: m.recipe.emoji),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(mealTypeIcon(m.mealType), size: 14, color: mealTypeColor(m.mealType)),
                      const SizedBox(width: 4),
                      Text('${m.mealType} · ${m.time}',
                          style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    Text(m.recipe.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('${m.recipe.caloriesPerServing} kcal', style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ]),
                ),
                IconButton.filledTonal(
                  tooltip: 'Log to diary',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _log(context, m),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
