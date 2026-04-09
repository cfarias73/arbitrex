import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_layout.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Spot Arbitrage Opportunities',
      subtitle: 'Real-time detection of probability inefficiencies across prediction markets.',
      image: 'assets/images/Logos.png',
      accentTitle: 'Spot',
    ),
    OnboardingData(
      title: 'Unmatched Reliability',
      subtitle: 'Data-driven insights you can trust, with 24/7 monitoring and high-precision alerts.',
      image: 'assets/images/Logos.png',
      accentTitle: 'Reliability',
    ),
    OnboardingData(
      title: 'Pure Simplicity',
      subtitle: 'Complex market intelligence simplified into actionable alerts. No trading, just edge.',
      image: 'assets/images/onboarding_3.png',
      accentTitle: 'Simplicity',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return _buildPage(data);
            },
          ),
          Positioned(
            top: 60,
            right: 0,
            left: 0,
            child: ResponsiveLayout.constrained(
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      'SKIP',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              width: ResponsiveLayout.maxFeedWidth,
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: ResponsiveLayout.constrained(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (index) => _buildIndicator(index == _currentPage),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildButton(),
                  ],
                ),
              ),
              width: ResponsiveLayout.maxFeedWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.foxOrange.withValues(alpha: 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(data.image, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 48),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: AppColors.textPrimary,
                ),
                children: _getSplitTitle(data.title, data.accentTitle),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              data.subtitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: AppColors.textSecondarySolid,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 100), // Space for bottom controls
        ],
      ),
    );
  }

  List<TextSpan> _getSplitTitle(String title, String accent) {
    final parts = title.split(accent);
    return [
      if (parts[0].isNotEmpty) TextSpan(text: parts[0]),
      TextSpan(text: accent, style: const TextStyle(color: AppColors.foxOrangeBright)),
      if (parts.length > 1) TextSpan(text: parts[1]),
    ];
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.foxOrange : AppColors.surface,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildButton() {
    final bool isLastPage = _currentPage == _onboardingData.length - 1;
    return GestureDetector(
      onTap: () {
        if (isLastPage) {
          context.go('/');
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutQuart,
          );
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.foxOrange.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastPage ? 'GET STARTED' : 'NEXT',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String image;
  final String accentTitle;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.accentTitle,
  });
}
