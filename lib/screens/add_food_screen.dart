import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../models/nutrition_goals.dart';
import '../theme.dart';

class AddFoodScreen extends StatefulWidget {
  final FoodItem? existingFood;
  const AddFoodScreen({super.key, this.existingFood});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _servingSize;
  late final TextEditingController _servingUnit;

  // micro id -> controller
  final Map<String, TextEditingController> _microControllers = {};

  bool get _isEditing => widget.existingFood != null;

  @override
  void initState() {
    super.initState();
    final f = widget.existingFood;
    _name = TextEditingController(text: f?.name ?? '');
    _calories = TextEditingController(text: f?.calories.toStringAsFixed(0) ?? '');
    _protein = TextEditingController(text: f?.protein.toStringAsFixed(1) ?? '');
    _carbs = TextEditingController(text: f?.carbs.toStringAsFixed(1) ?? '');
    _fat = TextEditingController(text: f?.fat.toStringAsFixed(1) ?? '');
    _servingSize = TextEditingController(text: f?.servingSize.toStringAsFixed(0) ?? '100');
    _servingUnit = TextEditingController(text: f?.servingUnit ?? 'g');

    // pre-fill micro controllers from existing food
    if (f != null) {
      for (final entry in f.micros.entries) {
        _microControllers[entry.key] =
            TextEditingController(text: entry.value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), ''));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _servingSize.dispose();
    _servingUnit.dispose();
    for (final c in _microControllers.values) c.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();

    final micros = <String, double>{};
    for (final entry in _microControllers.entries) {
      final v = double.tryParse(entry.value.text);
      if (v != null && v > 0) micros[entry.key] = v;
    }

    final food = FoodItem(
      id: widget.existingFood?.id ?? provider.generateId(),
      name: _name.text.trim(),
      calories: double.parse(_calories.text),
      protein: double.parse(_protein.text),
      carbs: double.parse(_carbs.text),
      fat: double.parse(_fat.text),
      servingSize: double.parse(_servingSize.text),
      servingUnit: _servingUnit.text.trim().isEmpty ? 'g' : _servingUnit.text.trim(),
      micros: micros,
    );

    if (_isEditing) {
      provider.updateFoodItem(food);
    } else {
      provider.addFoodItem(food);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // custom goals only (not calories/protein/carbs/fat — those are already shown)
    final microGoals = provider.nutritionGoals
        .where((g) => !['calories', 'protein', 'carbs', 'fat'].contains(g.id))
        .toList();

    // ensure controllers exist for all current micro goals
    for (final g in microGoals) {
      _microControllers.putIfAbsent(g.id, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit ingredient' : 'New ingredient'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel(context, 'Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Chicken breast'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),

            const SizedBox(height: 20),
            _sectionLabel(context, 'Serving size'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _servingSize,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '100'),
                  validator: (v) => _validatePositiveNumber(v, 'Size'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _servingUnit,
                  decoration: const InputDecoration(hintText: 'g'),
                ),
              ),
            ]),

            const SizedBox(height: 20),
            _sectionLabel(context, 'Macros per serving'),
            const SizedBox(height: 8),

            _NutritionField(
              controller: _calories,
              label: 'Calories',
              unit: 'kcal',
              color: AppTheme.accent,
              validator: (v) => _validatePositiveNumber(v, 'Calories'),
            ),
            const SizedBox(height: 10),
            _NutritionField(
              controller: _protein,
              label: 'Protein',
              unit: 'g',
              color: AppTheme.proteinColor,
              validator: (v) => _validateNumber(v, 'Protein'),
            ),
            const SizedBox(height: 10),
            _NutritionField(
              controller: _carbs,
              label: 'Carbohydrates',
              unit: 'g',
              color: AppTheme.carbsColor,
              validator: (v) => _validateNumber(v, 'Carbs'),
            ),
            const SizedBox(height: 10),
            _NutritionField(
              controller: _fat,
              label: 'Fat',
              unit: 'g',
              color: AppTheme.fatColor,
              validator: (v) => _validateNumber(v, 'Fat'),
            ),

            // Micros section — only shown if there are custom goals
            if (microGoals.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionLabel(context, 'Micronutrients per serving'),
              Text(
                'Based on your goals. Leave blank if unknown.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...microGoals.map((goal) {
                final ctrl = _microControllers[goal.id]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NutritionField(
                    controller: ctrl,
                    label: goal.name,
                    unit: goal.unit,
                    color: AppTheme.primaryLight,
                    validator: (_) => null, // optional
                    isOptional: true,
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add micronutrient goals in the Goals tab to track things like iron, vitamin C, and omega-3 here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                          ),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Update ingredient' : 'Add ingredient'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            color: AppTheme.textSecondary,
          ),
    );
  }

  String? _validatePositiveNumber(String? v, String field) {
    if (v == null || v.isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null || n < 0) return 'Enter a valid number';
    return null;
  }

  String? _validateNumber(String? v, String field) {
    if (v == null || v.isEmpty) return '$field is required';
    if (double.tryParse(v) == null) return 'Enter a valid number';
    return null;
  }
}

class _NutritionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final Color color;
  final String? Function(String?) validator;
  final bool isOptional;

  const _NutritionField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.color,
    required this.validator,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            suffixText: unit,
            hintText: isOptional ? 'optional' : null,
          ),
          validator: validator,
        ),
      ),
    ]);
  }
}