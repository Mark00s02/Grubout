import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../data/filipino_calories.dart';
import 'recipe_screen.dart';

enum _View { plans, planDetail, schedule }

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  _View _view = _View.plans;
  DietPlan? _selectedPlan;
  DateTime _selectedDate = DateTime.now();
  late List<ScheduledMeal> _meals = scheduledMealsForDate(_selectedDate);

  static const _timeSlots = ['8:00 AM', '12:00 PM', '3:00 PM', '7:00 PM'];
  static const _slotMealType = {
    '8:00 AM': 'Breakfast',
    '12:00 PM': 'Lunch',
    '3:00 PM': 'Snacks',
    '7:00 PM': 'Dinner',
  };

  List<ScheduledMeal> get _dayMeals => _meals;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _buildView()),
    );
  }

  Widget _buildView() {
    switch (_view) {
      case _View.plans:
        return _PlansView(
          plans: dietPlans,
          onSelect: (p) => setState(() {
            _selectedPlan = p;
            _view = _View.planDetail;
          }),
        );
      case _View.planDetail:
        return _PlanDetailView(
          plan: _selectedPlan!,
          onBack: () => setState(() => _view = _View.plans),
          onSchedule: () => setState(() => _view = _View.schedule),
        );
      case _View.schedule:
        return _ScheduleView(
          plan: _selectedPlan!,
          selectedDate: _selectedDate,
          dayMeals: _dayMeals,
          timeSlots: _timeSlots,
          slotMealType: _slotMealType,
          onDateChanged: (d) => setState(() {
            _selectedDate = d;
            _meals = scheduledMealsForDate(d);
          }),
          onReschedule: (meal, newType) => setState(() {
            final idx = _meals.indexWhere((m) =>
                m.mealType == meal.mealType && m.recipe.id == meal.recipe.id);
            if (idx != -1) {
              final updated = ScheduledMeal(
                mealType: newType,
                recipe: meal.recipe,
                time: _slotMealType.entries
                    .firstWhere((e) => e.value == newType)
                    .key,
                rescheduled: true,
              );
              _meals[idx] = updated;
            }
          }),
          onChangePlan: () => setState(() => _view = _View.plans),
          onGoToRecipe: (r) => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RecipeScreen(recipe: r))),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plans list
// ─────────────────────────────────────────────────────────────────────────────
class _PlansView extends StatelessWidget {
  final List<DietPlan> plans;
  final ValueChanged<DietPlan> onSelect;
  const _PlansView({required this.plans, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text('Diet Plans',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kDark)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text('Choose a plan that suits your lifestyle.',
              style: TextStyle(color: kGrey, fontSize: 14)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _PlanCard(plan: plans[i], onTap: () => onSelect(plans[i])),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final DietPlan plan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: plan.color,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (plan.imageUrl != null)
              CachedNetworkImage(
                imageUrl: plan.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: plan.color),
                errorWidget: (_, __, ___) => Container(color: plan.color),
              )
            else
              Container(color: plan.color),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Emoji badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(plan.emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(plan.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${plan.foods.length} foods included',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan detail
// ─────────────────────────────────────────────────────────────────────────────
class _PlanDetailView extends StatefulWidget {
  final DietPlan plan;
  final VoidCallback onBack;
  final VoidCallback onSchedule;
  const _PlanDetailView(
      {required this.plan, required this.onBack, required this.onSchedule});

  @override
  State<_PlanDetailView> createState() => _PlanDetailViewState();
}

class _PlanDetailViewState extends State<_PlanDetailView> {
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> get _filteredFoods {
    if (_search.isEmpty) return widget.plan.foods;
    return widget.plan.foods
        .where((f) => f.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Column(
      children: [
        // ── Image header ──
        SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (plan.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: plan.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: plan.color),
                  errorWidget: (_, __, ___) => Container(color: plan.color),
                )
              else
                Container(
                  color: plan.color,
                  child: Center(
                    child: Text(plan.emoji,
                        style: const TextStyle(fontSize: 64)),
                  ),
                ),
              // Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: 12, left: 12,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: kDark, size: 20),
                  ),
                ),
              ),
              // Title
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(plan.emoji,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(plan.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('${plan.foods.length} foods included',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Description ──
        Container(
          width: double.infinity,
          color: kBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Text(
            plan.description.split('\n').first,
            style: const TextStyle(fontSize: 13, color: kGrey, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text('Foods',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kDark)),
              const SizedBox(width: 8),
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: plan.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${plan.foods.length}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: plan.color)),
                ),
              ),
              const Spacer(),
              // Search
              Container(
                width: 160, height: 36,
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.search, color: kGrey, size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search foods...',
                        hintStyle: TextStyle(color: kGrey, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 13, color: kDark),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),

        // ── Foods list ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: _filteredFoods.length,
            itemBuilder: (_, i) => _FoodRow(
              food: _filteredFoods[i],
              color: plan.color,
            ),
          ),
        ),

        // ── Button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: widget.onSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: plan.color,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('View Schedule',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class _FoodRow extends StatelessWidget {
  final String food;
  final Color color;
  const _FoodRow({required this.food, required this.color});

  @override
  Widget build(BuildContext context) {
    // Look up nutrition from the Filipino food DB (case-insensitive prefix match)
    final lower = food.toLowerCase();
    final match = filipinoFoods.cast<FoodSearchResult?>().firstWhere(
      (f) => f!.name.toLowerCase().contains(lower) ||
             lower.contains(f.name.toLowerCase()),
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kDivider))),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kDark)),
              if (match != null)
                Text(
                  '${match.caloriesPer100g.round()} kcal / 100g'
                  '  •  P:${match.proteinPer100g.round()}g'
                  '  C:${match.carbsPer100g.round()}g'
                  '  F:${match.fatPer100g.round()}g',
                  style: const TextStyle(fontSize: 11, color: kGrey),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule view
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleView extends StatelessWidget {
  final DietPlan plan;
  final DateTime selectedDate;
  final List<ScheduledMeal> dayMeals;
  final List<String> timeSlots;
  final Map<String, String> slotMealType;
  final ValueChanged<DateTime> onDateChanged;
  final void Function(ScheduledMeal, String) onReschedule;
  final VoidCallback onChangePlan;
  final ValueChanged<Recipe> onGoToRecipe;

  const _ScheduleView({
    required this.plan,
    required this.selectedDate,
    required this.dayMeals,
    required this.timeSlots,
    required this.slotMealType,
    required this.onDateChanged,
    required this.onReschedule,
    required this.onChangePlan,
    required this.onGoToRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Container(
          color: plan.color,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: onChangePlan,
                    child: const Text('Change Plan',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _WeekStrip(selectedDate: selectedDate, onChanged: onDateChanged),
            ],
          ),
        ),

        // ── Sub header showing selected day ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kDark),
            ),
            const Spacer(),
            Text('${dayMeals.length} meals',
                style: const TextStyle(fontSize: 13, color: kGrey)),
          ]),
        ),

        // ── Time slots ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: timeSlots.length,
            itemBuilder: (_, i) {
              final slot = timeSlots[i];
              final mealType = slotMealType[slot]!;
              final meal = dayMeals
                  .where((m) => m.mealType == mealType)
                  .firstOrNull;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(slot,
                            style: const TextStyle(
                                fontSize: 12,
                                color: kGrey,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    Expanded(
                      child: meal != null
                          ? _MealCard(
                              meal: meal,
                              onTap: () => onGoToRecipe(meal.recipe),
                              onReschedule: () =>
                                  _showRescheduleModal(context, meal),
                            )
                          : Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: kBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: kDivider, width: 1.5,
                                    style: BorderStyle.solid),
                              ),
                              child: const Center(
                                  child: Text('No meal scheduled',
                                      style: TextStyle(
                                          color: kGrey, fontSize: 12))),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday]}, ${months[d.month]} ${d.day}';
  }

  void _showRescheduleModal(BuildContext context, ScheduledMeal meal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Move to Meal',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kDark)),
            const SizedBox(height: 16),
            ...['Breakfast', 'Lunch', 'Snacks', 'Dinner'].map((mt) => ListTile(
                  leading: Icon(mealTypeIcon(mt),
                      color: mealTypeColor(mt), size: 22),
                  title: Text(mt,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: kDark)),
                  contentPadding: EdgeInsets.zero,
                  selected: mt == meal.mealType,
                  selectedTileColor: kBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    onReschedule(meal, mt);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  const _WeekStrip({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final weekStart =
        selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final d = days[i];
        final isSelected =
            d.day == selectedDate.day && d.month == selectedDate.month;
        return GestureDetector(
          onTap: () => onChanged(d),
          child: Column(children: [
            Text(dayLabels[i],
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 4),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('${d.day}',
                    style: TextStyle(
                        color: isSelected ? kDark : Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal)),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

class _MealCard extends StatelessWidget {
  final ScheduledMeal meal;
  final VoidCallback onTap;
  final VoidCallback onReschedule;
  const _MealCard(
      {required this.meal, required this.onTap, required this.onReschedule});

  @override
  Widget build(BuildContext context) {
    final color = mealTypeColor(meal.mealType);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          // Meal type indicator
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(mealTypeIcon(meal.mealType),
                  color: mealTypeColor(meal.mealType), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.recipe.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: kDark)),
                Text(
                  '${meal.recipe.caloriesPerServing} cal  •  ${meal.mealType}',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onReschedule,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.swap_horiz, color: color, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}
