import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Opens the serving picker for [food]. Returns `true` when something was
/// added or updated. Pass [existing] to edit a diary entry instead.
Future<bool?> showFoodDetailSheet(
  BuildContext context, {
  required FoodSearchResult food,
  required String mealType,
  FoodLog? existing,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FoodDetailSheet(food: food, mealType: mealType, existing: existing),
    );

class _FoodDetailSheet extends StatefulWidget {
  final FoodSearchResult food;
  final String mealType;
  final FoodLog? existing;
  const _FoodDetailSheet({required this.food, required this.mealType, this.existing});

  @override
  State<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<_FoodDetailSheet> {
  late final Map<String, double> _units;
  late String _unit;
  late final TextEditingController _amountCtrl;
  late String _meal = widget.mealType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    final serving = f.servingGrams;
    _units = {
      if (serving != null) 'serving': serving,
      'g': 1,
      'oz': 28.35,
      'cup': 240,
      'tbsp': 15,
      'tsp': 5,
      if (serving == null) 'piece': 100,
    };
    final e = widget.existing;
    if (e != null) {
      _unit = _units.containsKey(e.servingUnit) ? e.servingUnit : 'g';
      final amount = _unit == e.servingUnit ? e.servingAmount : (e.grams ?? 100);
      _amountCtrl = TextEditingController(text: _fmt(amount));
    } else {
      _unit = serving != null ? 'serving' : 'g';
      _amountCtrl = TextEditingController(text: serving != null ? '1' : '100');
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');

  double get _amount => double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _grams => _amount * (_units[_unit] ?? 1);

  void _step(double delta) {
    final step = _unit == 'g' ? 10.0 : (_unit == 'oz' ? 1.0 : 0.5);
    final next = (_amount + delta * step).clamp(0, 10000).toDouble();
    setState(() => _amountCtrl.text = _fmt(next));
    HapticFeedback.selectionClick();
  }

  Future<void> _save() async {
    if (_grams <= 0) return;
    setState(() => _saving = true);
    final p = context.read<AppProvider>();
    final log = p.buildLog(
      food: widget.food,
      grams: _grams,
      amount: _amount,
      unit: _unit,
      mealType: _meal,
      date: widget.existing?.logDate,
    );
    if (widget.existing != null) {
      await p.updateFoodLog(FoodLog(
        id: widget.existing!.id,
        userId: log.userId,
        foodName: log.foodName,
        calories: log.calories,
        protein: log.protein,
        carbs: log.carbs,
        fat: log.fat,
        servingAmount: log.servingAmount,
        servingUnit: log.servingUnit,
        grams: log.grams,
        mealType: log.mealType,
        logDate: log.logDate,
        fdcId: log.fdcId,
      ));
    } else {
      await p.addFoodLog(log);
    }
    if (!mounted) return;
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(widget.existing != null
            ? 'Entry updated'
            : '${widget.food.name} added to ${mealTypeLabel(_meal)}'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = widget.food;
    final g = _grams;
    final kcal = f.caloriesPer100g * g / 100;
    final protein = f.proteinPer100g * g / 100;
    final carbs = f.carbsPer100g * g / 100;
    final fat = f.fatPer100g * g / 100;
    final macroKcal = protein * 4 + carbs * 4 + fat * 9;
    final goal = context.select<AppProvider, int>((p) => p.calorieGoal);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(f.name, style: context.text.titleLarge),
          if (f.brand != null && f.brand!.isNotEmpty)
            Text(f.brand!, style: TextStyle(color: c.textMuted)),
          const SizedBox(height: 18),

          // ── Calories + macro split ───────────────────────────────────────
          Row(children: [
            ProgressRing(
              value: goal > 0 ? kcal / goal : 0,
              size: 96,
              stroke: 9,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${kcal.round()}', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                Text('kcal', style: TextStyle(fontSize: 11, color: c.textMuted)),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(children: [
                _MacroLine('Protein', protein, macroKcal > 0 ? protein * 4 / macroKcal : 0, kProteinColor),
                _MacroLine('Carbs', carbs, macroKcal > 0 ? carbs * 4 / macroKcal : 0, kCarbsColor),
                _MacroLine('Fat', fat, macroKcal > 0 ? fat * 9 / macroKcal : 0, kFatColor),
              ]),
            ),
          ]),
          const SizedBox(height: 6),
          Text('${goal > 0 ? (kcal / goal * 100).round() : 0}% of your daily goal',
              style: TextStyle(fontSize: 12, color: c.textMuted)),
          const SizedBox(height: 22),

          // ── Serving ──────────────────────────────────────────────────────
          Text('Amount', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            StepperButton(icon: Icons.remove_rounded, onTap: () => _step(-1)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                style: context.text.titleLarge,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            StepperButton(icon: Icons.add_rounded, onTap: () => _step(1)),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final u in _units.keys)
              ChoiceChip(
                label: Text(u == 'serving' ? (f.servingLabel ?? 'serving') : u),
                selected: _unit == u,
                showCheckmark: false,
                labelStyle: TextStyle(
                    color: _unit == u ? Colors.white : c.text, fontWeight: FontWeight.w600),
                onSelected: (_) => setState(() {
                  // Keep the same gram amount when switching units.
                  final grams = _grams;
                  _unit = u;
                  _amountCtrl.text = _fmt(double.parse((grams / _units[u]!).toStringAsFixed(2)));
                }),
              ),
          ]),
          const SizedBox(height: 6),
          Text('≈ ${g.round()} g', style: TextStyle(fontSize: 12, color: c.textMuted)),
          const SizedBox(height: 18),

          // ── Meal ─────────────────────────────────────────────────────────
          Text('Meal', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            for (final m in mealTypes)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _MealChoice(meal: m, selected: _meal == m, onTap: () => setState(() => _meal = m)),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving || g <= 0 ? null : _save,
              child: Text(widget.existing != null ? 'Update entry' : 'Add to ${mealTypeLabel(_meal)}'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  final String label;
  final double grams;
  final double share;
  final Color color;
  const _MacroLine(this.label, this.grams, this.share, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: context.colors.textMuted))),
          Text('${grams.toStringAsFixed(grams < 10 ? 1 : 0)} g',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(
            width: 44,
            child: Text('${(share * 100).round()}%',
                textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
          ),
        ]),
      );
}

class _MealChoice extends StatelessWidget {
  final String meal;
  final bool selected;
  final VoidCallback onTap;
  const _MealChoice({required this.meal, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = mealTypeColor(meal);
    return Material(
      color: selected ? color : context.colors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(children: [
            Icon(mealTypeIcon(meal), size: 20, color: selected ? Colors.white : color),
            const SizedBox(height: 4),
            Text(mealTypeLabel(meal),
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : context.colors.text)),
          ]),
        ),
      ),
    );
  }
}

// ── Quick add ────────────────────────────────────────────────────────────────
Future<bool?> showQuickAddSheet(BuildContext context, {required String mealType, String? name}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _QuickAddSheet(mealType: mealType, name: name),
    );

class _QuickAddSheet extends StatefulWidget {
  final String mealType;
  final String? name;
  const _QuickAddSheet({required this.mealType, this.name});

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  late final _name = TextEditingController(text: widget.name ?? '');
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _kcal, _p, _c, _f]) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final kcal = _v(_kcal) > 0 ? _v(_kcal) : _v(_p) * 4 + _v(_c) * 4 + _v(_f) * 9;
    if (kcal <= 0) return;
    await context.read<AppProvider>().quickAdd(
          mealType: widget.mealType,
          calories: kcal,
          protein: _v(_p),
          carbs: _v(_c),
          fat: _v(_f),
          name: _name.text.trim().isEmpty ? 'Quick add' : _name.text.trim(),
        );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    Widget num(TextEditingController c, String label, {Color? color}) => TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: color == null
                ? null
                : Icon(Icons.circle, size: 10, color: color),
          ),
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Quick add to ${mealTypeLabel(widget.mealType)}', style: context.text.titleLarge),
        const SizedBox(height: 6),
        Text('Know the numbers? Log them directly.', style: TextStyle(color: context.colors.textMuted)),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name (optional)')),
        const SizedBox(height: 12),
        num(_kcal, 'Calories (kcal)'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: num(_p, 'Protein g', color: kProteinColor)),
          const SizedBox(width: 8),
          Expanded(child: num(_c, 'Carbs g', color: kCarbsColor)),
          const SizedBox(width: 8),
          Expanded(child: num(_f, 'Fat g', color: kFatColor)),
        ]),
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ]),
    );
  }
}
