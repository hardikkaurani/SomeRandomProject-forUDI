import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class TaxHealthCard extends StatelessWidget {
  final double grossIncome;
  final double taxableIncome;
  final double taxPayable;

  const TaxHealthCard({
    Key? key,
    required this.grossIncome,
    required this.taxableIncome,
    required this.taxPayable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSafe = taxableIncome <= 700000;
    final statusColor = isSafe ? colors.primary : colors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Tax Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Main metric rows
            _MetricRow(
              label: 'Gross Income',
              value: '₹${_formatNumber(grossIncome.toInt())}',
              isHighlight: false,
              context: context,
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricRow(
              label: 'Estimated Tax',
              value: '₹${_formatNumber(taxPayable.toInt())}',
              isHighlight: true,
              highlightColor: statusColor,
              context: context,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Simple one-liner explanation
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSafe
                    ? '✓ You qualify for tax rebate (₹0 tax if income stays below ₹7 lakh)'
                    : '⚠ Your income exceeds rebate limit. Plan to pay taxes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 10000000) {
      return '${(num / 10000000).toStringAsFixed(1)} Cr';
    } else if (num >= 100000) {
      return '${(num / 100000).toStringAsFixed(1)}L';
    }
    return num.toString();
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? highlightColor;
  final BuildContext context;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.isHighlight,
    required this.context,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? highlightColor : null,
              ),
        ),
      ],
    );
  }
}
