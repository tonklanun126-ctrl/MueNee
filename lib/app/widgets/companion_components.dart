import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'brand_mark.dart';

class CompanionSectionHeader extends StatelessWidget {
  const CompanionSectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xSmall),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
      ?action,
    ],
  );
}

class CompanionBudgetChip extends StatelessWidget {
  const CompanionBudgetChip({
    required this.amount,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'งบ $amount บาท',
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.selection,
      decoration: BoxDecoration(
        color: selected ? AppTheme.coralActive : Colors.white,
        borderRadius: AppRadii.button,
        border: Border.all(
          color: selected ? AppTheme.coralActive : AppTheme.ink,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadii.button,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, color: Colors.white, size: 18),
                const SizedBox(width: 4),
              ],
              Text(
                '฿$amount',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CompanionStateCard extends StatelessWidget {
  const CompanionStateCard({
    required this.title,
    this.message,
    this.action,
    this.icon,
    super.key,
  });

  final String title;
  final String? message;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              const ExcludeSemantics(child: BrandMark(size: 64))
            else
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.coralSoft,
                  borderRadius: AppRadii.card,
                ),
                child: Icon(icon, color: AppTheme.coralActive, size: 30),
              ),
            const SizedBox(height: AppSpacing.normal),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.small),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.large),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}
