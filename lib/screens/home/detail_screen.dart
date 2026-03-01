import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../models/opportunity.dart';
import '../../widgets/type_chip.dart';
import '../../providers/feed_provider.dart';

class DetailScreen extends StatefulWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Opportunity? _opportunity;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOpportunity();
  }

  Future<void> _loadOpportunity() async {
    final feedProvider = context.read<FeedProvider>();
    try {
      _opportunity = feedProvider.opportunities.firstWhere((o) => o.id == widget.id);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      try {
        final data = await Supabase.instance.client
            .from('opportunities')
            .select('*, market:market_id_1(title, category, prob_yes, prob_no)')
            .eq('id', widget.id)
            .single();
        
        if (mounted) {
          setState(() {
            _opportunity = Opportunity.fromJson(data);
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Error loading opportunity';
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.voidBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.purpleCore)),
      );
    }

    if (_error != null || _opportunity == null) {
      return Scaffold(
        backgroundColor: AppColors.voidBg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text(
            _error ?? 'Opportunity not found',
            style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final opportunity = _opportunity!;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    opportunity.displayTitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TypeChip(type: opportunity.type),
              ],
            ),
            const SizedBox(height: 24),
            _buildProbabilitySection(opportunity),
            const SizedBox(height: 32),
            _buildChartSection(opportunity),
            const SizedBox(height: 32),
            _buildExplanationSection(opportunity),
            const SizedBox(height: 32),
            _buildMetadataRow(opportunity),
            const SizedBox(height: 48),
            _buildActionButtons(context),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(CupertinoIcons.bell_fill, color: AppColors.textSecondarySolid),
                label: Text(
                  'CREATE ALERT',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilitySection(Opportunity opportunity) {
    final probYes = (opportunity.market?['prob_yes'] as num?)?.toDouble() ?? 0.0;
    final probNo = (opportunity.market?['prob_no'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        _buildProbBar(
          label: 'Prob. YES',
          value: probYes,
          color: AppColors.purpleCore,
        ),
        const SizedBox(height: 16),
        _buildProbBar(
          label: 'Prob. NO',
          value: probNo,
          color: AppColors.accentCyan,
        ),
      ],
    );
  }

  Widget _buildProbBar({required String label, required double value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid, fontSize: 12),
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(Opportunity opportunity) {
    if (opportunity.deltaHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DELTA HISTORY',
          style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: opportunity.deltaHistory.asMap().entries.map((e) {
                    final val = (e.value['delta'] as num?)?.toDouble() ?? 0.0;
                    return FlSpot(e.key.toDouble(), val);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.purpleCore,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.purpleCore.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationSection(Opportunity opportunity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purpleCore.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: const Border(
          left: BorderSide(color: AppColors.purpleCore, width: 4),
        ),
      ),
      child: Text(
        opportunity.explanation,
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.textSecondarySolid,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(Opportunity opportunity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetaItem('CURRENT DELTA', '+${opportunity.deltaPoints.toStringAsFixed(1)} pts'),
        _buildMetaItem('DETECTED AGO', opportunity.timeAgo),
        _buildMetaItem('MODE', opportunity.subtype.toUpperCase()),
      ],
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildOutlinedButton(
            'View on Polymarket',
            () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Polymarket...'))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOutlinedButton(
            'View on Kalshi',
            () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Kalshi...'))),
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinedButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
