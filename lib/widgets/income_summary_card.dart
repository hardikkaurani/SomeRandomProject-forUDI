import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class IncomeSummaryCard extends StatelessWidget {
  final int count;
  final double total;

  const IncomeSummaryCard({
    Key? key,
    required this.count,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final numString = _formatNumber(total.toInt());

    return Card(
      color: colors.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Income',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  numString,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                ),
              ],
            ),
            Text(
              '$count ${count == 1 ? 'entry' : 'entries'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 10000000) {
      return '₹${(num / 10000000).toStringAsFixed(1)} Cr';
    } else if (num >= 100000) {
      return '₹${(num / 100000).toStringAsFixed(1)}L';
    }
    return '₹$num';
  }
}
