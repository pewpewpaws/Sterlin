import 'package:flutter/material.dart';

/// Top-left page title treatment.
///
/// A big Sora heading anchored to the start of the content with an optional
/// uppercase eyebrow above it, an automatic back button when the route was
/// pushed on top of the shell, and room for trailing actions.
class PageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (canPop) ...[
            HeaderAction(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  style: theme.textTheme.displaySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 10), action],
        ],
      ),
    );
  }
}

/// Quiet circular icon button used alongside [PageHeader].
class HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const HeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: CircleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
