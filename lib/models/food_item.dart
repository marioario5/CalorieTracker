import 'dart:convert';

class FoodItem {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final Map<String, double> micros; // e.g. {'iron': 2.5, 'vitamin_c': 30.0}
  final bool isSpice; // spices/seasonings: macros negligible, used for flavour tracking

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
    this.micros = const {},
    this.isSpice = false,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? servingSize,
    String? servingUnit,
    Map<String, double>? micros,
    bool? isSpice,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      micros: micros ?? this.micros,
      isSpice: isSpice ?? this.isSpice,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'servingSize': servingSize,
        'servingUnit': servingUnit,
        'micros': micros,
        'isSpice': isSpice,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'],
        name: json['name'],
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        servingSize: (json['servingSize'] as num).toDouble(),
        servingUnit: json['servingUnit'],
        micros: json['micros'] != null
            ? Map<String, double>.from(
                (json['micros'] as Map).map(
                  (k, v) => MapEntry(k as String, (v as num).toDouble()),
                ),
              )
            : {},
        isSpice: json['isSpice'] ?? false,
      );

  String toJsonString() => jsonEncode(toJson());
  factory FoodItem.fromJsonString(String source) =>
      FoodItem.fromJson(jsonDecode(source));
}