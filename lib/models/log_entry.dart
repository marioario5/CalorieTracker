import 'food_item.dart';

class LogEntry {
  final String id;
  final FoodItem food;
  final double servings;
  final DateTime loggedAt;
  final String meal;
  final String? sourceMealName;

  LogEntry({
    required this.id,
    required this.food,
    required this.servings,
    required this.loggedAt,
    required this.meal,
    this.sourceMealName,
  });

  double get totalCalories => food.calories * servings;
  double get totalProtein => food.protein * servings;
  double get totalCarbs => food.carbs * servings;
  double get totalFat => food.fat * servings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'food': food.toJson(),
        'servings': servings,
        'loggedAt': loggedAt.toIso8601String(),
        'meal': meal,
        'sourceMealName': sourceMealName,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'],
        food: FoodItem.fromJson(json['food']),
        servings: (json['servings'] as num).toDouble(),
        loggedAt: DateTime.parse(json['loggedAt']),
        meal: json['meal'],
        sourceMealName: json['sourceMealName'],
      );
}