import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_announcement_provider.dart';
import '../../models/announcement_model.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../widgets/admin_section_header.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/premium_button.dart';
import '../../../widgets/premium_textfield.dart';
import '../../../widgets/premium_loading.dart';
import '../../../widgets/announcement_banner.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int _priority = 0;
  bool _isSaving = false;
  AnnouncementModel? _editingAnnouncement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAnnouncementProvider>().fetchAnnouncements();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AdminConfirmDialog(
        title: 'Delete Announcement',
        content: 'Are you sure you want to permanently delete "${announcement.title}"? Users will no longer see this notice.',
        confirmLabel: 'Delete',
        isDangerous: true,
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AdminAnnouncementProvider>().delete(announcement.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
      }
    }
  }

  void _toggleActive(BuildContext context, AnnouncementModel announcement, bool active) async {
    final success = await context.read<AdminAnnouncementProvider>().toggleActive(announcement.id, active: active);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement is now ${active ? 'active' : 'inactive'}')),
      );
    }
  }

  void _startEdit(AnnouncementModel announcement) {
    setState(() {
      _editingAnnouncement = announcement;
      _titleController.text = announcement.title;
      _bodyController.text = announcement.body;
      _priority = announcement.priority;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingAnnouncement = null;
      _titleController.clear();
      _bodyController.clear();
      _priority = 0;
    });
  }

  void _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final provider = context.read<AdminAnnouncementProvider>();

    bool success;
    if (_editingAnnouncement != null) {
      final updated = _editingAnnouncement!.copyWith(
        title: title,
        body: body,
        priority: _priority,
      );
      success = await provider.update(updated);
    } else {
      final newAnn = AnnouncementModel(
        id: '',
        title: title,
        body: body,
        priority: _priority,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await provider.create(newAnn);
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      _cancelEdit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement ${_editingAnnouncement != null ? 'updated' : 'posted'} successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post announcement: ${provider.error ?? 'Unknown error'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAnnouncementProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: AppSizes.pagePaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: 'Announcements Manager',
              subtitle: 'Compose system broadcast updates and display live notification banner headers.',
            ),
            SizedBox(height: AppSizes.s24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildComposerCard(isDark),
                                SizedBox(height: AppSizes.s24),
                                _buildPreviewCard(isDark),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: AppSizes.s24),
                        Expanded(
                          flex: 5,
                          child: _buildFeedColumn(provider, isDark),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildComposerCard(isDark),
                          SizedBox(height: AppSizes.s24),
                          _buildPreviewCard(isDark),
                          SizedBox(height: AppSizes.s24),
                          _buildFeedColumn(provider, isDark, isMobile: true),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerCard(bool isDark) {
    return GlassCard(
      padding: AppSizes.cardPadding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.s10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(Icons.campaign_rounded, color: AppColors.primary, size: AppSizes.iconMd),
                ),
                SizedBox(width: AppSizes.s12),
                Text(
                  _editingAnnouncement != null ? 'Edit Broadcast Post' : 'Compose Broadcast Post',
                  style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                if (_editingAnnouncement != null) ...[
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.cancel_outlined, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                    onPressed: _cancelEdit,
                    tooltip: 'Cancel Edit',
                  ),
                ],
              ],
            ),
            SizedBox(height: AppSizes.s16),
            PremiumTextField(
              controller: _titleController,
              hint: 'Add an announcement title...',
              onChanged: (_) => setState(() {}),
              validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
            ),
            SizedBox(height: AppSizes.s12),
            PremiumTextField(
              controller: _bodyController,
              hint: 'What notice or warning do you want to share with users?',
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              validator: (val) => val == null || val.trim().isEmpty ? 'Notice body text is required' : null,
            ),
            SizedBox(height: AppSizes.s16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text('Priority: ', style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: AppSizes.s8),
                  _buildPriorityButton(0, 'Normal'),
                  SizedBox(width: AppSizes.s6),
                  _buildPriorityButton(1, 'Warning'),
                  SizedBox(width: AppSizes.s6),
                  _buildPriorityButton(2, 'Critical'),
                ],
              ),
            ),
            SizedBox(height: AppSizes.s20),
            PremiumButton(
              label: _editingAnnouncement != null ? 'Update Post' : 'Publish Broadcast',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : () => _save(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(int val, String label) {
    final isSelected = _priority == val;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    Color bg = isDark ? AppColors.borderDark : AppColors.divider;
    if (val == 1) {
      color = AppColors.warning;
      bg = AppColors.warningLight;
    } else if (val == 2) {
      color = AppColors.error;
      bg = AppColors.errorLight;
    }

    return InkWell(
      onTap: () => setState(() => _priority = val),
      borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12, vertical: AppSizes.s8),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.transparent,
          border: Border.all(color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.border)),
          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(color: isSelected ? color : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary), fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark) {
    final hasContent = _titleController.text.isNotEmpty || _bodyController.text.isNotEmpty;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Banner Preview', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          SizedBox(height: AppSizes.s12),
          if (!hasContent)
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.divider,
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Center(child: Text('Fill in the composer inputs to see preview.', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 12))),
            )
          else
            _buildCustomPreviewBanner(isDark),
        ],
      ),
    );
  }

  Widget _buildCustomPreviewBanner(bool isDark) {
    Color cardColor = AppColors.primary;
    Color tintColor = AppColors.primary.withValues(alpha: 0.1);
    IconData icon = Icons.info_outline_rounded;

    if (_priority == 1) {
      cardColor = AppColors.warning;
      tintColor = AppColors.warningLight;
      icon = Icons.warning_amber_rounded;
    } else if (_priority == 2) {
      cardColor = AppColors.error;
      tintColor = AppColors.errorLight;
      icon = Icons.error_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s12),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cardColor, size: AppSizes.iconMd),
          SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_titleController.text, style: GoogleFonts.poppins(color: cardColor, fontSize: 13, fontWeight: FontWeight.w800)),
                if (_bodyController.text.isNotEmpty) ...[
                  SizedBox(height: AppSizes.s2),
                  Text(_bodyController.text, style: GoogleFonts.poppins(color: cardColor.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: cardColor, size: AppSizes.iconSm),
            onPressed: () {},
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedColumn(AdminAnnouncementProvider provider, bool isDark, {bool isMobile = false}) {
    if (provider.isLoading && provider.announcements.isEmpty) {
      return const PageShimmer(itemCount: 3);
    }

    if (provider.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: AppSizes.iconXl, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
            SizedBox(height: AppSizes.s12),
            Text('No announcements posted yet.', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(Icons.history_rounded, color: AppColors.primary, size: AppSizes.iconSm),
              ),
              SizedBox(width: AppSizes.s12),
              Text('Broadcast Stream History', style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: AppSizes.s16),
          if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.announcements.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.dividerDark : AppColors.divider, height: AppSizes.s20),
              itemBuilder: (context, index) {
                final ann = provider.announcements[index];
                return _buildAnnouncementFeedTile(ann, isDark);
              },
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: provider.announcements.length,
                separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.dividerDark : AppColors.divider, height: AppSizes.s20),
                itemBuilder: (context, index) {
                  final ann = provider.announcements[index];
                  return _buildAnnouncementFeedTile(ann, isDark);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementFeedTile(AnnouncementModel announcement, bool isDark) {
    Color accentColor = AppColors.primary;
    if (announcement.priority == 1) {
      accentColor = AppColors.warning;
    } else if (announcement.priority == 2) {
      accentColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(announcement.title, style: GoogleFonts.poppins(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      SizedBox(width: AppSizes.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s6, vertical: AppSizes.s2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                        ),
                        child: Text(
                          announcement.priority == 0
                              ? 'Normal'
                              : announcement.priority == 1
                                  ? 'Warning'
                                  : 'Critical',
                          style: GoogleFonts.poppins(color: accentColor, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.s4),
                  Text('Posted on ${announcement.createdAt.toLocal().toString().split(' ')[0]}', style: GoogleFonts.poppins(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Switch(
              value: announcement.isActive,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primaryLight,
              onChanged: (val) => _toggleActive(context, announcement, val),
            ),
          ],
        ),
        SizedBox(height: AppSizes.s8),
        Text(announcement.body, style: GoogleFonts.poppins(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 12, height: 1.4)),
        SizedBox(height: AppSizes.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _startEdit(announcement),
              icon: Icon(Icons.edit_outlined, size: AppSizes.iconXs, color: AppColors.primary),
              label: Text('Edit', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
                minimumSize: const Size(40, 24),
              ),
            ),
            SizedBox(width: AppSizes.s16),
            TextButton.icon(
              onPressed: () => _confirmDelete(context, announcement),
              icon: Icon(Icons.delete_outline_rounded, size: AppSizes.iconXs, color: AppColors.error),
              label: Text('Delete', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
                minimumSize: const Size(40, 24),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
