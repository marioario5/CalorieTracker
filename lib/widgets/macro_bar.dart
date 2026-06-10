import 'package:flutter/material.dart';
import '../theme.dart';

class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double? goal; // optional goal for progress calculation
  final String unit;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGoal = goal ?? 200.0;
    final progress = effectiveGoal > 0 ? (value / effectiveGoal).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: goal != null ? 80 : 52,
          child: Text(
            goal != null
                ? '${value.toStringAsFixed(1)} / ${goal!.toStringAsFixed(0)}$unit'
                : '${value.toStringAsFixed(1)}$unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}