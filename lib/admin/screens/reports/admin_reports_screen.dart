// lib/admin/screens/reports/admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_report_provider.dart';
import '../../models/report_model.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportProvider>().fetchReports(statusFilter: ReportStatus.pending);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final status = switch (_tabController.index) { 0 => ReportStatus.pending, 1 => ReportStatus.resolved, 2 => ReportStatus.dismissed, _ => ReportStatus.pending };
    context.read<AdminReportProvider>().fetchReports(statusFilter: status);
  }

  void _showResolveDismissDialog(BuildContext context, ReportModel report, bool isResolving) {
    final noteController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: AppSizes.cardPadding,
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(AppSizes.s8), decoration: BoxDecoration(color: (isResolving ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
                  child: Icon(isResolving ? Icons.done_all_rounded : Icons.close_rounded, color: isResolving ? AppColors.success : AppColors.textSecondary, size: AppSizes.iconMd)),
                const SizedBox(width: AppSizes.s12),
                Text(isResolving ? 'Resolve Report' : 'Dismiss Report', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: AppSizes.s12),
              Text(isResolving ? 'Add an administrative note detailing the action taken.' : 'Provide a brief explanation for dismissing this report.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13, height: 1.4)),
              const SizedBox(height: AppSizes.s16),
              TextField(
                controller: noteController, maxLines: 3,
                style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter admin note (optional)...',
                  hintStyle: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s14),
                ),
              ),
              const SizedBox(height: AppSizes.s24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                SizedBox(width: 100, child: PremiumButton(label: 'Cancel', style: PremiumButtonStyle.secondary, height: AppSizes.buttonMd, onPressed: () => Navigator.pop(dialogContext))),
                const SizedBox(width: AppSizes.s12),
                SizedBox(width: 120, child: PremiumButton(
                  label: isResolving ? 'Resolve' : 'Dismiss',
                  color: isResolving ? AppColors.success : AppColors.textSecondary,
                  height: AppSizes.buttonMd,
                  onPressed: () async {
                    final note = noteController.text.trim();
                    final noteVal = note.isEmpty ? null : note;
                    Navigator.pop(dialogContext);
                    final provider = context.read<AdminReportProvider>();
                    final success = isResolving ? await provider.resolveReport(report.id, note: noteVal) : await provider.dismissReport(report.id, note: noteVal);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report ${isResolving ? 'resolved' : 'dismissed'} successfully')));
                    }
                  },
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const AdminConfirmDialog(title: 'Delete Report Log', content: 'Are you sure you want to permanently delete this report log?', confirmLabel: 'Delete', isDangerous: true),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<AdminReportProvider>().deleteReport(report.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted successfully')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminReportProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: AppSizes.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Center', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: AppSizes.s4),
            Text('Moderate platform flags, spam listings, or policy-violating profiles.', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: AppSizes.s24),
            GlassCard(
              padding: const EdgeInsets.all(AppSizes.s4),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [Tab(text: 'Pending'), Tab(text: 'Resolved'), Tab(text: 'Dismissed')],
              ),
            ),
            const SizedBox(height: AppSizes.s20),
            Expanded(child: _buildReportsList(provider, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(AdminReportProvider provider, bool isDark) {
    if (provider.isLoading && provider.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (provider.reports.isEmpty) {
      final tabLabel = switch (_tabController.index) { 0 => 'pending', 1 => 'resolved', 2 => 'dismissed', _ => '' };
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(AppSizes.s20), decoration: BoxDecoration(color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5))),
          child: const Icon(Icons.assignment_turned_in_rounded, size: 40, color: AppColors.textMuted)),
        const SizedBox(height: AppSizes.s16),
        Text('No $tabLabel reports', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.s4),
        Text('Everything looks clean in this section.', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 12)),
      ]));
    }

    return ListView.separated(
      itemCount: provider.reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.s12),
      itemBuilder: (context, index) => _buildReportCard(provider.reports[index], isDark),
    );
  }

  Widget _buildReportCard(ReportModel report, bool isDark) {
    return GlassCard(
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('REPORT #${report.id.substring(0, 8).toUpperCase()}', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const Spacer(),
            Flexible(child: Text(report.createdAt.toLocal().toString().split('.')[0], style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: AppSizes.s16),
          _buildReportedItemRow(report, isDark),
          const SizedBox(height: AppSizes.s16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.s12),
            decoration: BoxDecoration(color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppSizes.radiusSm), border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.4))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reason for reporting:', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.s4),
              Text(report.reason, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 13, height: 1.4)),
            ]),
          ),
          if (report.adminNote != null && report.adminNote!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.s12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(AppSizes.s12),
              decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusSm), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Administrative Note:', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.s4),
                Text(report.adminNote!, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ]),
            ),
          ],
          if (report.status == ReportStatus.pending) ...[
            const SizedBox(height: AppSizes.s16),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.s12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Expanded(child: PremiumButton(
                label: 'Dismiss', icon: const Icon(Icons.close_rounded, size: 14),
                style: PremiumButtonStyle.secondary, height: AppSizes.buttonMd,
                onPressed: () => _showResolveDismissDialog(context, report, false),
              )),
              const SizedBox(width: AppSizes.s12),
              Expanded(child: PremiumButton(
                label: 'Resolve', icon: const Icon(Icons.done_all_rounded, size: 14),
                color: AppColors.success, height: AppSizes.buttonMd,
                onPressed: () => _showResolveDismissDialog(context, report, true),
              )),
            ]),
          ] else ...[
            const SizedBox(height: AppSizes.s12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: () => _confirmDelete(context, report),
                icon: const Icon(Icons.delete_outline_rounded, size: AppSizes.iconSm),
                label: Text('Delete Log', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildReportedItemRow(ReportModel report, bool isDark) {
    String typeLabel = '';
    String titleText = '';
    IconData itemIcon;
    if (report.reportedPostId != null) {
      typeLabel = 'REPORTED LISTING';
      titleText = report.reportedPostTitle ?? 'Unknown Listing';
      itemIcon = Icons.inventory_2_rounded;
    } else {
      typeLabel = 'REPORTED USER';
      titleText = report.reportedUserName ?? 'Unknown User';
      itemIcon = Icons.person_rounded;
    }

    return Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: isDark ? AppColors.bgSurfaceDark.withValues(alpha: 0.5) : AppColors.bgSurface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppSizes.radiusXs)), child: Icon(itemIcon, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, size: 16)),
      const SizedBox(width: AppSizes.s12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(typeLabel, style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSizes.s2),
        Text(titleText, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ])),
      if (report.reporterName != null) ...[
        const SizedBox(width: AppSizes.s12),
        Text('By: ${report.reporterName}', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    ]);
  }
}
