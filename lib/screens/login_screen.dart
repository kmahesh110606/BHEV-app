import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';

final authService = AuthService(backendBase);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final emailCodeCtrl = TextEditingController();

  bool isSignup = false;
  bool loading = false;
  bool verificationRequired = false;

  late final AnimationController _boltController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _boltController.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    emailCodeCtrl.dispose();
    super.dispose();
  }

  void _navigateByRole(Map<String, dynamic> res) {
    final user = res['user'] as Map<String, dynamic>?;
    final role = user != null ? (user['role'] ?? 'customer') : 'customer';
    if (!mounted) return;
    if (role == 'operator') {
      Navigator.pushReplacementNamed(context, '/operator');
    } else {
      Navigator.pushReplacementNamed(context, '/customer');
    }
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      if (isSignup) {
        final res = await authService.emailSignUp(
          emailCtrl.text.trim(),
          passwordCtrl.text,
          name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
        );
        if (!mounted) return;
        if (res['token'] != null) {
          _navigateByRole(res);
        } else if (res['needsVerification'] == true) {
          setState(() => verificationRequired = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification code sent to email')),
          );
        }
      } else {
        final res = await authService.emailLogin(
          emailCtrl.text.trim(),
          passwordCtrl.text,
        );
        _navigateByRole(res);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verifyEmail() async {
    setState(() => loading = true);
    try {
      final res = await authService.verifyEmail(
        emailCtrl.text.trim(),
        emailCodeCtrl.text.trim(),
      );
      _navigateByRole(res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _googlePressed() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Google sign-in will be wired in the next pass')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061A24), Color(0xFF063F4E), Color(0xFF0A7D74)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -40,
              child: _GlowBlob(
                  color: const Color(0xFF66F5C1).withValues(alpha: 0.24),
                  size: 180),
            ),
            Positioned(
              bottom: -80,
              right: -20,
              child: _GlowBlob(
                  color: const Color(0xFF4FD6FF).withValues(alpha: 0.22),
                  size: 220),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                    color: Colors.white.withValues(alpha: 0.08),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF62FFB4), Color(0xFF54C8FF)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF57E7C8)
                                    .withValues(alpha: 0.45),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            FluentIcons.flash_24_regular,
                            color: Color(0xFF04222A),
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CHARGEGRID',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'One API for connected EV charging networks.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (loading) ...[
                          LightningLoadingBar(animation: _boltController),
                          const SizedBox(height: 16),
                        ],
                        _AuthToggle(
                          isSignup: isSignup,
                          onChanged: (value) {
                            setState(() {
                              isSignup = value;
                              verificationRequired = false;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        if (isSignup) ...[
                          _StyledField(
                            controller: nameCtrl,
                            label: 'Full Name',
                            keyboardType: TextInputType.name,
                            icon: FluentIcons.person_24_regular,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _StyledField(
                          controller: emailCtrl,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          icon: FluentIcons.mail_24_regular,
                        ),
                        const SizedBox(height: 12),
                        _StyledField(
                          controller: passwordCtrl,
                          label: 'Password',
                          obscureText: true,
                          icon: FluentIcons.lock_closed_24_regular,
                        ),
                        if (isSignup) ...[
                          const SizedBox(height: 12),
                          _StyledField(
                            controller: emailCodeCtrl,
                            label: 'Email OTP code',
                            keyboardType: TextInputType.number,
                            icon: FluentIcons.checkmark_circle_24_regular,
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF63FFB8), Color(0xFF45BFFF)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4EE8CE)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: loading
                                    ? null
                                    : (isSignup && verificationRequired
                                        ? _verifyEmail
                                        : _submit),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      loading
                                          ? 'Please wait...'
                                          : isSignup
                                              ? (verificationRequired
                                                  ? 'Verify Email'
                                                  : 'Create Account')
                                              : 'Sign In',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFF041A21),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isSignup && !verificationRequired) ...[
                          const SizedBox(height: 10),
                          Text(
                            'We will send a one-time code to your email.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _OrDivider(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: loading ? null : _googlePressed,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              foregroundColor: Colors.white,
                            ),
                            icon: const _GoogleMark(),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isSignup = !isSignup;
                              verificationRequired = false;
                            });
                          },
                          child: Text(
                            isSignup
                                ? 'Already have an account? Sign in'
                                : 'Need an account? Sign up',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData icon;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: const Color(0xFF7DF7CF)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0xFF66FFD2), width: 1.4),
        ),
      ),
    );
  }
}

class _AuthToggle extends StatelessWidget {
  final bool isSignup;
  final ValueChanged<bool> onChanged;

  const _AuthToggle({required this.isSignup, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TogglePill(
              label: 'Sign in',
              active: !isSignup,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TogglePill(
              label: 'Sign up',
              active: isSignup,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TogglePill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF63FFB8) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF032129) : Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Colors.white24, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: TextStyle(
                  color: Colors.white60, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Divider(color: Colors.white24, thickness: 1)),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEA4335), width: 3),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const Positioned(
            right: 0,
            child:
                _GoogleColorBar(color: Color(0xFF4285F4), width: 9, height: 3),
          ),
          const Positioned(
            bottom: 0,
            child:
                _GoogleColorBar(color: Color(0xFF34A853), width: 11, height: 3),
          ),
          const Positioned(
            left: 0,
            child:
                _GoogleColorBar(color: Color(0xFFFBBC05), width: 3, height: 10),
          ),
        ],
      ),
    );
  }
}

class _GoogleColorBar extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _GoogleColorBar(
      {required this.color, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class LightningLoadingBar extends StatelessWidget {
  final Animation<double> animation;

  const LightningLoadingBar({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7BFFE2).withValues(alpha: 0.16),
                  const Color(0xFF47D9FF).withValues(alpha: 0.28),
                  const Color(0xFF7BFFE2).withValues(alpha: 0.16),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(-1.0 + (animation.value * 2.0), 0),
                  child: Transform.translate(
                    offset: const Offset(-10, 0),
                    child: const Icon(
                      FluentIcons.flash_24_regular,
                      color: Color(0xFF8CFFE2),
                      size: 18,
                      shadows: [
                        Shadow(color: Color(0xAA8CFFE2), blurRadius: 14)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 24)],
      ),
    );
  }
}
