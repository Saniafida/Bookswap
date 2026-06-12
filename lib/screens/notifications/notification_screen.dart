import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/swaply_background.dart';
import 'widgets/notification_tile.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return SwaplyBackground(
          child: Scaffold(
            appBar: CustomAppBar(
              title: 'Notifications',
              actions: [
                if (provider.unreadCount > 0)
                  TextButton(
                    onPressed: () => provider.markAllAsRead(),
                    child: Text('Mark all read',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.primary)),
                  ),
              ],
            ),
            body: provider.isLoading
                ? const LoadingWidget()
                : provider.notifications.isEmpty
                    ? _buildEmptyState(context)
                    : _buildList(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_rounded,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('No notifications yet',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('We\'ll notify you when something happens',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, NotificationProvider provider) {
    final grouped = _groupNotifications(provider.notifications);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: grouped.entries.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(entry.key,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            ...entry.value.map((n) => NotificationTile(
                  notification: n,
                  onTap: () => _handleTap(context, n),
                )),
          ],
        );
      },
    );
  }

  Map<String, List<NotificationModel>> _groupNotifications(
      List<NotificationModel> list) {
    final groups = <String, List<NotificationModel>>{};
    for (final n in list) {
      groups.putIfAbsent(n.groupLabel, () => []).add(n);
    }
    return groups;
  }

  void _handleTap(BuildContext context, NotificationModel notification) {
    context.read<NotificationProvider>().markAsRead(notification.id);

    final chatId = notification.data['chat_id'] as String?;
    if (chatId != null) {
      Navigator.pushNamed(context, '/chat', arguments: <String, dynamic>{'chatId': chatId});
      return;
    }

    final listingId = notification.data['listing_id'] as String?;
    if (listingId != null) {
      Navigator.pushNamed(context, '/listing-details', arguments: <String, dynamic>{'listingId': listingId});
    }
  }
}
