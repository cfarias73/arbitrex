import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_layout.dart';
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
    final activeFilter = context.watch<FeedProvider>().activeFilter;
    String title = 'Live Feed';
    if (activeFilter == 'Free') title = 'Free Ops';
    if (activeFilter == 'Pro') title = 'Alpha Ops';
    if (activeFilter == 'Cross') title = 'Cross Platform';

    return Scaffold(
      backgroundColor: AppColors.voidBg,
      appBar: AppBar(
        backgroundColor: AppColors.voidBg,
        elevation: 0,
        centerTitle: ResponsiveLayout.isDesktop(context),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        titleSpacing: context.canPop() ? 0 : 24,
        title: ResponsiveLayout.constrained(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 12),
              const LiveBadge(),
            ],
          ),
          width: ResponsiveLayout.maxFeedWidth,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ResponsiveLayout.constrained(
            _buildFilters(context),
            width: ResponsiveLayout.maxFeedWidth,
          ),
          const SizedBox(height: 8),
          ResponsiveLayout.constrained(
            _buildTimeFilters(context),
            width: ResponsiveLayout.maxFeedWidth,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer2<FeedProvider, UserProvider>(
              builder: (context, feedProvider, userProvider, child) {
                if (feedProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.foxOrange));
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

                return ResponsiveLayout.constrained(
                  RefreshIndicator(
                    color: AppColors.foxOrange,
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              itemCount: opportunities.length,
                              itemBuilder: (context, index) {
                                final opportunity = opportunities[index];
                                // final isLocked = isFree && opportunity.deltaPoints >= 3.1;
                                const isLocked = false; // FORCE UNLOCK FOR DESIGN REVIEW

                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: OpportunityCard(
                                        opportunity: opportunity,
                                        isFeatured: index == 0,
                                        onTap: () {
                                          context.push('/home/detail/${opportunity.id}');
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  width: ResponsiveLayout.maxFeedWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    const filters = ['All', 'Free', 'Pro', 'Cross'];
    final activeFilter = context.watch<FeedProvider>().activeFilter;

    return Center(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          shrinkWrap: true, // Crucial para centrar
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // Evita scroll si no es necesario
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final bool isActive = (activeFilter == 'all' && filter == 'All') || activeFilter == filter;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  filter.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: isActive ? Colors.white : AppColors.textSecondarySolid,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) {
                    final providerValue = filter == 'All' ? 'all' : filter;
                    context.read<FeedProvider>().setFilter(providerValue);
                  }
                },
                selectedColor: AppColors.foxOrange,
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isActive ? AppColors.foxOrangeBright : AppColors.borderColor,
                  ),
                ),
                showCheckmark: false,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeFilters(BuildContext context) {
    const timeFilters = [
      {'key': 'all', 'label': 'TODAS'},
      {'key': '7d', 'label': '≤ 7 DÍAS'},
      {'key': '90d', 'label': '≤ 90 DÍAS'},
      {'key': '90d+', 'label': '+90 DÍAS'},
    ];
    final activeTime = context.watch<FeedProvider>().timeFilter;

    return Center(
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: timeFilters.length,
          itemBuilder: (context, index) {
            final filter = timeFilters[index];
            final bool isActive = activeTime == filter['key'];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  context.read<FeedProvider>().setTimeFilter(filter['key']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentCyan.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? AppColors.accentCyan : AppColors.borderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filter['label']!,
                      style: GoogleFonts.spaceGrotesk(
                        color: isActive ? AppColors.accentCyan : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
