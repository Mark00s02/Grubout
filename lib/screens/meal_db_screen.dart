import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/food_api_service.dart';

class MealDbScreen extends StatefulWidget {
  final MealDbRecipe meal;
  const MealDbScreen({super.key, required this.meal});

  @override
  State<MealDbScreen> createState() => _MealDbScreenState();
}

class _MealDbScreenState extends State<MealDbScreen> {
  MealDbRecipe? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await FoodApiService().getMealDetail(widget.meal.id);
    if (mounted) {
      setState(() {
        _detail = detail ?? widget.meal;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = _detail ?? widget.meal;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: kPrimary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white,
                      size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: meal.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: meal.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: kPrimary),
                      errorWidget: (_, __, ___) => Container(
                          color: kPrimary,
                          child: const Center(
                              child: Text('🍽️',
                                  style: TextStyle(fontSize: 80)))),
                    )
                  : Container(
                      color: kPrimary,
                      child: const Center(
                          child: Text('🍽️',
                              style: TextStyle(fontSize: 80)))),
            ),
          ),

          SliverToBoxAdapter(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: kPrimary),
                    ),
                  )
                : _Body(meal: meal),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final MealDbRecipe meal;
  const _Body({required this.meal});

  @override
  Widget build(BuildContext context) {
    final ingredients = meal.ingredientLines;
    final steps = meal.instructionSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + tags ────────────────────────────────────────────────
          Text(meal.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: [
              if (meal.category != null)
                _Tag(meal.category!,
                    color: kPrimary.withValues(alpha: 0.12),
                    textColor: kPrimary),
              if (meal.area != null)
                _Tag(meal.area!,
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    textColor: const Color(0xFF1565C0)),
            ],
          ),

          const SizedBox(height: 24),

          // ── Ingredients ─────────────────────────────────────────────────
          if (ingredients.isNotEmpty) ...[
            const _SectionTitle('Ingredients'),
            const SizedBox(height: 10),
            ...ingredients.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        decoration: const BoxDecoration(
                            color: kPrimary, shape: BoxShape.circle),
                      ),
                      Expanded(
                          child: Text(line,
                              style: const TextStyle(
                                  fontSize: 14, color: kDark, height: 1.4))),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // ── Instructions ─────────────────────────────────────────────────
          if (steps.isNotEmpty) ...[
            const _SectionTitle('Instructions'),
            const SizedBox(height: 10),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26, height: 26,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                fontSize: 14,
                                color: kDark,
                                height: 1.5)),
                      ),
                    ],
                  ),
                )),
          ] else ...[
            const _SectionTitle('Instructions'),
            const SizedBox(height: 10),
            Text(
              meal.instructions?.trim().isNotEmpty == true
                  ? meal.instructions!
                  : 'No instructions available for this recipe.',
              style: const TextStyle(
                  fontSize: 14, color: kDark, height: 1.6),
            ),
          ],

          // ── YouTube hint ──────────────────────────────────────────────
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.play_circle_outline,
                  color: Color(0xFFCC0000), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Video Tutorial',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kDark)),
                    Text('Search this recipe on YouTube for a visual guide',
                        style: TextStyle(fontSize: 12, color: kGrey)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: kDark));
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Tag(this.label, {required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor)),
      );
}
