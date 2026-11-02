import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

/// Create a reusable food from a nutrition label (values per serving).
/// Pops with the created [FoodSearchResult].
class CreateFoodScreen extends StatefulWidget {
  final String initialName;
  const CreateFoodScreen({super.key, this.initialName = ''});

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  final _brand = TextEditingController();
  final _servingLabel = TextEditingController(text: '1 serving');
  final _servingGrams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _brand, _servingLabel, _servingGrams, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final g = _v(_servingGrams);
    final f = 100 / g;
    final food = FoodSearchResult(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      caloriesPer100g: _v(_kcal) * f,
      proteinPer100g: _v(_protein) * f,
      carbsPer100g: _v(_carbs) * f,
      fatPer100g: _v(_fat) * f,
      servingGrams: g,
      servingLabel: _servingLabel.text.trim().isEmpty ? '1 serving' : _servingLabel.text.trim(),
      source: FoodSource.custom,
    );
    await context.read<AppProvider>().addCustomFood(food);
    if (mounted) Navigator.pop(context, food);
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
    String? positive(String? v) =>
        (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) > 0 ? null : 'Enter a number';
    Widget numField(TextEditingController c, String label, {bool req = false, Color? dot}) => TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: req ? positive : null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: dot == null ? null : Icon(Icons.circle, size: 10, color: dot),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Create food')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Food name'),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Brand (optional)'),
            ),
            const SizedBox(height: 24),
            Text('Serving', style: context.text.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _servingLabel,
                  decoration: const InputDecoration(labelText: 'Serving name', hintText: 'e.g. 1 cup'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: numField(_servingGrams, 'Grams', req: true)),
            ]),
            const SizedBox(height: 24),
            Text('Nutrition per serving', style: context.text.titleMedium),
            const SizedBox(height: 12),
            numField(_kcal, 'Calories (kcal)', req: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: numField(_protein, 'Protein g', dot: kProteinColor)),
              const SizedBox(width: 8),
              Expanded(child: numField(_carbs, 'Carbs g', dot: kCarbsColor)),
              const SizedBox(width: 8),
              Expanded(child: numField(_fat, 'Fat g', dot: kFatColor)),
            ]),
            const SizedBox(height: 32),
            FilledButton(onPressed: _save, child: const Text('Save food')),
          ],
        ),
      ),
    );
  }
}
