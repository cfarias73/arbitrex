import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../services/analytics_service.dart';
import '../../services/purchase_service.dart';
import '../../providers/user_provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlanIndex = 0; // 0 for Pro, 1 for Plus
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logViewPaywall();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await PurchaseService.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (_offerings == null) return;
    
    final currentOffering = _offerings!.current;
    if (currentOffering == null) return;

    final package = _selectedPlanIndex == 0 
        ? currentOffering.monthly 
        : currentOffering.annual;

    if (package == null) return;

    setState(() => _isPurchasing = true);

    try {
      final success = await PurchaseService.purchasePackage(package);
      if (success) {
        if (mounted) {
          // Refresh user profile to reflect pro plan
          await context.read<UserProvider>().loadProfile();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Welcome to Polyfox Pro!')),
            );
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBg,
      body: Stack(
        children: [
          // Background Gradient Circles for Glassmorphism effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.foxOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.foxOrange)))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          _buildHeroSection(),
                          const SizedBox(height: 24),
                          _buildFeaturesList(),
                          const SizedBox(height: 24),
                          _buildPlanOptions(context),
                          const SizedBox(height: 32),
                          _buildLegalLinks(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isPurchasing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator(color: AppColors.foxOrange)),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _isPurchasing = true);
              final success = await PurchaseService.restorePurchases();
              if (mounted) {
                setState(() => _isPurchasing = false);
                if (success) {
                  await context.read<UserProvider>().loadProfile();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Purchases restored successfully!')),
                    );
                    context.pop();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No active subscriptions found.')),
                  );
                }
              }
            },
            child: Text(
              'Restore',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondarySolid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.foxOrange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.bolt_fill,
            color: AppColors.foxOrange,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Go Pro',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Automate your arbitrage strategy\nand never miss a signal again.',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            color: AppColors.textSecondarySolid,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeatureItem(CupertinoIcons.infinite, 'Unlimited Signals', 'Access all delta opportunities > 3%'),
        _buildFeatureItem(CupertinoIcons.bell_fill, 'Priority Alerts', 'Push notifications for every match'),
        _buildFeatureItem(CupertinoIcons.chart_bar_square_fill, 'Advanced Stats', 'Volume analysis and history'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.foxOrangeBright, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOptions(BuildContext context) {
    final currentOffering = _offerings?.current;
    if (currentOffering == null) return const SizedBox.shrink();

    final monthlyPkg = currentOffering.monthly;
    final yearlyPkg = currentOffering.annual;

    return Column(
      children: [
        if (monthlyPkg != null)
          GestureDetector(
            onTap: () => setState(() => _selectedPlanIndex = 0),
            child: _buildPlanCard(
              'Trader Pro',
              monthlyPkg.storeProduct.priceString,
              'per month',
              'Most Popular',
              _selectedPlanIndex == 0,
            ),
          ),
        const SizedBox(height: 12),
        if (yearlyPkg != null)
          GestureDetector(
            onTap: () => setState(() => _selectedPlanIndex = 1),
            child: _buildPlanCard(
              'Trader Plus',
              yearlyPkg.storeProduct.priceString,
              'per year',
              'Best Value - Save 20%',
              _selectedPlanIndex == 1,
            ),
          ),
      ],
    );
  }

  Widget _buildPlanCard(String title, String price, String period, String tag, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.foxOrange.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.foxOrange : AppColors.borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.foxOrange.withValues(alpha: 0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: isSelected ? AppColors.foxOrange : AppColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                period,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Column(
      children: [
        PrimaryButton(
          text: 'Subscribe Now',
          onPressed: _handlePurchase,
          isFullWidth: true,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLinkLabel('Privacy Policy', 'https://sites.google.com/view/privacypolicypolyfox/inicio'),
            const SizedBox(width: 8),
            Text('•', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(width: 8),
            _buildLinkLabel('Terms of Use (EULA)', 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkLabel(String text, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.textMuted,
          fontSize: 10,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

