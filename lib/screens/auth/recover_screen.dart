import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(_emailController.text.trim());
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'RECOVER ACCESS',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We will send recovery instructions to your email.',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondarySolid,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildTextField(
              label: 'Email',
              hint: 'name@example.com',
              controller: _emailController,
            ),
            const SizedBox(height: 32),
            if (!_sent)
              PrimaryButton(
                text: 'Send Instructions',
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : () => _handleRecover(),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.accentGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If the email is registered, you will receive a link in a few minutes.',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
          style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
