import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/etlab_api_service.dart';
import '../services/theme_service.dart';

import 'main_navigation_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = false;
    try {
      success = await EtlabApiService().login(
        subdomain: 'sctce',
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        hostelId: '0',
      );
    } catch (e) {
      if (!mounted) return;
      _fail(e.toString().replaceAll('Exception: ', ''));
      return;
    }

    if (!mounted) return;

    if (success) {
      // Trigger OS Password Manager save prompt (Google Password Manager / iOS Keychain)
      TextInput.finishAutofillContext();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } else {
      _fail('Login failed. Please check your credentials.');
    }
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  InputDecoration _fieldDecoration(
    ThemeData theme,
    String hint, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final dark = theme.brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: .7),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: dark
          ? Colors.white.withValues(alpha: .05)
          : Colors.black.withValues(alpha: .035),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand mark
                    _Entrance(
                      index: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: .9,
                                  ),
                                  theme.colorScheme.tertiary.withValues(
                                    alpha: .9,
                                  ),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Sterlin',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your day at a glance.\nAttendance without anxiety.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 38),

                    // Error
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _errorMessage == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withValues(
                                      alpha: .3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: theme.colorScheme.error,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),

                    // Fields
                    _Entrance(
                      index: 1,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              style: theme.textTheme.bodyLarge,
                              decoration: _fieldDecoration(
                                theme,
                                'Register number',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'Enter your register number'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              keyboardType: TextInputType.visiblePassword,
                              onFieldSubmitted: (_) =>
                                  _isLoading ? null : _handleLogin(),
                              style: theme.textTheme.bodyLarge,
                              decoration: _fieldDecoration(
                                theme,
                                'Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter your password'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Submit
                    _Entrance(
                      index: 2,
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .1,
                              fontFamily: ThemeService.uiFontFamily,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isLoading
                                ? SizedBox(
                                    key: const ValueKey('spinner'),
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Row(
                                    key: ValueKey('label'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Sign in'),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Entrance(
                      index: 3,
                      slide: 10,
                      child: Text(
                        'Uses your ETLab credentials · sctce.etlab.in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: .7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet fade-and-rise entrance so the page settles in gently.
class _Entrance extends StatefulWidget {
  final int index;
  final double slide;
  final Widget child;

  const _Entrance({required this.index, required this.child, this.slide = 20});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * 60).clamp(0, 240);
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 450 + delayMs),
    );
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(delayMs / (450 + delayMs), 1, curve: Curves.easeOutCubic),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) {
        final t = _a.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.slide),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
