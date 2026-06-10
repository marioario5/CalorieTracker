import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/log_entry.dart';
import '../models/nutrition_goals.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<FoodItem> _foodLibrary = [];
  List<Meal> _meals = [];
  List<LogEntry> _todayLog = [];
  double _dailyCalorieGoal = 2000;
  DateTime _selectedDate = DateTime.now();
  List<NutritionGoal> _nutritionGoals = [];

  // Serving size multipliers for macro display (independent from goals)
  // Key: macro id ('protein','carbs','fat'), value: serving multiplier
  Map<String, double> _macroServingSizes = {
    'protein': 1.0,
    'carbs': 1.0,
    'fat': 1.0,
  };

  List<FoodItem> get foodLibrary => _foodLibrary;
  List<Meal> get meals => _meals;
  List<LogEntry> get todayLog => List.unmodifiable(_todayLog);
  double get dailyCalorieGoal => _dailyCalorieGoal;
  DateTime get selectedDate => _selectedDate;
  List<NutritionGoal> get nutritionGoals => _nutritionGoals;
  Map<String, double> get macroServingSizes => Map.unmodifiable(_macroServingSizes);

  double get totalCaloriesToday =>
      _todayLog.fold(0, (sum, e) => sum + e.totalCalories);
  double get totalProteinToday =>
      _todayLog.fold(0, (sum, e) => sum + e.totalProtein);
  double get totalCarbsToday =>
      _todayLog.fold(0, (sum, e) => sum + e.totalCarbs);
  double get totalFatToday =>
      _todayLog.fold(0, (sum, e) => sum + e.totalFat);
  double get remainingCalories => _dailyCalorieGoal - totalCaloriesToday;

  // Goals for each macro (used by MacroBar for progress display)
  double? get proteinGoal {
    try {
      return _nutritionGoals.firstWhere((g) => g.id == 'protein').target;
    } catch (_) { return null; }
  }
  double? get carbsGoal {
    try {
      return _nutritionGoals.firstWhere((g) => g.id == 'carbs').target;
    } catch (_) { return null; }
  }
  double? get fatGoal {
    try {
      return _nutritionGoals.firstWhere((g) => g.id == 'fat').target;
    } catch (_) { return null; }
  }

  List<Meal> get sortedMeals {
    final favs = _meals.where((m) => m.isFavorite).toList();
    final rest = _meals.where((m) => !m.isFavorite).toList();
    return [...favs, ...rest];
  }

  List<Meal> mealsForTag(String tag) {
    final lower = tag.toLowerCase();
    final filtered = _meals
        .where((m) => m.tags.isEmpty || m.tags.contains(lower))
        .toList();
    final favs = filtered.where((m) => m.isFavorite).toList();
    final rest = filtered.where((m) => !m.isFavorite).toList();
    return [...favs, ...rest];
  }

  Map<String, List<LogEntry>> get logByMeal {
    final mealMap = {
      'Breakfast': <LogEntry>[],
      'Lunch': <LogEntry>[],
      'Dinner': <LogEntry>[],
      'Snack': <LogEntry>[],
    };
    for (final entry in _todayLog) {
      final key = entry.meal[0].toUpperCase() + entry.meal.substring(1);
      mealMap[key]?.add(entry);
    }
    return mealMap;
  }

  AppProvider() {
    _loadData();
  }

  static List<NutritionGoal> _defaultGoals() => [
        NutritionGoal(id: 'calories', name: 'Calories', unit: 'kcal', target: 2000, isDefault: true),
        NutritionGoal(id: 'protein', name: 'Protein', unit: 'g', target: 150, isDefault: true),
        NutritionGoal(id: 'carbs', name: 'Carbohydrates', unit: 'g', target: 250, isDefault: true),
        NutritionGoal(id: 'fat', name: 'Fat', unit: 'g', target: 65, isDefault: true),
      ];

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final libraryJson = prefs.getStringList('food_library') ?? [];
    _foodLibrary =
        libraryJson.map((s) => FoodItem.fromJson(jsonDecode(s))).toList();

    final mealsJson = prefs.getStringList('meals') ?? [];
    _meals = mealsJson.map((s) => Meal.fromJson(jsonDecode(s))).toList();

    _dailyCalorieGoal = prefs.getDouble('calorie_goal') ?? 2000;

    final dateKey = _dateKey(_selectedDate);
    final logJson = prefs.getStringList('log_$dateKey') ?? [];
    _todayLog =
        logJson.map((s) => LogEntry.fromJson(jsonDecode(s))).toList();

    final goalsJson = prefs.getStringList('nutrition_goals');
    if (goalsJson != null && goalsJson.isNotEmpty) {
      _nutritionGoals =
          goalsJson.map((s) => NutritionGoal.fromJson(jsonDecode(s))).toList();
      final cal = _nutritionGoals.firstWhere(
          (g) => g.id == 'calories',
          orElse: () => _defaultGoals().first);
      _dailyCalorieGoal = cal.target;
    } else {
      _nutritionGoals = _defaultGoals();
    }

    // Load macro serving sizes
    final servingSizesJson = prefs.getString('macro_serving_sizes');
    if (servingSizesJson != null) {
      final decoded = jsonDecode(servingSizesJson) as Map<String, dynamic>;
      _macroServingSizes = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    notifyListeners();
  }

  Future<void> _saveLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('food_library',
        _foodLibrary.map((f) => jsonEncode(f.toJson())).toList());
  }

  Future<void> _saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'meals', _meals.map((m) => jsonEncode(m.toJson())).toList());
  }

  Future<void> _saveLog() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _dateKey(_selectedDate);
    await prefs.setStringList('log_$dateKey',
        _todayLog.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nutrition_goals',
        _nutritionGoals.map((g) => jsonEncode(g.toJson())).toList());
  }

  Future<void> _saveMacroServingSizes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('macro_serving_sizes', jsonEncode(_macroServingSizes));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ── Food library ────────────────────────────────────────────────────────────

  Future<void> addFoodItem(FoodItem food) async {
    _foodLibrary.add(food);
    await _saveLibrary();
    notifyListeners();
  }

  Future<void> updateFoodItem(FoodItem food) async {
    final index = _foodLibrary.indexWhere((f) => f.id == food.id);
    if (index != -1) {
      _foodLibrary[index] = food;
      await _saveLibrary();
      notifyListeners();
    }
  }

  Future<void> deleteFoodItem(String id) async {
    _foodLibrary.removeWhere((f) => f.id == id);
    await _saveLibrary();
    notifyListeners();
  }

  // ── Meals ───────────────────────────────────────────────────────────────────

  Future<void> addMeal(Meal meal) async {
    _meals.add(meal);
    await _saveMeals();
    notifyListeners();
  }

  Future<void> updateMeal(Meal meal) async {
    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index != -1) {
      _meals[index] = meal;
      await _saveMeals();
      notifyListeners();
    }
  }

  Future<void> deleteMeal(String id) async {
    _meals.removeWhere((m) => m.id == id);
    await _saveMeals();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _meals.indexWhere((m) => m.id == id);
    if (index != -1) {
      _meals[index] = _meals[index].copyWith(isFavorite: !_meals[index].isFavorite);
      await _saveMeals();
      notifyListeners();
    }
  }

  // ── Log entries ─────────────────────────────────────────────────────────────

  Future<void> logMeal({required Meal meal, required String mealSlot}) async {
    for (final ingredient in meal.ingredients) {
      final entry = LogEntry(
        id: _uuid.v4(),
        food: ingredient.food,
        servings: ingredient.servings,
        loggedAt: DateTime.now(),
        meal: mealSlot,
        sourceMealName: meal.name,
      );
      _todayLog.add(entry);
    }
    await _saveLog();
    notifyListeners();
  }

  Future<void> logFood({
    required FoodItem food,
    required double servings,
    required String meal,
  }) async {
    final entry = LogEntry(
      id: _uuid.v4(),
      food: food,
      servings: servings,
      loggedAt: DateTime.now(),
      meal: meal,
    );
    _todayLog.add(entry);
    await _saveLog();
    notifyListeners();
  }

  /// Replace a logged entry's food item (substitution) without changing the meal slot.
  Future<void> substituteLogEntry({
    required String entryId,
    required FoodItem newFood,
    required double newServings,
  }) async {
    final index = _todayLog.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      final old = _todayLog[index];
      _todayLog[index] = LogEntry(
        id: old.id,
        food: newFood,
        servings: newServings,
        loggedAt: old.loggedAt,
        meal: old.meal,
        sourceMealName: old.sourceMealName,
      );
      await _saveLog();
      notifyListeners();
    }
  }

  Future<void> removeLogEntry(String id) async {
    final before = _todayLog.length;
    _todayLog.removeWhere((e) => e.id == id);
    if (_todayLog.length != before) {
      await _saveLog();
      notifyListeners();
    }
  }

  // ── Nutrition goals ─────────────────────────────────────────────────────────

  Future<void> updateGoal(NutritionGoal goal) async {
    final index = _nutritionGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _nutritionGoals[index] = goal;
    } else {
      _nutritionGoals.add(goal);
    }
    if (goal.id == 'calories') _dailyCalorieGoal = goal.target;
    await _saveGoals();
    await _syncCalorieGoal();
    notifyListeners();
  }

  Future<void> addCustomGoal(NutritionGoal goal) async {
    _nutritionGoals.add(goal);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> deleteCustomGoal(String id) async {
    _nutritionGoals.removeWhere((g) => g.id == id && !g.isDefault);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> setCalorieGoal(double goal) async {
    _dailyCalorieGoal = goal;
    final index = _nutritionGoals.indexWhere((g) => g.id == 'calories');
    if (index != -1) {
      _nutritionGoals[index] = _nutritionGoals[index].copyWith(target: goal);
    }
    await _saveGoals();
    await _syncCalorieGoal();
    notifyListeners();
  }

  Future<void> _syncCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('calorie_goal', _dailyCalorieGoal);
  }

  // ── Macro serving sizes (independent from goals) ────────────────────────────

  Future<void> setMacroServingSize(String macroId, double multiplier) async {
    _macroServingSizes[macroId] = multiplier;
    await _saveMacroServingSizes();
    notifyListeners();
  }

  double getMacroServingSize(String macroId) =>
      _macroServingSizes[macroId] ?? 1.0;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String generateId() => _uuid.v4();

  List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) return _foodLibrary;
    final lower = query.toLowerCase();
    return _foodLibrary.where((f) => f.name.toLowerCase().contains(lower)).toList();
  }

  List<Meal> searchMeals(String query) {
    if (query.isEmpty) return sortedMeals;
    final lower = query.toLowerCase();
    final filtered =
        _meals.where((m) => m.name.toLowerCase().contains(lower)).toList();
    final favs = filtered.where((m) => m.isFavorite).toList();
    final rest = filtered.where((m) => !m.isFavorite).toList();
    return [...favs, ...rest];
  }

  String exportDayAsText({String? note}) {
    final dateKey = _dateKey(_selectedDate);
    final lines = <String>[];
    lines.add('=== Food Log: $dateKey ===');
    lines.add('');

    final byMeal = logByMeal;
    for (final entry in byMeal.entries) {
      if (entry.value.isEmpty) continue;
      lines.add('[${entry.key}]');
      for (final log in entry.value) {
        final kcal = log.totalCalories.toStringAsFixed(0);
        final p = log.totalProtein.toStringAsFixed(1);
        final c = log.totalCarbs.toStringAsFixed(1);
        final f = log.totalFat.toStringAsFixed(1);
        final src = log.sourceMealName != null ? ' (from ${log.sourceMealName})' : '';
        lines.add(
          '- ${log.food.name}$src: ${log.servings}× ${log.food.servingSize.toStringAsFixed(0)}${log.food.servingUnit} | ${kcal}kcal | P:${p}g C:${c}g F:${f}g',
        );
      }
      lines.add('');
    }

    lines.add('--- Totals ---');
    lines.add('Calories: ${totalCaloriesToday.toStringAsFixed(0)} / ${_dailyCalorieGoal.toStringAsFixed(0)} kcal');
    lines.add('Protein: ${totalProteinToday.toStringAsFixed(1)}g');
    lines.add('Carbs: ${totalCarbsToday.toStringAsFixed(1)}g');
    lines.add('Fat: ${totalFatToday.toStringAsFixed(1)}g');

    if (note != null && note.trim().isNotEmpty) {
      lines.add('');
      lines.add('--- Note ---');
      lines.add(note.trim());
    }

    return lines.join('\n');
  }
}