import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Rect? _displayRect;
  double? _displayTop;
  double _borderScale = 0.0;
  double _scrimScale = 1.0;
  double _holeStrength = 0.0;
  double _cardHeight = 260;
  Rect? _dockRect;
  Rect? _bellRect;
  Rect? _attendanceRect;
  int _tabBaseline = -1;
  bool _advancing = false;

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
      showOutline: false,
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

  @override
  void initState() {
    super.initState();
    _moveC.addListener(_onMoveTick);
    NavigationTutorial.lastTabIndex.addListener(_onTabSignal);
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
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _advancing = false;
      if (_steps[_step].action == _StepAction.none) return;
      _goToStep(_step + 1);
    });
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
        _tabBaseline = NavigationTutorial.lastTabIndex.value;
      });
    });
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
    if (!mounted || (dock == null && bell == null && attendance == null)) return;
    setState(() {
      if (dock != null) _dockRect = dock;
      if (bell != null) _bellRect = bell;
      if (attendance != null) _attendanceRect = attendance;
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
      _measure();
      final h = _cardKey.currentContext?.size?.height;
      if (h != null && h > 0) _cardHeight = h;
      final size = MediaQuery.of(context).size;
      final isLast = step >= _steps.length - 1;
      final toRect = _rectTargetFor(step, size);
      final toTop = _topFor(step, size);
      final toBorder = isLast || !_steps[step].showOutline ? 0.0 : 1.0;
      final toScrim = isLast ? 0.0 : 1.0;
      final toHole = _hasHole(step) ? 1.0 : 0.0;
      _tabBaseline = NavigationTutorial.lastTabIndex.value;

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
          (fromRect.center.dx - toRect.center.dx).abs() > 1.0 ||
          (fromTop - toTop).abs() > 1.0 ||
          (fromBorder - toBorder).abs() > 0.01 ||
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

  List<Widget> _blockers(Size size) {
    Widget block(Rect r) => Positioned.fromRect(
          rect: r,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        );

    final interactive = _steps[_step].action != _StepAction.none;
    final rect = _displayRect;
    if (!interactive || rect == null || !_hasHole(_step)) {
      return [block(Rect.fromLTWH(0, 0, size.width, size.height))];
    }

    final hole = rect.inflate(12);
    final w = size.width;
    final h = size.height;
    return [
      block(Rect.fromLTWH(0, 0, w, math.max(0, hole.top))),
      block(Rect.fromLTWH(0, hole.bottom, w, math.max(0, h - hole.bottom))),
      block(Rect.fromLTWH(0, hole.top, math.max(0, hole.left), hole.height)),
      block(
        Rect.fromLTWH(
          hole.right,
          hole.top,
          math.max(0, w - hole.right),
          hole.height,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final rect = _displayRect;
    final top = _displayTop;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, entrance, _) => Opacity(
        opacity: entrance,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: rect == null
                      ? null
                      : _SpotlightPainter(
                          hole: rect,
                          borderScale: _borderScale,
                          scrimScale: _scrimScale,
                          holeStrength: _holeStrength,
                        ),
                ),
              ),
            ),
            ..._blockers(size),
            if (rect != null && top != null)
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
                    child: isAction
                        ? TextButton(
                            onPressed: _close,
                            child: const Text('Skip'),
                          )
                        : (_step == 0
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
                                )),
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
    final isCircular =
        (effective.width - effective.height).abs() < 20.0 && effective.width < 120.0;
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
      final scrim = Path()..addRect(full);
      final cutout = Path()..addRRect(rrect);
      canvas.drawPath(
        Path.combine(PathOperation.difference, scrim, cutout),
        scrimPaint,
      );
    }

    if (borderScale > 0.01) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = Colors.white.withAlpha((60 * borderScale).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Colors.white.withAlpha((240 * borderScale).round()),
      );
    }
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
