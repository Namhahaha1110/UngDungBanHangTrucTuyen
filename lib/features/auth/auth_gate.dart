import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/shop_repository.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_shell_wrapper.dart';
import '../shop/shop_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return AuthFlow(authService: authService);
        }

        // Check if user is admin
        return FutureBuilder<bool>(
          future: ShopRepository(FirebaseFirestore.instance).isAdmin(user.uid),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isAdmin = adminSnapshot.data ?? false;
            final firestore = FirebaseFirestore.instance;
            final repository = ShopRepository(firestore);

            if (isAdmin) {
              // Route admin users to admin shell wrapper
              return AdminShellWrapper(
                authService: authService,
                user: user,
                repository: repository,
              );
            }

            // Route regular users to ShopShell
            return ShopShell(
              authService: authService,
              user: user,
            );
          },
        );
      },
    );
  }
}

enum _AuthStage {
  start,
  signIn,
  signUp,
  forgotPassword,
  resetSent,
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({required this.authService, super.key});

  final AuthService authService;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  _AuthStage _stage = _AuthStage.start;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    await _runAuthAction(() async {
      await widget.authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    });
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.trim() != _confirmController.text.trim()) {
      setState(() {
        _errorText = 'Mật khẩu xác nhận chưa khớp.';
      });
      return;
    }

    await _runAuthAction(() async {
      await widget.authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    });
  }

  Future<void> _submitForgotPassword() async {
    if (!_forgotFormKey.currentState!.validate()) return;
    await _runAuthAction(() async {
      await widget.authService.sendPasswordResetEmail(
        _forgotEmailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _stage = _AuthStage.resetSent;
      });
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorText = _mapAuthError(error);
      });
    } catch (_) {
      setState(() {
        _errorText = 'Có lỗi xảy ra. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng, hoặc tài khoản này chưa được tạo trong project hiện tại.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'account-exists-with-different-credential':
        return 'Email này đã đăng ký bằng phương thức khác.';
      case 'credential-already-in-use':
        return 'Thông tin đăng nhập này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhanh. Hãy thử lại sau.';
      case 'network-request-failed':
        return 'Không kết nối được tới Firebase. Kiểm tra mạng rồi thử lại.';
      default:
        final fallback = error.message ?? 'Có lỗi xảy ra. Vui lòng thử lại.';
        if (!kDebugMode) return fallback;
        return '$fallback [${error.code}]';
    }
  }

  void _switchStage(_AuthStage stage) {
    setState(() {
      _stage = stage;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_stage) {
            _AuthStage.start => _StartView(
                key: const ValueKey('start'),
                onLogin: () => _switchStage(_AuthStage.signIn),
                onRegister: () => _switchStage(_AuthStage.signUp),
                onForgotPassword: () => _switchStage(_AuthStage.forgotPassword),
              ),
            _AuthStage.signIn => _CredentialView(
                key: const ValueKey('signIn'),
                title: 'Đăng nhập',
                subtitle: 'Đăng nhập để tiếp tục mua sắm và theo dõi đơn hàng.',
                primaryLabel: 'Đăng nhập',
                secondaryLabel: 'Tạo tài khoản',
                emailController: _emailController,
                passwordController: _passwordController,
                formKey: _formKey,
                isSubmitting: _isSubmitting,
                errorText: _errorText,
                onBackPressed: () => _switchStage(_AuthStage.start),
                onPrimaryPressed: _submitSignIn,
                onSecondaryPressed: () => _switchStage(_AuthStage.signUp),
                onForgotPassword: () => _switchStage(_AuthStage.forgotPassword),
              ),
            _AuthStage.signUp => _CredentialView(
                key: const ValueKey('signUp'),
                title: 'Đăng ký',
                subtitle: 'Tạo tài khoản mới để lưu yêu thích và giỏ hàng.',
                primaryLabel: 'Tạo tài khoản',
                secondaryLabel: 'Đã có tài khoản',
                emailController: _emailController,
                passwordController: _passwordController,
                confirmController: _confirmController,
                formKey: _formKey,
                isSubmitting: _isSubmitting,
                errorText: _errorText,
                onBackPressed: () => _switchStage(_AuthStage.start),
                onPrimaryPressed: _submitRegister,
                onSecondaryPressed: () => _switchStage(_AuthStage.signIn),
              ),
            _AuthStage.forgotPassword => _ForgotPasswordView(
                key: const ValueKey('forgotPassword'),
                formKey: _forgotFormKey,
                emailController: _forgotEmailController,
                isSubmitting: _isSubmitting,
                errorText: _errorText,
                onBack: () => _switchStage(_AuthStage.signIn),
                onSubmit: _submitForgotPassword,
              ),
            _AuthStage.resetSent => _ResetSentView(
                key: const ValueKey('resetSent'),
                email: _forgotEmailController.text.trim(),
                onBackToLogin: () => _switchStage(_AuthStage.signIn),
              ),
          },
        ),
      ),
    );
  }
}

class _StartView extends StatelessWidget {
  const _StartView({
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(23, 40, 23, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 120),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E8),
                borderRadius: BorderRadius.circular(40),
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Shoppe',
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mua sắm thoả thích',
            style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Đăng ký'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Đăng nhập'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onForgotPassword,
            child: const Text('Quên mật khẩu?'),
          ),
        ],
      ),
    );
  }
}

class _CredentialView extends StatelessWidget {
  const _CredentialView({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.isSubmitting,
    required this.errorText,
    required this.onBackPressed,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    this.onForgotPassword,
    this.confirmController,
    super.key,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? confirmController;
  final GlobalKey<FormState> formKey;
  final bool isSubmitting;
  final String? errorText;
  final VoidCallback onBackPressed;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: key,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 81,
              padding: const EdgeInsets.fromLTRB(21, 26, 21, 0),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: onBackPressed,
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 39, 23, 24),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E8),
                      borderRadius: BorderRadius.circular(39),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (onForgotPassword != null) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _AuthField(
                          controller: emailController,
                          hintText: 'Email/Số điện thoại/Tên đăng nhập',
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),
                        _AuthField(
                          controller: passwordController,
                          hintText: 'Mật khẩu',
                          obscureText: true,
                          validator: _validatePassword,
                          icon: Icons.lock_outline_rounded,
                        ),
                        if (confirmController != null) ...[
                          const SizedBox(height: 20),
                          _AuthField(
                            controller: confirmController!,
                            hintText: 'Nhập lại mật khẩu',
                            obscureText: true,
                            validator: _validatePassword,
                            icon: Icons.lock_outline_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : onPrimaryPressed,
                      child: Text(primaryLabel),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Hoặc',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SocialButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: onForgotPassword != null
                        ? 'Tiếp tục với Google'
                        : 'Đăng ký bằng Google',
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: Icons.facebook_rounded,
                    label: onForgotPassword != null
                        ? 'Tiếp tục với Facebook'
                        : 'Đăng ký bằng Facebook',
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: Icons.apple_rounded,
                    label: onForgotPassword != null
                        ? 'Tiếp tục với Apple'
                        : 'Đăng ký bằng Apple',
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: isSubmitting ? null : onSecondaryPressed,
                    child: Text(
                      onForgotPassword != null
                          ? 'Bạn chưa có tài khoản? Đăng ký ngay'
                          : 'Bạn đã có tài khoản? Đăng nhập ngay',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Vui lòng nhập email.';
    if (!input.contains('@')) return 'Email không hợp lệ.';
    return null;
  }

  String? _validatePassword(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (input.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    return null;
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView({
    required this.formKey,
    required this.emailController,
    required this.isSubmitting,
    required this.errorText,
    required this.onBack,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isSubmitting;
  final String? errorText;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: key,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 81,
            padding: const EdgeInsets.fromLTRB(21, 26, 21, 0),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  'Đặt lại mật khẩu',
                  style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(23, 120, 23, 24),
            child: Column(
              children: [
                Form(
                  key: formKey,
                  child: _AuthField(
                    controller: emailController,
                    hintText: 'Email/Số điện thoại',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) return 'Vui lòng nhập email.';
                      if (!input.contains('@')) return 'Email không hợp lệ.';
                      return null;
                    },
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Số điện thoại đã thay đổi?'),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  child: const Text('Tiếp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetSentView extends StatelessWidget {
  const _ResetSentView({
    required this.email,
    required this.onBackToLogin,
    super.key,
  });

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đã gửi liên kết đặt lại mật khẩu',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Kiểm tra email $email để tiếp tục. Sau khi đổi mật khẩu xong, đăng nhập lại trong app.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onBackToLogin,
            child: const Text('Quay lại đăng nhập'),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hintText,
    required this.validator,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                validator: validator,
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: Color(0xFF1A1A1A)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}
