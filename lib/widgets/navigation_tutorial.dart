import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationTutorial {
  NavigationTutorial._();

  static final GlobalKey navBarKey = GlobalKey();
  static final GlobalKey bellKey = GlobalKey();
  static const String _seenKey = 'app_nav_tutorial_seen';
  static final Completer<void> _firstRunCompleter = Completer<void>();

  static Future<void> get waitForFirstRun => _firstRunCompleter.future;

  static void _completeFirstRun() {
    if (!_firstRunCompleter.isCompleted) _firstRunCompleter.complete();
  }

  static Future<void> maybeShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_seenKey) ?? false) return;

      await Future.delayed(const Duration(milliseconds: 800));
      await prefs.setBool(_seenKey, true);
      if (!context.mounted) return;
      await show(context);
    } catch (_) {} finally {
      _completeFirstRun();
    }
  }

  static Future<void> show(BuildContext context) async {
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const _TutorialOverlay(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }
}

class _StepSpec {
  final String title;
  final String body;
  final WidgetBuilder art;
  final bool targetBell;
  final bool showOutline;
  final bool spotlight;
  const _StepSpec(
    this.title,
    this.body,
    this.art, {
    this.targetBell = false,
    this.showOutline = true,
    this.spotlight = true,
  });
}

class _TutorialOverlay extends StatefulWidget {
  const _TutorialOverlay();

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  Rect? _displayRect;
  double? _displayTop;
  double _borderScale = 0.0;
  double _scrimScale = 1.0;
  double _holeStrength = 0.0;
  double _cardHeight = 320;
  Rect? _dockRect;
  Rect? _bellRect;

  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _moveC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final CurvedAnimation _moveCurved =
      CurvedAnimation(parent: _moveC, curve: Curves.easeInOutCubic);
  RectTween? _rectTween;
  Tween<double>? _topTween;
  Tween<double>? _borderTween;
  Tween<double>? _scrimTween;
  Tween<double>? _holeTween;

  bool _hasHole(int step) =>
      _steps[step].spotlight && step < _steps.length - 1;

  static const List<_StepSpec> _steps = [
    _StepSpec(
      'Welcome to Sterlin!',
      'Everything lives behind this little dock at the bottom of the screen. Here is the 20-second tour.',
      _buildWelcomeArt,
      spotlight: false,
    ),
    _StepSpec(
      'Tap or glide',
      'Tap a bubble to open that page, or drag sideways along the dock — you will feel a little tick as you pass each one.',
      _buildGlideArt,
      showOutline: false,
    ),
    _StepSpec(
      'Watch for absences',
      'This bell sits at the top corner of every page — tap it to see absences newly recorded in ETLab.',
      _buildBellArt,
      targetBell: true,
      showOutline: false,
    ),
    _StepSpec(
      "You're all set!",
      "That's the whole tour. You can replay it anytime from Settings.",
      _buildDoneArt,
    ),
  ];

  static Widget _buildWelcomeArt(BuildContext context) =>
      const _DockPreview(sweep: false);
  static Widget _buildGlideArt(BuildContext context) =>
      const _DockPreview(sweep: true);
  static Widget _buildBellArt(BuildContext context) => const _BellWobble();
  static Widget _buildDoneArt(BuildContext context) => const _DoneCheck();

  Rect _targetFor(int step) {
    if (_steps[step].targetBell) {
      return _bellRect ?? _fallbackBellRect();
    }
    return _dockRect ?? _fallbackDockRect();
  }

  Rect _fallbackDockRect() {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barTop = size.height - bottomInset - 20.0 - 104.0;
    return Rect.fromLTWH(12, barTop, size.width - 24, 134);
  }

  Rect _fallbackBellRect() {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    return Rect.fromLTWH(size.width - 62, topInset + 30, 42, 42);
  }

  @override
  void initState() {
    super.initState();
    _moveC.addListener(_onMoveTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _placeInitial());
  }

  void _onMoveTick() {
    if (!mounted) return;
    setState(() {
      _displayRect = _rectTween?.evaluate(_moveCurved) ?? _displayRect;
      _displayTop = _topTween?.evaluate(_moveCurved) ?? _displayTop;
      _borderScale = _borderTween?.evaluate(_moveCurved) ?? _borderScale;
      _scrimScale = _scrimTween?.evaluate(_moveCurved) ?? _scrimScale;
      _holeStrength = _holeTween?.evaluate(_moveCurved) ?? _holeStrength;
    });
  }

  double _topFor(int step, Size size) {
    if (!_steps[step].spotlight || step >= _steps.length - 1) {
      return math.max(16.0, (size.height - _cardHeight) / 2);
    }
    final target = _targetFor(step);
    if (_steps[step].targetBell) {
      return math.min(
        target.bottom + 16,
        math.max(12.0, size.height - _cardHeight - 12),
      );
    }
    return math.max(target.top - 16 - _cardHeight, 12);
  }

  Rect _rectTargetFor(int step, Size size) {
    if (!_steps[step].spotlight || step >= _steps.length - 1) {
      return Rect.fromCircle(center: size.center(Offset.zero), radius: size.longestSide * 0.75);
    }
    return _targetFor(step);
  }

  void _placeInitial() {
    _measure();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final h = _cardKey.currentContext?.size?.height;
      if (h != null && h > 0) _cardHeight = h;
      final size = MediaQuery.of(context).size;
      setState(() {
        _displayRect = _rectTargetFor(0, size);
        _displayTop = _topFor(0, size);
        _borderScale = 0.0;
        _scrimScale = 1.0;
        _holeStrength = 0.0;
      });
    });
  }

  void _measure() {
    Rect? measure(GlobalKey key) {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final ro = ctx.findRenderObject();
      if (ro is RenderBox && ro.attached && ro.hasSize) {
        return ro.localToGlobal(Offset.zero) & ro.size;
      }
      return null;
    }

    final dock = measure(NavigationTutorial.navBarKey);
    final bell = measure(NavigationTutorial.bellKey);
    if (!mounted || (dock == null && bell == null)) return;
    setState(() {
      if (dock != null) _dockRect = dock;
      if (bell != null) _bellRect = bell;
    });
  }
  void _goToStep(int step) {
    HapticFeedback.selectionClick();
    final fromRect = _displayRect;
    final fromTop = _displayTop;
    final fromBorder = _borderScale;
    final fromScrim = _scrimScale;
    final fromHole = _holeStrength;
    final prevStep = _step;
    setState(() => _step = step);
    _moveC.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final h = _cardKey.currentContext?.size?.height;
      if (h != null && h > 0) _cardHeight = h;
      final size = MediaQuery.of(context).size;
      final isLast = step >= _steps.length - 1;
      final toRect = _rectTargetFor(step, size);
      final toTop = _topFor(step, size);
      final toBorder =
          isLast || !_steps[step].showOutline ? 0.0 : 1.0;
      final toScrim = isLast ? 0.0 : 1.0;
      final toHole = _hasHole(step) ? 1.0 : 0.0;

      void snap() {
        setState(() {
          _displayRect = toRect;
          _displayTop = toTop;
          _borderScale = toBorder;
          _scrimScale = toScrim;
          _holeStrength = toHole;
        });
      }

      if (fromRect == null || fromTop == null) {
        snap();
        return;
      }
      final moved = (fromRect.center.dy - toRect.center.dy).abs() > 1.0 ||
          (fromTop - toTop).abs() > 1.0 ||
          (fromScrim - toScrim).abs() > 0.01 ||
          (fromHole - toHole).abs() > 0.01 ||
          prevStep == step;
      if (!moved) {
        snap();
        return;
      }
      setState(() {
        _rectTween = RectTween(begin: fromRect, end: toRect);
        _topTween = Tween<double>(begin: fromTop, end: toTop);
        _borderTween = Tween<double>(begin: fromBorder, end: toBorder);
        _scrimTween = Tween<double>(begin: fromScrim, end: toScrim);
        _holeTween = Tween<double>(begin: fromHole, end: toHole);
      });
      _moveC.forward(from: 0);
    });
  }

  void _next() {
    if (_step >= _steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _goToStep(_step + 1);
  }

  void _back() {
    if (_step == 0) return;
    _goToStep(_step - 1);
  }

  @override
  void dispose() {
    _moveC.dispose();
    _moveCurved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rect = _displayRect;
    final top = _displayTop;
    if (rect == null || top == null) return const SizedBox.expand();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _SpotlightPainter(
              hole: rect,
              borderScale: _borderScale,
              scrimScale: _scrimScale,
              holeStrength: _holeStrength,
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: top,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildCard(theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(ThemeData theme) {
    final scheme = theme.colorScheme;
    final spec = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Container(
      key: _cardKey,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withAlpha(110)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: Column(
              key: ValueKey(_step),
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: Center(child: spec.art(context)),
                ),
                const SizedBox(height: 10),
                Text(
                  spec.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spec.body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _step == 0
                        ? TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Skip'),
                          )
                        : TextButton.icon(
                            onPressed: _back,
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text('Back'),
                          ),
                  ),
                ),
                ...List.generate(_steps.length, (i) {
                  final active = i == _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 7,
                    width: active ? 20 : 7,
                    decoration: BoxDecoration(
                      color: active ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(isLast ? 'Got it' : 'Next'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    this.borderScale = 1.0,
    this.scrimScale = 1.0,
    this.holeStrength = 1.0,
  });

  final Rect hole;
  final double borderScale;
  final double scrimScale;
  final double holeStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final effective = Rect.lerp(full, hole, holeStrength.clamp(0.0, 1.0))!;
    final inflated = effective.inflate(12);
    final radius = Radius.circular(
      math.min(30.0, inflated.shortestSide * 0.38),
    );
    final rrect = RRect.fromRectAndRadius(inflated, radius);

    final scrim = Path()..addRect(full);
    final cutout = Path()..addRRect(rrect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, scrim, cutout),
      Paint()..color = Colors.black.withAlpha((153 * scrimScale).round()),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = Colors.white.withAlpha((50 * borderScale).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withAlpha((230 * borderScale).round()),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.borderScale != borderScale ||
      oldDelegate.scrimScale != scrimScale ||
      oldDelegate.holeStrength != holeStrength;
}

class _LoopingAnimation extends StatefulWidget {
  final Duration duration;
  final bool reverse;
  final Widget Function(BuildContext context, double value) builder;

  const _LoopingAnimation({
    required this.duration,
    this.reverse = false,
    required this.builder,
  });

  @override
  State<_LoopingAnimation> createState() => _LoopingAnimationState();
}

class _LoopingAnimationState extends State<_LoopingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.reverse) {
      _c.repeat(reverse: true);
    } else {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(context, _c.value),
    );
  }
}

class _DockPreview extends StatelessWidget {
  final bool sweep;

  const _DockPreview({this.sweep = false});

  static const _icons = [
    Icons.people_outline_rounded,
    Icons.home_outlined,
    Icons.analytics_outlined,
    Icons.settings_outlined,
  ];
  static const _labels = ['Faculty', 'Home', 'Attendance', 'Settings'];
  static const double _spacing = 58.0;
  static const double _diameter = 42.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = _spacing * 3 + _diameter + 32;

    return _LoopingAnimation(
      duration: const Duration(milliseconds: 3200),
      builder: (context, t) {
        final p = sweep ? 1.5 + 1.45 * math.sin(t * 2 * math.pi) : 1.0;

        return SizedBox(
          width: width,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (sweep) ...[
                Positioned(
                  left: 0,
                  top: 8,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 8,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
              ],
              for (var i = 0; i < _icons.length; i++)
                Positioned(
                  left: width / 2 + (i - p) * _spacing - 50,
                  width: 100,
                  top: 0,
                  child: Column(
                    children: [
                      Transform.scale(
                        scale: _scaleFor(i, p, t),
                        child: Opacity(
                          opacity: (1.0 - (i - p).abs() * 0.45).clamp(0.30, 1.0),
                          child: Container(
                            width: _diameter,
                            height: _diameter,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _bubbleColor(theme, i, p),
                              border: Border.all(
                                color: theme.colorScheme.primary.withAlpha(
                                  ((1 - (i - p).abs()).clamp(0.0, 1.0) * 255).round(),
                                ),
                                width: (i - p).abs() < 0.45 ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              _icons[i],
                              size: 20,
                              color: _iconColor(theme, i, p),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Opacity(
                        opacity: (1.0 - (i - p).abs() * 2.2).clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withAlpha(220),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            _labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _scaleFor(int i, double p, double t) {
    final base = (1.24 - (i - p).abs() * 0.36).clamp(0.78, 1.24);
    if (!sweep) return base + math.sin(t * 2 * math.pi) * 0.02;
    return base;
  }

  Color _bubbleColor(ThemeData theme, int i, double p) {
    final dark = theme.brightness == Brightness.dark;
    final inactive = dark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;
    final f = (1.0 - (i - p).abs() * 1.8).clamp(0.0, 1.0);
    return Color.lerp(inactive, theme.colorScheme.primary, f)!;
  }

  Color _iconColor(ThemeData theme, int i, double p) {
    final f = (1.0 - (i - p).abs() * 1.8).clamp(0.0, 1.0);
    return Color.lerp(
      theme.colorScheme.onSurfaceVariant,
      theme.colorScheme.onPrimary,
      f,
    )!;
  }
}

class _BellWobble extends StatelessWidget {
  const _BellWobble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _LoopingAnimation(
      duration: const Duration(milliseconds: 1900),
      builder: (context, value) {
        final angle = math.sin(value * 2 * math.pi) * 0.16;
        return Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer,
          ),
          child: Transform.rotate(
            angle: angle,
            child: Icon(
              Icons.notifications_active_outlined,
              size: 27,
              color: scheme.onPrimaryContainer,
            ),
          ),
        );
      },
    );
  }
}

class _DoneCheck extends StatelessWidget {
  const _DoneCheck();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _LoopingAnimation(
      duration: const Duration(milliseconds: 1200),
      reverse: true,
      builder: (context, value) {
        final scale = 1.0 + 0.06 * math.sin(value * math.pi);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            child: Icon(Icons.check_rounded, size: 30, color: scheme.primary),
          ),
        );
      },
    );
  }
}
