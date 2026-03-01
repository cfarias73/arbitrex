import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _registrationSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _registrationSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.voidBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Create Account',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join the elite circle of arbitrage traders',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: AppColors.textSecondarySolid,
              ),
            ),
            const SizedBox(height: 48),
            if (!_registrationSuccess) ...[
              _buildTextField(
                label: 'Email',
                hint: 'name@example.com',
                controller: _emailController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Password',
                hint: '••••••••',
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Confirm Password',
                hint: '••••••••',
                isPassword: true,
                controller: _confirmPasswordController,
              ),
              if (authProvider.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  authProvider.error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.accentRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Sign Up',
                isFullWidth: true,
                isLoading: authProvider.isLoading,
                onPressed: authProvider.isLoading ? null : () => _handleRegister(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.mail_solid, color: AppColors.accentGreen, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Registration Successful!',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a confirmation link to your email. Please verify it to log in.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondarySolid,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Back to Log In',
                      onPressed: () => context.pop(),
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!_registrationSuccess)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Log In',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondarySolid,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textSecondarySolid,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
