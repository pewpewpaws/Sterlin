import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive Animated Icon for the Carousel Dock
class AnimatedNavIcon extends StatefulWidget {
  final String id;
  final bool isSelected;
  final double distance;
  final Color color;
  final double size;

  const AnimatedNavIcon({
    super.key,
    required this.id,
    required this.isSelected,
    required this.distance,
    required this.color,
    this.size = 22,
  });

  @override
  State<AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<AnimatedNavIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.isSelected) {
          _controller.forward(from: 0.0);
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.id) {
      case 'settings':
        return _buildSpinningGear();
      case 'attendance':
        return _buildAnimatedBars();
      case 'faculty':
        return _buildAnimatedFaculty();
      case 'home':
      default:
        return _buildAnimatedHome();
    }
  }

  // ⚙️ Settings: Rotating Gear Animation
  Widget _buildSpinningGear() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * (math.pi / 2);
        return Transform.rotate(
          angle: angle,
          child: Icon(
            widget.isSelected ? Icons.settings_rounded : Icons.settings_outlined,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }

  // 📊 Attendance: Staggered Growing Bar Chart Animation
  Widget _buildAnimatedBars() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = widget.isSelected ? _controller.value : 0.0;
        final bar1 = 0.5 + 0.5 * math.sin(progress * math.pi * 0.5);
        final bar2 = 0.3 + 0.7 * math.sin((progress * math.pi * 0.5).clamp(0.0, math.pi * 0.5));
        final bar3 = 0.4 + 0.6 * math.sin((progress * math.pi * 0.5).clamp(0.0, math.pi * 0.5));

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(bar1 * widget.size * 0.65, widget.color),
              _buildBar(bar2 * widget.size * 0.90, widget.color),
              _buildBar(bar3 * widget.size * 0.75, widget.color),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 3.5,
      height: height.clamp(4.0, widget.size),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // 👨‍🏫 Faculty: People Wave / Pop Animation
  Widget _buildAnimatedFaculty() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (0.15 * math.sin(_controller.value * math.pi));
        final tilt = math.sin(_controller.value * math.pi * 2) * 0.1;
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: tilt,
            child: Icon(
              widget.isSelected ? Icons.people_alt_rounded : Icons.people_outline_rounded,
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }

  // 🏠 Home: Elastic Jump / Pulse Animation
  Widget _buildAnimatedHome() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = math.sin(_controller.value * math.pi) * -4.0;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: Icon(
            widget.isSelected ? Icons.home_rounded : Icons.home_outlined,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}
