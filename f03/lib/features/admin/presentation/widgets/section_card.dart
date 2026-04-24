import 'package:flutter/material.dart';

import '../../../../app_theme.dart';

/// Khối nội dung bo góc thống nhất trên mobile: tiêu đề + trailing + body.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || trailing != null)
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            if (title != null || trailing != null) const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Pill hiển thị status (mobile-friendly, màu theo từng nhóm).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  static Color colorOf(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CANCEL_REQUESTED':
        return const Color(0xFFF59E0B);
      case 'CONFIRMED':
      case 'INPROGRESS':
        return const Color(0xFF2563EB);
      case 'SHIPPED':
        return const Color(0xFF7C3AED);
      case 'DELIVERED':
      case 'COMPLETED':
      case 'APPROVED':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
      case 'REJECTED':
      case 'RETURNED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B6885);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? colorOf(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Hàng chip cuộn ngang (tránh overflow khi có nhiều filter trên mobile).
class HorizontalChips extends StatelessWidget {
  const HorizontalChips({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 8,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}

/// Card rỗng / trạng thái no-data.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.message = 'Không có dữ liệu',
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
