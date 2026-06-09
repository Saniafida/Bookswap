import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_stats_provider.dart';
import '../../widgets/admin_section_header.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_loading.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStatsProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminStatsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: provider.isLoading && provider.bookStats.isEmpty
          ? const PageShimmer(itemCount: 3)
          : RefreshIndicator(
              onRefresh: provider.fetchAll,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSizes.pagePaddingLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSectionHeader(
                      title: 'Advanced Analytics',
                      subtitle: 'Visual distributions, platform performance metrics, and inventory analysis.',
                    ),
                    SizedBox(height: AppSizes.s24),
                    if (provider.bookStats.isEmpty && provider.categoryStats.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.s64),
                          child: Column(
                            children: [
                              Icon(Icons.analytics_outlined, size: AppSizes.iconXl, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                              SizedBox(height: AppSizes.s16),
                              Text('No data collected yet', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildListingTypePieChart(provider.bookStats, isDark)),
                                SizedBox(width: AppSizes.s20),
                                Expanded(child: _buildCategoryBarChart(provider.categoryStats, isDark)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildListingTypePieChart(provider.bookStats, isDark),
                                SizedBox(height: AppSizes.s20),
                                _buildCategoryBarChart(provider.categoryStats, isDark),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(height: AppSizes.s24),
                      _buildMetricsSummaryTable(provider, isDark),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildListingTypePieChart(Map<String, int> bookStats, bool isDark) {
    if (bookStats.isEmpty) {
      return GlassCard(
        height: 320,
        child: Center(child: Text('No listing data', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted))),
      );
    }

    final total = bookStats.values.fold<int>(0, (sum, val) => sum + val);

    final colors = {
      'swap': AppColors.primary,
      'sell': const Color(0xFF8B5CF6),
      'donate': AppColors.success,
      'both': AppColors.warning,
    };

    final sections = bookStats.entries.map((e) {
      final value = e.value.toDouble();
      final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0';
      return PieChartSectionData(
        color: colors[e.key] ?? AppColors.info,
        value: value,
        title: '$percentage%',
        radius: 40,
        titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      );
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 500;

    return GlassCard(
      height: isMobile ? 360 : 320,
      padding: EdgeInsets.all(isMobile ? AppSizes.s16 : AppSizes.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: AppSizes.iconSm),
              ),
              SizedBox(width: AppSizes.s12),
              Text('Listing Types Distribution', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: AppSizes.s20),
          Expanded(
            child: isMobile
                ? Column(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: sections,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSizes.s16),
                      Wrap(
                        spacing: AppSizes.s12,
                        runSpacing: AppSizes.s6,
                        children: bookStats.keys.map((k) {
                          final color = colors[k] ?? AppColors.info;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              SizedBox(width: AppSizes.s6),
                              Text('${k.toUpperCase()} (${bookStats[k]})', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: sections,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.s16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: bookStats.keys.map((k) {
                          final color = colors[k] ?? AppColors.info;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSizes.s4),
                            child: Row(
                              children: [
                                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                SizedBox(width: AppSizes.s8),
                                Text('${k.toUpperCase()} (${bookStats[k]})', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart(Map<String, int> categoryStats, bool isDark) {
    if (categoryStats.isEmpty) {
      return GlassCard(
        height: 320,
        child: Center(child: Text('No category data', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted))),
      );
    }

    final sorted = categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topList = sorted.take(5).toList();

    final barGroups = List.generate(topList.length, (index) {
      final val = topList[index].value.toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: val,
            color: AppColors.primary,
            width: 16,
            borderRadius: BorderRadius.circular(AppSizes.radiusXs),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: val * 1.2 == 0 ? 10 : val * 1.2,
              color: isDark ? AppColors.bgSurfaceDark : AppColors.divider,
            ),
          ),
        ],
      );
    });

    return GlassCard(
      height: 320,
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: AppSizes.iconSm),
              ),
              SizedBox(width: AppSizes.s12),
              Text('Top Categories Popularity', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: AppSizes.s24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (topList.map((e) => e.value).fold<int>(0, (max, v) => v > max ? v : max) * 1.2).toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (indexDouble, meta) {
                        final index = indexDouble.toInt();
                        if (index < 0 || index >= topList.length) return const SizedBox();
                        final name = topList[index].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSizes.s8),
                          child: Text(
                            name.length > 8 ? '${name.substring(0, 6)}..' : name,
                            style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSummaryTable(AdminStatsProvider provider, bool isDark) {
    final stats = provider.stats;
    final isMobile = MediaQuery.of(context).size.width < 500;

    return GlassCard(
      padding: EdgeInsets.all(isMobile ? AppSizes.s16 : AppSizes.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(Icons.summarize_rounded, color: AppColors.primary, size: AppSizes.iconSm),
              ),
              SizedBox(width: AppSizes.s12),
              Text('System Growth & Volume Summary', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: AppSizes.s20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
              },
              children: [
                _buildTableRow('Metric Description', 'Active Value', 'Today Change', isDark, isHeader: true),
                _buildTableRow('Registered Profiles', stats.totalUsers.toString(), '+${stats.newUsersToday}', isDark),
                _buildTableRow('Books Listed for Exchange/Sale', stats.totalBooks.toString(), '+${stats.newBooksToday}', isDark),
                _buildTableRow('Real-time Active Chats', stats.totalChats.toString(), '-', isDark),
                _buildTableRow('Actionable Reports Log', stats.pendingReports.toString(), '-', isDark),
                _buildTableRow('Announcement Board', stats.activeAnnouncements.toString(), '-', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String desc, String val, String delta, bool isDark, {bool isHeader = false}) {
    final textStyle = GoogleFonts.poppins(
      color: isHeader ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
      fontSize: isHeader ? 12 : 13,
    );

    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
          child: Text(desc, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
          child: Text(val, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
          child: Text(
            delta,
            style: isHeader
                ? textStyle
                : GoogleFonts.poppins(
                    color: delta.startsWith('+') && delta != '+0' ? AppColors.success : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
          ),
        ),
      ],
    );
  }
}
