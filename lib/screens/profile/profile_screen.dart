import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
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
                  activeTrackColor: AppColors.purpleCore.withValues(alpha: 0.3),
                  activeThumbColor: AppColors.purpleCore,
                ),
              ),
              _buildSettingTile(
                icon: CupertinoIcons.square_grid_2x2,
                title: 'Favorite Categories',
                subtitle: profile.favoriteCategories.isEmpty 
                  ? 'None selected' 
                  : profile.favoriteCategories.join(', '),
              ),
              _buildSettingTile(
                icon: CupertinoIcons.question_circle,
                title: 'Support',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: CupertinoIcons.info,
                title: 'About Arbitrex',
                subtitle: 'Version 1.2.0 (Phase 2)',
                onTap: () {},
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
          'Arbitrex Member',
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
                  color: isPro ? AppColors.purpleCore : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isPro ? AppColors.purpleBright : AppColors.borderColor),
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
              onPressed: () => _showUpgradeSheet(context),
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
      leading: Icon(icon, color: AppColors.purpleBright),
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

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Text(
              'Choose your plan',
              style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 32),
            _buildUpgradeOption(context, 'Trader Pro', '\$9.99/mo', true),
            const SizedBox(height: 12),
            _buildUpgradeOption(context, 'Trader Plus', '\$19.99/mo', false),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeOption(BuildContext context, String title, String price, bool isRecommended) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isRecommended ? AppColors.purpleCore : AppColors.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
                Text(
                  price,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid, fontSize: 13),
                ),
              ],
            ),
            const Icon(CupertinoIcons.bolt_fill, color: AppColors.purpleBright, size: 20),
          ],
        ),
      ),
    );
  }
}
