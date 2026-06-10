import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../theme.dart';

class AddMealScreen extends StatefulWidget {
  final Meal? existingMeal;
  const AddMealScreen({super.key, this.existingMeal});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _nameController = TextEditingController();
  final _ingredientSearchController = TextEditingController();
  final List<_EditableIngredient> _ingredients = [];
  final Set<String> _tags = {};
  bool _isFavorite = false;
  String _ingredientQuery = '';

  final _allTags = ['breakfast', 'lunch', 'dinner', 'snack'];

  bool get _isEditing => widget.existingMeal != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMeal;
    if (m != null) {
      _nameController.text = m.name;
      _isFavorite = m.isFavorite;
      _tags.addAll(m.tags);
      _ingredients.addAll(m.ingredients.map((i) => _EditableIngredient(
            food: i.food,
            servingsController:
                TextEditingController(text: i.servings.toString()),
          )));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientSearchController.dispose();
    for (final i in _ingredients) {
      i.servingsController.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a meal name')),
      );
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient')),
      );
      return;
    }
    final provider = context.read<AppProvider>();
    final meal = Meal(
      id: widget.existingMeal?.id ?? provider.generateId(),
      name: _nameController.text.trim(),
      ingredients: _ingredients
          .map((i) => MealIngredient(
                food: i.food,
                servings: double.tryParse(i.servingsController.text) ?? 1.0,
              ))
          .toList(),
      tags: _tags.toList(),
      isFavorite: _isFavorite,
    );
    if (_isEditing) {
      provider.updateMeal(meal);
    } else {
      provider.addMeal(meal);
    }
    Navigator.pop(context);
  }

  double get _totalCalories => _ingredients.fold(0, (s, i) {
        final servings = double.tryParse(i.servingsController.text) ?? 1.0;
        return s + i.food.calories * servings;
      });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final searchResults = _ingredientQuery.isEmpty
        ? provider.foodLibrary
        : provider.searchFoods(_ingredientQuery);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit meal' : 'New meal'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Meal name'),
          ),

          const SizedBox(height: 20),

          // Favourite + tags row
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _isFavorite = !_isFavorite),
              child: Row(children: [
                Icon(
                  _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _isFavorite
                      ? const Color(0xFFE9C46A)
                      : AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text('Favourite',
                    style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ]),

          const SizedBox(height: 14),

          // Tags
          Text('Appears in',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _allTags.map((tag) {
              final selected = _tags.contains(tag);
              return FilterChip(
                label: Text(tag[0].toUpperCase() + tag.substring(1)),
                selected: selected,
                onSelected: (_) => setState(() =>
                    selected ? _tags.remove(tag) : _tags.add(tag)),
                selectedColor: AppTheme.primarySurface,
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color:
                      selected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                    color:
                        selected ? AppTheme.primary : AppTheme.border),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Current ingredients
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Ingredients',
                style: Theme.of(context).textTheme.titleMedium),
            if (_ingredients.isNotEmpty)
              Text(
                '${_totalCalories.toStringAsFixed(0)} kcal total',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
          ]),
          const SizedBox(height: 10),

          if (_ingredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Search below to add ingredients.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),

          ..._ingredients.asMap().entries.map((entry) {
            final i = entry.key;
            final ing = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ing.food.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            '${ing.food.calories.toStringAsFixed(0)} kcal / ${ing.food.servingSize.toStringAsFixed(0)}${ing.food.servingUnit}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ]),
                  ),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: ing.servingsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        suffixText: '×',
                        suffixStyle: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _ingredients.removeAt(i)),
                    color: AppTheme.textSecondary,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Ingredient search
          Text('Add ingredient',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _ingredientSearchController,
            onChanged: (v) => setState(() => _ingredientQuery = v),
            decoration: const InputDecoration(
              hintText: 'Search ingredients...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 8),

          if (provider.foodLibrary.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No ingredients in your library yet. Add them first in the Ingredients tab.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else if (searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No results for "$_ingredientQuery"',
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            ...searchResults.map((food) {
              final alreadyAdded =
                  _ingredients.any((i) => i.food.id == food.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: alreadyAdded
                      ? null
                      : () => setState(() {
                            _ingredients.add(_EditableIngredient(
                              food: food,
                              servingsController:
                                  TextEditingController(text: '1'),
                            ));
                            _ingredientSearchController.clear();
                            _ingredientQuery = '';
                          }),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: alreadyAdded
                          ? AppTheme.primarySurface
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: alreadyAdded
                              ? AppTheme.primary.withOpacity(0.3)
                              : AppTheme.border),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(food.name,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ),
                      Text(
                        '${food.calories.toStringAsFixed(0)} kcal',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        alreadyAdded
                            ? Icons.check_circle_outline
                            : Icons.add_circle_outline,
                        color: alreadyAdded
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ]),
                  ),
                ),
              );
            }),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            child: Text(_isEditing ? 'Update meal' : 'Save meal'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _EditableIngredient {
  final FoodItem food;
  final TextEditingController servingsController;
  _EditableIngredient({required this.food, required this.servingsController});
}
