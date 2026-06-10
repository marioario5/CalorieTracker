import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../theme.dart';

class MealSection extends StatelessWidget {
  final String meal;
  final List<LogEntry> entries;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;
  final void Function(LogEntry entry) onSubstitute;

  const MealSection({
    super.key,
    required this.meal,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
    required this.onSubstitute,
  });

  @override
  Widget build(BuildContext context) {
    final totalKcal = entries.fold(0.0, (s, e) => s + e.totalCalories);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  _mealIcon(meal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(meal,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (entries.isNotEmpty)
                    Text(
                      '${totalKcal.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: onAdd,
                    color: AppTheme.primary,
                    tooltip: 'Log food',
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Entries
            if (entries.isNotEmpty) ...[
              const Divider(height: 1, color: AppTheme.border),
              // Each entry gets a ValueKey on its unique ID.
              // This ensures Flutter correctly reconciles rows after deletion,
              // eliminating the "ghost item" bug caused by key mismatches.
              ...entries.map((entry) => _EntryRow(
                    key: ValueKey(entry.id),
                    entry: entry,
                    onRemove: () => onRemove(entry.id),
                    onSubstitute: () => onSubstitute(entry),
                  )),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'Nothing logged yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mealIcon(String meal) {
    final icons = {
      'Breakfast': Icons.wb_sunny_outlined,
      'Lunch': Icons.lunch_dining_outlined,
      'Dinner': Icons.dinner_dining_outlined,
      'Snack': Icons.cookie_outlined,
    };
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icons[meal] ?? Icons.restaurant_outlined,
          size: 16, color: AppTheme.primary),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final LogEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onSubstitute;

  const _EntryRow({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onSubstitute,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // ValueKey on entry.id — critical fix for the ghost-item bug.
      // Without this, Flutter reuses widget instances incorrectly
      // after removal, making deleted items appear to still exist.
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onRemove();
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text('Delete',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: AppTheme.accent),
            SizedBox(width: 20),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.food.name,
                      style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    '${entry.servings}× ${entry.food.servingSize.toStringAsFixed(0)}${entry.food.servingUnit}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              '${entry.totalCalories.toStringAsFixed(0)} kcal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(width: 8),
            // Substitute button
            GestureDetector(
              onTap: onSubstitute,
              child: Tooltip(
                message: 'Substitute',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.swap_horiz,
                      size: 18, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Delete button
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Tooltip(
                message: 'Remove',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close,
                      size: 16, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "${entry.food.name}" from your log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}