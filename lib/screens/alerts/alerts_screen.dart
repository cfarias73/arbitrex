import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/freemium_gate.dart';
import '../../providers/user_provider.dart';
import '../../models/alert.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
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
        centerTitle: ResponsiveLayout.isDesktop(context),
        title: Text(
          'Alerts',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.alerts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ResponsiveLayout.constrained(
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionTitle('CONFIGURED'),
                const SizedBox(height: 12),
                if (userProvider.alerts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No alerts configured yet',
                        style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...userProvider.alerts.map((alert) => Dismissible(
                        key: Key(alert.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.accentRed.withValues(alpha: 0.2),
                          child: const Icon(CupertinoIcons.delete, color: AppColors.accentRed),
                        ),
                        onDismissed: (_) => userProvider.deleteAlert(alert.id),
                        child: _buildAlertTile(context, alert, userProvider),
                      )),
                const SizedBox(height: 32),
                _buildSectionTitle('RECENT NOTIFICATIONS'),
                const SizedBox(height: 12),
                _buildNotificationTile('Harris wins PA', 'Detected 2m ago • Delta 12.5', true),
                _buildNotificationTile('BTC hits 100k', 'Detected 15m ago • Delta 11.2', true),
                _buildNotificationTile('Fed hawkish Q2', 'Detected 30m ago • Delta 10.8', false),
              ],
            ),
            width: ResponsiveLayout.maxFeedWidth,
          );
        },
      ),
      floatingActionButton: ResponsiveLayout.constrained(
        Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            onPressed: () => _showNewAlertSheet(context),
            backgroundColor: AppColors.foxOrange,
            child: const Icon(CupertinoIcons.add, color: Colors.white, size: 32),
          ),
        ),
        width: ResponsiveLayout.maxFeedWidth,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, PolyfoxAlert alert, UserProvider provider) {
    Color iconColor;
    IconData icon;
    switch (alert.type) {
      case AlertType.typeA:
        iconColor = AppColors.foxOrangeBright;
        icon = CupertinoIcons.bolt_fill;
        break;
      case AlertType.typeB:
        iconColor = AppColors.accentCyan;
        icon = CupertinoIcons.graph_square_fill;
        break;
      case AlertType.typeC:
        iconColor = AppColors.accentAmber;
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.name,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
                Text(
                  alert.description,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondarySolid, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: alert.isEnabled,
            onChanged: (val) => provider.toggleAlert(alert.id, val),
            activeColor: AppColors.foxOrange,
            activeTrackColor: AppColors.foxOrange.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(String title, String subtitle, bool isRead) {
    return Opacity(
      opacity: isRead ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              isRead ? CupertinoIcons.checkmark_circle : CupertinoIcons.circle_fill,
              color: isRead ? AppColors.textMuted : AppColors.accentGreen,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewAlertSheet(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final isLocked = !userProvider.isPro && userProvider.alerts.length >= 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: AppColors.borderColor, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'New Alert',
                style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 32),
              Text(
                'OPPORTUNITY TYPE',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ToggleButtons(
                isSelected: const [true, false, false],
                onPressed: (i) {},
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: AppColors.foxOrange,
                color: AppColors.textSecondarySolid,
                borderColor: AppColors.borderColor,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('INTRA')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('INTER')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ANOMALY')),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'THRESHOLD (DELTA PTS)',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  const Icon(CupertinoIcons.add, color: AppColors.foxOrangeBright, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: 7.0,
                min: 3.0,
                max: 15.0,
                divisions: 12,
                onChanged: (v) {},
                activeColor: AppColors.foxOrange,
                inactiveColor: AppColors.borderColor,
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Save Alert',
                onPressed: () async {
                  final success = await userProvider.createAlert(
                    PolyfoxAlert(
                      id: '',
                      name: 'Alert Delta 7',
                      description: 'Notify when delta > 7 pts',
                      type: AlertType.typeA,
                      categories: [],
                      threshold: 7.0,
                    )
                  );
                  if (mounted) Navigator.pop(context);
                },
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
