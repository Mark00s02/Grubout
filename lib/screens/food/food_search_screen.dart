import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/filipino_calories.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/food_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'barcode_scanner_screen.dart';
import 'create_food_screen.dart';
import 'food_detail_sheet.dart';

/// Full-screen food search. Stays open after adding so several foods can be
/// logged in a row (like MyFitnessPal's multi-add).
class FoodSearchScreen extends StatefulWidget {
  final String mealType;
  const FoodSearchScreen({super.key, required this.mealType});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> with SingleTickerProviderStateMixin {
  late String _meal = widget.mealType;
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _searching = false;
  List<FoodSearchResult> _apiResults = [];
  int _added = 0;
  int _searchId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _query = v.trim());
    _debounce?.cancel();
    if (_query.length < 2) {
      setState(() {
        _apiResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _searchApi(_query));
  }

  Future<void> _searchApi(String q) async {
    final id = ++_searchId;
    setState(() => _searching = true);
    final results = await FoodApiService().searchAll(q);
    if (!mounted || id != _searchId) return;
    setState(() {
      _apiResults = results;
      _searching = false;
    });
  }

  Future<void> _open(FoodSearchResult food) async {
    final added = await showFoodDetailSheet(context, food: food, mealType: _meal);
    if (added == true && mounted) setState(() => _added++);
  }

  Future<void> _scan() async {
    final added = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => BarcodeScannerScreen(mealType: _meal)));
    if (added == true && mounted) setState(() => _added++);
  }

  Future<void> _quickAdd() async {
    final added = await showQuickAddSheet(context, mealType: _meal);
    if (added == true && mounted) setState(() => _added++);
  }

  Future<void> _createFood() async {
    final food = await Navigator.push<FoodSearchResult>(
        context, MaterialPageRoute(builder: (_) => CreateFoodScreen(initialName: _query)));
    if (food != null && mounted) {
      _tabs.animateTo(1);
      _open(food);
    }
  }

  void _pickMeal() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final m in mealTypes)
            ListTile(
              leading: Icon(mealTypeIcon(m), color: mealTypeColor(m)),
              title: Text(mealTypeLabel(m), style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: m == _meal ? const Icon(Icons.check_rounded, color: kPrimary) : null,
              onTap: () => Navigator.pop(ctx, m),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null) setState(() => _meal = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _pickMeal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(mealTypeIcon(_meal), color: mealTypeColor(_meal), size: 22),
              const SizedBox(width: 8),
              Text(mealTypeLabel(_meal)),
              const Icon(Icons.expand_more_rounded),
            ]),
          ),
        ),
        actions: [
          if (_added > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                child: Text('Done · $_added'),
              ),
            ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search foods, brands, dishes…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onChanged('');
                      })
                  : IconButton(
                      tooltip: 'Scan barcode',
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: kPrimary),
                      onPressed: _scan,
                    ),
            ),
          ),
        ),
        if (_query.isEmpty) ...[
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _ActionChip(Icons.qr_code_scanner_rounded, 'Scan barcode', _scan),
                _ActionChip(Icons.bolt_rounded, 'Quick add', _quickAdd),
                _ActionChip(Icons.add_circle_outline_rounded, 'Create food', _createFood),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(controller: _tabs, tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'My foods'),
            Tab(text: 'Filipino'),
          ]),
          Expanded(
            child: TabBarView(controller: _tabs, children: [
              _recentTab(),
              _customTab(),
              _FoodList(foods: filipinoFoods, onTap: _open),
            ]),
          ),
        ] else
          Expanded(child: _searchResults(c)),
      ]),
    );
  }

  Widget _recentTab() {
    final recent = context.watch<AppProvider>().recentFoods;
    if (recent.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No recent foods yet',
        message: 'Foods you log show up here so you can add them again with one tap.',
      );
    }
    return _FoodList(foods: recent.map((l) => l.toFood()).toList(), onTap: _open);
  }

  Widget _customTab() {
    final provider = context.watch<AppProvider>();
    final foods = provider.customFoods;
    if (foods.isEmpty) {
      return EmptyState(
        icon: Icons.edit_note_rounded,
        title: 'Create your own foods',
        message: 'Add family recipes or foods with a nutrition label to reuse them any time.',
        action: FilledButton.icon(
          onPressed: _createFood,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create food'),
        ),
      );
    }
    return _FoodList(
      foods: foods,
      onTap: _open,
      onDelete: (f) => provider.deleteCustomFood(f.id),
    );
  }

  Widget _searchResults(AppColors c) {
    final provider = context.watch<AppProvider>();
    final q = _query.toLowerCase();
    bool match(FoodSearchResult f) =>
        f.name.toLowerCase().contains(q) || (f.brand?.toLowerCase().contains(q) ?? false);
    final local = [
      ...provider.customFoods.where(match),
      ...provider.recentFoods.map((l) => l.toFood()).where(match),
      ...searchFilipino(_query),
    ];
    final seen = <String>{};
    final mine = local.where((f) => seen.add(f.name.toLowerCase())).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        if (mine.isNotEmpty) ...[
          const _ListLabel('Your foods & Filipino favourites'),
          for (final f in mine) _FoodTile(food: f, onTap: () => _open(f)),
        ],
        _ListLabel('Food database', trailing: _searching
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : null),
        if (!_searching && _apiResults.isEmpty && _query.length >= 2)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text("Can't find it?", style: context.text.titleMedium),
              const SizedBox(height: 6),
              Text('Check your connection, or add it yourself.',
                  style: TextStyle(color: c.textMuted)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                OutlinedButton(onPressed: _quickAdd, child: const Text('Quick add')),
                OutlinedButton(onPressed: _createFood, child: const Text('Create food')),
              ]),
            ]),
          ),
        for (final f in _apiResults) _FoodTile(food: f, onTap: () => _open(f)),
        if (_apiResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Data from USDA FoodData Central and Open Food Facts',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: c.textMuted)),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: Icon(icon, size: 18, color: kPrimary),
          label: Text(label),
          onPressed: onTap,
        ),
      );
}

class _ListLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _ListLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: Row(children: [
          Expanded(
            child: Text(text.toUpperCase(),
                style: TextStyle(
                    fontSize: 12, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: context.colors.textMuted)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class _FoodList extends StatelessWidget {
  final List<FoodSearchResult> foods;
  final ValueChanged<FoodSearchResult> onTap;
  final ValueChanged<FoodSearchResult>? onDelete;
  const _FoodList({required this.foods, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 40),
        itemCount: foods.length,
        itemBuilder: (_, i) {
          final f = foods[i];
          final tile = _FoodTile(food: f, onTap: () => onTap(f));
          if (onDelete == null) return tile;
          return Dismissible(
            key: ValueKey(f.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: kDanger,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            onDismissed: (_) => onDelete!(f),
            child: tile,
          );
        },
      );
}

class _FoodTile extends StatelessWidget {
  final FoodSearchResult food;
  final VoidCallback onTap;
  const _FoodTile({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final verified = food.source == FoodSource.local || food.source == FoodSource.usda;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(children: [
        Flexible(
          child: Text(food.name,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        if (food.isLocal) const Padding(padding: EdgeInsets.only(left: 6), child: Text('🇵🇭', style: TextStyle(fontSize: 13))),
        if (verified && !food.isLocal)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.verified_rounded, size: 15, color: kPrimary),
          ),
      ]),
      subtitle: Text(food.subtitle, style: TextStyle(color: c.textMuted, fontSize: 13)),
      trailing: Container(
        decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.add_rounded, color: kPrimary, size: 20),
        ),
      ),
    );
  }
}
