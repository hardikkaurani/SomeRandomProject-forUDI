import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class SuggestionCard extends StatelessWidget {
  final String suggestion;
  final SuggestionType type;

  const SuggestionCard({
    Key? key,
    required this.suggestion,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    final (bgColor, iconColor, icon) = switch (type) {
      SuggestionType.positive => (
        colors.primaryContainer,
        colors.primary,
        Icons.check_circle_outline,
      ),
      SuggestionType.warning => (
        colors.errorContainer,
        colors.error,
        Icons.warning_outlined,
      ),
      SuggestionType.info => (
        colors.tertiaryContainer,
        colors.tertiary,
        Icons.info_outlined,
      ),
    };

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                suggestion,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SuggestionType { positive, warning, info }
