import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBg,
      appBar: AppBar(
        backgroundColor: AppColors.voidBg,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final profile = userProvider.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(profile),
              const SizedBox(height: 32),
              _buildPlanCard(context, profile),
              const SizedBox(height: 32),
              _buildSectionTitle('SETTINGS'),
              const SizedBox(height: 12),
              _buildSettingTile(
                icon: CupertinoIcons.bell,
                title: 'Push Notifications',
                trailing: Switch(
                  value: profile.notificationsEnabled,
                  onChanged: (v) => userProvider.updateNotificationsEnabled(v),
                  activeTrackColor: AppColors.foxOrange.withValues(alpha: 0.3),
                  activeThumbColor: AppColors.foxOrange,
                ),
              ),
              _buildSettingTile(
                icon: CupertinoIcons.question_circle,
                title: 'Support',
                subtitle: 'info@zoomarketingdigital.com',
                onTap: () => launchUrl(Uri.parse('mailto:info@zoomarketingdigital.com'), mode: LaunchMode.externalApplication),
              ),
              _buildSettingTile(
                icon: CupertinoIcons.doc_text,
                title: 'Privacy Policy',
                onTap: () => launchUrl(Uri.parse('https://sites.google.com/view/privacypolicypolyfox/inicio'), mode: LaunchMode.externalApplication),
              ),
              _buildSettingTile(
                icon: CupertinoIcons.shield,
                title: 'Terms of Use (EULA)',
                onTap: () => launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'), mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 12),
              _buildSettingTile(
                icon: CupertinoIcons.trash,
                title: 'Delete Account',
                onTap: () => _showDeleteConfirmation(context),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: Text(
                  'Log Out',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.accentRed, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              profile.email[0].toUpperCase(),
              style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.email,
          style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Polyfox Member',
          style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, UserProfile profile) {
    final isPro = profile.plan != 'free';

    return GlassCard(
      padding: const EdgeInsets.all(24),
      hasGlow: isPro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Plan',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro ? AppColors.foxOrange : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isPro ? AppColors.foxOrangeBright : AppColors.borderColor),
                ),
                child: Text(
                  profile.plan.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPlanFeature('Real-time feed access', true),
          _buildPlanFeature('Unlimited personalized alerts', isPro),
          _buildPlanFeature('Full historical data (30d+)', isPro),
          _buildPlanFeature('Advanced power filters', isPro),
          const SizedBox(height: 24),
          if (!isPro)
            PrimaryButton(
              text: 'Upgrade to PRO — \$9.99/mo',
              onPressed: () => context.push('/paywall'),
              isFullWidth: true,
            )
          else
            OutlinedButton(
              onPressed: () {}, 
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Manage Subscription',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanFeature(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isActive ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
            color: isActive ? AppColors.accentGreen : AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              color: isActive ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.foxOrangeBright),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid, fontSize: 12),
            )
          : null,
      trailing: trailing ?? const Icon(CupertinoIcons.chevron_right, color: AppColors.textMuted),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and will delete all your data. Are you sure you want to proceed?'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              // Logic to delete account would go here
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
