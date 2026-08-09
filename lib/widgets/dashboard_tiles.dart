import 'package:flutter/material.dart';

class DashboardTilesWidget extends StatelessWidget {
  final Function(String route) onTileTap;

  const DashboardTilesWidget({
    super.key,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tiles = [
      (title: 'Results', icon: Icons.grade_outlined, route: '/results'),
      (title: 'Syllabus', icon: Icons.menu_book_outlined, route: '/syllabus'),
      (title: 'Attendance', icon: Icons.pie_chart_outline, route: '/attendance'),
      (title: 'Faculty', icon: Icons.people_outline, route: '/faculty'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "QUICK ACCESS",
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final tile = tiles[index];
            return Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTileTap(tile.route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(tile.icon, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        tile.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
