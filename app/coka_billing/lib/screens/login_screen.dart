import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coka_logo_badge.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _animController.reset();
    _animController.forward();
  }

  void _submit(AppProvider provider) {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_isLogin) {
      provider.loginWithFirebaseOrLocal(email, password);
    } else {
      provider.registerWithFirebaseOrLocal(email, password);
    }
  }

  void _showFirebaseConfig(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              provider.isFirebaseConfigured ? Icons.cloud_done : Icons.cloud_off,
              color: provider.isFirebaseConfigured ? AppColors.successGreen : AppColors.errorRed,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Firebase Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _configRow('Configured', provider.isFirebaseConfigured ? 'Yes' : 'No',
                provider.isFirebaseConfigured ? AppColors.successGreen : AppColors.errorRed),
            const SizedBox(height: 8),
            _configRow('Auth Provider', 'Email/Password + Google'),
            const SizedBox(height: 8),
            _configRow('Database', 'Local SQLite (fallback)'),
            const SizedBox(height: 8),
            _configRow('Sync', provider.isCloudSynced ? 'Auto' : 'Manual'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cokaAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cokaAmber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.cokaAmber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firebase not configured. Using local database for now.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _configRow(String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(value, style: TextStyle(fontSize: 13, color: valueColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CokaLogoBadge(size: 72, showText: true),
                        const SizedBox(height: 16),
                        Text(
                          'COKA BILLING',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'COIMBATORE ORIGINAL KAALAN ADDA',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Firebase Status Strip
                        GestureDetector(
                          onTap: () => _showFirebaseConfig(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: provider.isFirebaseConfigured
                                  ? AppColors.successGreen.withValues(alpha: 0.1)
                                  : AppColors.cokaAmber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: provider.isFirebaseConfigured
                                    ? AppColors.successGreen.withValues(alpha: 0.3)
                                    : AppColors.cokaAmber.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.isFirebaseConfigured ? Icons.cloud_done : Icons.cloud_off,
                                  size: 16,
                                  color: provider.isFirebaseConfigured ? AppColors.successGreen : AppColors.cokaAmber,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  provider.isFirebaseConfigured ? 'Firebase Connected' : 'Firebase Not Configured',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: provider.isFirebaseConfigured ? AppColors.successGreen : AppColors.cokaAmber,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.tap_and_play, size: 14,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Toggle Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLogin ? null : _toggleMode,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _isLogin ? theme.colorScheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Sign In',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _isLogin ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLogin ? _toggleMode : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_isLogin ? theme.colorScheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Register',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: !_isLogin ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please enter your email';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please enter your password';
                                  if (v.length < 4) return 'Password must be at least 4 characters';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error / Success Messages
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildStatusMessage(provider, theme),
                        ),
                        const SizedBox(height: 16),

                        // Login / Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: provider.isFirebaseLoading ? null : () => _submit(provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: provider.isFirebaseLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dark mode toggle
                        TextButton.icon(
                          onPressed: () => provider.toggleDarkMode(),
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            size: 18,
                          ),
                          label: Text(
                            isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (provider.isFirebaseLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Please wait...', style: TextStyle(fontSize: 14)),
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

  Widget? _buildStatusMessage(AppProvider provider, ThemeData theme) {
    final error = provider.loginError;
    final success = provider.registrationSuccess;
    if (error == null && success == null) return const SizedBox.shrink(key: ValueKey('empty'));

    if (error != null) {
      return Container(
        key: ValueKey(error),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(error, style: const TextStyle(color: AppColors.errorRed, fontSize: 13))),
          ],
        ),
      );
    }

    return Container(
      key: ValueKey(success),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(success!, style: const TextStyle(color: AppColors.successGreen, fontSize: 13))),
        ],
      ),
    );
  }
}
