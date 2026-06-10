import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/nutrition_goals.dart';
import '../theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add custom goal',
            onPressed: () => _showGoalEditor(context, null),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final goals = provider.nutritionGoals;
          final defaults = goals.where((g) => g.isDefault).toList();
          final custom = goals.where((g) => !g.isDefault).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader(context, 'Core goals'),
              const SizedBox(height: 10),
              ...defaults.map((goal) => _GoalCard(
                    goal: goal,
                    onEdit: () => _showGoalEditor(context, goal),
                  )),

              if (custom.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionHeader(context, 'Custom goals'),
                const SizedBox(height: 10),
                ...custom.map((goal) => _GoalCard(
                      goal: goal,
                      onEdit: () => _showGoalEditor(context, goal),
                      onDelete: () => _confirmDelete(context, provider, goal),
                    )),
              ],

              // ── Macro serving sizes ────────────────────────────────────────
              const SizedBox(height: 24),
              _sectionHeader(context, 'Macro display serving sizes'),
              const SizedBox(height: 6),
              Text(
                'Set the serving size multiplier shown on the dashboard for each macro. '
                'This is separate from your goals — use it to track intake in specific portion sizes.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              _MacroServingCard(
                macroId: 'protein',
                label: 'Protein serving size',
                unit: 'g',
                color: AppTheme.proteinColor,
                icon: Icons.fitness_center_outlined,
                provider: provider,
                onEdit: () => _showServingSizeDialog(context, provider, 'protein', 'Protein', 'g'),
              ),
              const SizedBox(height: 8),
              _MacroServingCard(
                macroId: 'carbs',
                label: 'Carbs serving size',
                unit: 'g',
                color: AppTheme.carbsColor,
                icon: Icons.grain_outlined,
                provider: provider,
                onEdit: () => _showServingSizeDialog(context, provider, 'carbs', 'Carbohydrates', 'g'),
              ),
              const SizedBox(height: 8),
              _MacroServingCard(
                macroId: 'fat',
                label: 'Fat serving size',
                unit: 'g',
                color: AppTheme.fatColor,
                icon: Icons.water_drop_outlined,
                provider: provider,
                onEdit: () => _showServingSizeDialog(context, provider, 'fat', 'Fat', 'g'),
              ),

              const SizedBox(height: 24),
              _SuggestedGoals(
                existing: goals,
                onAdd: (g) => provider.addCustomGoal(g),
              ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalEditor(context, null),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Custom goal'),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            color: AppTheme.textSecondary,
          ),
    );
  }

  void _showGoalEditor(BuildContext context, NutritionGoal? existing) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? '');
    final targetCtrl = TextEditingController(
        text: existing?.target.toStringAsFixed(
                existing.unit == 'kcal' ? 0 : 1) ??
            '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  isNew ? 'New goal' : 'Edit ${existing!.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 16),
            if (isNew || !existing!.isDefault) ...[
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nutrient name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'g, mg, mcg, IU...',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Daily target',
                suffixText: existing?.unit ?? unitCtrl.text,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final target = double.tryParse(targetCtrl.text);
                  if (target == null || target < 0) return;

                  final provider = context.read<AppProvider>();
                  if (existing != null) {
                    provider.updateGoal(existing.copyWith(target: target));
                  } else {
                    if (nameCtrl.text.trim().isEmpty ||
                        unitCtrl.text.trim().isEmpty) return;
                    provider.addCustomGoal(NutritionGoal(
                      id: provider.generateId(),
                      name: nameCtrl.text.trim(),
                      unit: unitCtrl.text.trim(),
                      target: target,
                    ));
                  }
                  Navigator.pop(ctx);
                },
                child: Text(isNew ? 'Add goal' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServingSizeDialog(BuildContext context, AppProvider provider,
      String macroId, String label, String unit) {
    final current = provider.getMacroServingSize(macroId);
    final ctrl = TextEditingController(text: current.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  '$label serving size',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Adjusts how $label is displayed on the dashboard. '
              'Your goal target stays the same.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Serving multiplier',
                suffixText: unit,
                helperText: 'e.g. 1.0 = full serving, 0.5 = half serving',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text);
                  if (v != null && v > 0) {
                    provider.setMacroServingSize(macroId, v);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, NutritionGoal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove goal?'),
        content: Text('Remove "${goal.name}" from your goals?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteCustomGoal(goal.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Macro serving size card ───────────────────────────────────────────────────

class _MacroServingCard extends StatelessWidget {
  final String macroId;
  final String label;
  final String unit;
  final Color color;
  final IconData icon;
  final AppProvider provider;
  final VoidCallback onEdit;

  const _MacroServingCard({
    required this.macroId,
    required this.label,
    required this.unit,
    required this.color,
    required this.icon,
    required this.provider,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final size = provider.getMacroServingSize(macroId);
    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    'Multiplier: ${size.toStringAsFixed(2)}×',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Goal card ────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final NutritionGoal goal;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _iconColor(goal).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon(goal), color: _iconColor(goal), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'Target: ${_formatTarget(goal)} ${goal.unit}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ]),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: onDelete,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary, size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  String _formatTarget(NutritionGoal g) {
    if (g.target == g.target.roundToDouble()) {
      return g.target.toStringAsFixed(0);
    }
    return g.target.toStringAsFixed(1);
  }

  IconData _icon(NutritionGoal g) {
    switch (g.id) {
      case 'calories': return Icons.local_fire_department_outlined;
      case 'protein': return Icons.fitness_center_outlined;
      case 'carbs': return Icons.grain_outlined;
      case 'fat': return Icons.water_drop_outlined;
      default: return Icons.science_outlined;
    }
  }

  Color _iconColor(NutritionGoal g) {
    switch (g.id) {
      case 'calories': return AppTheme.accent;
      case 'protein': return AppTheme.proteinColor;
      case 'carbs': return AppTheme.carbsColor;
      case 'fat': return AppTheme.fatColor;
      default: return AppTheme.primaryLight;
    }
  }
}

// ── Suggested goals ──────────────────────────────────────────────────────────

class _SuggestedGoals extends StatelessWidget {
  final List<NutritionGoal> existing;
  final void Function(NutritionGoal) onAdd;

  const _SuggestedGoals({required this.existing, required this.onAdd});

  static const _suggestions = [
    ('Fiber', 'g', 30.0),
    ('Sodium', 'mg', 2300.0),
    ('Potassium', 'mg', 3500.0),
    ('Calcium', 'mg', 1000.0),
    ('Iron', 'mg', 18.0),
    ('Magnesium', 'mg', 400.0),
    ('Vitamin C', 'mg', 90.0),
    ('Vitamin D', 'IU', 600.0),
    ('Vitamin B12', 'mcg', 2.4),
    ('Zinc', 'mg', 11.0),
    ('Omega-3', 'g', 1.6),
    ('Folate', 'mcg', 400.0),
  ];

  @override
  Widget build(BuildContext context) {
    final existingNames =
        existing.map((g) => g.name.toLowerCase()).toSet();
    final available = _suggestions
        .where((s) => !existingNames.contains(s.$1.toLowerCase()))
        .toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'QUICK ADD',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
            ),
      ),
      const SizedBox(height: 10),
      Text(
        'Common nutrients you might want to track:',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: available.map((s) {
          return ActionChip(
            label: Text('+ ${s.$1}'),
            onPressed: () => onAdd(NutritionGoal(
              id: s.$1.toLowerCase().replaceAll(' ', '_'),
              name: s.$1,
              unit: s.$2,
              target: s.$3,
            )),
            backgroundColor: AppTheme.background,
            side: const BorderSide(color: AppTheme.border),
            labelStyle: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          );
        }).toList(),
      ),
    ]);
  }
}