import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor.withAlpha(120),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Banner Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SkeletonBox(width: 56, height: 56, borderRadius: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 140, height: 18),
                          SizedBox(height: 8),
                          SkeletonBox(width: 100, height: 14),
                          SizedBox(height: 6),
                          SkeletonBox(width: 80, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Next Class Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBox(width: 100, height: 20, borderRadius: 4),
                        SkeletonBox(width: 80, height: 16),
                      ],
                    ),
                    SizedBox(height: 12),
                    SkeletonBox(width: 200, height: 20),
                    SizedBox(height: 8),
                    SkeletonBox(width: 150, height: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Timetable Section Header & Cards Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 120, height: 16),
                SkeletonBox(width: 90, height: 24, borderRadius: 12),
              ],
            ),
          ),
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SkeletonBox(width: 60, height: 16),
                              SkeletonBox(width: 16, height: 16, borderRadius: 8),
                            ],
                          ),
                          SkeletonBox(width: 160, height: 18),
                          SkeletonBox(width: 120, height: 14),
                          SkeletonBox(width: 90, height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Attendance Section Skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SkeletonBox(width: 150, height: 16),
          ),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 160, height: 16),
                            SizedBox(height: 8),
                            SkeletonBox(width: 80, height: 14),
                            SizedBox(height: 6),
                            SkeletonBox(width: 120, height: 12),
                          ],
                        ),
                      ),
                      SkeletonBox(width: 54, height: 54, borderRadius: 27),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginSkeletonLoader extends StatelessWidget {
  const LoginSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                SkeletonBox(width: 64, height: 64, borderRadius: 32),
                SizedBox(height: 16),
                SkeletonBox(width: 120, height: 24),
                SizedBox(height: 8),
                SkeletonBox(width: 180, height: 14),
                SizedBox(height: 36),
                SkeletonBox(width: double.infinity, height: 56, borderRadius: 8),
                SizedBox(height: 16),
                SkeletonBox(width: double.infinity, height: 56, borderRadius: 8),
                SizedBox(height: 16),
                SkeletonBox(width: double.infinity, height: 56, borderRadius: 8),
                SizedBox(height: 24),
                SkeletonBox(width: double.infinity, height: 48, borderRadius: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
