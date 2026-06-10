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
  bool _isSpice = false;

  bool get _isEditing => widget.existingFood != null;

  @override
  void initState() {
    super.initState();
    final f = widget.existingFood;
    _name = TextEditingController(text: f?.name ?? '');
    _calories = TextEditingController(text: f?.calories != null && f!.calories > 0 ? f.calories.toStringAsFixed(0) : '');
    _protein = TextEditingController(text: f?.protein != null && f!.protein > 0 ? f.protein.toStringAsFixed(1) : '');
    _carbs = TextEditingController(text: f?.carbs != null && f!.carbs > 0 ? f.carbs.toStringAsFixed(1) : '');
    _fat = TextEditingController(text: f?.fat != null && f!.fat > 0 ? f.fat.toStringAsFixed(1) : '');
    _servingSize = TextEditingController(text: f?.servingSize.toStringAsFixed(0) ?? '1');
    _servingUnit = TextEditingController(text: f?.servingUnit ?? 'tsp');
    _isSpice = f?.isSpice ?? false;

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
      calories: _isSpice ? (double.tryParse(_calories.text) ?? 0) : double.parse(_calories.text),
      protein: _isSpice ? (double.tryParse(_protein.text) ?? 0) : double.parse(_protein.text),
      carbs: _isSpice ? (double.tryParse(_carbs.text) ?? 0) : double.parse(_carbs.text),
      fat: _isSpice ? (double.tryParse(_fat.text) ?? 0) : double.parse(_fat.text),
      servingSize: double.parse(_servingSize.text),
      servingUnit: _servingUnit.text.trim().isEmpty ? (_isSpice ? 'tsp' : 'g') : _servingUnit.text.trim(),
      micros: micros,
      isSpice: _isSpice,
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
              decoration: InputDecoration(
                hintText: _isSpice ? 'e.g. Turmeric, Black pepper' : 'e.g. Chicken breast',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),

            const SizedBox(height: 16),

            // Spice toggle
            GestureDetector(
              onTap: () => setState(() {
                _isSpice = !_isSpice;
                if (_isSpice) {
                  // set sensible spice defaults
                  if (_servingSize.text == '100' || _servingSize.text.isEmpty) {
                    _servingSize.text = '1';
                  }
                  if (_servingUnit.text == 'g' || _servingUnit.text.isEmpty) {
                    _servingUnit.text = 'tsp';
                  }
                } else {
                  if (_servingSize.text == '1') _servingSize.text = '100';
                  if (_servingUnit.text == 'tsp') _servingUnit.text = 'g';
                }
              }),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isSpice ? AppTheme.primarySurface : AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSpice ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    Icons.spa_outlined,
                    color: _isSpice ? AppTheme.primary : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        'Spice / seasoning',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isSpice ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Macros become optional — negligible calories',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ]),
                  ),
                  Switch(
                    value: _isSpice,
                    onChanged: (v) => setState(() => _isSpice = v),
                    activeColor: AppTheme.primary,
                  ),
                ]),
              ),
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
                  decoration: InputDecoration(hintText: _isSpice ? '1' : '100'),
                  validator: (v) => _validatePositiveNumber(v, 'Size'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _servingUnit,
                  decoration: InputDecoration(hintText: _isSpice ? 'tsp' : 'g'),
                ),
              ),
            ]),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _sectionLabel(context, 'Macros per serving')),
              if (_isSpice)
                Text(
                  'all optional',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
            ]),
            const SizedBox(height: 8),

            _NutritionField(
              controller: _calories,
              label: 'Calories',
              unit: 'kcal',
              color: AppTheme.accent,
              validator: _isSpice ? (_) => null : (v) => _validatePositiveNumber(v, 'Calories'),
              isOptional: _isSpice,
            ),
            const SizedBox(height: 10),
            _NutritionField(
              controller: _protein,
              label: 'Protein',
              unit: 'g',
              color: AppTheme.proteinColor,
              validator: _isSpice ? (_) => null : (v) => _validateNumber(v, 'Protein'),
              isOptional: _isSpice,
            ),
            const SizedBox(height: 10),
            _NutritionField(
              controller: _carbs,
              label: 'Carbohydrates',
              unit: 'g',
              color: AppTheme.carbsColor,
              validator: _isSpice ? (_) => null : (v) => _validateNumber(v, 'Carbs'),
              isOptional: _isSpice,
            ),
            const SizedBox(height: 10),
            _NutritionField(
              controller: _fat,
              label: 'Fat',
              unit: 'g',
              color: AppTheme.fatColor,
              validator: _isSpice ? (_) => null : (v) => _validateNumber(v, 'Fat'),
              isOptional: _isSpice,
            ),

            // Micros section
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
                    validator: (_) => null,
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