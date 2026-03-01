import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/opportunity_card.dart';
import '../../widgets/freemium_gate.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = context.read<UserProvider>();
      await userProvider.loadProfile();
      if (mounted) {
        context.read<FeedProvider>().initialize(userProvider.plan);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBg,
      appBar: AppBar(
        backgroundColor: AppColors.voidBg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Feed',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            const LiveBadge(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3, color: AppColors.purpleBright, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: Consumer2<FeedProvider, UserProvider>(
              builder: (context, feedProvider, userProvider, child) {
                if (feedProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.purpleCore));
                }

                if (feedProvider.error != null) {
                  return Center(
                    child: Text(
                      'Error loading opportunities',
                      style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                    ),
                  );
                }

                final opportunities = feedProvider.opportunities;
                final isFree = userProvider.plan == 'free';

                return RefreshIndicator(
                  color: AppColors.purpleCore,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    await feedProvider.refresh(userProvider.plan);
                  },
                  child: opportunities.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(
                              child: Text(
                                'No active opportunities',
                                style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: opportunities.length,
                            itemBuilder: (context, index) {
                              final opportunity = opportunities[index];
                              final isLocked = isFree && opportunity.isDelayed;

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: FreemiumGate(
                                      isLocked: isLocked,
                                      child: OpportunityCard(
                                        opportunity: opportunity,
                                        isFeatured: index == 0,
                                        onTap: () {
                                          if (!isLocked) {
                                            context.push('/home/detail/${opportunity.id}');
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    const filters = ['All', 'Intra', 'Inter', 'Anomaly', '≥7pts'];
    final activeFilter = context.watch<FeedProvider>().activeFilter;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          // We map 'All' to 'all' for internal consistency with the provider
          final displayValue = filter;
          final bool isActive = (activeFilter == 'all' && displayValue == 'All') || activeFilter == displayValue;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                displayValue,
                style: GoogleFonts.spaceGrotesk(
                  color: isActive ? Colors.white : AppColors.textSecondarySolid,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isActive,
              onSelected: (selected) {
                if (selected) {
                  final providerValue = displayValue == 'All' ? 'all' : displayValue;
                  context.read<FeedProvider>().setFilter(providerValue);
                }
              },
              selectedColor: AppColors.purpleCore,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isActive ? AppColors.purpleBright : AppColors.borderColor,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}
