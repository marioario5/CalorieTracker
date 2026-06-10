class NutritionGoal {
  final String id;
  final String name;
  final String unit;
  final double target;
  final bool isDefault; // can't be deleted

  NutritionGoal({
    required this.id,
    required this.name,
    required this.unit,
    required this.target,
    this.isDefault = false,
  });

  NutritionGoal copyWith({
    String? name,
    String? unit,
    double? target,
  }) =>
      NutritionGoal(
        id: id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        target: target ?? this.target,
        isDefault: isDefault,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'target': target,
        'isDefault': isDefault,
      };

  factory NutritionGoal.fromJson(Map<String, dynamic> json) => NutritionGoal(
        id: json['id'],
        name: json['name'],
        unit: json['unit'],
        target: (json['target'] as num).toDouble(),
        isDefault: json['isDefault'] ?? false,
      );
}
