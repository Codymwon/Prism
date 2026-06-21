import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../providers/auth_provider.dart';

class AccountRegistrationScreen extends ConsumerStatefulWidget {
  final bool isRegisterMode;
  final VoidCallback? onSkip;

  const AccountRegistrationScreen({
    super.key,
    this.isRegisterMode = true,
    this.onSkip,
  });

  @override
  ConsumerState<AccountRegistrationScreen> createState() =>
      _AccountRegistrationScreenState();
}

class _AccountRegistrationScreenState
    extends ConsumerState<AccountRegistrationScreen> {
  late bool _isRegisterMode;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.isRegisterMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final authNotifier = ref.read(authProvider.notifier);

    if (_isRegisterMode) {
      final res = await authNotifier.signUpWithEmail(email, password);
      res.fold(
        (failure) => _showError(failure.message),
        (user) => _handleSuccess(),
      );
    } else {
      final res = await authNotifier.loginWithEmail(email, password);
      res.fold(
        (failure) => _showError(failure.message),
        (user) => _handleSuccess(),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    final res = await ref.read(authProvider.notifier).loginWithGoogle();
    res.fold(
      (failure) => _showError(failure.message),
      (user) => _handleSuccess(),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleSuccess() {
    if (!mounted) return;
    context.go('/notes');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = DesignColors.text(context);
    final textSecStyle = DesignColors.textSecondary(context);
    final cardBorder = DesignColors.border(context);

    final title = _isRegisterMode ? 'Create Prism Account' : 'Sign In to Prism';
    final buttonLabel = _isRegisterMode ? 'Register' : 'Sign In';
    final toggleLabel = _isRegisterMode
        ? 'Already have an account? Sign In'
        : 'Don\'t have an account? Register';

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(DesignIcons.back, color: textStyle),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          if (_isRegisterMode && widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Skip for now',
                style: DesignTypography.details(
                  context,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: DesignTypography.display(
                    context,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textStyle,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Prism Account keeps your subscription benefits active and syncs your encrypted vault.',
                  style: DesignTypography.body(
                    context,
                    fontSize: 14,
                    color: textSecStyle,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: DesignTypography.body(context, color: textStyle),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: DesignColors.surfaceVariant(context),
                    hintText: 'Email Address',
                    hintStyle: DesignTypography.body(
                      context,
                      color: DesignColors.textTertiary(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignSpacing.borderRadiusMedium,
                      ),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignSpacing.borderRadiusMedium,
                      ),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!val.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: DesignTypography.body(context, color: textStyle),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: DesignColors.surfaceVariant(context),
                    hintText: 'Password',
                    hintStyle: DesignTypography.body(
                      context,
                      color: DesignColors.textTertiary(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignSpacing.borderRadiusMedium,
                      ),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignSpacing.borderRadiusMedium,
                      ),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  DesignPrimaryButton(
                    label: buttonLabel,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'OR',
                      style: DesignTypography.details(
                        context,
                        color: DesignColors.textTertiary(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TactileWrapper(
                    onTap: _loginWithGoogle,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: DesignColors.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(
                          DesignSpacing.borderRadiusMedium,
                        ),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.g_mobiledata_rounded,
                            size: 28,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Continue with Google',
                            style: DesignTypography.heading(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                    });
                  },
                  child: Text(
                    toggleLabel,
                    style: DesignTypography.body(
                      context,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
