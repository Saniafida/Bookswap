// lib/admin/screens/dashboard/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_stats_provider.dart';
import '../../providers/admin_user_provider.dart';
import '../../providers/admin_book_provider.dart';
import '../../providers/admin_report_provider.dart';
import '../../widgets/admin_stat_card.dart';
import '../../widgets/admin_section_header.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_loading.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStatsProvider>().fetchAll();
      context.read<AdminUserProvider>().fetchUsers(refresh: true);
      context.read<AdminBookProvider>().fetchBooks(refresh: true);
      context.read<AdminReportProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<AdminStatsProvider>();
    final userProvider = context.watch<AdminUserProvider>();
    final bookProvider = context.watch<AdminBookProvider>();
    final reportProvider = context.watch<AdminReportProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isLoading = statsProvider.isLoading && statsProvider.stats.totalUsers == 0;

    if (isLoading) {
      return const PageShimmer(itemCount: 6);
    }

    final stats = statsProvider.stats;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await statsProvider.fetchAll();
          await userProvider.fetchUsers(refresh: true);
          await bookProvider.fetchBooks(refresh: true);
          await reportProvider.fetchReports();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(isDark),
              const SizedBox(height: AppSizes.s28),
              _buildStatsGrid(stats),
              const SizedBox(height: AppSizes.s28),
              _buildAnalyticsCard(isDark),
              const SizedBox(height: AppSizes.s28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < AppSizes.tabletBreakpoint;
                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRecentActivity(userProvider, bookProvider, reportProvider, isDark),
                        const SizedBox(height: AppSizes.s24),
                        _buildQuickActionsCard(isDark),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildRecentActivity(userProvider, bookProvider, reportProvider, isDark)),
                        const SizedBox(width: AppSizes.s24),
                        Expanded(child: _buildQuickActionsCard(isDark)),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview Dashboard', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: AppSizes.s4),
              Text('Real-time metrics, analytics, and activities for BookSwap.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSizes.s8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: AppSizes.s6),
              Text('Live', style: GoogleFonts.poppins(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(dynamic stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (isMobile ? 1 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.s16,
          mainAxisSpacing: AppSizes.s16,
          childAspectRatio: constraints.maxWidth > 900 ? 1.6 : (isMobile ? 2.0 : 1.4),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AdminStatCard(title: 'Total Users', value: stats.totalUsers.toString(), icon: Icons.people_alt_rounded, iconColor: AppColors.primary, trend: '+14% this month', isPositive: true),
            AdminStatCard(title: 'Total Books Listed', value: stats.totalBooks.toString(), icon: Icons.menu_book_rounded, iconColor: AppColors.secondary, trend: '+8% this week', isPositive: true),
            AdminStatCard(title: 'Book Donations', value: stats.totalDonations.toString(), icon: Icons.volunteer_activism_rounded, iconColor: AppColors.success, trend: '+22% growth', isPositive: true),
            AdminStatCard(title: 'Book Exchanges', value: stats.totalExchanges.toString(), icon: Icons.sync_alt_rounded, iconColor: const Color(0xFF8B5CF6), trend: '+16% success', isPositive: true),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsCard(bool isDark) {
    return GlassCard(
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Growth & Listings Activity', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSizes.s2),
                  Text('Monthly chart mapping signup rate and active book uploads.', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12, vertical: AppSizes.s6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Text('Last 30 Days', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s28),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.4), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        switch (value.toInt()) { case 1: text = 'Week 1'; case 3: text = 'Week 2'; case 5: text = 'Week 3'; case 7: text = 'Week 4'; }
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text(text, style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 8, minY: 0, maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 1), FlSpot(1, 2.5), FlSpot(2, 2), FlSpot(3, 4.5), FlSpot(4, 3.8), FlSpot(5, 6.2), FlSpot(6, 5.5), FlSpot(7, 8), FlSpot(8, 9)],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                  LineChartBarData(
                    spots: const [FlSpot(0, 0.5), FlSpot(1, 1.2), FlSpot(2, 1.8), FlSpot(3, 2.4), FlSpot(4, 3.5), FlSpot(5, 4.2), FlSpot(6, 4.8), FlSpot(7, 5.6), FlSpot(8, 6.8)],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Color(0xFF8B5CF6).withValues(alpha: 0.1), Color(0xFF8B5CF6).withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AdminUserProvider up, AdminBookProvider bp, AdminReportProvider rp, bool isDark) {
    final List<_ActivityItem> activities = [];
    for (final user in up.users.take(3)) {
      activities.add(_ActivityItem(icon: Icons.person_add_rounded, color: AppColors.primary, title: 'New User Registered', subtitle: '${user.fullName} (${user.email}) signed up to BookSwap.', time: _formatDate(user.createdAt), timestamp: user.createdAt));
    }
    for (final book in bp.books.take(3)) {
      activities.add(_ActivityItem(icon: Icons.menu_book_rounded, color: AppColors.secondary, title: 'Book Listed for exchange', subtitle: '"${book.title}" was listed by ${book.ownerName ?? 'a user'}.', time: _formatDate(book.createdAt), timestamp: book.createdAt));
    }
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return GlassCard(
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: AppSizes.s10),
              Text('Live Activity Feed', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          if (activities.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSizes.s32), child: Text('No recent activities to show.', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted))))
          else
            ...activities.take(5).map((act) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: act.color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: act.color.withValues(alpha: 0.2))),
                    child: Icon(act.icon, color: act.color, size: AppSizes.iconSm),
                  ),
                  const SizedBox(width: AppSizes.s14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(act.title, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSizes.s2),
                        Text(act.subtitle, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Text(act.time, style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(bool isDark) {
    return GlassCard(
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 20, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: AppSizes.s10),
              Text('Quick Tasks', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          _buildQuickAction('Announcements Board', Icons.campaign_rounded, AppColors.warning, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Click Campaign on the sidebar to create system-wide banners.')));
          }),
          const SizedBox(height: AppSizes.s12),
          _buildQuickAction('Review Content Reports', Icons.flag_rounded, AppColors.error, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Click Flag on the sidebar to inspect reported posts/accounts.')));
          }),
          const SizedBox(height: AppSizes.s12),
          _buildQuickAction('Add New Category', Icons.category_rounded, AppColors.success, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Click Category on the sidebar to build dynamic book folders.')));
          }),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s14, vertical: AppSizes.s14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusXs)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(child: Text(label, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500))),
              Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMutedDark : AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final DateTime timestamp;
  const _ActivityItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time, required this.timestamp});
}
