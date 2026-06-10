import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../theme.dart';
import 'add_food_screen.dart';
import 'add_meal_screen.dart';

class FoodLibraryScreen extends StatefulWidget {
  const FoodLibraryScreen({super.key});

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
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
        title: const Text('My foods'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Ingredients'),
            Tab(text: 'Meals'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
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
                _IngredientsTab(query: _query),
                _MealsTab(query: _query),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabController.index == 0
            ? _openAddFood(context)
            : _openAddMeal(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'New ingredient' : 'New meal'),
      ),
    );
  }

  void _openAddFood(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddFoodScreen()));
  }

  void _openAddMeal(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddMealScreen()));
  }
}

// ── Ingredients tab ──────────────────────────────────────────────────────────

class _IngredientsTab extends StatelessWidget {
  final String query;
  const _IngredientsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final foods = provider.searchFoods(query);
        if (foods.isEmpty) {
          return _emptyState(
            context,
            query.isEmpty ? 'No ingredients yet' : 'No results for "$query"',
            query.isEmpty
                ? 'Add your ingredients — chicken breast, rice, oats — and use them to build meals.'
                : 'Try a different search.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: foods.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _FoodCard(
            food: foods[i],
            onEdit: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => AddFoodScreen(existingFood: foods[i]))),
            onDelete: () => _confirmDelete(context, provider, foods[i]),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, FoodItem food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove ingredient?'),
        content: Text('Remove "${food.name}" from your library?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { provider.deleteFoodItem(food.id); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Meals tab ────────────────────────────────────────────────────────────────

class _MealsTab extends StatelessWidget {
  final String query;
  const _MealsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final meals = provider.searchMeals(query);
        if (meals.isEmpty) {
          return _emptyState(
            context,
            query.isEmpty ? 'No meals yet' : 'No results for "$query"',
            query.isEmpty
                ? 'Create meals from your ingredients. Star favourites so they appear first when logging.'
                : 'Try a different search.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: meals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _MealCard(
            meal: meals[i],
            onEdit: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => AddMealScreen(existingMeal: meals[i]))),
            onDelete: () => _confirmDeleteMeal(context, provider, meals[i]),
            onToggleFav: () => provider.toggleFavorite(meals[i].id),
          ),
        );
      },
    );
  }

  void _confirmDeleteMeal(BuildContext context, AppProvider provider, Meal meal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('Delete "${meal.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { provider.deleteMeal(meal.id); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

Widget _emptyState(BuildContext context, String title, String subtitle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_outlined,
              size: 52, color: AppTheme.textSecondary.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// ── Food card ────────────────────────────────────────────────────────────────

class _FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _FoodCard({required this.food, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
            _MacroPill('P ${food.protein.toStringAsFixed(0)}g', AppTheme.proteinColor),
            const SizedBox(width: 4),
            _MacroPill('C ${food.carbs.toStringAsFixed(0)}g', AppTheme.carbsColor),
            const SizedBox(width: 4),
            _MacroPill('F ${food.fat.toStringAsFixed(0)}g', AppTheme.fatColor),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal card ────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFav;
  const _MealCard(
      {required this.meal,
      required this.onEdit,
      required this.onDelete,
      required this.onToggleFav});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(meal.name, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              icon: Icon(
                meal.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: meal.isFavorite ? const Color(0xFFE9C46A) : AppTheme.textSecondary,
              ),
              onPressed: onToggleFav,
              tooltip: meal.isFavorite ? 'Unfavourite' : 'Favourite',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            ),
          ]),
          Text(
            '${meal.totalCalories.toStringAsFixed(0)} kcal · ${meal.ingredients.length} ingredient${meal.ingredients.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (meal.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: meal.tags.map((t) => _TagChip(t)).toList()),
          ],
        ]),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip(this.tag);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(tag[0].toUpperCase() + tag.substring(1),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary)),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroPill(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85))),
    );
  }
}