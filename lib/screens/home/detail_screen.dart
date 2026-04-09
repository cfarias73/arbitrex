import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
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
        body: Center(child: CircularProgressIndicator(color: AppColors.foxOrange)),
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

    // For type_b we use a completely different layout
    if (opportunity.type == 'type_b') {
      return _buildCrossDetailScreen(opportunity);
    }

    return _buildIntraDetailScreen(opportunity);
  }

  // ═══════════════════════════════════════════════
  //  CROSS-EXCHANGE DETAIL (type_b) — COMPLETELY SEPARATE UI
  // ═══════════════════════════════════════════════
  Widget _buildCrossDetailScreen(Opportunity opportunity) {
    // Parse the structured JSON explanation
    Map<String, dynamic>? crossData;
    try {
      crossData = jsonDecode(opportunity.explanation);
    } catch (_) {
      crossData = null;
    }

    final pmTitle = crossData?['pm_title'] ?? opportunity.displayTitle;
    final pmBuy = crossData?['pm_buy'] ?? 'YES';
    final pmPrice = (crossData?['pm_price'] as num?)?.toDouble() ?? 0.0;
    final ksTitle = crossData?['ks_title'] ?? 'Kalshi Market';
    final ksBuy = crossData?['ks_buy'] ?? 'NO';
    final ksPrice = (crossData?['ks_price'] as num?)?.toDouble() ?? 0.0;
    // Base 100 for display
    final pmPrice100 = pmPrice * 100;
    final ksPrice100 = ksPrice * 100;
    final totalCost100 = pmPrice100 + ksPrice100;
    final profit100 = 100.0 - totalCost100;

    final query = Uri.encodeComponent(pmTitle);
    final polyUrl = 'https://polymarket.com/markets?query=$query';
    final kalshiQuery = Uri.encodeComponent(ksTitle.toString().split(',').first);
    final kalshiUrl = 'https://kalshi.com/search/$kalshiQuery';

    return Scaffold(
      backgroundColor: AppColors.voidBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Arbitraje Cross-Exchange',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── PROFIT HEADER ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentGreen.withValues(alpha: 0.15),
                        AppColors.accentGreen.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+${opportunity.deltaPoints.toStringAsFixed(1)}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 40, fontWeight: FontWeight.w900,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PROFIT GARANTIZADO POR OPERACIÓN',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.accentGreen, letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── VISUAL TWO-COLUMN DIAGRAM ──
                Text(
                  '¿QUÉ TIENES QUE HACER?',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Step 1: Polymarket
                _buildStepCard(
                  stepNumber: '1',
                  platformName: 'POLYMARKET',
                  platformColor: const Color(0xFF6366F1),
                  action: 'Compra $pmBuy',
                  price: '\$${pmPrice100.toStringAsFixed(0)}',
                  marketTitle: pmTitle,
                  buttonLabel: 'Abrir en Polymarket',
                  onTap: () => _launchUrl(polyUrl),
                ),
                
                // Connector arrow
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: const Icon(CupertinoIcons.add, color: AppColors.textMuted, size: 20),
                  ),
                ),

                // Step 2: Kalshi
                _buildStepCard(
                  stepNumber: '2',
                  platformName: 'KALSHI',
                  platformColor: const Color(0xFFF59E0B),
                  action: 'Compra $ksBuy',
                  price: '\$${ksPrice100.toStringAsFixed(0)}',
                  marketTitle: ksTitle,
                  buttonLabel: 'Abrir en Kalshi',
                  onTap: () => _launchUrl(kalshiUrl),
                ),

                const SizedBox(height: 20),

                // ── COST SUMMARY ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'RESUMEN DE LA OPERACIÓN',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Costo en Polymarket ($pmBuy)', '\$${pmPrice100.toStringAsFixed(1)}'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Costo en Kalshi ($ksBuy)', '\$${ksPrice100.toStringAsFixed(1)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.borderColor, height: 1),
                      ),
                      _buildSummaryRow('Inversión total', '\$${totalCost100.toStringAsFixed(1)}', bold: true),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Pago garantizado', '\$100.00', bold: true),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Ganancia neta',
                        '\$${profit100.toStringAsFixed(1)} (${opportunity.deltaPoints.toStringAsFixed(1)}%)',
                        bold: true,
                        valueColor: AppColors.accentGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── HOW IT WORKS ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.lightbulb, color: AppColors.accentCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '¿POR QUÉ FUNCIONA?',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.accentCyan, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ambas plataformas cubren el mismo evento. Comprando "$pmBuy" en Polymarket y "$ksBuy" en Kalshi, cubres ambos resultados posibles. Sin importar quién gane, una de las dos posiciones paga \$100. Como el costo combinado es menor a \$100, la diferencia es tu ganancia garantizada.',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary, fontSize: 14, height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── METADATA ──
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaItem('DETECTADO', opportunity.timeAgo),
                      _buildMetaItem('TIPO', 'CROSS-EXCHANGE'),
                      _buildMetaItem('DELTA', '+${opportunity.deltaPoints.toStringAsFixed(1)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Copy title button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: opportunity.displayTitle));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Título copiado al portapapeles'),
                          backgroundColor: AppColors.accentGreen,
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.doc_on_clipboard, color: AppColors.textPrimary, size: 18),
                    label: Text(
                      'Copiar título',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderColor, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String platformName,
    required Color platformColor,
    required String action,
    required String price,
    required String marketTitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: platformColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: platformColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: platformColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                platformName,
                style: GoogleFonts.spaceGrotesk(
                  color: platformColor, fontSize: 13,
                  fontWeight: FontWeight.w800, letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      marketTitle.length > 80 ? '${marketTitle.substring(0, 80)}...' : marketTitle,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondarySolid, fontSize: 13, height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                price,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: platformColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textSecondarySolid,
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  INTRA-POLYMARKET DETAIL (type_a) — ORIGINAL UI (UNTOUCHED)
  // ═══════════════════════════════════════════════
  Widget _buildIntraDetailScreen(Opportunity opportunity) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
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
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TypeChip(type: opportunity.type),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Giant profit estimation
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.foxOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.foxOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.sparkles, color: AppColors.foxOrange, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${opportunity.deltaPoints.toStringAsFixed(1)}% PROFIT ESTIMADO',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.foxOrange,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Retorno proyectado tras ejecución en polymarket.',
                              style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Responsive probabilities and chart
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _buildProbabilitySection(opportunity)),
                      const SizedBox(width: 32),
                      Expanded(flex: 1, child: _buildChartSection(opportunity)),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProbabilitySection(opportunity),
                      const SizedBox(height: 32),
                      _buildChartSection(opportunity),
                    ],
                  ),
                
                const SizedBox(height: 32),
                _buildExplanationSection(opportunity),
                const SizedBox(height: 24),
                _buildExecutionCard(opportunity),
                const SizedBox(height: 24),
                _buildOmissionRiskWarning(),
                const SizedBox(height: 32),
                _buildMetadataRow(opportunity),
                const SizedBox(height: 48),
                _buildActionButtons(opportunity),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProbabilitySection(Opportunity opportunity) {
    final probYes = (opportunity.market?['prob_yes'] as num?)?.toDouble() ?? 0.0;
    final probNo = (opportunity.market?['prob_no'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        _buildProbBar(label: 'Prob. YES', value: probYes, color: AppColors.foxOrange),
        const SizedBox(height: 16),
        _buildProbBar(label: 'Prob. NO', value: probNo, color: AppColors.accentCyan),
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
            Text(label, style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid, fontSize: 12)),
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
            minHeight: 10,
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
                  color: AppColors.foxOrange,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.foxOrange.withValues(alpha: 0.1),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.doc_text_viewfinder, color: AppColors.textSecondarySolid, size: 20),
              const SizedBox(width: 8),
              Text(
                'EXPLICACIÓN DEL MERCADO',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            opportunity.explanation,
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionCard(Opportunity opportunity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.check_mark_circled_solid, size: 20, color: AppColors.accentGreen),
              const SizedBox(width: 10),
              Text(
                'PLAN DE EJECUCIÓN (BASE 100)',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.accentGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Compra el NO en ABSOLUTAMENTE TODAS las opciones.',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary, fontSize: 18, height: 1.4, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Aseguras \$100 con una inversión total aproximada de \$${(100 - opportunity.deltaPoints).toStringAsFixed(1)}.',
              style: GoogleFonts.spaceGrotesk(color: AppColors.accentGreen, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOmissionRiskWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 20, color: Colors.orange),
              const SizedBox(width: 10),
              Text(
                'RIESGO DE OMISIÓN',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Las opciones baratas (1% - 3%) son tu seguro. Si omites comprar el NO en estas opciones para "ahorrar", te arriesgas a perder toda tu inversión si ocurre el evento improbable.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.orange.shade100, fontSize: 14, height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(Opportunity opportunity) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMetaItem('DETECTED', opportunity.timeAgo),
          _buildMetaItem('MODE', opportunity.subtype.toUpperCase()),
          _buildMetaItem('DELTA', '+${opportunity.deltaPoints.toStringAsFixed(1)}'),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  Widget _buildActionButtons(Opportunity opportunity) {
    final query = Uri.encodeComponent(opportunity.displayTitle);
    final polyAutoSearchUrl = 'https://polymarket.com/markets?query=$query';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => _launchUrl(polyAutoSearchUrl),
            icon: const Icon(CupertinoIcons.search, color: Colors.white),
            label: Text(
              'Buscar en Polymarket',
              style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: opportunity.displayTitle));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Título copiado al portapapeles'),
                  backgroundColor: AppColors.accentGreen,
                ),
              );
            },
            icon: const Icon(CupertinoIcons.doc_on_clipboard, color: AppColors.textPrimary),
            label: Text(
              'Copiar título',
              style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderColor, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
