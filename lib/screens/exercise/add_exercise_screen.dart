import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/nutrition_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  String _query = '';

  Future<void> _open(ExerciseType? type) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExerciseSheet(type: type),
    );
    if (added == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = exerciseTypes.where((e) => e.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Add exercise')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
                hintText: 'Search activities', prefixIcon: Icon(Icons.search_rounded)),
          ),
        ),
        ListTile(
          leading: const CircleAvatar(
              backgroundColor: kPrimary, child: Icon(Icons.add_rounded, color: Colors.white)),
          title: const Text('Custom exercise', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('Enter the calories from your watch or machine',
              style: TextStyle(color: c.textMuted)),
          onTap: () => _open(null),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.surfaceAlt,
                  child: Text(e.icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('MET ${e.met}', style: TextStyle(color: c.textMuted)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(e),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ExerciseSheet extends StatefulWidget {
  final ExerciseType? type;
  const _ExerciseSheet({this.type});

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet> {
  double _minutes = 30;
  final _name = TextEditingController();
  final _kcal = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    super.dispose();
  }

  double _calories(double weight) => widget.type == null
      ? double.tryParse(_kcal.text) ?? 0
      : NutritionCalculator.exerciseCalories(met: widget.type!.met, weightKg: weight, minutes: _minutes.round());

  Future<void> _save() async {
    final p = context.read<AppProvider>();
    final kcal = _calories(p.currentWeightKg);
    final name = widget.type?.name ?? (_name.text.trim().isEmpty ? 'Exercise' : _name.text.trim());
    if (kcal <= 0) return;
    await p.addExerciseLog(ExerciseLog(
      userId: p.user!.id!,
      name: name,
      durationMinutes: _minutes.round(),
      caloriesBurned: kcal,
      logDate: p.selectedDate,
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
    showSnack(context, '$name logged · ${kcal.round()} kcal burned 🔥');
  }

  @override
  Widget build(BuildContext context) {
    final weight = context.select<AppProvider, double>((p) => p.currentWeightKg);
    final kcal = _calories(weight);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.type?.name ?? 'Custom exercise', style: context.text.titleLarge),
        const SizedBox(height: 16),
        if (widget.type == null) ...[
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Activity name')),
          const SizedBox(height: 12),
          TextField(
            controller: _kcal,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Calories burned'),
          ),
          const SizedBox(height: 12),
        ],
        Row(children: [
          Text('Duration', style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${_minutes.round()} min', style: context.text.titleLarge),
        ]),
        Slider(
          value: _minutes,
          min: 5,
          max: 180,
          divisions: 35,
          onChanged: (v) => setState(() => _minutes = v),
        ),
        if (widget.type != null)
          AppCard(
            color: kCarbsColor.withValues(alpha: 0.12),
            child: Row(children: [
              const Icon(Icons.local_fire_department_rounded, color: kCarbsColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${kcal.round()} kcal', style: context.text.titleLarge),
                  Text('Estimated for ${weight.toStringAsFixed(1)} kg',
                      style: TextStyle(color: context.colors.textMuted, fontSize: 13)),
                ]),
              ),
            ]),
          ),
        const SizedBox(height: 20),
        FilledButton(onPressed: kcal > 0 ? _save : null, child: const Text('Log exercise')),
      ]),
    );
  }
}
