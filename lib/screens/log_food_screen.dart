import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/log_entry.dart';
import '../theme.dart';

class LogFoodScreen extends StatefulWidget {
  final String defaultMeal;
  /// When set, the screen acts as a substitution picker for this log entry.
  final LogEntry? substituteEntry;

  const LogFoodScreen({
    super.key,
    required this.defaultMeal,
    this.substituteEntry,
  });

  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedSlot = 'Snack';

  final _slots = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  bool get _isSubstitution => widget.substituteEntry != null;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.defaultMeal;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _query = ''));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSubstitution
            ? 'Substitute "${widget.substituteEntry!.food.name}"'
            : 'Log food'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Meals'), Tab(text: 'Ingredients')],
        ),
      ),
      body: Column(children: [
        // Substitution banner
        if (_isSubstitution)
          Container(
            width: double.infinity,
            color: AppTheme.primarySurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.swap_horiz, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pick a replacement for "${widget.substituteEntry!.food.name}"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                      ),
                ),
              ),
            ]),
          ),

        // Meal slot selector (hidden in substitution mode — slot stays the same)
        if (!_isSubstitution)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _slots.map((slot) {
                  final selected = _selectedSlot == slot;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(slot),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                      selectedColor: AppTheme.primarySurface,
                      checkmarkColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(
                          color: selected ? AppTheme.primary : AppTheme.border),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Search
        Padding(
          padding: EdgeInsets.fromLTRB(16, _isSubstitution ? 12 : 12, 16, 8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MealsTab(
                  query: _query,
                  slot: _selectedSlot,
                  substituteEntry: widget.substituteEntry,
                  onLogged: () => Navigator.pop(context)),
              _IngredientsTab(
                  query: _query,
                  slot: _selectedSlot,
                  substituteEntry: widget.substituteEntry,
                  onLogged: () => Navigator.pop(context)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Meals tab ────────────────────────────────────────────────────────────────

class _MealsTab extends StatelessWidget {
  final String query;
  final String slot;
  final LogEntry? substituteEntry;
  final VoidCallback onLogged;
  const _MealsTab({
    required this.query,
    required this.slot,
    required this.onLogged,
    this.substituteEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      List<Meal> meals;
      if (query.isEmpty) {
        meals = provider.mealsForTag(slot.toLowerCase());
      } else {
        meals = provider.searchMeals(query);
      }

      if (meals.isEmpty) {
        return _empty(context,
            query.isEmpty
                ? 'No meals tagged for $slot'
                : 'No meals match "$query"',
            query.isEmpty
                ? 'Create meals in My Foods and tag them as ${slot.toLowerCase()} to see them here. Untagged meals always appear.'
                : '');
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: meals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _MealLogCard(
          meal: meals[i],
          onTap: () => _confirmLog(context, provider, meals[i]),
        ),
      );
    });
  }

  void _confirmLog(BuildContext context, AppProvider provider, Meal meal) {
    // In substitution mode, log each ingredient as a substitute for the original entry.
    // We log only the first ingredient as the replacement (or let user pick).
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(meal.name, style: Theme.of(context).textTheme.titleLarge)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          Text(
            '${meal.totalCalories.toStringAsFixed(0)} kcal · ${meal.ingredients.length} ingredient${meal.ingredients.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...meal.ingredients.map((ing) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Expanded(child: Text(ing.food.name, style: Theme.of(context).textTheme.bodyLarge)),
              Text('${ing.servings}× ${ing.food.servingSize.toStringAsFixed(0)}${ing.food.servingUnit}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (substituteEntry != null && meal.ingredients.isNotEmpty) {
                  final ing = meal.ingredients.first;
                  provider.substituteLogEntry(
                    entryId: substituteEntry!.id,
                    newFood: ing.food,
                    newServings: ing.servings,
                  );
                } else {
                  provider.logMeal(meal: meal, mealSlot: slot.toLowerCase());
                }
                Navigator.pop(ctx);
                onLogged();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(substituteEntry != null
                      ? '${meal.name} substituted'
                      : '${meal.name} logged to $slot'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.primary,
                ));
              },
              child: Text(substituteEntry != null ? 'Use as substitute' : 'Log to $slot'),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Ingredients tab ──────────────────────────────────────────────────────────

class _IngredientsTab extends StatelessWidget {
  final String query;
  final String slot;
  final LogEntry? substituteEntry;
  final VoidCallback onLogged;
  const _IngredientsTab({
    required this.query,
    required this.slot,
    required this.onLogged,
    this.substituteEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final foods = provider.searchFoods(query);
      if (foods.isEmpty) {
        return _empty(context,
            query.isEmpty ? 'No ingredients yet' : 'No results for "$query"',
            query.isEmpty ? 'Add ingredients in the My Foods tab.' : '');
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: foods.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _FoodLogCard(
          food: foods[i],
          onTap: () => _showServingDialog(context, provider, foods[i]),
        ),
      );
    });
  }

  void _showServingDialog(
      BuildContext context, AppProvider provider, FoodItem food) {
    final ctrl = TextEditingController(
        text: substituteEntry != null
            ? substituteEntry!.servings.toString()
            : '1');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(food.name, style: Theme.of(context).textTheme.titleLarge)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          if (substituteEntry != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.swap_horiz, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Replacing: ${substituteEntry!.food.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primary),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          Text('${food.calories.toStringAsFixed(0)} kcal / ${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Servings',
              suffixText: '× ${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final s = double.tryParse(ctrl.text);
                if (s != null && s > 0) {
                  if (substituteEntry != null) {
                    provider.substituteLogEntry(
                      entryId: substituteEntry!.id,
                      newFood: food,
                      newServings: s,
                    );
                    Navigator.pop(ctx);
                    onLogged();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Substituted with ${food.name}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primary,
                    ));
                  } else {
                    provider.logFood(food: food, servings: s, meal: slot.toLowerCase());
                    Navigator.pop(ctx);
                    onLogged();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${food.name} logged to $slot'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primary,
                    ));
                  }
                }
              },
              child: Text(substituteEntry != null ? 'Substitute' : 'Add to $slot'),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Cards ────────────────────────────────────────────────────────────────────

class _MealLogCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  const _MealLogCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10)),
              child: meal.isFavorite
                  ? const Icon(Icons.star_rounded,
                      color: Color(0xFFE9C46A), size: 20)
                  : const Icon(Icons.restaurant_outlined,
                      color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal.name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${meal.totalCalories.toStringAsFixed(0)} kcal · ${meal.ingredients.length} item${meal.ingredients.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ]),
            ),
            const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 24),
          ]),
        ),
      ),
    );
  }
}

class _FoodLogCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;
  const _FoodLogCard({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                food.isSpice ? Icons.spa_outlined : Icons.egg_alt_outlined,
                color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(food.name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${food.calories.toStringAsFixed(0)} kcal / ${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ]),
            ),
            const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 24),
          ]),
        ),
      ),
    );
  }
}

Widget _empty(BuildContext context, String title, String sub) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_outlined,
            size: 48, color: AppTheme.textSecondary.withOpacity(0.35)),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(sub,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ]),
    ),
  );
}