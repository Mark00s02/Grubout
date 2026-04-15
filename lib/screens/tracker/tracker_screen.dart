import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/food_api_service.dart';
import '../../data/filipino_calories.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (!provider.isLoggedIn) {
      return const _NoAccessScreen();
    }

    final date = provider.selectedDate;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Month navigation ─────────────────────────────────────────
            _MonthHeader(date: date, provider: provider),

            // ── Week strip ───────────────────────────────────────────────
            _WeekStrip(selected: date, onTap: provider.selectDate),

            const SizedBox(height: 12),

            // ── Tabs ─────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: kGrey,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Calories'),
                  Tab(text: 'Macronutrients'),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Tab content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _CaloriesTab(provider: provider),
                  _MacroTab(provider: provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Month header ─────────────────────────────────────────────────────────────
class _MonthHeader extends StatelessWidget {
  final DateTime date;
  final AppProvider provider;
  const _MonthHeader({required this.date, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.selectDate(
                DateTime(date.year, date.month - 1, date.day)),
            child: const Icon(Icons.chevron_left, color: kDark),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy').format(date),
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kDark),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.selectDate(
                DateTime(date.year, date.month + 1, date.day)),
            child: const Icon(Icons.chevron_right, color: kDark),
          ),
        ],
      ),
    );
  }
}

// ── Week strip ───────────────────────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onTap;
  const _WeekStrip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = selected.subtract(
        Duration(days: selected.weekday % 7));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: days.asMap().entries.map((e) {
          final d = e.value;
          final isSelected = d.day == selected.day &&
              d.month == selected.month &&
              d.year == selected.year;
          final isToday = _isToday(d);

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(d),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabels[e.key],
                    style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? kPrimary : kGrey,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: kPrimary, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : kDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.day == now.day && d.month == now.month && d.year == now.year;
  }
}

// ── Calories tab ─────────────────────────────────────────────────────────────
class _CaloriesTab extends StatelessWidget {
  final AppProvider provider;
  const _CaloriesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final consumed  = provider.caloriesConsumed;
    final remaining = provider.caloriesRemaining;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 12),

        // ── Calorie ring ──────────────────────────────────────────────────
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      value: consumed > 0 ? consumed : 0.001,
                      color: kPrimary,
                      radius: 14,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: remaining > 0 ? remaining : 0.001,
                      color: kLightGrey,
                      radius: 14,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${consumed.round()}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: kDark),
                ),
                const Text('cals',
                    style: TextStyle(fontSize: 12, color: kGrey)),
                Text(
                  remaining >= 0
                      ? '${remaining.round()} under'
                      : '${(-remaining).round()} over',
                  style: TextStyle(
                      fontSize: 11,
                      color: remaining >= 0 ? kPrimary : Colors.red,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ]),
          ),
        ),

        // ── Macro mini bars ───────────────────────────────────────────────
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MacroChip('Fat',     '${provider.totalFat.round()}g',
                const Color(0xFFFF9800)),
            _MacroChip('Carbs',   '${provider.totalCarbs.round()}g',
                const Color(0xFF9C27B0)),
            _MacroChip('Protein', '${provider.totalProtein.round()}g',
                const Color(0xFF2196F3)),
          ],
        ),

        const SizedBox(height: 20),

        // ── Meal sections ─────────────────────────────────────────────────
        for (final meal in ['Breakfast', 'Lunch', 'Dinner', 'Snacks'])
          _MealSection(
              mealType: meal,
              logs: provider.logsForMeal(meal.toLowerCase()),
              provider: provider),

        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Macronutrients tab ────────────────────────────────────────────────────────
class _MacroTab extends StatelessWidget {
  final AppProvider provider;
  const _MacroTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final fat     = provider.fatPct;
    final carbs   = provider.carbsPct;
    final protein = provider.proteinPct;
    final hasData = provider.totalMacros > 0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),

        // ── Pie chart ─────────────────────────────────────────────────────
        Center(
          child: SizedBox(
            height: 180,
            width: 180,
            child: hasData
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: fat * 100,
                          color: const Color(0xFFFF9800),
                          title: '${(fat * 100).round()}%',
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: carbs * 100,
                          color: const Color(0xFF9C27B0),
                          title: '${(carbs * 100).round()}%',
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: protein * 100,
                          color: const Color(0xFF2196F3),
                          title: '${(protein * 100).round()}%',
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                          radius: 60,
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text('No food logged yet',
                        style: TextStyle(color: Colors.grey.shade400))),
          ),
        ),

        const SizedBox(height: 16),

        // ── Legend ────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot('Fat',     const Color(0xFFFF9800),
                '${provider.totalFat.round()}g'),
            const SizedBox(width: 20),
            _LegendDot('Carbs',   const Color(0xFF9C27B0),
                '${provider.totalCarbs.round()}g'),
            const SizedBox(width: 20),
            _LegendDot('Protein', const Color(0xFF2196F3),
                '${provider.totalProtein.round()}g'),
          ],
        ),

        const SizedBox(height: 24),

        // ── Meal sections ─────────────────────────────────────────────────
        for (final meal in ['Breakfast', 'Lunch', 'Dinner', 'Snacks'])
          _MealSection(
              mealType: meal,
              logs: provider.logsForMeal(meal.toLowerCase()),
              provider: provider),

        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Meal section ──────────────────────────────────────────────────────────────
class _MealSection extends StatelessWidget {
  final String mealType;
  final List<FoodLog> logs;
  final AppProvider provider;
  const _MealSection(
      {required this.mealType,
      required this.logs,
      required this.provider});

  double get _totalCal =>
      logs.fold(0.0, (s, l) => s + l.calories);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              Icon(mealTypeIcon(mealType),
                  size: 20, color: mealTypeColor(mealType)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mealType,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kDark)),
                    Text('${_totalCal.round()} calories',
                        style: const TextStyle(
                            fontSize: 11, color: kGrey)),
                  ],
                ),
              ),
              // Add food button
              GestureDetector(
                onTap: () => _showAddFood(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Add Food',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),

          // Log items
          ...logs.map((log) => _LogTile(log: log, provider: provider)),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showAddFood(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(
        mealType: mealType.toLowerCase(),
        provider: provider,
        selectedDate: provider.selectedDate,
      ),
    );
  }
}

// ── Log tile ─────────────────────────────────────────────────────────────────
class _LogTile extends StatelessWidget {
  final FoodLog log;
  final AppProvider provider;
  const _LogTile({required this.log, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('log_${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        if (log.id != null) provider.removeFoodLog(log.id!);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.foodName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDark)),
                Text(
                    '${log.servingAmount.round()}${log.servingUnit}  •  '
                    '${log.protein.round()}g protein  •  '
                    '${log.carbs.round()}g carbs',
                    style: const TextStyle(fontSize: 11, color: kGrey)),
              ],
            ),
          ),
          Text('${log.calories.round()} cal',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: kPrimary)),
        ]),
      ),
    );
  }
}

// ── Add Food sheet ────────────────────────────────────────────────────────────
class _AddFoodSheet extends StatefulWidget {
  final String mealType;
  final AppProvider provider;
  final DateTime selectedDate;
  const _AddFoodSheet(
      {required this.mealType,
      required this.provider,
      required this.selectedDate});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

/// Conversion factors to grams for calorie calculation (approximate).
const _unitFactors = <String, double>{
  'g':       1.0,
  'oz':      28.35,
  'cup':     240.0,
  'tbsp':    15.0,
  'tsp':     5.0,
  'piece':   100.0,
  'serving': 100.0,
};

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _searchCtrl   = TextEditingController();
  final _amountCtrl   = TextEditingController(text: '100');
  List<FoodSearchResult> _results = [];
  bool _searching = false;
  FoodSearchResult? _selected;
  String _unit = 'g';

  double get _grams {
    final amount = double.tryParse(_amountCtrl.text) ?? 100;
    return amount * (_unitFactors[_unit] ?? 1.0);
  }

  @override
  void initState() {
    super.initState();
    _results = filipinoFoods.take(20).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = filipinoFoods.take(20).toList());
      return;
    }
    setState(() => _searching = true);

    // Local Filipino DB first (instant)
    final local = searchFilipino(q);
    setState(() => _results = local);

    // Parallel API calls: USDA + Open Food Facts
    final svc = FoodApiService();
    final apiResults = await Future.wait([
      svc.searchUSDA(q),
      svc.searchOpenFoodFacts(q),
    ]);

    if (mounted) {
      setState(() {
        _results = [...local, ...apiResults[0], ...apiResults[1]];
        _searching = false;
      });
    }
  }

  void _addFood() {
    if (_selected == null || widget.provider.user == null) return;
    final cal = _selected!.caloriesPer100g * _grams / 100;
    final amount = double.tryParse(_amountCtrl.text) ?? 100;
    final log = FoodLog(
      userId: widget.provider.user!.id!,
      foodName: _selected!.name,
      calories: cal,
      protein: _selected!.proteinPer100g * _grams / 100,
      carbs: _selected!.carbsPer100g * _grams / 100,
      fat: _selected!.fatPer100g * _grams / 100,
      servingAmount: amount,
      servingUnit: _unit,
      mealType: widget.mealType,
      logDate: widget.selectedDate,
      fdcId: _selected!.id,
    );
    widget.provider.addFoodLog(log);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: kLightGrey,
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Add to ${_capitalize(widget.mealType)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const Spacer(),
                  if (_selected != null)
                    TextButton(
                      onPressed: _addFood,
                      child: const Text('Add',
                          style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search food...',
                  prefixIcon: const Icon(Icons.search, color: kGrey, size: 20),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kPrimary)))
                      : null,
                ),
                onChanged: (v) =>
                    Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchCtrl.text == v) _search(v);
                }),
              ),
            ),

            // Serving size (if selected)
            if (_selected != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selected!.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: kDark,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(children: [
                        // Amount field
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: kDark,
                                fontSize: 14),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: kLightGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: kLightGrey),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unit dropdown
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _unit,
                            isDense: true,
                            borderRadius: BorderRadius.circular(10),
                            items: _unitFactors.keys
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: kDark)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _unit = v ?? 'g'),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '≈ ${_grams.round()} g',
                          style: const TextStyle(
                              fontSize: 12, color: kGrey),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        '${(_selected!.caloriesPer100g * _grams / 100).round()} kcal  '
                        '• P: ${(_selected!.proteinPer100g * _grams / 100).round()}g  '
                        '• C: ${(_selected!.carbsPer100g * _grams / 100).round()}g  '
                        '• F: ${(_selected!.fatPer100g * _grams / 100).round()}g',
                        style: const TextStyle(
                            fontSize: 12,
                            color: kPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Results list
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final f = _results[i];
                  final isSelected = _selected?.id == f.id;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: kPrimary.withValues(alpha: 0.08),
                    title: Text(f.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                        '${f.caloriesPer100g.round()} kcal/100g'
                        '${f.isLocal ? '  🇵🇭' : ''}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: kPrimary)
                        : null,
                    onTap: () => setState(() {
                      _selected = f;
                      _amountCtrl.text = '100';
                      _unit = 'g';
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: kDark)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: kGrey)),
        ],
      );
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  final String value;
  const _LegendDot(this.label, this.color, this.value);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: kGrey)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kDark)),
          ]),
        ],
      );
}

// ── No access screen (not logged in) ─────────────────────────────────────────
class _NoAccessScreen extends StatelessWidget {
  const _NoAccessScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart_rounded, size: 72, color: kPrimary),
              const SizedBox(height: 16),
              const Text('Calorie Tracker',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kDark)),
              const SizedBox(height: 8),
              Text('You must login to use this feature',
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pushNamed('/login'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Login',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}
