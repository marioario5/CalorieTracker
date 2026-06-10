import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/log_entry.dart';
import '../theme.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/macro_bar.dart';
import '../widgets/meal_section.dart';
import 'log_food_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.surface,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today',
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text(_formattedDate(),
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.ios_share_outlined),
                    tooltip: 'Export log',
                    onPressed: () => _showExportDialog(context, provider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _showGoalDialog(context, provider),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calorie summary card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(children: [
                            CalorieRing(
                              consumed: provider.totalCaloriesToday,
                              goal: provider.dailyCalorieGoal,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _statRow(context, 'Consumed',
                                        '${provider.totalCaloriesToday.toStringAsFixed(0)} kcal',
                                        AppTheme.primary),
                                    const SizedBox(height: 10),
                                    _statRow(context, 'Goal',
                                        '${provider.dailyCalorieGoal.toStringAsFixed(0)} kcal',
                                        AppTheme.textSecondary),
                                    const SizedBox(height: 10),
                                    _statRow(
                                        context,
                                        provider.remainingCalories >= 0
                                            ? 'Remaining'
                                            : 'Over by',
                                        '${provider.remainingCalories.abs().toStringAsFixed(0)} kcal',
                                        provider.remainingCalories >= 0
                                            ? AppTheme.primaryLight
                                            : AppTheme.accent),
                                  ]),
                            ),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Macros card — goals wired in for accurate progress bars
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Macros',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 16),
                                MacroBar(
                                    label: 'Protein',
                                    value: provider.totalProteinToday,
                                    goal: provider.proteinGoal,
                                    unit: 'g',
                                    color: AppTheme.proteinColor),
                                const SizedBox(height: 10),
                                MacroBar(
                                    label: 'Carbs',
                                    value: provider.totalCarbsToday,
                                    goal: provider.carbsGoal,
                                    unit: 'g',
                                    color: AppTheme.carbsColor),
                                const SizedBox(height: 10),
                                MacroBar(
                                    label: 'Fat',
                                    value: provider.totalFatToday,
                                    goal: provider.fatGoal,
                                    unit: 'g',
                                    color: AppTheme.fatColor),
                              ]),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text('Meals',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),

                      ...provider.logByMeal.entries.map(
                        (entry) => MealSection(
                          meal: entry.key,
                          entries: entry.value,
                          onAdd: () => _logFood(context, entry.key),
                          onRemove: (id) => provider.removeLogEntry(id),
                          onSubstitute: (logEntry) =>
                              _substituteFood(context, logEntry),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logFood(context, 'Snack'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log food'),
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: valueColor)),
      ],
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  void _logFood(BuildContext context, String meal) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => LogFoodScreen(defaultMeal: meal)));
  }

  void _substituteFood(BuildContext context, LogEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogFoodScreen(
          defaultMeal: entry.meal,
          substituteEntry: entry,
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(
        text: provider.dailyCalorieGoal.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily calorie goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Calories (kcal)', suffixText: 'kcal'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) provider.setCalorieGoal(v);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, AppProvider provider) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Export today\'s log',
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx)),
          ]),
          Text('Copies a plain text summary to your clipboard — paste it into Claude or anywhere else.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a note (optional) — e.g. felt bloated, skipped lunch...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy to clipboard'),
              onPressed: () {
                final text = provider.exportDayAsText(
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text);
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.primary,
                ));
              },
            ),
          ),
        ]),
      ),
    );
  }
}