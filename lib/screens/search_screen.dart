import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/food_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/recipe_card.dart';
import 'meal_db_screen.dart';
import 'recipe_screen.dart';

/// Recipe search — by name (with voice) or by the ingredients you have.
class RecipeSearchScreen extends StatefulWidget {
  final bool autoVoice;
  final String? category;
  final bool byIngredients;
  const RecipeSearchScreen({super.key, this.autoVoice = false, this.category, this.byIngredients = false});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final _ctrl = TextEditingController();
  final _speech = SpeechToText();
  Timer? _debounce;
  late bool _byIngredients = widget.byIngredients;
  final Set<String> _ingredients = {};
  bool _listening = false;
  bool _loading = false;
  List<Recipe> _local = recipes;
  List<MealDbRecipe> _meals = [];
  int _searchId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) _loadCategory(widget.category!);
    if (widget.autoVoice) WidgetsBinding.instance.addPostFrameCallback((_) => _toggleListening());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    if (_listening) _speech.stop();
    super.dispose();
  }

  Future<void> _loadCategory(String category) async {
    setState(() => _loading = true);
    final api = FoodApiService();
    final meals = category == 'Filipino' ? await api.getFilipino() : await api.getByCategory(category);
    if (!mounted) return;
    setState(() {
      _local = category == 'Filipino' ? recipes : [];
      _meals = meals;
      _loading = false;
    });
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(v));
  }

  Future<void> _search(String q) async {
    final query = q.trim().toLowerCase();
    final id = ++_searchId;
    if (query.isEmpty) {
      setState(() {
        _local = recipes;
        _meals = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _local = recipes
          .where((r) => r.name.toLowerCase().contains(query) || r.tags.any((t) => t.toLowerCase().contains(query)))
          .toList();
      _loading = true;
    });
    final meals = await FoodApiService().searchMeals(q.trim());
    if (!mounted || id != _searchId) return;
    setState(() {
      _meals = meals;
      _loading = false;
    });
  }

  Future<void> _searchByIngredients() async {
    final id = ++_searchId;
    if (_ingredients.isEmpty) {
      setState(() {
        _local = recipes;
        _meals = [];
      });
      return;
    }
    final wanted = _ingredients.map((i) => i.toLowerCase()).toList();
    setState(() {
      _local = recipes
          .where((r) => wanted.every((w) =>
              r.tags.any((t) => t.toLowerCase().contains(w)) || r.ingredients.any((t) => t.toLowerCase().contains(w))))
          .toList();
      _loading = true;
    });
    // TheMealDB's free API filters by one ingredient; intersect the results.
    final api = FoodApiService();
    final lists = await Future.wait(_ingredients.take(3).map(api.getByIngredient));
    if (!mounted || id != _searchId) return;
    var meals = lists.first;
    for (final l in lists.skip(1)) {
      final ids = l.map((m) => m.id).toSet();
      meals = meals.where((m) => ids.contains(m.id)).toList();
    }
    setState(() {
      _meals = meals;
      _loading = false;
    });
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!available) {
      showSnack(context, 'Voice search needs microphone & speech permission', icon: Icons.mic_off_rounded);
      return;
    }
    setState(() {
      _listening = true;
      _byIngredients = false;
    });
    await _speech.listen(
      onResult: (r) {
        _ctrl.text = r.recognizedWords;
        if (r.finalResult) {
          _search(r.recognizedWords);
          setState(() => _listening = false);
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(widget.category ?? 'Find recipes')),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('By name'), icon: Icon(Icons.search_rounded)),
                  ButtonSegment(value: true, label: Text('What I have'), icon: Icon(Icons.kitchen_rounded)),
                ],
                selected: {_byIngredients},
                onSelectionChanged: (s) {
                  setState(() => _byIngredients = s.first);
                  _byIngredients ? _searchByIngredients() : _search(_ctrl.text);
                },
              ),
              const SizedBox(height: 12),
              if (!_byIngredients)
                TextField(
                  controller: _ctrl,
                  autofocus: !widget.autoVoice && widget.category == null,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: _listening ? 'Listening…' : 'Adobo, sinigang, salad…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _listening ? kDanger : kPrimary),
                      onPressed: _toggleListening,
                    ),
                  ),
                )
              else
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tap what you have at home', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final i in allIngredients)
                      FilterChip(
                        label: Text(i),
                        selected: _ingredients.contains(i),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                            color: _ingredients.contains(i) ? Colors.white : c.text, fontWeight: FontWeight.w600),
                        onSelected: (v) {
                          setState(() => v ? _ingredients.add(i) : _ingredients.remove(i));
                          _searchByIngredients();
                        },
                      ),
                  ]),
                ]),
            ]),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
        if (_local.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('GrubOut recipes · with nutrition')),
          _grid([
            for (final r in _local)
              RecipeCard(
                title: r.name,
                imageUrl: r.imageUrl,
                emoji: r.emoji,
                subtitle: '${r.caloriesPerServing} kcal / serving',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeScreen(recipe: r))),
              ),
          ]),
        ],
        if (_meals.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('From the recipe library')),
          _grid([
            for (final m in _meals)
              RecipeCard(
                title: m.name,
                imageUrl: m.imageUrl,
                subtitle: m.area ?? m.category,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDbScreen(meal: m))),
              ),
          ]),
        ],
        if (!_loading && _local.isEmpty && _meals.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No recipes found',
              message: 'Try a different name or fewer ingredients.',
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }

  Widget _grid(List<Widget> children) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
          children: children,
        ),
      );
}
