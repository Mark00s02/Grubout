import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/exercise/add_exercise_screen.dart';
import '../screens/fasting/fasting_screen.dart';
import '../screens/food/barcode_scanner_screen.dart';
import '../screens/food/food_search_screen.dart';
import '../screens/progress/weight_sheet.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Meal that best matches the current time of day.
String defaultMealForNow() {
  final h = DateTime.now().hour;
  if (h < 11) return 'breakfast';
  if (h < 15) return 'lunch';
  if (h < 17) return 'snacks';
  if (h < 22) return 'dinner';
  return 'snacks';
}

void showQuickLogSheet(BuildContext context) {
  final provider = context.read<AppProvider>();
  // Quick logging always targets today.
  if (!provider.isToday) provider.selectDate(DateTime.now());

  showModalBottomSheet(
    context: context,
    builder: (sheetCtx) {
      void go(Widget page) {
        Navigator.pop(sheetCtx);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Quick log', style: context.text.titleLarge),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _Action(Icons.restaurant_rounded, 'Log food', kPrimary,
                    () => go(FoodSearchScreen(mealType: defaultMealForNow()))),
                _Action(Icons.qr_code_scanner_rounded, 'Scan barcode', kProteinColor,
                    () => go(BarcodeScannerScreen(mealType: defaultMealForNow()))),
                _Action(Icons.directions_run_rounded, 'Exercise', kCarbsColor,
                    () => go(const AddExerciseScreen())),
                _Action(Icons.water_drop_rounded, '+250 ml water', kWaterColor, () {
                  Navigator.pop(sheetCtx);
                  provider.addWater(250);
                  showSnack(context, 'Added a glass of water 💧');
                }),
                _Action(Icons.monitor_weight_rounded, 'Weight', kFatColor, () {
                  Navigator.pop(sheetCtx);
                  showWeightSheet(context);
                }),
                _Action(Icons.timer_rounded, 'Fasting', kDinnerColor, () => go(const FastingScreen())),
              ],
            ),
          ]),
        ),
      );
    },
  );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
