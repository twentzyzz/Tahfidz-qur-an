import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.icon});
  final String title;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    ),
  );
}
