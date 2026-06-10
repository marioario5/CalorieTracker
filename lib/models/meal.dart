import 'food_item.dart';

class MealIngredient {
  final FoodItem food;
  final double servings;

  MealIngredient({required this.food, required this.servings});

  double get calories => food.calories * servings;
  double get protein => food.protein * servings;
  double get carbs => food.carbs * servings;
  double get fat => food.fat * servings;

  Map<String, dynamic> toJson() => {
        'food': food.toJson(),
        'servings': servings,
      };

  factory MealIngredient.fromJson(Map<String, dynamic> json) => MealIngredient(
        food: FoodItem.fromJson(json['food']),
        servings: (json['servings'] as num).toDouble(),
      );
}

class Meal {
  final String id;
  final String name;
  final List<MealIngredient> ingredients;
  final List<String> tags; // 'breakfast', 'lunch', 'dinner', 'snack'
  final bool isFavorite;

  Meal({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.tags,
    this.isFavorite = false,
  });

  double get totalCalories =>
      ingredients.fold(0, (s, i) => s + i.calories);
  double get totalProtein =>
      ingredients.fold(0, (s, i) => s + i.protein);
  double get totalCarbs =>
      ingredients.fold(0, (s, i) => s + i.carbs);
  double get totalFat =>
      ingredients.fold(0, (s, i) => s + i.fat);

  Meal copyWith({
    String? id,
    String? name,
    List<MealIngredient>? ingredients,
    List<String>? tags,
    bool? isFavorite,
  }) =>
      Meal(
        id: id ?? this.id,
        name: name ?? this.name,
        ingredients: ingredients ?? this.ingredients,
        tags: tags ?? this.tags,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'tags': tags,
        'isFavorite': isFavorite,
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'],
        name: json['name'],
        ingredients: (json['ingredients'] as List)
            .map((i) => MealIngredient.fromJson(i))
            .toList(),
        tags: List<String>.from(json['tags'] ?? []),
        isFavorite: json['isFavorite'] ?? false,
      );
}
