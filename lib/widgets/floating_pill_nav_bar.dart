import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animated_nav_icons.dart';

class NavDestinationItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavDestinationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class FloatingPillNavBar extends StatefulWidget {
  final int selectedIndex;
  final List<NavDestinationItem> items;
  final ValueChanged<int> onDestinationSelected;

  const FloatingPillNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
  });

  @override
  State<FloatingPillNavBar> createState() => _FloatingPillNavBarState();
}

class _FloatingPillNavBarState extends State<FloatingPillNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _offsetAnimation;
  double _currentPosition = 0.0;
  bool _isDragging = false;
  int? _lastHapticIndex;
  
  // Refined compact spacing and dimensions for tight Slice cluster
  static const double _itemSpacing = 66.0;
  static const double _circleDiameter = 48.0;
  static const double _columnWidth = 96.0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.selectedIndex.toDouble();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didUpdateWidget(FloatingPillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && !_isDragging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDragging) {
          _animateTo(widget.selectedIndex.toDouble(), notifyOnComplete: false);
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target, {bool notifyOnComplete = true}) {
    _animController.stop();
    final start = _currentPosition;
    int lastAnimatedHaptic = start.round();

    _offsetAnimation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        final val = _offsetAnimation!.value;
        final currentRounded = val.round();
        if (currentRounded != lastAnimatedHaptic) {
          lastAnimatedHaptic = currentRounded;
          HapticFeedback.mediumImpact();
        }
        setState(() {
          _currentPosition = val;
        });
      });

    _animController.forward(from: 0.0).then((_) {
      if (mounted && notifyOnComplete) {
        final targetIndex = target.round();
        if (targetIndex == widget.selectedIndex) return;
        HapticFeedback.heavyImpact();
        widget.onDestinationSelected(targetIndex);
      }
    });
  }

  void _handleDragStart(DragStartDetails details) {
    _animController.stop();
    setState(() {
      _isDragging = true;
      _lastHapticIndex = _currentPosition.round();
    });
    HapticFeedback.mediumImpact();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final deltaIndex = -details.delta.dx / (_itemSpacing * 1.75);
    final newPos = (_currentPosition + deltaIndex).clamp(0.0, (widget.items.length - 1).toDouble());

    final currentRounded = newPos.round();
    if (_lastHapticIndex != currentRounded) {
      _lastHapticIndex = currentRounded;
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _currentPosition = newPos;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    // Convert fling velocity (pixels/sec) to item index shifts (flick left = positive target shift)
    final velocityX = details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx;
    final velocityBoost = (-velocityX / 900.0); // Momentum boost factor

    final projectedPosition = _currentPosition + velocityBoost;
    final targetIndex = projectedPosition.round().clamp(0, widget.items.length - 1);

    setState(() {
      _isDragging = false;
      _lastHapticIndex = null;
    });

    HapticFeedback.heavyImpact();

    // Smooth momentum animation
    final distanceToTarget = (_currentPosition - targetIndex).abs();
    final durationMs = (240 + (distanceToTarget * 60)).clamp(200, 450).toInt();
    _animController.duration = Duration(milliseconds: durationMs);

    // Only swap page when carousel arrives and stops
    _animateTo(targetIndex.toDouble(), notifyOnComplete: true);
  }

  void _handleDragCancel() {
    final targetIndex = _currentPosition.round().clamp(0, widget.items.length - 1);
    setState(() {
      _isDragging = false;
      _lastHapticIndex = null;
    });
    _animateTo(targetIndex.toDouble(), notifyOnComplete: true);
  }

  void _handleTap(int index) {
    if (widget.selectedIndex != index) {
      HapticFeedback.mediumImpact();
      _animateTo(index.toDouble(), notifyOnComplete: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemsCount = widget.items.length;

    final inactiveBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;
    final activeBg = theme.colorScheme.primary;
    final inactiveBorder = theme.colorScheme.outlineVariant.withAlpha(120);
    final activeBorder = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final centerX = screenWidth / 2;

        return Container(
          height: 104,
          margin: EdgeInsets.zero,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _handleDragCancel,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Floating Circle Carousel (Slice Style)
                ...List.generate(itemsCount, (index) {
                  final item = widget.items[index];
                  final offsetFromCenter = (index - _currentPosition);
                  final itemCenterX = centerX + (offsetFromCenter * _itemSpacing);
                  final distance = offsetFromCenter.abs();

                  // Continuous mathematical scale & opacity
                  final scale = (1.24 - (distance * 0.38)).clamp(0.78, 1.24);
                  final opacity = (1.0 - (distance * 0.45)).clamp(0.30, 1.0);

                  // Continuous color interpolation
                  final activeFactor = (1.0 - (distance * 2.0)).clamp(0.0, 1.0);
                  final bubbleColor = Color.lerp(inactiveBg, activeBg, activeFactor)!;
                  final borderColor = Color.lerp(inactiveBorder, activeBorder, activeFactor)!;
                  final iconColor = Color.lerp(theme.colorScheme.onSurfaceVariant, theme.colorScheme.onPrimary, activeFactor)!;
                  final labelOpacity = (1.0 - (distance * 2.2)).clamp(0.0, 1.0);
                  final isCenter = distance < 0.4;
                  final iconScale = 1.0 + (0.18 * (1.0 - distance.clamp(0.0, 1.0)));

                  return Positioned(
                    // Perfectly centered container so different text widths never shift the circle position!
                    left: itemCenterX - (_columnWidth / 2),
                    width: _columnWidth,
                    top: 18,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circle Bubble with direct scale
                        Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              elevation: isCenter ? 6 : 1.5,
                              shadowColor: isCenter
                                  ? theme.colorScheme.primary.withAlpha(isDark ? 160 : 100)
                                  : Colors.black26,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _handleTap(index),
                                child: Container(
                                  width: _circleDiameter,
                                  height: _circleDiameter,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: bubbleColor,
                                    border: Border.all(
                                      color: borderColor,
                                      width: isCenter ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Transform.scale(
                                      scale: iconScale,
                                      child: AnimatedNavIcon(
                                        id: item.id,
                                        isSelected: isCenter,
                                        distance: distance,
                                        color: iconColor,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Clean Centered Label Tag
                        Opacity(
                          opacity: labelOpacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withAlpha(isDark ? 210 : 235),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withAlpha(90),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              item.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
