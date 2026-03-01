import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../providers/user_provider.dart';
import '../../mock/mock_data.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _period = '7d';

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
          'Analytics',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPeriodSelector(userProvider.isPro),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: StatCard(label: 'TOTAL', value: '47', subtext: 'this week')),
                    SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'MAGNITUDE', value: '6.2', subtext: 'avg pts')),
                  ],
                ),
                const SizedBox(height: 12),
                const StatCard(label: 'CONVERGENCE', value: '2.4h', subtext: 'avg time to close'),
                const SizedBox(height: 32),
                _buildChartSection(),
                const SizedBox(height: 32),
                _buildTopCategories(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(bool isPro) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '7d', label: Text('7d')),
        ButtonSegment(value: '30d', label: Text('30d')),
        ButtonSegment(value: 'All', label: Text('All')),
      ],
      selected: {_period},
      onSelectionChanged: (Set<String> newSelection) {
        final val = newSelection.first;
        if (val != '7d' && !isPro) {
          _showProGate();
        } else {
          setState(() => _period = val);
        }
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surface,
        selectedBackgroundColor: AppColors.purpleCore,
        selectedForegroundColor: Colors.white,
        foregroundColor: AppColors.textSecondarySolid,
        side: const BorderSide(color: AppColors.borderColor),
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY OPPORTUNITIES',
          style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 25,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          days[value.toInt() % 7],
                          style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: (MockData.stats['dailyBarData'] as List<double>).asMap().entries.map((e) {
                final isToday = e.key == 6;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      gradient: LinearGradient(
                        colors: [AppColors.purpleCore, isToday ? AppColors.purpleBright : AppColors.purpleCore.withValues(alpha: 0.5)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 25,
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategories() {
    final categories = MockData.stats['topCategories'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOP CATEGORIES',
          style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        ...categories.map((cat) {
            String catName = cat['name'];
            if (catName == 'Política') catName = 'Politics';
            if (catName == 'Deportes') catName = 'Sports';
            if (catName == 'Cripto') catName = 'Crypto';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      catName,
                      style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${cat['count']} op.',
                      style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: cat['value'],
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purpleBright),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showProGate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('PRO Feature', style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
        content: Text('Complete historical analysis is only available for PRO users.', style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood')),
        ],
      ),
    );
  }
}
