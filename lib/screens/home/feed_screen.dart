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
    final activeFilter = context.watch<FeedProvider>().activeFilter;
    String title = 'Feed';
    if (activeFilter == 'Free') title = 'Free';
    if (activeFilter == 'Pro') title = 'Premium';

    return Scaffold(
      backgroundColor: AppColors.voidBg,
      appBar: AppBar(
        backgroundColor: AppColors.voidBg,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        titleSpacing: context.canPop() ? 0 : 16,
        title: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const LiveBadge(),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(context),
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

                return RefreshIndicator(
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
                            padding: const EdgeInsets.all(16),
                            itemCount: opportunities.length,
                            itemBuilder: (context, index) {
                              final opportunity = opportunities[index];
                              // MODELO FREEMIUM ACTUALIZADO:
                              // Free (< 3.0%): Visible para todos.
                              // Pro (>= 3.1%): Bloqueado para usuarios gratuitos.
                              final isLocked = isFree && opportunity.deltaPoints >= 3.1;

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: FreemiumGate(
                                      isLocked: isLocked,
                                      delta: opportunity.deltaPoints,
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
    const filters = ['All', 'Free', 'Pro'];
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
}
