import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';

/// Authentication screen supporting Email/Password Login, Registration, and Role selection
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController(text: 'operator@chargegrid.in');
  final _loginPasswordController = TextEditingController(text: 'Operator@2026');

  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  String _selectedRole = 'customer'; // 'customer' or 'operator'
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Please enter both email and password');
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.login(email: email, password: password);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else if (mounted) {
      _showSnackbar(auth.errorMessage ?? 'Login failed. Please check credentials.');
    }
  }

  Future<void> _handleRegister() async {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text.trim();
    final confirm = _signupConfirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Please enter valid email and password');
      return;
    }

    if (password.length < 8) {
      _showSnackbar('Password must be at least 8 characters long');
      return;
    }

    if (password != confirm) {
      _showSnackbar('Passwords do not match');
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.register(
      email: email,
      password: password,
      name: name.isNotEmpty ? name : 'EV Driver',
      role: _selectedRole,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else if (mounted) {
      _showSnackbar(auth.errorMessage ?? 'Registration failed. Try again.');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Brand Icon & Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                    ),
                    child: const Icon(FluentIcons.flash_24_filled, color: AppColors.emerald, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URJAA',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.03,
                        ),
                      ),
                      Text(
                        'Unified Open EV Network',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Tab Switcher
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Create Account'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tab Views
              SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Tab 1: Sign In ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to access discovery, live sessions, or CPO console.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _loginEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(FluentIcons.mail_24_regular, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _loginPasswordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(FluentIcons.lock_closed_24_regular, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? FluentIcons.eye_24_regular : FluentIcons.eye_off_24_regular, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Demo credentials hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Demo CPO: operator@chargegrid.in / Operator@2026',
                            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ),
                        const Spacer(),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleLogin,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Sign In to URJAA'),
                          ),
                        ),
                      ],
                    ),

                    // ── Tab 2: Create Account ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Your Account',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),

                        // Role Selector Cards
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedRole = 'customer'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == 'customer' ? AppColors.emerald.withOpacity(0.15) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedRole == 'customer' ? AppColors.emerald : AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(FluentIcons.vehicle_car_profile_24_filled,
                                          color: _selectedRole == 'customer' ? AppColors.emerald : AppColors.textTertiary, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        'EV Driver',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedRole == 'customer' ? AppColors.emerald : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedRole = 'operator'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == 'operator' ? AppColors.sky.withOpacity(0.15) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedRole == 'operator' ? AppColors.sky : AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(FluentIcons.building_24_filled,
                                          color: _selectedRole == 'operator' ? AppColors.sky : AppColors.textTertiary, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Station Operator',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedRole == 'operator' ? AppColors.sky : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _signupNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(FluentIcons.person_24_regular, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _signupEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(FluentIcons.mail_24_regular, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _signupPasswordController,
                          obscureText: _obscurePassword,
                          decoration: const InputDecoration(
                            labelText: 'Password (min 8 chars)',
                            prefixIcon: Icon(FluentIcons.lock_closed_24_regular, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _signupConfirmPasswordController,
                          obscureText: _obscurePassword,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(FluentIcons.lock_closed_24_regular, size: 20),
                          ),
                        ),
                        const Spacer(),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleRegister,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : Text(_selectedRole == 'operator' ? 'Register as Station Operator' : 'Create Driver Account'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
