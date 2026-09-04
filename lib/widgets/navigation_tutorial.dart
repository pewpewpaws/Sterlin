import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interactive first-run onboarding tutorial highlighting key navigation targets.
class NavigationTutorial {
  NavigationTutorial._();

  static final GlobalKey navBarKey = GlobalKey();
  static final GlobalKey bellKey = GlobalKey();
  static final GlobalKey attendanceKey = GlobalKey();

  static const String _seenKey = 'app_nav_tutorial_seen';
  static final Completer<void> _firstRunCompleter = Completer<void>();

  static Future<void> get waitForFirstRun => _firstRunCompleter.future;

  static void _completeFirstRun() {
    if (!_firstRunCompleter.isCompleted) _firstRunCompleter.complete();
  }

  static final ValueNotifier<int> lastTabIndex = ValueNotifier(-1);

  static void reportTab(int index) {
    NavigationTutorial.lastTabIndex.value = index;
  }

  static Future<void> maybeShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_seenKey) ?? false) {
        _completeFirstRun();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 800));
      await prefs.setBool(_seenKey, true);
      if (!context.mounted) return;
      show(context);
    } catch (_) {
      _completeFirstRun();
    }
  }

  static void show(BuildContext context) {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final overlayState = rootNav.overlay;
    if (overlayState == null) return;

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => _TutorialOverlay(
        onClose: () {
          entry?.remove();
          _completeFirstRun();
        },
      ),
    );
    overlayState.insert(entry);
  }
}

enum _StepTarget { dock, bell, attendance }

enum _StepAction { none, tapAttendance, glideToHome }

class _StepSpec {
  final String title;
  final String body;
  final WidgetBuilder? art;
  final _StepTarget target;
  final bool showOutline;
  final bool spotlight;
  final _StepAction action;

  const _StepSpec(
    this.title,
    this.body,
    this.art, {
    this.target = _StepTarget.dock,
    this.showOutline = true,
    this.spotlight = true,
    this.action = _StepAction.none,
  });
}

class _TutorialOverlay extends StatefulWidget {
  const _TutorialOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  double _cardHeight = 240;
  Rect? _dockRect;
  Rect? _bellRect;
  Rect? _attendanceRect;
  int _tabBaseline = -1;
  bool _advancing = false;

  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _moveC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final CurvedAnimation _moveCurved =
      CurvedAnimation(parent: _moveC, curve: Curves.easeInOutCubic);

  late RectTween _rectTween;
  late Tween<double> _topTween;
  late Tween<double> _borderTween;
  late Tween<double> _scrimTween;
  late Tween<double> _holeTween;

  static const List<_StepSpec> _steps = [
    _StepSpec(
      'Welcome to Sterlin!',
      'Everything lives behind this little dock at the bottom of the screen. Here is the 20-second tour.',
      null,
      spotlight: false,
      showOutline: false,
    ),
    _StepSpec(
      'Tap Attendance',
      'Tap the Attendance bubble on the dock to open your attendance overview.',
      null,
      target: _StepTarget.attendance,
      showOutline: true,
      spotlight: true,
      action: _StepAction.tapAttendance,
    ),
    _StepSpec(
      'Slide back to Home',
      'Drag sideways across the dock and glide back to Home.',
      null,
      target: _StepTarget.dock,
      showOutline: true,
      spotlight: true,
      action: _StepAction.glideToHome,
    ),
    _StepSpec(
      'Watch for absences',
      'This bell sits at the top corner of every page — tap it to see absences newly recorded in ETLab.',
      _buildBellArt,
      target: _StepTarget.bell,
      showOutline: true,
      spotlight: true,
    ),
    _StepSpec(
      "You're all set!",
      "That's the whole tour. You can replay it anytime from Settings.",
      _buildDoneArt,
      spotlight: false,
      showOutline: false,
    ),
  ];

  static Widget _buildBellArt(BuildContext context) => const _BellWobble();
  static Widget _buildDoneArt(BuildContext context) => const _DoneCheck();

  bool _hasHole(int step) => _steps[step].spotlight && step < _steps.length - 1;

  Rect _targetFor(int step) {
    switch (_steps[step].target) {
      case _StepTarget.bell:
        return _bellRect ?? _fallbackBellRect();
      case _StepTarget.attendance:
        return _attendanceRect ?? _fallbackAttendanceRect();
      case _StepTarget.dock:
        return _dockRect ?? _fallbackDockRect();
    }
  }

  Rect _fallbackDockRect() {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barTop = size.height - bottomInset - 20.0 - 104.0;
    return Rect.fromLTWH(12, barTop, size.width - 24, 134);
  }

  Rect _fallbackAttendanceRect() {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barTop = size.height - bottomInset - 20.0 - 104.0;
    return Rect.fromCenter(
      center: Offset(size.width / 2 + 66.0, barTop + 18.0 + 24.0),
      width: 48,
      height: 48,
    );
  }

  Rect _fallbackBellRect() {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    return Rect.fromLTWH(size.width - 62, topInset + 30, 42, 42);
  }

  double _topFor(int step, Size size) {
    if (!_steps[step].spotlight || step >= _steps.length - 1) {
      return math.max(16.0, (size.height - _cardHeight) / 2);
    }
    final target = _targetFor(step);
    if (_steps[step].target == _StepTarget.bell) {
      return math.min(
        target.bottom + 16,
        math.max(12.0, size.height - _cardHeight - 12),
      );
    }
    return math.max(target.top - 16 - _cardHeight, 12);
  }

  Rect _rectTargetFor(int step, Size size) {
    if (!_steps[step].spotlight || step >= _steps.length - 1) {
      return Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.longestSide * 0.75,
      );
    }
    return _targetFor(step);
  }

  @override
  void initState() {
    super.initState();
    final initialRect = Rect.fromCircle(center: Offset.zero, radius: 100);
    _rectTween = RectTween(begin: initialRect, end: initialRect);
    _topTween = Tween<double>(begin: 100, end: 100);
    _borderTween = Tween<double>(begin: 0, end: 0);
    _scrimTween = Tween<double>(begin: 1, end: 1);
    _holeTween = Tween<double>(begin: 0, end: 0);

    NavigationTutorial.lastTabIndex.addListener(_onTabSignal);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPosition());
  }

  void _initPosition() {
    if (!mounted) return;
    _measure();
    final size = MediaQuery.of(context).size;
    final cardH = _cardKey.currentContext?.size?.height;
    if (cardH != null && cardH > 0) _cardHeight = cardH;

    final targetRect = _rectTargetFor(0, size);
    final targetTop = _topFor(0, size);

    _rectTween = RectTween(begin: targetRect, end: targetRect);
    _topTween = Tween<double>(begin: targetTop, end: targetTop);
    _borderTween = Tween<double>(begin: 0.0, end: 0.0);
    _scrimTween = Tween<double>(begin: 1.0, end: 1.0);
    _holeTween = Tween<double>(begin: 0.0, end: 0.0);
    _tabBaseline = NavigationTutorial.lastTabIndex.value;

    setState(() {});
  }

  void _measure() {
    Rect? measure(GlobalKey key) {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final ro = ctx.findRenderObject();
      if (ro is RenderBox && ro.attached && ro.hasSize) {
        final topLeft = ro.localToGlobal(Offset.zero);
        final bottomRight = ro.localToGlobal(
          Offset(ro.size.width, ro.size.height),
        );
        return Rect.fromPoints(topLeft, bottomRight);
      }
      return null;
    }

    final dock = measure(NavigationTutorial.navBarKey);
    final bell = measure(NavigationTutorial.bellKey);
    final attendance = measure(NavigationTutorial.attendanceKey);
    if (dock != null) _dockRect = dock;
    if (bell != null) _bellRect = bell;
    if (attendance != null) _attendanceRect = attendance;
  }

  void _onTabSignal() {
    if (!mounted || _advancing) return;
    final spec = _steps[_step];
    if (spec.action == _StepAction.none) return;
    final value = NavigationTutorial.lastTabIndex.value;
    if (value < 0) return;

    if (spec.action == _StepAction.tapAttendance) {
      if (value != _tabBaseline) {
        _completeActionStep();
      }
    } else if (spec.action == _StepAction.glideToHome) {
      if (value == 1) {
        _completeActionStep();
      } else if (value != _tabBaseline) {
        _tabBaseline = value;
      }
    }
  }

  void _completeActionStep() {
    if (_advancing) return;
    _advancing = true;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _advancing = false;
      if (_steps[_step].action == _StepAction.none) return;
      _goToStep(_step + 1);
    });
  }

  void _goToStep(int step) {
    HapticFeedback.selectionClick();
    _measure();
    final cardH = _cardKey.currentContext?.size?.height;
    if (cardH != null && cardH > 0) _cardHeight = cardH;

    final size = MediaQuery.of(context).size;
    final isLast = step >= _steps.length - 1;

    final fromRect = _rectTween.evaluate(_moveCurved) ?? _targetFor(_step);
    final fromTop = _topTween.evaluate(_moveCurved);
    final fromBorder = _borderTween.evaluate(_moveCurved);
    final fromScrim = _scrimTween.evaluate(_moveCurved);
    final fromHole = _holeTween.evaluate(_moveCurved);

    final toRect = _rectTargetFor(step, size);
    final toTop = _topFor(step, size);
    final toBorder = isLast || !_steps[step].showOutline ? 0.0 : 1.0;
    final toScrim = isLast ? 0.0 : 1.0;
    final toHole = _hasHole(step) ? 1.0 : 0.0;

    _rectTween = RectTween(begin: fromRect, end: toRect);
    _topTween = Tween<double>(begin: fromTop, end: toTop);
    _borderTween = Tween<double>(begin: fromBorder, end: toBorder);
    _scrimTween = Tween<double>(begin: fromScrim, end: toScrim);
    _holeTween = Tween<double>(begin: fromHole, end: toHole);

    _tabBaseline = NavigationTutorial.lastTabIndex.value;
    setState(() => _step = step);

    _moveC.forward(from: 0);
  }

  void _next() {
    if (_step >= _steps.length - 1) {
      _close();
      return;
    }
    _goToStep(_step + 1);
  }

  void _back() {
    if (_step == 0) return;
    _goToStep(_step - 1);
  }

  void _close() {
    HapticFeedback.lightImpact();
    widget.onClose();
  }

  @override
  void dispose() {
    NavigationTutorial.lastTabIndex.removeListener(_onTabSignal);
    _moveC.dispose();
    _moveCurved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = _steps[_step].action != _StepAction.none;
    final currentTarget = _hasHole(_step) ? _targetFor(_step).inflate(12) : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, entrance, _) => Opacity(
        opacity: entrance,
        child: Stack(
          children: [
            // RepaintBoundary isolates canvas scrim rendering to GPU
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      animation: _moveCurved,
                      rectTween: _rectTween,
                      borderTween: _borderTween,
                      scrimTween: _scrimTween,
                      holeTween: _holeTween,
                    ),
                  ),
                ),
              ),
            ),
            // High-efficiency gesture barrier: passes through touches only inside active hole
            Positioned.fill(
              child: _HoleHitBlocker(
                hole: currentTarget,
                isInteractive: isInteractive,
              ),
            ),
            // Animated card position driven by topTween without rebuilding the card content
            AnimatedBuilder(
              animation: _moveCurved,
              builder: (context, child) {
                return Positioned(
                  left: 20,
                  right: 20,
                  top: _topTween.evaluate(_moveCurved),
                  child: child!,
                );
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: RepaintBoundary(
                    child: _buildCard(theme),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme) {
    final scheme = theme.colorScheme;
    final spec = _steps[_step];
    final isLast = _step == _steps.length - 1;
    final isAction = spec.action != _StepAction.none;

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
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
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
                if (spec.art != null) ...[
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: Center(child: spec.art!(context)),
                  ),
                  const SizedBox(height: 10),
                ],
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
                    child: isAction || _step == 0
                        ? TextButton(
                            onPressed: _close,
                            child: const Text('Skip'),
                          )
                        : TextButton.icon(
                            onPressed: _back,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
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
                    child: isAction
                        ? _WaitingPulse(color: scheme.primary)
                        : FilledButton.icon(
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

/// O(1) Gesture hit blocker using native RenderProxyBox.
/// Blocks all touches outside [hole]; passes through touches inside [hole].
class _HoleHitBlocker extends SingleChildRenderObjectWidget {
  final Rect? hole;
  final bool isInteractive;

  const _HoleHitBlocker({
    required this.hole,
    required this.isInteractive,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHoleHitBlocker(hole: hole, isInteractive: isInteractive);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHoleHitBlocker renderObject,
  ) {
    renderObject
      ..hole = hole
      ..isInteractive = isInteractive;
  }
}

class _RenderHoleHitBlocker extends RenderProxyBox {
  _RenderHoleHitBlocker({
    this.hole,
    required this.isInteractive,
  });

  Rect? hole;
  bool isInteractive;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If interactive action step and user tapped inside the target hole,
    // don't intercept — let the hit test pass through to the dock/button.
    if (isInteractive && hole != null && hole!.contains(position)) {
      return false;
    }
    // Block touch outside hole
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestSelf(Offset position) => true;
}

/// Hardware-accelerated spotlight painter using GPU even-odd winding rule.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.animation,
    required this.rectTween,
    required this.borderTween,
    required this.scrimTween,
    required this.holeTween,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final RectTween rectTween;
  final Tween<double> borderTween;
  final Tween<double> scrimTween;
  final Tween<double> holeTween;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final hole = rectTween.transform(t);
    if (hole == null) return;

    final borderScale = borderTween.transform(t);
    final scrimScale = scrimTween.transform(t);
    final holeStrength = holeTween.transform(t);

    final full = Offset.zero & size;
    final effective = Rect.lerp(full, hole, holeStrength.clamp(0.0, 1.0))!;
    final isCircular = (effective.width - effective.height).abs() < 20.0 &&
        effective.width < 120.0;
    final pad = isCircular ? 8.0 : 12.0;
    final inflated = effective.inflate(pad);
    final radius = isCircular
        ? Radius.circular(inflated.shortestSide / 2)
        : Radius.circular(math.min(30.0, inflated.shortestSide * 0.38));
    final rrect = RRect.fromRectAndRadius(inflated, radius);

    final scrimPaint = Paint()
      ..color = Colors.black.withAlpha((160 * scrimScale).round());

    if (holeStrength <= 0.001) {
      canvas.drawRect(full, scrimPaint);
    } else {
      // GPU even-odd winding rule — hardware accelerated without CPU polygon difference
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(full)
        ..addRRect(rrect);
      canvas.drawPath(path, scrimPaint);
    }

    if (borderScale > 0.01) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Colors.white.withAlpha((50 * borderScale).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withAlpha((240 * borderScale).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) => false;
}

class _WaitingPulse extends StatefulWidget {
  final Color color;
  const _WaitingPulse({required this.color});

  @override
  State<_WaitingPulse> createState() => _WaitingPulseState();
}

class _WaitingPulseState extends State<_WaitingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: 0.45 + 0.55 * _c.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_downward_rounded, size: 16, color: widget.color),
            const SizedBox(width: 4),
            Text(
              'Your turn',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BellWobble extends StatefulWidget {
  const _BellWobble();

  @override
  State<_BellWobble> createState() => _BellWobbleState();
}

class _BellWobbleState extends State<_BellWobble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final angle = math.sin(_c.value * 2 * math.pi) * 0.16;
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

class _DoneCheck extends StatefulWidget {
  const _DoneCheck();

  @override
  State<_DoneCheck> createState() => _DoneCheckState();
}

class _DoneCheckState extends State<_DoneCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final scale = 1.0 + 0.06 * math.sin(_c.value * math.pi);
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
